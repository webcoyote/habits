import SwiftUI

struct AddHabitView: View {
    @ObservedObject var viewModel: HabitListViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var habitName = ""
    @State private var selectedIcon = "heart.fill"
    @State private var selectedColor = Color.purple
    @State private var selectedType = 0
    @State private var numericTarget = 8
    @State private var moodScale = 10
    @State private var showingIconPicker = false
    
    let habitTypeOptions = ["Yes/No", "Count", "Mood"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name", text: $habitName)
                    
                    HStack {
                        Label("Icon", systemImage: selectedIcon)
                            .foregroundColor(selectedColor)
                        Spacer()
                        Button("Choose") {
                            showingIconPicker = true
                        }
                    }
                    
                    ColorPicker("Color", selection: $selectedColor)
                }
                
                Section("Tracking Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(0..<habitTypeOptions.count, id: \.self) { index in
                            Text(habitTypeOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    switch selectedType {
                    case 1:
                        Stepper("Daily Target: \(numericTarget)", value: $numericTarget, in: 1...100)
                    case 2:
                        Stepper("Mood Scale: 1-\(moodScale)", value: $moodScale, in: 5...10, step: 5)
                    default:
                        EmptyView()
                    }
                }
                
                Section("Examples") {
                    switch selectedType {
                    case 0:
                        Text("Perfect for habits you either complete or don't: Exercise, Meditate, Read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case 1:
                        Text("Track quantities: Glasses of water, Pages read, Minutes exercised")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case 2:
                        Text("Monitor your daily mood or energy levels")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon, selectedColor: selectedColor)
            }
        }
    }
    
    private func saveHabit() {
        let habitType: HabitType
        switch selectedType {
        case 1:
            habitType = .numeric(target: numericTarget)
        case 2:
            habitType = .mood(scale: moodScale)
        default:
            habitType = .binary
        }
        
        let newHabit = Habit(
            name: habitName.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor,
            type: habitType
        )
        
        viewModel.addHabit(newHabit, context: viewContext)
        
        // Track habit creation
        UsageTracker.shared.incrementHabitsCreated()
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let selectedColor: Color
    @Environment(\.presentationMode) var presentationMode
    
    let iconCategories: [(String, [String])] = [
        ("Health & Fitness", ["heart.fill", "figure.run", "figure.walk", "bicycle", "sportscourt", "dumbbell"]),
        ("Wellness", ["drop.fill", "bed.double.fill", "brain.head.profile", "lungs.fill", "cross.case.fill"]),
        ("Productivity", ["book.fill", "pencil", "keyboard", "desktopcomputer", "checklist", "calendar"]),
        ("Mindfulness", ["leaf.fill", "sun.max.fill", "moon.fill", "sparkles", "wind", "flame.fill"]),
        ("Social", ["person.2.fill", "bubble.left.and.bubble.right.fill", "phone.fill", "envelope.fill", "gift.fill"]),
        ("Hobbies", ["music.note", "paintbrush.fill", "camera.fill", "gamecontroller.fill", "puzzlepiece.fill"])
    ]
    
    let columns = [GridItem(.adaptive(minimum: 50))]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(iconCategories, id: \.0) { category, icons in
                        VStack(alignment: .leading) {
                            Text(category)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(icons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? selectedColor : .primary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.gray.opacity(0.1))
                                        )
                                        .onTapGesture {
                                            selectedIcon = icon
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
