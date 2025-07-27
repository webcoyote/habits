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
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        switch selectedType {
                        case 0:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Perfect for habits you either complete or don't:")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Exercise, Meditate, Read, Journal, Stretch")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                // Visual example
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Preview:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    ExampleBinaryProgressView(color: selectedColor)
                                        .frame(height: 40)
                                }
                            }
                        case 1:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Track quantities throughout the day:")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Glasses of water, Steps, Pages read, Minutes studied")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                // Visual example
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Preview (Target: \(numericTarget)):")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    ExampleNumericProgressView(color: selectedColor, target: numericTarget)
                                        .frame(height: 40)
                                }
                            }
                        case 2:
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Monitor levels or ratings:")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("Energy level, Mood, Pain level, Sleep quality")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                // Visual example
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Preview (Scale: 1-\(graphScale)):")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    ExampleGraphProgressView(color: selectedColor, scale: graphScale)
                                        .frame(height: 40)
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.vertical, 4)
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

// Example progress views for the Add Habit screen
struct ExampleBinaryProgressView: View {
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { day in
                RoundedRectangle(cornerRadius: 4)
                    .fill(day < 5 ? color : Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                    .frame(width: 25, height: 25)
            }
        }
    }
}

struct ExampleNumericProgressView: View {
    let color: Color
    let target: Int
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { day in
                let progress = Double([0.5, 0.8, 1.0, 0.3, 0.9, 0, 0][day])
                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progress > 0 ? color.opacity(0.3 + progress * 0.7) : Color.gray.opacity(0.2))
                        .frame(height: 40 * progress)
                }
                .frame(width: 25, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            }
        }
    }
}

struct ExampleGraphProgressView: View {
    let color: Color
    let scale: Int
    
    var body: some View {
        GeometryReader { geometry in
            let values: [Double] = [0.6, 0.7, 0.5, 0.8, 0.4, 0.3, 0.5]
            let width = geometry.size.width
            let height = geometry.size.height
            let spacing = width / 6
            
            ZStack {
                // Grid lines
                Path { path in
                    // Horizontal lines
                    for i in 0...2 {
                        let y = height * Double(i) / 2
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                
                // Line graph
                Path { path in
                    for (index, value) in values.enumerated() {
                        let x = Double(index) * spacing
                        let y = height * (1 - value)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                
                // Points
                ForEach(0..<values.count, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(
                            x: Double(index) * spacing,
                            y: height * (1 - values[index])
                        )
                }
            }
        }
    }
}
