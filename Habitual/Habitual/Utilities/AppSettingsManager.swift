import UIKit
import UserNotifications
import SwiftUI

extension Notification.Name {
    static let timeDisplayModeChanged = Notification.Name("timeDisplayModeChanged")
    static let weightDisplayModeChanged = Notification.Name("weightDisplayModeChanged")
    static let appearanceModeChanged = Notification.Name("appearanceModeChanged")
}

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "Use System Settings"
        }
    }
    
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return .unspecified
        }
    }
}

enum TimeDisplayMode: String, CaseIterable {
    case twelveHour = "12hour"
    case twentyfourHour = "24hour"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .twelveHour:
            return "12-Hour Time"
        case .twentyfourHour:
            return "24-Hour Time"
        case .system:
            return "Use System Settings"
        }
    }
}

enum WeightUnitsMode: String, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .metric:
            return "Metric (kg)"
        case .imperial:
            return "Imperial (lbs)"
        case .system:
            return "Use System Settings"
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    private let appearanceModeKey = "appearance_mode"
    private let timeDisplayModeKey = "time_display_mode"
    private let weightUnitsDisplayModeKey = "weight_units_mode"
    private let appLaunchesKey = "app_launches"
    private let totalCompletedHabitsKey = "total_completed_habits"
    private let lastReviewRequestDateKey = "last_review_request_date"
    private let completedHabitsAtLastReviewKey = "completed_habits_at_last_review"
    private let gradientStartColorKey = "gradient_start_color"
    private let gradientMiddleColorKey = "gradient_middle_color"
    private let gradientEndColorKey = "gradient_end_color"
    private let gradientOpacityKey = "gradient_opacity"
    
    @Published var appearanceMode: AppearanceMode {
        didSet {
            userDefaults.set(appearanceMode.rawValue, forKey: appearanceModeKey)
            applyAppearance()
            NotificationCenter.default.post(name: .appearanceModeChanged, object: nil)
        }
    }
    
    @Published var timeDisplayMode: TimeDisplayMode {
        didSet {
            userDefaults.set(timeDisplayMode.rawValue, forKey: timeDisplayModeKey)
            NotificationCenter.default.post(name: .timeDisplayModeChanged, object: nil)
        }
    }
    
    @Published var weightUnitsMode: WeightUnitsMode {
        didSet {
            userDefaults.set(weightUnitsMode.rawValue, forKey: weightUnitsDisplayModeKey)
            NotificationCenter.default.post(name: .weightDisplayModeChanged, object: nil)
        }
    }
    
    @Published var gradientStartColor: Color {
        didSet {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(gradientStartColor), requiringSecureCoding: false) {
                userDefaults.set(data, forKey: gradientStartColorKey)
            }
        }
    }
    
    @Published var gradientMiddleColor: Color {
        didSet {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(gradientMiddleColor), requiringSecureCoding: false) {
                userDefaults.set(data, forKey: gradientMiddleColorKey)
            }
        }
    }
    
    @Published var gradientEndColor: Color {
        didSet {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(gradientEndColor), requiringSecureCoding: false) {
                userDefaults.set(data, forKey: gradientEndColorKey)
            }
        }
    }
    
    @Published var gradientOpacity: Double {
        didSet {
            userDefaults.set(gradientOpacity, forKey: gradientOpacityKey)
        }
    }
    
    var appLaunches: Int {
        get { userDefaults.integer(forKey: appLaunchesKey) }
        set { userDefaults.set(newValue, forKey: appLaunchesKey) }
    }
    
    var totalCompletedHabits: Int {
        get { userDefaults.integer(forKey: totalCompletedHabitsKey) }
        set { userDefaults.set(newValue, forKey: totalCompletedHabitsKey) }
    }
    
    var lastReviewRequestDate: Date? {
        get { userDefaults.object(forKey: lastReviewRequestDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastReviewRequestDateKey) }
    }
    
    var completedHabitsAtLastReview: Int {
        get { userDefaults.integer(forKey: completedHabitsAtLastReviewKey) }
        set { userDefaults.set(newValue, forKey: completedHabitsAtLastReviewKey) }
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                gradientStartColor,
                gradientMiddleColor,
                gradientEndColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundGradientWithOpacity: some View {
        backgroundGradient.opacity(gradientOpacity)
    }
    
    private init() {
        // Load initial values from UserDefaults
        let savedAppearanceMode: AppearanceMode
        if let rawValue = userDefaults.string(forKey: appearanceModeKey),
           let mode = AppearanceMode(rawValue: rawValue) {
            savedAppearanceMode = mode
        } else {
            savedAppearanceMode = .system
        }
        
        let savedTimeDisplayMode: TimeDisplayMode
        if let rawValue = userDefaults.string(forKey: timeDisplayModeKey),
           let mode = TimeDisplayMode(rawValue: rawValue) {
            savedTimeDisplayMode = mode
        } else {
            savedTimeDisplayMode = .system
        }
        
        let savedWeightUnitsMode: WeightUnitsMode
        if let rawValue = userDefaults.string(forKey: weightUnitsDisplayModeKey),
           let mode = WeightUnitsMode(rawValue: rawValue) {
            savedWeightUnitsMode = mode
        } else {
            savedWeightUnitsMode = .system
        }
        
        // Load saved gradient colors
        let savedStartColor: Color
        if let data = userDefaults.data(forKey: gradientStartColorKey),
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor {
            savedStartColor = Color(uiColor)
        } else {
            savedStartColor = .blue
        }
        
        let savedMiddleColor: Color
        if let data = userDefaults.data(forKey: gradientMiddleColorKey),
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor {
            savedMiddleColor = Color(uiColor)
        } else {
            savedMiddleColor = .purple
        }
        
        let savedEndColor: Color
        if let data = userDefaults.data(forKey: gradientEndColorKey),
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor {
            savedEndColor = Color(uiColor)
        } else {
            savedEndColor = .pink
        }
        
        // Load saved gradient opacity
        let savedOpacity = userDefaults.double(forKey: gradientOpacityKey)
        let gradientOpacityValue = savedOpacity > 0 ? savedOpacity : 0.4 // Default to 0.4 if not set
        
        // Initialize published properties
        appearanceMode = savedAppearanceMode
        timeDisplayMode = savedTimeDisplayMode
        weightUnitsMode = savedWeightUnitsMode
        gradientStartColor = savedStartColor
        gradientMiddleColor = savedMiddleColor
        gradientEndColor = savedEndColor
        gradientOpacity = gradientOpacityValue
    }
    
    func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        
        switch timeDisplayMode {
        case .twelveHour:
            formatter.dateFormat = "h:mm a"
        case .twentyfourHour:
            formatter.dateFormat = "HH:mm"
        case .system:
            formatter.timeStyle = .short
        }
        
        return formatter.string(from: date)
    }
    
    func formatTime(from timeString: String) -> String {
        // Convert time string to Date and format
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        
        guard let date = inputFormatter.date(from: timeString) else {
            return timeString // Return original if parsing fails
        }
        
        return formatTime(from: date)
    }
    
    func applyAppearance() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            window.overrideUserInterfaceStyle = self.appearanceMode.interfaceStyle
        }
    }
    
    func formatWeight(_ weight: Double) -> String {
        switch weightUnitsMode {
        case .metric:
            return String(format: "%.1f kg", weight)
        case .imperial:
            let pounds = weight * 2.20462
            return String(format: "%.1f lbs", pounds)
        case .system:
            let formatter = MeasurementFormatter()
            formatter.unitStyle = .short
            let measurement = Measurement(value: weight, unit: UnitMass.kilograms)
            return formatter.string(from: measurement)
        }
    }
    
    func getAppInfo() -> (name: String, version: String, build: String) {
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Habitual"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return (appName, appVersion, buildNumber)
    }
    
    func getDeviceInfo() -> String {
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        let appInfo = getAppInfo()
        
        return """
App: \(appInfo.name)
Version: \(appInfo.version).\(appInfo.build)
Device: \(deviceName)
Model: \(deviceModel)
OS: \(systemName) \(systemVersion)
"""
    }
    
    func incrementAppLaunches() {
        appLaunches += 1
    }
    
    func incrementCompletedHabits() {
        totalCompletedHabits += 1
    }
}

typealias AppSettingsManager = AppSettings
