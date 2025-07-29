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
    @State private var celebrationClickLocation: CGPoint? = nil
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HabitEntity.order, ascending: true),
            NSSortDescriptor(keyPath: \HabitEntity.modifiedAt, ascending: false)
        ],
        animation: .easeInOut(duration: 0.15))
    private var habitEntities: FetchedResults<HabitEntity>
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Habits")
                .toolbar {
                    toolbarContent
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
                    startAnimationTimer()
                }
                .onChange(of: habitEntities.count) { _ in
                    viewModel.loadHabits(from: habitEntities, context: viewContext)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshHabits"))) { _ in
                    viewModel.loadHabits(from: habitEntities, context: viewContext)
                }
                .onDisappear {
                    stopAnimationTimer()
                }
        }
        .coordinateSpace(name: "habitListView")
        .overlay(celebrationOverlay)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            appSettings.backgroundGradientWithOpacity
                .ignoresSafeArea(edges: .top)
            
            habitList
            
            floatingActionButton
        }
    }
    
    @ViewBuilder
    private var habitList: some View {
        List {
            ForEach(viewModel.habits, id: \.id) { habit in
                habitRow(for: habit)
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
    }
    
    @ViewBuilder
    private func habitRow(for habit: Habit) -> some View {
        HabitCardView(
            habit: habit,
            isCompact: showingCompactView,
            isAnimating: animatingHabitId == habit.id,
            onComplete: { value, location in
                handleHabitCompletion(habit: habit, value: value, location: location)
            },
            onTap: {
                selectedHabit = habit
                AnalyticsManager.shared.track("habit_viewed", properties: [
                    "habit_id": habit.id.uuidString,
                    "habit_name": habit.name
                ])
            }
        )
    }
    
    private func handleHabitCompletion(habit: Habit, value: Int, location: CGPoint?) {
        let wasCompleted = habit.todayValue > 0
        viewModel.updateHabitValue(habit, value: value)
        let completed = value > 0
        
        if completed && !wasCompleted {
            celebrationClickLocation = location
            showingCelebration = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                showingCelebration = false
                celebrationEffect = celebrationEffect.next()
            }
        }
        
        AnalyticsManager.shared.track("habit_completed", properties: [
            "habit_id": habit.id.uuidString,
            "habit_name": habit.name,
            "habit_type": habit.type.displayName,
            "completed": completed,
            "value": value
        ])
        
        if completed {
            let statistics = HabitStatistics(habit: habit, timeRange: .allTime)
            UserIdentityManager.shared.trackStreakMilestone(
                streakDays: statistics.currentStreak + 1,
                habitName: habit.name
            )
        }
    }
    
    @ViewBuilder
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                AddButton {
                    showingAddHabit = true
                    AnalyticsManager.shared.track("add_habit_tapped")
                }
                .padding()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        if showingCelebration {
            CelebrationEffectView(effect: celebrationEffect, location: celebrationClickLocation ?? CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY))
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(999)
        }
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
