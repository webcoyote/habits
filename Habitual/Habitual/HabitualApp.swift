import SwiftUI

@main
struct HabitualApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: .appearanceModeChanged)) { _ in
                    // Appearance is handled by AppSettings.applyAppearance()
                }
        }
    }
}
