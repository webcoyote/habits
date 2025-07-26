import SwiftUI
import CoreData

struct HabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = HabitListViewModel()
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var showingCompactView = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HabitEntity.modifiedAt, ascending: false)],
        animation: .default)
    private var habitEntities: FetchedResults<HabitEntity>
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: showingCompactView ? 8 : 16) {
                        ForEach(viewModel.habits) { habit in
                            HabitCardView(
                                habit: habit,
                                isCompact: showingCompactView,
                                onComplete: { completed in
                                    viewModel.updateHabitCompletion(habit, completed: completed)
                                },
                                onTap: {
                                    selectedHabit = habit
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddButton {
                            showingAddHabit = true
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Habitual")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "line.horizontal.3")
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
                    
                    Button(action: {}) {
                        Image(systemName: "star")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
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
