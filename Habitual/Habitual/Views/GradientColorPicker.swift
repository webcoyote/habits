import SwiftUI

struct GradientColorPicker: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.dismiss) var dismiss
    
    let presetGradients: [(start: Color, middle: Color, end: Color)] = [
        // Original vibrant
        (.blue, .purple, .pink),
        // Sunset
        (.orange, .red, .purple),
        // Ocean
        (.teal, .blue, .indigo),
        // Forest
        (.green, .mint, .teal),
        // Sunrise
        (.pink, .orange, .yellow),
        // Royal
        (.indigo, .purple, .blue),
        // Fire
        (.red, .orange, .yellow),
        // Cotton Candy
        (.pink, .purple, .blue),
        // Autumn
        (.orange, .brown, .red),
        // Lavender
        (.purple, .pink, .indigo),
        // Mint Fresh
        (.mint, .teal, .cyan),
        // Berry
        (.red, .pink, .purple)
    ]
    
    private func randomColor() -> Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .mint, .teal,
            .cyan, .blue, .indigo, .purple, .pink, .brown
        ]
        return colors.randomElement() ?? .blue
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current gradient preview
                    VStack(alignment: .leading) {
                        Text("CURRENT GRADIENT")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(appSettings.backgroundGradient.opacity(appSettings.gradientOpacity))
                        }
                        .frame(height: 100)
                        .padding(.horizontal)
                    }
                    
                    // Custom color pickers
                    VStack(alignment: .leading) {
                        Text("CUSTOM COLORS")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ColorPickerRow(title: "Start Color", color: $appSettings.gradientStartColor)
                            Divider()
                            ColorPickerRow(title: "Middle Color", color: $appSettings.gradientMiddleColor)
                            Divider()
                            ColorPickerRow(title: "End Color", color: $appSettings.gradientEndColor)
                            Divider()
                            
                            // Opacity slider
                            OpacitySliderRow(opacity: $appSettings.gradientOpacity)
                            Divider()
                            
                            // Random colors button
                            Button(action: {
                                appSettings.gradientStartColor = randomColor()
                                appSettings.gradientMiddleColor = randomColor()
                                appSettings.gradientEndColor = randomColor()
                            }) {
                                HStack {
                                    Image(systemName: "dice")
                                        .foregroundColor(.accentColor)
                                    Text("Choose Random Colors")
                                        .foregroundColor(.accentColor)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Preset gradients
                    VStack(alignment: .leading) {
                        Text("PRESET GRADIENTS")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ForEach(0..<presetGradients.count, id: \.self) { index in
                                let gradient = presetGradients[index]
                                Button(action: {
                                    appSettings.gradientStartColor = gradient.start
                                    appSettings.gradientMiddleColor = gradient.middle
                                    appSettings.gradientEndColor = gradient.end
                                }) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [gradient.start, gradient.middle, gradient.end]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(height: 60)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Background Colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            ColorPicker("", selection: $color)
                .labelsHidden()
        }
        .padding()
    }
}

struct OpacitySliderRow: View {
    @Binding var opacity: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Opacity")
                Spacer()
                Text("\(Int(opacity * 100))%")
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.05)
                        .accentColor(.blue)
                        .allowsHitTesting(false) // Disable slider's default interaction
                    
                    // Invisible overlay to capture all interactions
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let percentage = value.location.x / geometry.size.width
                                    let newValue = 0.1 + (0.9 * percentage)
                                    opacity = min(max(round(newValue * 20) / 20, 0.1), 1.0) // Round to nearest 0.05
                                }
                        )
                }
            }
            .frame(height: 44)
        }
        .padding()
    }
}

struct GradientColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        GradientColorPicker()
    }
}
