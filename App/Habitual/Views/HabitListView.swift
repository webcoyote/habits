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
                            onComplete: { value in
                                viewModel.updateHabitValue(habit, value: value)
                                // Track habit completion
                                let completed = value > 0
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
            .navigationTitle("Habitual")
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
