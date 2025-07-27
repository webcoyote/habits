import Foundation
import CoreData
import SwiftUI
import UniformTypeIdentifiers

class BackupManager {
    static let shared = BackupManager()
    
    private let persistenceController = PersistenceController.shared
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    private init() {
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Backup Structure
    struct BackupData: Codable {
        let version: Int
        let createdAt: Date
        let habits: [Habit]
        
        init(habits: [Habit]) {
            self.version = 1
            self.createdAt = Date()
            self.habits = habits
        }
    }
    
    // MARK: - Backup Methods
    func createBackup(completion: @escaping (Result<URL, Error>) -> Void) {
        let context = persistenceController.container.viewContext
        
        context.perform {
            do {
                // Fetch all habits
                let habitRequest: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
                habitRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitEntity.order, ascending: true)]
                let habitEntities = try context.fetch(habitRequest)
                
                // Convert to Habit models
                var habits: [Habit] = []
                for habitEntity in habitEntities {
                    if let habit = self.habitFromEntity(habitEntity) {
                        habits.append(habit)
                    }
                }
                
                // Create backup data
                let backupData = BackupData(habits: habits)
                let jsonData = try self.jsonEncoder.encode(backupData)
                
                // Save to temporary file
                let fileName = "habitual_backup_\(Date().formatted(.iso8601)).json"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try jsonData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    completion(.success(tempURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Restore Methods
    func restoreBackup(from url: URL, completion: @escaping (Result<Int, Error>) -> Void) {
        do {
            // Read and decode backup data
            let jsonData = try Data(contentsOf: url)
            let backupData = try jsonDecoder.decode(BackupData.self, from: jsonData)
            
            // Validate backup version
            guard backupData.version == 1 else {
                throw BackupError.unsupportedVersion
            }
            
            // Perform restore on background context
            let context = persistenceController.container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            context.perform {
                do {
                    // Delete existing data more thoroughly
                    // First fetch all existing habits
                    let fetchRequest: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
                    let existingHabits = try context.fetch(fetchRequest)
                    
                    // Delete each habit (this also deletes related records due to cascade rules)
                    for habit in existingHabits {
                        context.delete(habit)
                    }
                    
                    // Save the deletion first
                    try context.save()
                    
                    // Reset the context to clear any cached data
                    context.reset()
                    
                    // Import new data
                    for (index, habit) in backupData.habits.enumerated() {
                        self.createHabitEntity(from: habit, order: index, in: context)
                    }
                    
                    // Save imported data
                    try context.save()
                    
                    // Notify the view context to refresh
                    DispatchQueue.main.async {
                        // Reset the view context to ensure it picks up all changes
                        self.persistenceController.container.viewContext.reset()
                        completion(.success(backupData.habits.count))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Helper Methods
    private func habitFromEntity(_ entity: HabitEntity) -> Habit? {
        guard let id = entity.id,
              let name = entity.name,
              let icon = entity.icon,
              let colorData = entity.colorData,
              let typeData = entity.typeData else {
            return nil
        }
        
        do {
            let color = try jsonDecoder.decode(CodableColor.self, from: colorData)
            let type = try jsonDecoder.decode(HabitType.self, from: typeData)
            let goal = entity.goalData.flatMap { try? jsonDecoder.decode(Goal.self, from: $0) }
            
            // Fetch records
            var history: [DayRecord] = []
            if let records = entity.records as? Set<RecordEntity> {
                for recordEntity in records {
                    if let recordId = recordEntity.id,
                       let date = recordEntity.date,
                       let valueData = recordEntity.valueData,
                       let value = try? jsonDecoder.decode(HabitValue.self, from: valueData) {
                        history.append(DayRecord(id: recordId, date: date, value: value))
                    }
                }
            }
            
            // Sort history by date
            history.sort { $0.date < $1.date }
            
            return Habit(
                id: id,
                name: name,
                icon: icon,
                color: color.color,
                type: type,
                goal: goal,
                history: history
            )
        } catch {
            print("Error converting entity to habit: \(error)")
            return nil
        }
    }
    
    private func createHabitEntity(from habit: Habit, order: Int, in context: NSManagedObjectContext) {
        let habitEntity = HabitEntity(context: context)
        habitEntity.id = habit.id
        habitEntity.name = habit.name
        habitEntity.icon = habit.icon
        habitEntity.createdAt = Date()
        habitEntity.modifiedAt = Date()
        habitEntity.order = Int32(order)
        
        habitEntity.colorData = try? jsonEncoder.encode(habit.color)
        habitEntity.typeData = try? jsonEncoder.encode(habit.type)
        habitEntity.goalData = habit.goal.flatMap { try? jsonEncoder.encode($0) }
        
        // Create record entities
        for record in habit.history {
            let recordEntity = RecordEntity(context: context)
            recordEntity.id = record.id
            recordEntity.date = record.date
            recordEntity.valueData = try? jsonEncoder.encode(record.value)
            recordEntity.habit = habitEntity
        }
    }
    
    // MARK: - Error Types
    enum BackupError: LocalizedError {
        case unsupportedVersion
        
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion:
                return "This backup file is from a newer version of the app and cannot be restored."
            }
        }
    }
}
