import SwiftUI
import RollbarNotifier
import UserNotifications

@main
struct HabitualApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Configure Rollbar
        configureRollbar()
        // Initialize error tracker for unhandled exceptions
        _ = ErrorTracker.shared

        // Apply initial appearance
        AppSettings.shared.applyAppearance()
        
        // Track app launch with new usage tracker
        UsageTracker.shared.incrementAppLaunches()

        // Request notification permission on first launch
        requestNotificationPermissionIfNeeded()
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

    private func configureRollbar() {
        let config = RollbarConfig.mutableConfig(
            withAccessToken: "0d6c8dc7b2b6471dbef59ba25f537998",
            environment: "production")
        config.loggingOptions.codeVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        config.loggingOptions.captureIp = RollbarCaptureIpType.anonymize
        config.server.host = UIDevice.current.identifierForVendor?.uuidString

        // Critical: Enable crash reporting
        config.loggingOptions.crashLevel = RollbarLevel.error
        config.loggingOptions.logLevel = RollbarLevel.info

        // Enable all telemetry
        config.telemetry.enabled = true
        config.telemetry.captureLog = true
        config.telemetry.captureConnectivity = true

        // Initialize with crash reporting
        Rollbar.initWithConfiguration(config)

        // Include usage stats in startup message
        if let stats = UsageTracker.shared.getStats() {
            let statsData = [
                "launches": stats.launches,
                "habits_created": stats.habitsCreated,
                "habits_checked": stats.habitsChecked
            ]
            Rollbar.infoMessage("Habitual initialized", data: statsData, context: nil)
        } else {
            Rollbar.infoMessage("Habitual initialized", data: nil, context: nil)
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if granted {
                        ErrorTracker.shared.logInfo("Notification permission granted", context: "App Launch")
                    } else {
                        ErrorTracker.shared.logInfo("Notification permission denied", context: "App Launch")
                    }
                }
            }
        }
    }
}
