import CoreData
import SwiftUI

class PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let sampleHabits = [
            Habit(name: "Morning Run", icon: "figure.run", color: .orange, type: .binary),
            Habit(name: "Drink Water", icon: "drop.fill", color: .blue, type: .numeric(target: 8)),
            Habit(name: "Daily Mood", icon: "face.smiling", color: .purple, type: .mood(scale: 10)),
            Habit(name: "Read", icon: "book.fill", color: .orange.opacity(0.8), type: .numeric(target: 30)),
            Habit(name: "Meditate", icon: "brain.head.profile", color: .green, type: .binary),
            Habit(name: "Sleep 8 Hours", icon: "bed.double.fill", color: .indigo, type: .binary)
        ]
        
        for (index, habit) in sampleHabits.enumerated() {
            result.saveHabit(habit, context: viewContext)
            // Set initial order for preview data
            let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
            if let entity = try? viewContext.fetch(request).first {
                entity.order = Int32(index)
            }
        }
        try? viewContext.save()
        
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Habitual")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch let error as NSError {
            // Handle merge conflicts
            if error.code == 133020 { // NSManagedObjectMergeError
                print("Merge conflict detected, attempting to resolve...")
                
                // Refresh objects with conflicts
                if let conflicts = error.userInfo["conflictList"] as? [NSManagedObject] {
                    conflicts.forEach { conflict in
                        context.refresh(conflict, mergeChanges: true)
                    }
                }
                
                // Retry save
                do {
                    try context.save()
                } catch {
                    print("Failed to save after merge conflict resolution: \(error)")
                }
            } else {
                print("Core Data save error: \(error), \(error.userInfo)")
            }
        }
    }
    
    func saveHabit(_ habit: Habit, context: NSManagedObjectContext) {
        let habitEntity = HabitEntity(context: context)
        habitEntity.id = habit.id
        habitEntity.name = habit.name
        habitEntity.icon = habit.icon
        habitEntity.createdAt = Date()
        habitEntity.modifiedAt = Date()
        
        // Set order to be at the end
        let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        let count = (try? context.count(for: request)) ?? 0
        habitEntity.order = Int32(count)
        
        let encoder = JSONEncoder()
        habitEntity.colorData = try? encoder.encode(habit.color)
        habitEntity.typeData = try? encoder.encode(habit.type)
        habitEntity.goalData = habit.goal.flatMap { try? encoder.encode($0) }
        
        for record in habit.history {
            let recordEntity = RecordEntity(context: context)
            recordEntity.id = record.id
            recordEntity.date = record.date
            recordEntity.valueData = try? encoder.encode(record.value)
            recordEntity.habit = habitEntity
        }
        
        save(context: context)
    }
    
    func updateHabit(_ habit: Habit, context: NSManagedObjectContext) {
        let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let habitEntity = results.first {
                habitEntity.name = habit.name
                habitEntity.icon = habit.icon
                habitEntity.modifiedAt = Date()
                
                let encoder = JSONEncoder()
                habitEntity.colorData = try? encoder.encode(habit.color)
                habitEntity.typeData = try? encoder.encode(habit.type)
                habitEntity.goalData = habit.goal.flatMap { try? encoder.encode($0) }
                
                save(context: context)
            }
        } catch {
            print("Error updating habit: \(error)")
        }
    }
    
    func deleteHabit(_ habit: Habit, context: NSManagedObjectContext) {
        let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let habitEntity = results.first {
                // Refresh the object to ensure we have the latest version
                context.refresh(habitEntity, mergeChanges: false)
                context.delete(habitEntity)
                save(context: context)
            }
        } catch {
            print("Error deleting habit: \(error)")
        }
    }
}
