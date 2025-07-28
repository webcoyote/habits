import Foundation
import SwiftUI
import CoreData

class HabitListViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    
    func moveHabits(from source: IndexSet, to destination: Int, context: NSManagedObjectContext) {
        // Create a copy of habits array
        var reorderedHabits = habits
        
        // Perform the move
        reorderedHabits.move(fromOffsets: source, toOffset: destination)
        
        // Update the published property immediately to prevent UI glitch
        habits = reorderedHabits
        
        // Update Core Data with batch operation
        context.perform {
            do {
                // Fetch all habit entities
                let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
                let entities = try context.fetch(request)
                
                // Create a dictionary for quick lookup
                let entityDict: [UUID: HabitEntity] = Dictionary(uniqueKeysWithValues: entities.compactMap { entity in
                    guard let id = entity.id else { return nil }
                    return (id, entity)
                })
                
                // Update order for all habits in one batch
                for (index, habit) in reorderedHabits.enumerated() {
                    if let entity = entityDict[habit.id] {
                        entity.order = Int32(index)
                    }
                }
                
                // Single save operation
                if context.hasChanges {
                    PersistenceController.shared.save(context: context)
                }
            } catch {
                print("Error updating habit order: \(error)")
            }
        }
    }
    
    func loadHabits(from entities: FetchedResults<HabitEntity>, context: NSManagedObjectContext) {
        let decoder = JSONDecoder()
        
        // Check if any habits need order assignment
        var needsOrderUpdate = false
        for (index, entity) in entities.enumerated() {
            if entity.order == 0 && index > 0 {
                entity.order = Int32(index)
                needsOrderUpdate = true
            }
        }
        if needsOrderUpdate {
            try? context.save()
        }
        
        habits = entities.compactMap { entity in
            guard let id = entity.id,
                  let name = entity.name,
                  let icon = entity.icon,
                  let colorData = entity.colorData,
                  let typeData = entity.typeData else { return nil }
            
            guard let color = try? decoder.decode(CodableColor.self, from: colorData),
                  let type = try? decoder.decode(HabitType.self, from: typeData) else { return nil }
            
            let goal = entity.goalData.flatMap { try? decoder.decode(Goal.self, from: $0) }
            
            let records = (entity.records as? Set<RecordEntity>)?.compactMap { recordEntity -> DayRecord? in
                guard let recordId = recordEntity.id,
                      let date = recordEntity.date,
                      let valueData = recordEntity.valueData,
                      let value = try? decoder.decode(HabitValue.self, from: valueData) else { return nil }
                
                return DayRecord(id: recordId, date: date, value: value)
            } ?? []
            
            return Habit(id: id, name: name, icon: icon, color: color.color, type: type, goal: goal, history: records.sorted { $0.date > $1.date })
        }
    }
    
    func addHabit(_ habit: Habit, context: NSManagedObjectContext) {
        habits.append(habit)
        PersistenceController.shared.saveHabit(habit, context: context)
    }
    
    func updateHabit(_ habit: Habit, context: NSManagedObjectContext) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            PersistenceController.shared.updateHabit(habit, context: context)
        }
    }
    
    func deleteHabit(_ habit: Habit, context: NSManagedObjectContext) {
        // Track habit deletion
        let statistics = HabitStatistics(habit: habit, timeRange: .allTime)
        AnalyticsManager.shared.track("habit_deleted", properties: [
            "habit_id": habit.id.uuidString,
            "habit_name": habit.name,
            "days_active": habit.history.count,
            "current_streak": statistics.currentStreak
        ])
        
        habits.removeAll { $0.id == habit.id }
        PersistenceController.shared.deleteHabit(habit, context: context)
    }
    
    func updateHabitValue(_ habit: Habit, value: Int) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        var updatedHabit = habit
        let today = Date()
        let calendar = Calendar.current
        
        updatedHabit.history.removeAll { calendar.isDate($0.date, inSameDayAs: today) }
        
        let newRecord: DayRecord
        switch habit.type {
        case .binary:
            newRecord = DayRecord(date: today, value: .binary(completed: value > 0))
        case .numeric:
            newRecord = DayRecord(date: today, value: .numeric(value: value))
        case .graph:
            newRecord = DayRecord(date: today, value: .graph(value: value))
        }
        
        updatedHabit.history.append(newRecord)
        habits[index] = updatedHabit
        
        saveRecord(newRecord, for: updatedHabit)
        
        // Track completed habits for review prompts
        if value > 0 {
            AppSettings.shared.incrementCompletedHabits()
            Task {
                await UsageTracker.shared.requestReviewIfAppropriate()
            }
        }
    }
    
    private func getCurrentNumericValue(for habit: Habit) -> Int {
        let today = Date()
        let calendar = Calendar.current
        
        guard let todayRecord = habit.history.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) else { return 0 }
        
        switch todayRecord.value {
        case .numeric(let value):
            return value
        default:
            return 0
        }
    }
    
    private func saveRecord(_ record: DayRecord, for habit: Habit) {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
        
        do {
            if let habitEntity = try context.fetch(request).first {
                let recordRequest: NSFetchRequest<RecordEntity> = RecordEntity.fetchRequest()
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: record.date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                recordRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "habit == %@", habitEntity),
                    NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
                ])
                
                let existingRecords = try context.fetch(recordRequest)
                existingRecords.forEach { context.delete($0) }
                
                let recordEntity = RecordEntity(context: context)
                recordEntity.id = record.id
                recordEntity.date = record.date
                recordEntity.valueData = try JSONEncoder().encode(record.value)
                recordEntity.habit = habitEntity
                
                PersistenceController.shared.save(context: context)
            }
        } catch {
            print("Error saving record: \(error)")
        }
    }
}
