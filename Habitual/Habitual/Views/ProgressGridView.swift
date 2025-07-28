import SwiftUI

struct ProgressGridView: View {
    let habit: Habit
    let daysToShow: Int
    
    init(habit: Habit, daysToShow: Int = 90) {
        self.habit = habit
        self.daysToShow = daysToShow
    }
    
    var body: some View {
        GeometryReader { geometry in
            let squareSize: CGFloat = 8 // Fixed square size
            let spacing: CGFloat = 2
            let availableWidth = geometry.size.width
            
            // Calculate columns that fit in available width
            let maxColumns = Int((availableWidth + spacing) / (squareSize + spacing))
            
            // Always show 7 rows (one week)
            let rowsToShow = 7
            
            // Calculate how many days we can actually show based on available space
            let totalDays = rowsToShow * maxColumns
            
            // Get the most recent days that fit in our grid
            let dates = getDateRange(limit: totalDays)
            
            // Recalculate columns based on actual dates to show
            let columnsToUse = min(maxColumns, max(1, (dates.count + rowsToShow - 1) / rowsToShow))
            
            VStack(spacing: spacing) {
                ForEach(0..<rowsToShow, id: \.self) { rowIndex in
                    HStack(spacing: spacing) {
                        ForEach(0..<columnsToUse, id: \.self) { colIndex in
                            if let date = getDateForPosition(row: rowIndex, col: colIndex, dates: dates, columns: columnsToUse) {
                                DaySquare(
                                    date: date,
                                    isCompleted: isCompleted(on: date),
                                    color: habit.color.color,
                                    size: squareSize
                                )
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.clear)
                                    .frame(width: squareSize, height: squareSize)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getDateForPosition(row: Int, col: Int, dates: [Date], columns: Int) -> Date? {
        let calendar = Calendar.current
        guard !dates.isEmpty else { return nil }
        
        // Calculate date index based on column-wise filling
        var dateIndex = dates.count - 1
        
        // Process columns from right to left
        for currentCol in (0..<columns).reversed() {
            if currentCol == columns - 1 && dateIndex >= 0 && dateIndex < dates.count {
                // For the rightmost column, check weekday constraints
                let mostRecentWeekday = calendar.component(.weekday, from: dates[dateIndex])
                let maxRowForCol = mostRecentWeekday - 1
                
                if currentCol == col {
                    // We're in the rightmost column
                    if row <= maxRowForCol {
                        let offset = maxRowForCol - row
                        let targetIndex = dateIndex - offset
                        if targetIndex >= 0 && targetIndex < dates.count {
                            return dates[targetIndex]
                        }
                    }
                    return nil
                } else {
                    // Skip past the dates in the rightmost column
                    dateIndex -= (maxRowForCol + 1)
                }
            } else if currentCol == col {
                // We're in the target column (not rightmost)
                let offset = 6 - row // bottom to top
                let targetIndex = dateIndex - offset
                if targetIndex >= 0 && targetIndex < dates.count {
                    return dates[targetIndex]
                }
                return nil
            } else {
                // Skip past the dates in this column
                dateIndex -= 7
            }
            
            if dateIndex < 0 {
                return nil
            }
        }
        
        return nil
    }
    
    private func calculateSquareSize(for width: CGFloat, columns: Int) -> CGFloat {
        let totalSpacing = CGFloat(columns - 1) * 2
        let availableWidth = width - totalSpacing
        return max(8, min(12, availableWidth / CGFloat(columns)))
    }
    
    private func getDateRange(limit: Int? = nil) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        
        // If we have history, use the earliest date from history
        if let earliestRecord = habit.history.min(by: { $0.date < $1.date }) {
            let startDate = earliestRecord.date
            let days = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
            let daysToGet = limit ?? max(daysToShow, days + 1)
            
            for dayOffset in (0..<daysToGet).reversed() {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    dates.append(date)
                }
            }
        } else {
            // No history, use default
            let daysToGet = limit ?? daysToShow
            
            for dayOffset in (0..<daysToGet).reversed() {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    dates.append(date)
                }
            }
        }
        
        return dates
    }
    
    
    private func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        guard let record = habit.history.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else { return false }
        
        switch record.value {
        case .binary(let completed):
            return completed
        case .numeric(let value):
            if case .numeric(let target) = habit.type {
                return value >= target
            }
            return value > 0
        case .graph(let value):
            return value > 0
        }
    }
}

struct DaySquare: View {
    let date: Date
    let isCompleted: Bool
    let color: Color
    let size: CGFloat
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        date > Date()
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(fillColor)
            .frame(width: size, height: size)
            .overlay(
                isToday ?
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.primary, lineWidth: 1.5)
                : nil
            )
    }
    
    private var fillColor: Color {
        if isFuture {
            return Color.gray.opacity(0.1)
        } else if isCompleted {
            return color
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
