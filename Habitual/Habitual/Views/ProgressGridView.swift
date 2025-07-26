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
            let dates = getDateRange()
            let rows = dates.chunked(into: columnsPerRow)
            let squareSize = calculateSquareSize(for: geometry.size.width)
            
            VStack(spacing: 2) {
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 2) {
                        ForEach(rows[rowIndex], id: \.self) { date in
                            DaySquare(
                                date: date,
                                isCompleted: isCompleted(on: date),
                                color: habit.color.color,
                                size: squareSize
                            )
                        }
                        
                        if rows[rowIndex].count < columnsPerRow {
                            Spacer()
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
    
    private func getDateRange() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        
        for dayOffset in (0..<daysToShow).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                dates.append(date)
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
        case .mood(let value):
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
