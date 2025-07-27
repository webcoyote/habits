import SwiftUI
import StoreKit
import UIKit
import WebKit
import UniformTypeIdentifiers

extension UTType {
    static let habitual = UTType(exportedAs: "com.habitual.backup")
}

struct SettingsView: View {
    @ObservedObject private var notificationManager = NotificationPermissionManager.shared
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var usageTracker = UsageTracker.shared
    @State private var activeSheet: SheetType?
    @State private var activeAlert: AlertType?
    @State private var showingSurvey = false
    
    enum SheetType: Identifiable {
        case appearance
        case survey
        
        var id: Self { self }
    }
    
    enum AlertType: Identifiable {
        case notification, appInfo, language, support, privacy, terms
        
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
                        AnalyticsManager.shared.track("settings_tapped", properties: ["setting": "appearance"])
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
                    NavigationLink {
                        BackupSyncView()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            Text("Backup & Restore")
                            Spacer()
                        }
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
                    
                    SettingsRowWithIcon(
                        title: "App Details",
                        subtitle: "\(appInfo.name) version \(appInfo.version) (build \(appInfo.build))",
                        icon: "info.circle"
                    ) {
                        activeAlert = .appInfo
                    }
                    
                    if let stats = usageTracker.stats {
                        SettingsInfoRow(
                            title: "App Launches",
                            subtitle: "\(stats.launches) times",
                            icon: "chart.bar.fill"
                        )
                        
                        SettingsInfoRow(
                            title: "Habits Created",
                            subtitle: "\(stats.habitsCreated) habits",
                            icon: "plus.circle.fill"
                        )
                        
                        SettingsInfoRow(
                            title: "Habits Formed",
                            subtitle: "\(stats.habitsFormed) times",
                            icon: "checkmark.circle.fill"
                        )
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
        AnalyticsManager.shared.track("rate_app_tapped")
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

struct BackupSyncView: View {
    @State private var showingShareSheet = false
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var backupURL: URL?
    @State private var showingRestoreConfirmation = false
    @State private var pendingRestoreURL: URL?
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keep your habits safe")
                        .font(.headline)
                    Text("Create backups to save your habit data and history. You can restore from these backups at any time, even on a different device.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Backup & Restore") {
                Button(action: createBackup) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Create Backup")
                        Spacer()
                        if isLoading && backupURL == nil {
                            SwiftUI.ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isLoading)
                
                Button(action: { showingDocumentPicker = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Restore from Backup")
                        Spacer()
                    }
                }
                .disabled(isLoading)
                
                Text("Create a backup of all your habits and history, or restore from a previous backup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = backupURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(
                documentTypes: [.habitual, .json],
                onPick: { url in
                    pendingRestoreURL = url
                    showingRestoreConfirmation = true
                }
            )
        }
        .alert("Backup", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Restore Backup", isPresented: $showingRestoreConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingRestoreURL = nil
            }
            Button("Restore", role: .destructive) {
                if let url = pendingRestoreURL {
                    restoreBackup(from: url)
                }
            }
        } message: {
            Text("Warning: Restoring from a backup will permanently delete all your current habits and history. This action cannot be undone.\n\nAre you sure you want to continue?")
        }
    }
    
    private func createBackup() {
        isLoading = true
        
        BackupManager.shared.createBackup { result in
            isLoading = false
            
            switch result {
            case .success(let url):
                backupURL = url
                showingShareSheet = true
                AnalyticsManager.shared.track("backup_created")
            case .failure(let error):
                alertMessage = "Failed to create backup: \(error.localizedDescription)"
                showingAlert = true
                AnalyticsManager.shared.track("backup_failed", properties: ["error": error.localizedDescription])
            }
        }
    }
    
    private func restoreBackup(from url: URL) {
        isLoading = true
        
        BackupManager.shared.restoreBackup(from: url) { result in
            isLoading = false
            
            switch result {
            case .success(let count):
                alertMessage = "Successfully restored \(count) habit\(count == 1 ? "" : "s")!"
                showingAlert = true
                AnalyticsManager.shared.track("backup_restored", properties: ["habit_count": count])
                
                // Post notification to refresh the habit list
                NotificationCenter.default.post(name: NSNotification.Name("RefreshHabits"), object: nil)
            case .failure(let error):
                alertMessage = "Failed to restore backup: \(error.localizedDescription)"
                showingAlert = true
                AnalyticsManager.shared.track("restore_failed", properties: ["error": error.localizedDescription])
            }
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - DocumentPicker
struct DocumentPicker: UIViewControllerRepresentable {
    let documentTypes: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: documentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Copy file to temporary location
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                parent.onPick(tempURL)
            } catch {
                print("Error copying file: \(error)")
            }
        }
    }
}

struct SettingsInfoRow: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
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
