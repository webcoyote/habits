import UIKit
import UserNotifications
import RollbarNotifier

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupDatabase()
        setupRollbar()
        setupErrorTracking()
        setupAnalytics()
        setupUserIdentity()
        setupAppearance()
        setupUsageTracking()
        setupNotifications()
        reportAppStarted()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // MARK: - Setup Methods
    
    private func setupDatabase() {
        _ = DatabaseManager.shared
        _ = PersistenceController.shared
    }
    
    private func setupRollbar() {
        let config = RollbarConfig.mutableConfig(
            withAccessToken: Configuration.Rollbar.accessToken,
            environment: Configuration.Rollbar.environment)
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
    }
    
    private func setupErrorTracking() {
        // Initialize error tracker and set up exception handlers
        ErrorTracker.shared.setupExceptionHandlers()
    }
    
    private func setupAnalytics() {
        // Configure analytics providers with API keys from Configuration
        AnalyticsManager.shared.configure(
            postHogApiKey: Configuration.Analytics.postHogApiKey,
            postHogHost: Configuration.Analytics.postHogHost,
            amplitudeApiKey: Configuration.Analytics.amplitudeApiKey,
            mixpanelToken: Configuration.Analytics.mixpanelToken
        )
    }
    
    private func setupUserIdentity() {
        // Initialize user identity (this must come after analytics configuration)
        UserIdentityManager.shared.initializeUser()
        UserIdentityManager.shared.trackFirstLaunchEvents()
        UserIdentityManager.shared.trackAppLaunch()
        UserIdentityManager.shared.updateHabitStats()
    }
    
    private func setupAppearance() {
        // Apply initial appearance
        AppSettings.shared.applyAppearance()
    }
    
    private func setupUsageTracking() {
        // Track app launch with usage tracker
        UsageTracker.shared.incrementAppLaunches()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permission on first launch
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if granted {
                        print("✅ Notification permission granted")
                    } else {
                        print("❌ Notification permission denied")
                    }
                }
            }
        }
    }
    
    private func reportAppStarted() {
        #if false // for testing only
        Rollbar.infoMessage("Habitual initialized", data: nil, context: nil)
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification response if needed
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
