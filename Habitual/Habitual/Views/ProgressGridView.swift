import SwiftUI

struct ProgressGridView: View {
    let habit: Habit
    let daysToShow: Int
    let columnsPerRow: Int
    
    init(habit: Habit, daysToShow: Int = 90, columnsPerRow: Int = 30) {
        self.habit = habit
        self.daysToShow = daysToShow
        self.columnsPerRow = columnsPerRow
    }
    
    var body: some View {
        GeometryReader { geometry in
            let squareSize: CGFloat = 8 // Fixed square size
            let spacing: CGFloat = 2
            let availableWidth = geometry.size.width
            
            // Calculate columns that fit in available width
            let maxColumns = Int((availableWidth + spacing) / (squareSize + spacing))
            let columnsToUse = min(maxColumns, columnsPerRow)
            
            // Always show 7 rows (one week)
            let rowsToShow = 7
            let totalDays = rowsToShow * columnsToUse
            
            // Get the most recent days that fit in our grid
            let dates = getDateRange(limit: totalDays)
            
            // Reorganize dates to fill column-wise from bottom-right
            let columnOrderedDates = arrangeInColumnOrder(dates: dates, rows: rowsToShow, columns: columnsToUse)
            
            VStack(spacing: spacing) {
                ForEach(0..<rowsToShow, id: \.self) { rowIndex in
                    HStack(spacing: spacing) {
                        ForEach(0..<columnsToUse, id: \.self) { colIndex in
                            let dateIndex = rowIndex * columnsToUse + colIndex
                            if dateIndex < columnOrderedDates.count {
                                let date = columnOrderedDates[dateIndex]
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
    
    private func calculateSquareSize(for width: CGFloat) -> CGFloat {
        let totalSpacing = CGFloat(columnsPerRow - 1) * 2
        let availableWidth = width - totalSpacing
        return max(8, min(12, availableWidth / CGFloat(columnsPerRow)))
    }
    
    private func getDateRange(limit: Int? = nil) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        
        let daysToGet = limit ?? daysToShow
        
        for dayOffset in (0..<daysToGet).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private func arrangeInColumnOrder(dates: [Date], rows: Int, columns: Int) -> [Date] {
        var result: [Date] = []
        
        // Create a 2D array to hold dates in their final positions
        var grid: [[Date?]] = Array(repeating: Array(repeating: nil, count: columns), count: rows)
        
        // Fill the grid column by column, from bottom to top, right to left
        var dateIndex = dates.count - 1 // Start with the most recent date
        
        // Start from the rightmost column
        for col in (0..<columns).reversed() {
            // Fill from bottom to top
            for row in (0..<rows).reversed() {
                if dateIndex >= 0 && dateIndex < dates.count {
                    grid[row][col] = dates[dateIndex]
                    dateIndex -= 1
                }
            }
        }
        
        // Convert the 2D grid back to a 1D array in row order for display
        for row in 0..<rows {
            for col in 0..<columns {
                if let date = grid[row][col] {
                    result.append(date)
                }
            }
        }
        
        return result
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
