import SwiftUI
import CoreData

struct HabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = HabitListViewModel()
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var showingCompactView = false
    @State private var isEditMode = false
    @State private var animatingHabitId: UUID?
    @State private var animationTimer: Timer?
    @State private var showingCelebration = false
    @State private var celebrationEffect: CelebrationEffect = .confetti
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HabitEntity.order, ascending: true),
            NSSortDescriptor(keyPath: \HabitEntity.modifiedAt, ascending: false)
        ],
        animation: .easeInOut(duration: 0.15))
    private var habitEntities: FetchedResults<HabitEntity>
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background for entire page
                appSettings.backgroundGradientWithOpacity
                .ignoresSafeArea(edges: .top)
                
                List {
                    ForEach(viewModel.habits, id: \.id) { habit in
                        HabitCardView(
                            habit: habit,
                            isCompact: showingCompactView,
                            isAnimating: animatingHabitId == habit.id,
                            onComplete: { value in
                                let wasCompleted = habit.todayValue > 0
                                viewModel.updateHabitValue(habit, value: value)
                                let completed = value > 0
                                
                                // Show celebration if habit was just completed (not uncompleted)
                                if completed && !wasCompleted {
                                    showingCelebration = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                        showingCelebration = false
                                        // Move to next effect for the next celebration
                                        celebrationEffect = celebrationEffect.next()
                                    }
                                }
                                
                                // Track habit completion
                                AnalyticsManager.shared.track("habit_completed", properties: [
                                    "habit_id": habit.id.uuidString,
                                    "habit_name": habit.name,
                                    "habit_type": habit.type.displayName,
                                    "completed": completed,
                                    "value": value
                                ])
                                
                                // Track streak milestone if completed
                                if completed {
                                    let statistics = HabitStatistics(habit: habit, timeRange: .allTime)
                                    UserIdentityManager.shared.trackStreakMilestone(
                                        streakDays: statistics.currentStreak + 1,
                                        habitName: habit.name
                                    )
                                }
                            },
                            onTap: {
                                selectedHabit = habit
                                // Track habit detail view
                                AnalyticsManager.shared.track("habit_viewed", properties: [
                                    "habit_id": habit.id.uuidString,
                                    "habit_name": habit.name
                                ])
                            }
                        )
                        .listRowInsets(EdgeInsets(top: showingCompactView ? 4 : 8, leading: 16, bottom: showingCompactView ? 4 : 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onMove { indices, newOffset in
                        withAnimation(.none) {
                            viewModel.moveHabits(from: indices, to: newOffset, context: viewContext)
                        }
                    }
                    
                    // Spacer to account for FAB
                    Color.clear
                        .frame(height: 80)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddButton {
                            showingAddHabit = true
                            // Track add habit button tap
                            AnalyticsManager.shared.track("add_habit_tapped")
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }) {
                        Text(isEditMode ? "Done" : "Edit")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showingCompactView.toggle()
                        }
                    }) {
                        Image(systemName: showingCompactView ? "rectangle.grid.1x2" : "square.grid.2x2")
                    }
                }
            }
            .environment(\.editMode, .constant(isEditMode ? EditMode.active : EditMode.inactive))
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit, viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadHabits(from: habitEntities, context: viewContext)
            }
            .onChange(of: habitEntities.count) { _ in
                viewModel.loadHabits(from: habitEntities, context: viewContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshHabits"))) { _ in
                viewModel.loadHabits(from: habitEntities, context: viewContext)
            }
            .onAppear {
                startAnimationTimer()
            }
            .onDisappear {
                stopAnimationTimer()
            }
        }
        .overlay(
            Group {
                if showingCelebration {
                    CelebrationEffectView(effect: celebrationEffect)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .zIndex(999)
                }
            }
        )
    }
    
    private func startAnimationTimer() {
        stopAnimationTimer()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...5), repeats: true) { _ in
            selectRandomIncompleteHabit()
        }
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
        animatingHabitId = nil
    }
    
    private func selectRandomIncompleteHabit() {
        let incompleteHabits = viewModel.habits.filter { habit in
            guard let todayRecord = habit.history.first(where: { Calendar.current.isDateInToday($0.date) }) else {
                return true // No record today means incomplete
            }
            
            switch habit.type {
            case .binary:
                if case .binary(let completed) = todayRecord.value {
                    return !completed
                }
                return true
            case .numeric(let target):
                if case .numeric(let value) = todayRecord.value {
                    return value < target
                }
                return true
            case .graph(let scale):
                if case .graph(let value) = todayRecord.value {
                    return value < scale
                }
                return true
            }
        }
        
        if !incompleteHabits.isEmpty {
            animatingHabitId = incompleteHabits.randomElement()?.id
            
            // Stop animation after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if animatingHabitId != nil {
                    animatingHabitId = nil
                }
            }
        }
    }
}

struct AddButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.blue))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
