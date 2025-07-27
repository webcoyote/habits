import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let isCompact: Bool
    let onComplete: (Bool) -> Void
    let onTap: () -> Void
    
    @State private var isCompleted = false
    @State private var currentValue = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
            HStack {
                Image(systemName: habit.icon)
                    .font(isCompact ? .body : .title2)
                    .foregroundColor(habit.color.color)
                    .frame(width: isCompact ? 20 : 24)
                
                Text(habit.name)
                    .font(isCompact ? .subheadline : .headline)
                    .lineLimit(isCompact ? 1 : 2)
                
                Spacer()
                
                CompleteButton(
                    habitType: habit.type,
                    isCompleted: isCompleted,
                    currentValue: currentValue,
                    color: habit.color.color,
                    isCompact: isCompact
                ) { newValue in
                    handleCompletion(newValue)
                }
            }
            
            if !isCompact {
                ProgressView(habit: habit)
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            onTap()
        }
        .onAppear {
            updateCompletionStatus()
        }
    }
    
    private func handleCompletion(_ value: Int) {
        let wasCompleted = isCompleted || currentValue > 0
        
        switch habit.type {
        case .binary:
            isCompleted.toggle()
            onComplete(isCompleted)
            // Track habit formation
            if isCompleted && !wasCompleted {
                UsageTracker.shared.incrementHabitsFormed()
            }
        case .numeric:
            let previousValue = currentValue
            currentValue = value
            onComplete(currentValue > 0)
            // Track when habit goes from incomplete to complete
            if currentValue > 0 && previousValue == 0 {
                UsageTracker.shared.incrementHabitsFormed()
            }
        case .mood:
            let hadValue = currentValue > 0
            currentValue = value
            onComplete(true)
            // Track when mood is first set for the day
            if !hadValue && currentValue > 0 {
                UsageTracker.shared.incrementHabitsFormed()
            }
        }
    }
    
    private func updateCompletionStatus() {
        guard let todayRecord = habit.history.first(where: { Calendar.current.isDateInToday($0.date) }) else {
            isCompleted = false
            currentValue = 0
            return
        }
        
        switch todayRecord.value {
        case .binary(let completed):
            isCompleted = completed
        case .numeric(let value):
            currentValue = value
            isCompleted = value > 0
        case .mood(let value):
            currentValue = value
            isCompleted = true
        }
    }
}

struct CompleteButton: View {
    let habitType: HabitType
    let isCompleted: Bool
    let currentValue: Int
    let color: Color
    let isCompact: Bool
    let onComplete: (Int) -> Void
    
    var body: some View {
        switch habitType {
        case .binary:
            Button(action: { onComplete(isCompleted ? 0 : 1) }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(isCompact ? .title3 : .title2)
                    .foregroundColor(isCompleted ? color : .gray)
            }
        case .numeric(let target):
            HStack(spacing: 4) {
                if !isCompact {
                    Text("\(currentValue)/\(target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button(action: { 
                    let newValue = max(0, currentValue - 1)
                    onComplete(newValue)
                }) {
                    Image(systemName: "minus.circle")
                        .font(isCompact ? .title3 : .title2)
                        .foregroundColor(currentValue > 0 ? color : .gray)
                }
                Button(action: { 
                    let newValue = currentValue < target ? currentValue + 1 : 0
                    onComplete(newValue)
                }) {
                    Image(systemName: currentValue >= target ? "checkmark.circle.fill" : "plus.circle")
                        .font(isCompact ? .title3 : .title2)
                }
            }
        case .mood(let scale):
            HStack(spacing: 4) {
                if !isCompact {
                    Text("\(currentValue)/\(scale)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button(action: { 
                    let newValue = max(0, currentValue - 1)
                    onComplete(newValue)
                }) {
                    Image(systemName: "minus.circle")
                        .font(isCompact ? .title3 : .title2)
                        .foregroundColor(currentValue > 0 ? color : .gray)
                }
                Button(action: { 
                    let newValue = currentValue < scale ? currentValue + 1 : 0
                    onComplete(newValue)
                }) {
                    Image(systemName: currentValue >= scale ? "checkmark.circle.fill" : "plus.circle")
                        .font(isCompact ? .title3 : .title2)
                        .foregroundColor(currentValue >= scale ? color : .gray)
                }
            }
        }
    }
}

struct ProgressView: View {
    let habit: Habit
    
    var body: some View {
        switch habit.type {
        case .binary:
            ProgressGridView(habit: habit)
                .frame(height: 60)
        case .numeric:
            ProgressChartView(habit: habit, type: .bar)
                .frame(height: 60)
        case .mood:
            ProgressChartView(habit: habit, type: .line)
                .frame(height: 60)
        }
    }
}

