import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let isCompact: Bool
    let isAnimating: Bool
    let onComplete: (Int) -> Void
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
                    isCompact: isCompact,
                    isAnimating: isAnimating
                ) { newValue in
                    handleCompletion(newValue)
                }
                .contentShape(Rectangle())
            }
            
            if !isCompact {
                ProgressView(habit: habit)
            } else {
                // Show last 7 days in compact mode
                CompactProgressView(habit: habit)
                    .frame(height: 20)
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .contentShape(Rectangle())
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
            onComplete(isCompleted ? 1 : 0)
            // Track habit formation
            if isCompleted && !wasCompleted {
                UsageTracker.shared.incrementHabitsFormedIfNotCountedToday(habitId: habit.id.uuidString)
            }
        case .numeric:
            let previousValue = currentValue
            currentValue = value
            onComplete(value)
            // Track when habit goes from incomplete to complete
            if currentValue > 0 && previousValue == 0 {
                UsageTracker.shared.incrementHabitsFormedIfNotCountedToday(habitId: habit.id.uuidString)
            }
        case .graph:
            let hadValue = currentValue > 0
            currentValue = value
            onComplete(value)
            // Track when graph is first set for the day
            if !hadValue && currentValue > 0 {
                UsageTracker.shared.incrementHabitsFormedIfNotCountedToday(habitId: habit.id.uuidString)
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
        case .graph(let value):
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
    let isAnimating: Bool
    let onComplete: (Int) -> Void
    
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonOffset: CGSize = .zero
    @State private var glowOpacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Group {
            switch habitType {
        case .binary:
            Button(action: { onComplete(isCompleted ? 0 : 1) }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(isCompact ? .title3 : .title2)
                    .foregroundColor(color)
                    .background(
                        Circle()
                            .fill(color.opacity(glowOpacity))
                            .blur(radius: 8)
                            .scaleEffect(1.5)
                    )
                    .shadow(color: color.opacity(glowOpacity), radius: 10, x: 0, y: 0)
                    .scaleEffect(buttonScale)
                    .offset(buttonOffset)
                    .rotationEffect(.degrees(rotation))
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())
        case .numeric(let target):
            HStack(spacing: 4) {
                Text("\(currentValue)/\(target)")
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundColor(.secondary)
                Button(action: { 
                    let newValue = max(0, currentValue - 1)
                    onComplete(newValue)
                }) {
                    Image(systemName: "minus.circle")
                        .font(isCompact ? .title3 : .title2)
                        .foregroundColor(currentValue > 0 ? color : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
                Button(action: { 
                    let newValue = currentValue < target ? currentValue + 1 : 0
                    onComplete(newValue)
                }) {
                    Image(systemName: currentValue >= target ? "checkmark.circle.fill" : "plus.circle")
                        .font(isCompact ? .title3 : .title2)
                        .foregroundColor(color)
                        .background(
                            Circle()
                                .fill(color.opacity(glowOpacity))
                                .blur(radius: 8)
                                .scaleEffect(1.5)
                        )
                        .shadow(color: color.opacity(glowOpacity), radius: 10, x: 0, y: 0)
                        .scaleEffect(buttonScale)
                        .offset(buttonOffset)
                        .rotationEffect(.degrees(rotation))
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
            }
        case .graph(let scale):
            HStack(spacing: 4) {
                Text("\(currentValue)/\(scale)")
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundColor(.secondary)
                Button(action: { 
                    let newValue = max(0, currentValue - 1)
                    onComplete(newValue)
                }) {
                    Image(systemName: "minus.circle")
                        .font(isCompact ? .title3 : .title2)
                        .foregroundColor(currentValue > 0 ? color : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
                Button(action: { 
                    let newValue = currentValue < scale ? currentValue + 1 : 0
                    onComplete(newValue)
                }) {
                    Image(systemName: currentValue >= scale ? "checkmark.circle.fill" : "plus.circle")
                        .font(isCompact ? .title3 : .title2)
                        .foregroundColor(color)
                        .background(
                            Circle()
                                .fill(color.opacity(glowOpacity))
                                .blur(radius: 8)
                                .scaleEffect(1.5)
                        )
                        .shadow(color: color.opacity(glowOpacity), radius: 10, x: 0, y: 0)
                        .scaleEffect(buttonScale)
                        .offset(buttonOffset)
                        .rotationEffect(.degrees(rotation))
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
            }
            }
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                // Start with a big pulse and glow
                withAnimation(.easeOut(duration: 0.2)) {
                    buttonScale = 1.8
                    glowOpacity = 0.6
                }
                
                // Then bounce with movement
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                        buttonScale = 1.2
                        buttonOffset = CGSize(width: -8, height: -8)
                        rotation = -20
                    }
                }
                
                // Bounce to other side
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                        buttonOffset = CGSize(width: 8, height: -8)
                        rotation = 20
                    }
                }
                
                // Back to center with another pulse
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        buttonOffset = .zero
                        rotation = 0
                        buttonScale = 1.5
                        glowOpacity = 0.8
                    }
                }
                
                // Final settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        buttonScale = 1.0
                        glowOpacity = 0
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    rotation = 0
                    buttonScale = 1.0
                    buttonOffset = .zero
                    glowOpacity = 0
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
                .frame(height: 70) // 7 rows * 8px + 6 gaps * 2px = 68px, rounded to 70
        case .numeric:
            ProgressChartView(habit: habit, type: .bar)
                .frame(height: 60)
        case .graph:
            ProgressChartView(habit: habit, type: .line)
                .frame(height: 60)
        }
    }
}

struct CompactProgressView: View {
    let habit: Habit
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(byAdding: .day, value: -6 + dayOffset, to: Date()) ?? Date()
                CompactDayIndicator(
                    habit: habit,
                    date: date
                )
            }
        }
    }
}

struct CompactDayIndicator: View {
    let habit: Habit
    let date: Date
    
    private var completionValue: Int? {
        guard let record = habit.history.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
            return nil
        }
        
        switch record.value {
        case .binary(let completed):
            return completed ? 1 : 0
        case .numeric(let value):
            return value
        case .graph(let value):
            return value
        }
    }
    
    private var fillAmount: Double {
        guard let value = completionValue else { return 0 }
        
        switch habit.type {
        case .binary:
            return value > 0 ? 1.0 : 0.0
        case .numeric(let target):
            return min(1.0, Double(value) / Double(target))
        case .graph(let scale):
            return Double(value) / Double(scale)
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(completionValue == nil ? Color(.systemGray4) : habit.color.color.opacity(0.2 + fillAmount * 0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color(.systemGray3), lineWidth: 0.5)
            )
    }
}

