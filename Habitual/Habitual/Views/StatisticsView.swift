import SwiftUI

struct StatisticsView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitEntity.name, ascending: true)],
        animation: .default)
    private var habitEntities: FetchedResults<HabitEntity>
    
    @State private var selectedTimeRange = 1
    let timeRanges = ["Week", "Month", "3 Months", "Year", "All Time"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background for entire page
                appSettings.backgroundGradientWithOpacity
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(0..<timeRanges.count, id: \.self) { index in
                            Text(timeRanges[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    OverallStatsCard(habitEntities: habitEntities, timeRange: selectedTimeRange)
                    
                    if !habitEntities.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Habit Performance")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(habitEntities), id: \.id) { habitEntity in
                                if let habit = habitFromEntity(habitEntity) {
                                    HabitStatsCard(habit: habit, timeRange: selectedTimeRange)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
            }
        }
    }
    
    private func habitFromEntity(_ entity: HabitEntity) -> Habit? {
        guard let id = entity.id,
              let name = entity.name,
              let icon = entity.icon,
              let colorData = entity.colorData,
              let typeData = entity.typeData else { return nil }
        
        let decoder = JSONDecoder()
        guard let color = try? decoder.decode(CodableColor.self, from: colorData),
              let type = try? decoder.decode(HabitType.self, from: typeData) else { return nil }
        
        let records = (entity.records as? Set<RecordEntity>)?.compactMap { recordEntity -> DayRecord? in
            guard let recordId = recordEntity.id,
                  let date = recordEntity.date,
                  let valueData = recordEntity.valueData,
                  let value = try? decoder.decode(HabitValue.self, from: valueData) else { return nil }
            
            return DayRecord(id: recordId, date: date, value: value)
        } ?? []
        
        return Habit(id: id, name: name, icon: icon, color: color.color, type: type, history: records)
    }
}

struct OverallStatsCard: View {
    let habitEntities: FetchedResults<HabitEntity>
    let timeRange: Int
    
    private var habits: [Habit] {
        habitEntities.compactMap { entity in
            habitFromEntity(entity)
        }
    }
    
    private var totalCompletions: Int {
        habits.reduce(0) { total, habit in
            let stats = HabitStatistics(habit: habit, timeRange: TimeRangeOption(rawValue: timeRange) ?? .month)
            return total + stats.totalCompletions
        }
    }
    
    private var averageCompletionRate: Int {
        guard !habits.isEmpty else { return 0 }
        
        let totalRate = habits.reduce(0) { total, habit in
            let stats = HabitStatistics(habit: habit, timeRange: TimeRangeOption(rawValue: timeRange) ?? .month)
            return total + stats.completionRate
        }
        
        return totalRate / habits.count
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayHasCompletion = habits.contains { habit in
                habit.history.contains { record in
                    calendar.isDate(record.date, inSameDayAs: currentDate) && isRecordCompleted(record, habitType: habit.type)
                }
            }
            
            if dayHasCompletion {
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
    
    private func habitFromEntity(_ entity: HabitEntity) -> Habit? {
        guard let id = entity.id,
              let name = entity.name,
              let icon = entity.icon,
              let colorData = entity.colorData,
              let typeData = entity.typeData else { return nil }
        
        let decoder = JSONDecoder()
        guard let color = try? decoder.decode(CodableColor.self, from: colorData),
              let type = try? decoder.decode(HabitType.self, from: typeData) else { return nil }
        
        let records = (entity.records as? Set<RecordEntity>)?.compactMap { recordEntity -> DayRecord? in
            guard let recordId = recordEntity.id,
                  let date = recordEntity.date,
                  let valueData = recordEntity.valueData,
                  let value = try? decoder.decode(HabitValue.self, from: valueData) else { return nil }
            
            return DayRecord(id: recordId, date: date, value: value)
        } ?? []
        
        return Habit(id: id, name: name, icon: icon, color: color.color, type: type, history: records)
    }
    
    private func isRecordCompleted(_ record: DayRecord, habitType: HabitType) -> Bool {
        switch record.value {
        case .binary(let completed):
            return completed
        case .numeric(let value):
            if case .numeric(let target) = habitType {
                return value >= target
            }
            return value > 0
        case .graph(let value):
            return value > 0
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Overall Performance")
                .font(.headline)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Active Habits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(habits.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                HStack {
                    Text("Total Completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(totalCompletions)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                HStack {
                    Text("Success Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(averageCompletionRate)%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct HabitStatsCard: View {
    let habit: Habit
    let timeRange: Int
    
    private var statistics: HabitStatistics {
        HabitStatistics(habit: habit, timeRange: TimeRangeOption(rawValue: timeRange) ?? .month)
    }
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .font(.title2)
                .foregroundColor(habit.color.color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(habit.name)
                    .font(.headline)
                Text("\(statistics.completionRate)% completion rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(statistics.currentStreak)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("day streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
    }
}
