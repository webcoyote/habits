import SwiftUI

struct TabBarButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption2)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .blue : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Page content with swipe gestures
            TabView(selection: $selectedTab) {
                HabitListView()
                    .tag(0)
                
                StatisticsView()
                    .tag(1)
                
                SettingsView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom tab bar
            HStack(spacing: 0) {
                TabBarButton(
                    title: "Habits",
                    systemImage: "heart.fill",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                TabBarButton(
                    title: "Stats",
                    systemImage: "chart.bar.fill",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                
                TabBarButton(
                    title: "Settings",
                    systemImage: "gear",
                    isSelected: selectedTab == 2,
                    action: { selectedTab = 2 }
                )
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.separator)),
                alignment: .top
            )
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Track tab changes
            let tabNames = ["habits", "statistics", "settings"]
            if newValue < tabNames.count {
                AnalyticsManager.shared.trackScreenView(screenName: tabNames[newValue])
            }
        }
        .onAppear {
            // Track initial screen view
            AnalyticsManager.shared.trackScreenView(screenName: "habits")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
