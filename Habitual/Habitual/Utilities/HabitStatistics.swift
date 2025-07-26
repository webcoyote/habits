import Foundation

enum TimeRangeOption: Int {
    case week = 0
    case month = 1
    case threeMonths = 2
    case year = 3
    case allTime = 4
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        case .allTime: return Int.max
        }
    }
}

struct HabitStatistics {
    let habit: Habit
    let timeRange: TimeRangeOption
    
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    var bestStreak: Int {
        calculateBestStreak()
    }
    
    var completionRate: Int {
        calculateCompletionRate()
    }
    
    var totalCompletions: Int {
        calculateTotalCompletions()
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            if isCompleted(on: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if calendar.isDateInToday(currentDate) {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                continue
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateBestStreak() -> Int {
        let sortedRecords = habit.history.sorted { $0.date < $1.date }
        var bestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for record in sortedRecords {
            if isRecordCompleted(record) {
                if let last = lastDate {
                    let daysDifference = Calendar.current.dateComponents([.day], from: last, to: record.date).day ?? 0
                    if daysDifference == 1 {
                        currentStreak += 1
                    } else {
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }
                bestStreak = max(bestStreak, currentStreak)
                lastDate = record.date
            } else {
                currentStreak = 0
                lastDate = nil
            }
        }
        
        return bestStreak
    }
    
    private func calculateCompletionRate() -> Int {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        if timeRange == .allTime {
            startDate = habit.history.map { $0.date }.min() ?? endDate
        } else {
            startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate) ?? endDate
        }
        
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let completedDays = calculateTotalCompletions()
        
        return totalDays > 0 ? Int((Double(completedDays) / Double(totalDays)) * 100) : 0
    }
    
    private func calculateTotalCompletions() -> Int {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        if timeRange == .allTime {
            return habit.history.filter { isRecordCompleted($0) }.count
        } else {
            startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate) ?? endDate
            return habit.history.filter { record in
                record.date >= startDate && record.date <= endDate && isRecordCompleted(record)
            }.count
        }
    }
    
    private func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        guard let record = habit.history.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else { return false }
        
        return isRecordCompleted(record)
    }
    
    private func isRecordCompleted(_ record: DayRecord) -> Bool {
        switch record.value {
        case .binary(let completed):
            return completed
        case .numeric(let value):
            if case .numeric(let target) = habit.type {
                return value >= target
            }
            return value > 0
        case .mood(let value):
            return value > 0
        }
    }
}
