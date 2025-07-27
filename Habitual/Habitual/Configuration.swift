import Foundation

enum Configuration {
    enum Analytics {
        static let postHogApiKey: String? = "phc_vTNwWX2t1ZlfS5J5ow2IjXvrQPOqyvo0kcrsfrdrist"
        static let postHogHost: String? = "https://app.posthog.com"
        static let amplitudeApiKey: String? = "e6019a6cedcf18389345c3a9d4735234"
        static let mixpanelToken: String? = "713ba3932d7bcab83487e7ae7ea475af"
    }
    
    enum Rollbar {
        static let accessToken = "0d6c8dc7b2b6471dbef59ba25f537998"
        static let environment = "production"
    }
    
    enum App {
        // Add app-specific configuration here
        static let appName = "Habitual"
        static let supportEmail = "support@habitual.app"
    }
}

// SECURITY NOTES:
// For production apps, consider using:
// 1. .xcconfig files for different environments (Dev, Staging, Prod)
// 2. Info.plist with environment-specific values
// 3. Keychain for sensitive data
// 4. Environment variables during build time
// 5. Never commit real API keys to version control
