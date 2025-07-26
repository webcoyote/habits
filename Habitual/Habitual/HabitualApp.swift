import SwiftUI

@main
struct HabitualApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Apply initial appearance
        AppSettings.shared.applyAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: .appearanceModeChanged)) { _ in
                    // Appearance is handled by AppSettings.applyAppearance()
                }
        }
    }
}
