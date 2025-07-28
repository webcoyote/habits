import Foundation

class Configuration {
    enum Analytics {
        static let postHogApiKey: String? = "phc_vTNwWX2t1ZlfS5J5ow2IjXvrQPOqyvo0kcrsfrdrist"
        static let postHogHost: String? = "https://app.posthog.com"
        static let amplitudeApiKey: String? = "e6019a6cedcf18389345c3a9d4735234"
        static let mixpanelToken: String? = "713ba3932d7bcab83487e7ae7ea475af"
        static let rollbarAccessToken = "0d6c8dc7b2b6471dbef59ba25f537998"
    }
    
    enum App {
        // Add app-specific configuration here
        static let appName = "Habitual"
        static let supportEmail = "pat@codeofhonor.com"
        static let surveyURL = "https://tally.so/r/mRyLPp"
        static let privacyPolicyURL =
            "https://www.termsfeed.com/live/d7469d0c-8047-435a-8208-f7811d293a88"

        // Do not change or backup files cannot be loaded
        static let backupUTTypeName = "com.codeofhonor.habitual.backup";
    }
    
    enum ReviewRequest {
        static let minimumAppLaunches = 3
        static let minimumCompletedHabits = 50
        static let daysBetweenRequests: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    }
    
    enum Database {
        // Don't ever change these values or users will lose their data
        static let coreDataContainerName = "Habits"
        static let sqliteDBName = "Habits.db"
    }

    // MARK: - Environment Detection
    static func getEnvironment() -> String {
        return isDebugEnvironment() ? "development" : "production";
    }

    static func isDebugEnvironment() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

   static func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// SECURITY NOTES:
// For production apps, consider using:
// 1. .xcconfig files for different environments (Dev, Staging, Prod)
// 2. Info.plist with environment-specific values
// 3. Keychain for sensitive data
// 4. Environment variables during build time
// 5. Never commit real API keys to version control
