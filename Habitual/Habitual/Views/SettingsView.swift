import SwiftUI
import StoreKit
import UIKit
import WebKit

struct SettingsView: View {
    @ObservedObject private var notificationManager = NotificationPermissionManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var activeSheet: SheetType?
    @State private var activeAlert: AlertType?
    @State private var showingExport = false
    @State private var showingSurvey = false
    
    enum SheetType: Identifiable {
        case appearance
        case survey
        
        var id: Self { self }
    }
    
    enum AlertType: Identifiable {
        case notification, appInfo, language, help, support, privacy, terms
        
        var id: Self { self }
    }

    private let warningColor = Color(red: 255/255.0, green: 104/255.0, blue: 0/255.0, opacity: 1.0)
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    SettingsRowWithIcon(
                        title: "Appearance",
                        subtitle: appSettings.appearanceMode.displayName,
                        icon: "paintbrush"
                    ) {
                        activeSheet = .appearance
                    }
                }
                
                Section("Reminders") {
                    SettingsRowWithIcon(
                        title: "Notifications",
                        subtitle: notificationManager.notificationStatus.displayName,
                        icon: "bell",
                        isDisabled: notificationManager.notificationStatus.isDisabled,
                        showWarning: notificationManager.notificationStatus.isDisabled
                    ) {
                        activeAlert = .notification
                    }
                    
                    SettingsRowWithIcon(
                        title: "Language",
                        subtitle: "English",
                        icon: "globe"
                    ) {
                        activeAlert = .language
                    }
                }
                
                Section("Data") {
                    Button("Export Data") {
                        showingExport = true
                    }
                    
                    NavigationLink("Backup & Sync") {
                        BackupSyncView()
                    }
                }
                
                Section("Feedback") {
                    SettingsRowWithIcon(
                        title: "Rate the App",
                        subtitle: nil,
                        icon: "star.fill"
                    ) {
                        requestAppReview()
                    }

                    SettingsRowWithIcon(
                        title: "Take a Survey",
                        subtitle: nil,
                        icon: "doc.text"
                    ) {
                        showingSurvey = true
                    }
                }

                Section("Support") {
                    SettingsRowWithIcon(
                        title: "Help & FAQ",
                        subtitle: nil,
                        icon: "questionmark.circle"
                    ) {
                        activeAlert = .help
                    }
                    
                    SettingsRowWithIcon(
                        title: "Contact Support",
                        subtitle: nil,
                        icon: "envelope"
                    ) {
                        activeAlert = .support
                    }
                    
                    SettingsRowWithIcon(
                        title: "Privacy Policy",
                        subtitle: nil,
                        icon: "lock.shield"
                    ) {
                        activeAlert = .privacy
                    }
                    
                    SettingsRowWithIcon(
                        title: "Terms of Service",
                        subtitle: nil,
                        icon: "doc.text"
                    ) {
                        activeAlert = .terms
                    }
                    
                }
                
                Section("App Information") {
                    let appInfo = AppSettings.shared.getAppInfo()
                    let stats = UsageTracker.shared.getStats()
                    
                    SettingsRowWithIcon(
                        title: "App Details",
                        subtitle: "\(appInfo.name) v\(appInfo.version) (\(appInfo.build))",
                        icon: "info.circle"
                    ) {
                        activeAlert = .appInfo
                    }
                    
                    if let stats = stats {
                        SettingsRowWithIcon(
                            title: "App Launches",
                            subtitle: "\(stats.launches) times",
                            icon: "chart.bar.fill"
                        ) {}
                        
                        SettingsRowWithIcon(
                            title: "Habits Created",
                            subtitle: "\(stats.habitsCreated) habits",
                            icon: "plus.circle.fill"
                        ) {}
                        
                        SettingsRowWithIcon(
                            title: "Habits Checked",
                            subtitle: "\(stats.habitsChecked) times",
                            icon: "checkmark.circle.fill"
                        ) {}
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .appearance:
                    AppearanceSelectionView()
                case .survey:
                    SurveyWebView(url: URL(string: "https://tally.so/r/mRyLPp")!)
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportView()
            }
            .sheet(isPresented: $showingSurvey) {
                SurveyWebView(url: URL(string: "https://tally.so/r/mRyLPp")!)
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .notification:
                    Alert(
                        title: Text("Notifications"),
                        message: Text(notificationManager.getNotificationActionMessage()),
                        primaryButton: .default(Text(notificationManager.notificationStatus == .notDetermined ? "Allow" : "Open Settings")) {
                            if notificationManager.notificationStatus == .notDetermined {
                                notificationManager.handleNotificationAction()
                            } else {
                                notificationManager.openAppSettings()
                            }
                        },
                        secondaryButton: .cancel(Text(notificationManager.notificationStatus == .notDetermined ? "Not Now" : "Cancel"))
                    )
                case .appInfo:
                    Alert(
                        title: Text("App Information"),
                        message: Text(AppSettings.shared.getDeviceInfo()),
                        primaryButton: .default(Text("Copy")) {
                            UIPasteboard.general.string = AppSettings.shared.getDeviceInfo()
                        },
                        secondaryButton: .cancel(Text("OK"))
                    )
                case .language:
                    Alert(
                        title: Text("Language"),
                        message: Text("Language selection coming soon"),
                        dismissButton: .default(Text("OK"))
                    )
                case .help:
                    Alert(
                        title: Text("Help & FAQ"),
                        message: Text("Help documentation coming soon"),
                        dismissButton: .default(Text("OK"))
                    )
                case .support:
                    Alert(
                        title: Text("Contact Support"),
                        message: Text("Email: pat@codeofhonor.com"),
                        dismissButton: .default(Text("OK"))
                    )
                case .privacy:
                    Alert(
                        title: Text("Privacy Policy"),
                        message: Text("Privacy policy coming soon"),
                        dismissButton: .default(Text("OK"))
                    )
                case .terms:
                    Alert(
                        title: Text("Terms of Service"),
                        message: Text("Terms of service coming soon"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    private func requestAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

struct BackupSyncView: View {
    @State private var iCloudEnabled = true
    
    var body: some View {
        Form {
            Section("iCloud Sync") {
                Toggle("Sync with iCloud", isOn: $iCloudEnabled)
                
                Text("Enable iCloud sync to keep your habits synchronized across all your devices.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Backup") {
                Button("Create Backup") {
                    createBackup()
                }
                
                Button("Restore from Backup") {
                    restoreBackup()
                }
            }
        }
        .navigationTitle("Backup & Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func createBackup() {
        
    }
    
    private func restoreBackup() {
        
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                HelpItem(title: "Creating a Habit", description: "Tap the + button to create a new habit. Choose a name, icon, color, and tracking type.")
                HelpItem(title: "Tracking Progress", description: "Tap the circle button on each habit card to mark it as complete for today.")
                HelpItem(title: "Viewing Details", description: "Tap on any habit card to see detailed statistics and history.")
            }
            
            Section("Habit Types") {
                HelpItem(title: "Yes/No Habits", description: "Simple habits that you either complete or don't. Perfect for daily activities.")
                HelpItem(title: "Numeric Habits", description: "Track quantities like glasses of water or pages read. Set a daily target to reach.")
                HelpItem(title: "Mood Tracking", description: "Monitor your daily mood or energy levels on a scale.")
            }
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}


struct ExportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose a format to export your habit data")
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    ExportButton(title: "CSV", subtitle: "Compatible with Excel and Google Sheets", icon: "doc.text") {
                        exportCSV()
                    }
                    
                    ExportButton(title: "JSON", subtitle: "For developers and advanced users", icon: "doc.badge.gearshape") {
                        exportJSON()
                    }
                    
                    ExportButton(title: "PDF Report", subtitle: "Visual summary of your progress", icon: "doc.richtext") {
                        exportPDF()
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func exportCSV() {
        
    }
    
    private func exportJSON() {
        
    }
    
    private func exportPDF() {
        
    }
}

struct ExportButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 40)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRowWithIcon: View {
    let title: String
    let subtitle: String?
    let icon: String
    let isDisabled: Bool
    let showWarning: Bool
    let action: () -> Void
    
    private let warningColor = Color(red: 255/255.0, green: 104/255.0, blue: 0/255.0, opacity: 1.0)
    
    init(
        title: String,
        subtitle: String?,
        icon: String,
        isDisabled: Bool = false,
        showWarning: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isDisabled = isDisabled
        self.showWarning = showWarning
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(isDisabled ? .secondary : .primary)
                    
                    if let subtitle = subtitle {
                        HStack {
                            if showWarning {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(warningColor)
                                    .font(.caption)
                            }
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(showWarning ? warningColor : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SurveyWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            WebView(url: url)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(Color.accentColor)
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
