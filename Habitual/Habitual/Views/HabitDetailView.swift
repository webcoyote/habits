import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitListViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var selectedTimeRange = 0
    
    let timeRanges = ["Week", "Month", "3 Months", "Year"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HeaderSection(habit: habit)
                    
                    StatisticsSection(habit: habit, timeRange: selectedTimeRange)
                    
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(0..<timeRanges.count, id: \.self) { index in
                            Text(timeRanges[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    ProgressSection(habit: habit, timeRange: selectedTimeRange)
                    
                    HistorySection(habit: habit)
                }
                .padding(.vertical)
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingEditView = true }) {
                        Image(systemName: "pencil")
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditHabitView(habit: habit, viewModel: viewModel)
            }
            .alert("Delete Habit", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteHabit(habit, context: viewContext)
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Are you sure you want to delete \"\(habit.name)\"? This action cannot be undone.")
            }
        }
    }
}

struct HeaderSection: View {
    let habit: Habit
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: habit.icon)
                .font(.system(size: 60))
                .foregroundColor(habit.color.color)
            
            Text(habit.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(habit.type.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.gray.opacity(0.1)))
        }
        .padding()
    }
}

struct StatisticsSection: View {
    let habit: Habit
    let timeRange: Int
    
    var statistics: HabitStatistics {
        HabitStatistics(habit: habit, timeRange: TimeRangeOption(rawValue: timeRange) ?? .week)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                StatCard(title: "Current Streak", value: "\(statistics.currentStreak)", subtitle: "days")
                StatCard(title: "Best Streak", value: "\(statistics.bestStreak)", subtitle: "days")
                StatCard(title: "Completion", value: "\(statistics.completionRate)%", subtitle: "rate")
            }
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
    }
}

struct ProgressSection: View {
    let habit: Habit
    let timeRange: Int
    
    private var daysToShow: Int {
        switch timeRange {
        case 0: return 7
        case 1: return 30
        case 2: return 90
        case 3: return 365
        default: return 30
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            switch habit.type {
            case .binary:
                ProgressGridView(habit: habit, daysToShow: daysToShow)
                    .frame(height: min(200, CGFloat(daysToShow / 30) * 40))
                    .padding(.horizontal)
            case .numeric, .graph:
                ProgressChartView(habit: habit, type: habit.type.isGraph ? .line : .bar, daysToShow: min(daysToShow, 30))
                    .frame(height: 200)
                    .padding(.horizontal)
            }
        }
    }
}

struct HistorySection: View {
    let habit: Habit
    
    private var recentHistory: [DayRecord] {
        habit.history
            .sorted { $0.date > $1.date }
            .prefix(10)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if recentHistory.isEmpty {
                Text("No activity recorded yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(recentHistory, id: \.id) { record in
                        HStack {
                            Text(record.date, style: .date)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            RecordValueView(value: record.value, habitType: habit.type)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct RecordValueView: View {
    let value: HabitValue
    let habitType: HabitType
    
    var body: some View {
        switch value {
        case .binary(let completed):
            Image(systemName: completed ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(completed ? .green : .red)
        case .numeric(let val):
            if case .numeric(let target) = habitType {
                Text("\(val)/\(target)")
                    .foregroundColor(val >= target ? .green : .orange)
            } else {
                Text("\(val)")
            }
        case .graph(let val):
            HStack(spacing: 2) {
                Image(systemName: "face.smiling")
                Text("\(val)")
            }
            .foregroundColor(.purple)
        }
    }
}

extension HabitType {
    var isGraph: Bool {
        if case .graph = self { return true }
        return false
    }
}
