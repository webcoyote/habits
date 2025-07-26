import Foundation
import UserNotifications
import UIKit
import SwiftUI

enum NotificationStatus: String, CaseIterable {
    case authorized = "authorized"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case provisional = "provisional"
    case ephemeral = "ephemeral"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        case .unknown:
            return "Unknown"
        }
    }
    
    var isEnabled: Bool {
        return self == .authorized
    }
    
    var isDisabled: Bool {
        return self == .denied
    }
}

class NotificationPermissionManager: ObservableObject {
    static let shared = NotificationPermissionManager()
    
    @Published var notificationStatus: NotificationStatus = .unknown
    
    private init() {
        checkNotificationStatus()
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        checkNotificationStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                let status: NotificationStatus
                switch settings.authorizationStatus {
                case .authorized:
                    status = .authorized
                case .denied:
                    status = .denied
                case .notDetermined:
                    status = .notDetermined
                case .provisional:
                    status = .provisional
                case .ephemeral:
                    status = .ephemeral
                @unknown default:
                    status = .unknown
                }
                self?.notificationStatus = status
            }
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.checkNotificationStatus()
                completion(granted)
            }
        }
    }
    
    func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func getNotificationActionTitle() -> String {
        switch notificationStatus {
        case .notDetermined:
            return "Enable Notifications"
        case .denied, .authorized, .provisional, .ephemeral:
            return "Open Settings"
        case .unknown:
            return "Check Settings"
        }
    }
    
    func getNotificationActionMessage() -> String {
        switch notificationStatus {
        case .notDetermined:
            return "Allow Habitual to send you habit reminders?"
        case .denied:
            return "Notifications are currently disabled. Open Settings to enable habit reminders."
        case .authorized, .provisional, .ephemeral:
            return "Manage your notification preferences in Settings."
        case .unknown:
            return "Check your notification settings in the Settings app."
        }
    }
    
    func handleNotificationAction() {
        switch notificationStatus {
        case .notDetermined:
            requestNotificationPermission { granted in
                // Handle notification permission granted
            }
        case .denied, .authorized, .provisional, .ephemeral, .unknown:
            openAppSettings()
        }
    }
}
