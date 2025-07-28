import SwiftUI

struct EditHabitView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitListViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var habitName: String
    @State private var selectedIcon: String
    @State private var selectedColor: Color
    @State private var showingIconPicker = false
    
    init(habit: Habit, viewModel: HabitListViewModel) {
        self.habit = habit
        self.viewModel = viewModel
        _habitName = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColor = State(initialValue: habit.color.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name", text: $habitName)
                    
                    HStack {
                        Label("Icon", systemImage: selectedIcon)
                            .foregroundColor(selectedColor)
                        Spacer()
                        Button("Change") {
                            showingIconPicker = true
                        }
                    }
                    
                    ColorPicker("Color", selection: $selectedColor)
                }
                
                Section("Type") {
                    HStack {
                        Text("Tracking Type")
                        Spacer()
                        Text(habit.type.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    switch habit.type {
                    case .numeric(let target):
                        HStack {
                            Text("Daily Target")
                            Spacer()
                            Text("\(target)")
                                .foregroundColor(.secondary)
                        }
                    case .graph(let scale):
                        HStack {
                            Text("Graph Scale")
                            Spacer()
                            Text("1-\(scale)")
                                .foregroundColor(.secondary)
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon, selectedColor: selectedColor)
            }
        }
    }
    
    private func saveChanges() {
        var updatedHabit = habit
        updatedHabit.name = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedHabit.icon = selectedIcon
        updatedHabit.color = CodableColor(color: selectedColor)
        
        viewModel.updateHabit(updatedHabit, context: viewContext)
        
        // Track habit update
        AnalyticsManager.shared.track("habit_updated", properties: [
            "habit_id": habit.id.uuidString,
            "habit_name": updatedHabit.name,
            "name_changed": habit.name != updatedHabit.name,
            "icon_changed": habit.icon != updatedHabit.icon,
            "color_changed": habit.color.color != updatedHabit.color.color
        ])
        
        presentationMode.wrappedValue.dismiss()
    }
}
