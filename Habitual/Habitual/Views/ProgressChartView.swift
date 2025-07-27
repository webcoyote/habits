import SwiftUI
import Charts

enum ChartType {
    case bar
    case line
}

struct ProgressChartView: View {
    let habit: Habit
    let type: ChartType
    let daysToShow: Int
    
    init(habit: Habit, type: ChartType, daysToShow: Int = 7) {
        self.habit = habit
        self.type = type
        self.daysToShow = daysToShow
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ModernChartView(habit: habit, type: type, daysToShow: daysToShow)
        } else {
            LegacyChartView(habit: habit, type: type, daysToShow: daysToShow)
        }
    }
}

@available(iOS 16.0, *)
struct ModernChartView: View {
    let habit: Habit
    let type: ChartType
    let daysToShow: Int
    
    var body: some View {
        let data = getChartData()
        
        Chart(data) { item in
            switch type {
            case .bar:
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(habit.color.color)
                .cornerRadius(4)
            case .line:
                LineMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(habit.color.color)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(habit.color.color)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: getYDomain())
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(preset: .aligned, position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func getChartData() -> [ChartDataItem] {
        let calendar = Calendar.current
        let today = Date()
        var data: [ChartDataItem] = []
        
        for dayOffset in (0..<daysToShow).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let value = getValue(for: date)
                data.append(ChartDataItem(date: date, value: value))
            }
        }
        
        return data
    }
    
    private func getValue(for date: Date) -> Double {
        let calendar = Calendar.current
        guard let record = habit.history.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else { return 0 }
        
        switch record.value {
        case .binary(let completed):
            return completed ? 1 : 0
        case .numeric(let value):
            return Double(value)
        case .graph(let value):
            return Double(value)
        }
    }
    
    private func getYDomain() -> ClosedRange<Double> {
        switch habit.type {
        case .binary:
            return 0...1
        case .numeric(let target):
            let maxValue = getChartData().map { $0.value }.max() ?? Double(target)
            return 0...max(Double(target), maxValue * 1.1)
        case .graph(let scale):
            return 0...Double(scale)
        }
    }
}

struct LegacyChartView: View {
    let habit: Habit
    let type: ChartType
    let daysToShow: Int
    
    var body: some View {
        GeometryReader { geometry in
            let data = getSimpleChartData()
            let maxValue = data.map { $0.value }.max() ?? 1
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data) { item in
                    VStack {
                        Spacer()
                        
                        if type == .bar {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(habit.color.color)
                                .frame(height: max(2, geometry.size.height * CGFloat(item.value / maxValue)))
                        } else {
                            Circle()
                                .fill(habit.color.color)
                                .frame(width: 6, height: 6)
                                .offset(y: -geometry.size.height * CGFloat(item.value / maxValue) + geometry.size.height)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func getSimpleChartData() -> [SimpleChartItem] {
        let calendar = Calendar.current
        let today = Date()
        var data: [SimpleChartItem] = []
        
        for dayOffset in (0..<daysToShow).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let value = getValue(for: date)
                data.append(SimpleChartItem(id: dayOffset, value: value))
            }
        }
        
        return data
    }
    
    private func getValue(for date: Date) -> Double {
        let calendar = Calendar.current
        guard let record = habit.history.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else { return 0 }
        
        switch record.value {
        case .binary(let completed):
            return completed ? 1 : 0
        case .numeric(let value):
            return Double(value)
        case .graph(let value):
            return Double(value)
        }
    }
}

struct ChartDataItem: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct SimpleChartItem: Identifiable {
    let id: Int
    let value: Double
}
