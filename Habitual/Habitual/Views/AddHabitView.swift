import SwiftUI

struct AddHabitView: View {
    @ObservedObject var viewModel: HabitListViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var habitName = ""
    @State private var selectedIcon = "heart.fill"
    @State private var selectedColor = Color.purple
    @State private var selectedType = 0
    @State private var numericTarget = 4
    @State private var graphScale = 5
    @State private var showingIconPicker = false
    @FocusState private var isNameFieldFocused: Bool
    
    let habitTypeOptions = ["Toggle", "Count", "Graph"]
    
    let defaultColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, 
        .blue, .indigo, .purple, .pink, .brown
    ]
    
    let allIcons: [String] = [
        "heart.fill", "figure.run", "figure.walk", "bicycle", "sportscourt", "dumbbell",
        "drop.fill", "bed.double.fill", "brain.head.profile", "lungs.fill", "cross.case.fill",
        "book.fill", "pencil", "keyboard", "desktopcomputer", "checklist", "calendar",
        "leaf.fill", "sun.max.fill", "moon.fill", "sparkles", "wind", "flame.fill",
        "person.2.fill", "bubble.left.and.bubble.right.fill", "phone.fill", "envelope.fill", "gift.fill",
        "music.note", "paintbrush.fill", "camera.fill", "gamecontroller.fill", "puzzlepiece.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name", text: $habitName)
                        .focused($isNameFieldFocused)
                    
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
                        Picker("Graph Scale", selection: $graphScale) {
                            Text("1-5").tag(5)
                            Text("1-7").tag(7)
                            Text("1-10").tag(10)
                        }
                        .pickerStyle(SegmentedPickerStyle())
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
                        Text("Track quantities, like Glasses of water")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case 2:
                        Text("Monitor your daily graph or energy levels")
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
            .onAppear {
                // Set random default color and icon
                selectedColor = defaultColors.randomElement() ?? Color.purple
                selectedIcon = allIcons.randomElement() ?? "heart.fill"
                // Focus the habit name field
                isNameFieldFocused = true
            }
        }
    }
    
    private func saveHabit() {
        let habitType: HabitType
        switch selectedType {
        case 1:
            habitType = .numeric(target: numericTarget)
        case 2:
            habitType = .graph(scale: graphScale)
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
        
        // Track analytics event for habit creation
        var properties: [String: Any] = [
            "habit_id": newHabit.id.uuidString,
            "habit_name": newHabit.name,
            "habit_type": habitTypeOptions[selectedType],
            "icon": selectedIcon,
            "has_target": selectedType == 1
        ]
        
        if selectedType == 1 {
            properties["target_value"] = numericTarget
        }
        
        if selectedType == 2 {
            properties["graph_scale"] = graphScale
        }
        
        AnalyticsManager.shared.track("habit_created", properties: properties)
        
        // Track habit creation milestone
        if let stats = UsageTracker.shared.getStats() {
            UserIdentityManager.shared.trackHabitMilestone(habitCount: stats.habitsCreated)
        }
        
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
