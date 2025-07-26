import SwiftUI

struct StatisticsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitEntity.name, ascending: true)],
        animation: .default)
    private var habitEntities: FetchedResults<HabitEntity>
    
    @State private var selectedTimeRange = 1
    let timeRanges = ["Week", "Month", "3 Months", "Year", "All Time"]
    
    var body: some View {
        NavigationView {
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
    
    private var totalCompletions: Int {
        
        return 0
    }
    
    private var averageCompletionRate: Int {
        
        return 0
    }
    
    private var currentStreak: Int {
        
        return 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Performance")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(habitEntities.count)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Active Habits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("\(totalCompletions)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Completions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("\(averageCompletionRate)%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Success Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.1)))
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
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
    }
}
