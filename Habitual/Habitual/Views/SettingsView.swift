import SwiftUI
import StoreKit
import UIKit
import WebKit
import UniformTypeIdentifiers
import CoreData

extension UTType {
    static let habitual = UTType(exportedAs: "com.habitual.backup")
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
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
        case gradientColors
        case survey
        case privacy

        var id: Self { self }
    }

    enum AlertType: Identifiable {
        case notification, appInfo, language, support, debugFillData

        var id: Self { self }
    }

    private let warningColor = Color(red: 255/255.0, green: 104/255.0, blue: 0/255.0, opacity: 1.0)

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background for entire page
                appSettings.backgroundGradientWithOpacity
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SettingsSection("Appearance") {
                            VStack(spacing: 0) {
                                SettingsRowWithIcon(
                                    title: "Appearance",
                                    subtitle: appSettings.appearanceMode.displayName,
                                    icon: "paintbrush"
                                ) {
                                    activeSheet = .appearance
                                    AnalyticsManager.shared.track("settings_tapped", properties: ["setting": "appearance"])
                                }
                                .padding()
                                
                                Divider()
                                
                                SettingsRowWithIcon(
                                    title: "Background Colors",
                                    subtitle: "Customize background",
                                    icon: "paintpalette"
                                ) {
                                    activeSheet = .gradientColors
                                    AnalyticsManager.shared.track("settings_tapped", properties: ["setting": "gradient_colors"])
                                }
                                .padding()
                            }
                        }

                        SettingsSection("Reminders") {
                            VStack(spacing: 0) {
                                SettingsRowWithIcon(
                                    title: "Notifications",
                                    subtitle: notificationManager.notificationStatus.displayName,
                                    icon: "bell",
                                    isDisabled: notificationManager.notificationStatus.isDisabled,
                                    showWarning: notificationManager.notificationStatus.isDisabled
                                ) {
                                    activeAlert = .notification
                                }
                                .padding()

                                Divider()

                                SettingsRowWithIcon(
                                    title: "Language",
                                    subtitle: "English",
                                    icon: "globe"
                                ) {
                                    activeAlert = .language
                                }
                                .padding()
                            }
                        }

                        SettingsSection("Data") {
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
                            .padding()
                        }

                        SettingsSection("Feedback") {
                            VStack(spacing: 0) {
                                SettingsRowWithIcon(
                                    title: "Rate the App",
                                    subtitle: nil,
                                    icon: "star.fill"
                                ) {
                                    requestAppReview()
                                }
                                .padding()

                                Divider()

                                SettingsRowWithIcon(
                                    title: "Take a Survey",
                                    subtitle: nil,
                                    icon: "doc.text"
                                ) {
                                    showingSurvey = true
                                }
                                .padding()
                            }
                        }

                        SettingsSection("Support") {
                            VStack(spacing: 0) {
                                SettingsRowWithIcon(
                                    title: "Contact Support",
                                    subtitle: nil,
                                    icon: "envelope"
                                ) {
                                    activeAlert = .support
                                }
                                .padding()

                                Divider()

                                SettingsRowWithIcon(
                                    title: "Privacy Policy",
                                    subtitle: nil,
                                    icon: "lock.shield"
                                ) {
                                    activeSheet = .privacy
                                    AnalyticsManager.shared.track("settings_tapped", properties: ["setting": "privacy_policy"])
                                }
                                .padding()
                            }
                        }

                        SettingsSection("App Information") {
                            VStack(spacing: 0) {
                                let appInfo = AppSettings.shared.getAppInfo()

                                SettingsRowWithIcon(
                                    title: "App Details",
                                    subtitle: "\(appInfo.name) v\(appInfo.version).\(appInfo.build)",
                                    icon: "info.circle"
                                ) {
                                    activeAlert = .appInfo
                                }
                                .padding()

                                if let stats = usageTracker.stats {
                                    Divider()

                                    SettingsInfoRow(
                                        title: "App Launches",
                                        subtitle: "\(stats.launches) times",
                                        icon: "chart.bar.fill"
                                    )
                                    .padding()

                                    Divider()

                                    SettingsInfoRow(
                                        title: "Habits Created",
                                        subtitle: "\(stats.habitsCreated) habits",
                                        icon: "plus.circle.fill"
                                    )
                                    .padding()

                                    Divider()

                                    SettingsInfoRow(
                                        title: "Habits Formed",
                                        subtitle: "\(stats.habitsFormed) times",
                                        icon: "checkmark.circle.fill"
                                    )
                                    .padding()
                                }
                            }
                        }

                        #if DEBUG
                        SettingsSection("Debug") {
                            SettingsRowWithIcon(
                                title: "Fill Sample Data",
                                subtitle: "Overwrites all current data",
                                icon: "exclamationmark.triangle.fill",
                                showWarning: true
                            ) {
                                activeAlert = .debugFillData
                            }
                            .padding()
                        }
                        #endif
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Settings")
            }
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .appearance:
                    AppearanceSelectionView()
                case .gradientColors:
                    GradientColorPicker()
                case .survey:
                    SurveyWebView(url: URL(string: "https://tally.so/r/mRyLPp")!)
                case .privacy:
                    SurveyWebView(url: URL(string: "https://www.termsfeed.com/live/d7469d0c-8047-435a-8208-f7811d293a88")!)
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
                        primaryButton: .default(Text("Send Email")) {
                            if let url = URL(string: "mailto:pat@codeofhonor.com") {
                                UIApplication.shared.open(url)
                            }
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                case .debugFillData:
                    Alert(
                        title: Text("Fill Sample Data"),
                        message: Text("This will permanently delete all your current habits and history, then create sample habits with realistic data. This action cannot be undone.\n\nAre you sure you want to continue?"),
                        primaryButton: .destructive(Text("Delete & Fill")) {
                            fillSampleData()
                        },
                        secondaryButton: .cancel()
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

    private func fillSampleData() {
        let context = PersistenceController.shared.container.viewContext

        // Delete all existing records first
        let recordFetchRequest: NSFetchRequest<NSFetchRequestResult> = RecordEntity.fetchRequest()
        let deleteRecordsRequest = NSBatchDeleteRequest(fetchRequest: recordFetchRequest)

        do {
            try context.execute(deleteRecordsRequest)
        } catch {
            print("Error deleting existing records: \(error)")
        }

        // Delete all existing habits
        let habitFetchRequest: NSFetchRequest<NSFetchRequestResult> = HabitEntity.fetchRequest()
        let deleteHabitsRequest = NSBatchDeleteRequest(fetchRequest: habitFetchRequest)

        do {
            try context.execute(deleteHabitsRequest)

            // Reset the persistent store to ensure clean state
            context.reset()

            // Save to ensure deletions are committed
            try context.save()
        } catch {
            print("Error deleting existing habits: \(error)")
        }

        // Create sample habits for someone trying to be a better person (one of each type)
        let sampleHabits = [
            (name: "Morning Exercise", icon: "figure.run", color: Color.orange, type: HabitType.binary, goal: Goal(value: 5, period: .weekly)),
            (name: "Drink Water", icon: "drop.fill", color: Color.blue, type: HabitType.numeric(target: 8), goal: Goal(value: 8, period: .daily)),
            (name: "Mood Tracker", icon: "face.smiling", color: Color.yellow, type: HabitType.graph(scale: 10), goal: nil)
        ]

        for (index, habitData) in sampleHabits.enumerated() {
            let habit = Habit(
                name: habitData.name,
                icon: habitData.icon,
                color: habitData.color,
                type: habitData.type,
                goal: habitData.goal
            )

            // Save the habit
            PersistenceController.shared.saveHabit(habit, context: context)

            // Set order
            let request: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
            if let entity = try? context.fetch(request).first {
                entity.order = Int32(index)

                // Generate realistic historical data
                generateRealisticHistory(for: entity, habit: habit, context: context)
            }
        }

        // Save all changes
        do {
            try context.save()

            // Update statistics
            DatabaseManager.shared.incrementHabitsCreated()

            // Post notification to refresh the habit list
            NotificationCenter.default.post(name: NSNotification.Name("RefreshHabits"), object: nil)

            AnalyticsManager.shared.track("debug_sample_data_filled")
        } catch {
            print("Error saving sample habits: \(error)")
        }
    }

    private func generateRealisticHistory(for habitEntity: HabitEntity, habit: Habit, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = Date()
        let encoder = JSONEncoder()

        // Different patterns for different habits
        switch habit.name {
        case "Morning Exercise":
            // Generate data, starting sporadically on weekends and getting progressively better
            let maxDays = 200
            for daysAgo in 0..<maxDays {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

                let dayOfWeek = calendar.component(.weekday, from: date)
                let progress = Double(maxDays - daysAgo) / Double(maxDays)

                // Start with low completion rate on weekends only, improve over time
                var completionChance: Double = 0.0

                if daysAgo > 160 {
                    // First month: only weekends with low chance
                    if dayOfWeek == 1 || dayOfWeek == 7 {
                        completionChance = 0.4
                    }
                } else if daysAgo > 120 {
                    // Second month: weekends more likely, some weekdays
                    if dayOfWeek == 1 || dayOfWeek == 7 {
                        completionChance = 0.5
                    } else {
                        completionChance = 0.2
                    }
                } else if daysAgo > 80 {
                    // Third month: improving consistency
                    if dayOfWeek == 1 || dayOfWeek == 7 {
                        completionChance = 0.6
                    } else {
                        completionChance = 0.3
                    }
                } else if daysAgo > 7 {
                    // Last 40 days: much better consistency
                    completionChance = 0.7 + (progress * 0.2) // 70% to 90%
                } else {
                    completionChance = 1
                }

                let completed = Double.random(in: 0...1) < completionChance

                if completed || (daysAgo < 20 && Double.random(in: 0...1) < 0.3) {
                    let recordEntity = RecordEntity(context: context)
                    recordEntity.id = UUID()
                    recordEntity.date = date
                    recordEntity.habit = habitEntity

                    let value = HabitValue.binary(completed: completed)
                    recordEntity.valueData = try? encoder.encode(value)
                }
            }

        case "Drink Water":
            // Generate 7 days of data, starting low and finishing higher
            for daysAgo in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

                let recordEntity = RecordEntity(context: context)
                recordEntity.id = UUID()
                recordEntity.date = date
                recordEntity.habit = habitEntity

                // Start at ~3-4 glasses, end at ~8 glasses
                let progress = Double(7 - daysAgo) / 7.0
                let baseValue = Int(3.5 + (4.5 * progress))
                let variance = Int.random(in: -1...1)
                let finalValue = max(0, min(10, baseValue + variance))

                let value = HabitValue.numeric(value: finalValue)
                recordEntity.valueData = try? encoder.encode(value)
            }

        case "Mood Tracker":
            // Generate 7 days of data, starting low and finishing at 10
            for daysAgo in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

                let recordEntity = RecordEntity(context: context)
                recordEntity.id = UUID()
                recordEntity.date = date
                recordEntity.habit = habitEntity

                // Start at ~3-4, end at 10
                let progress = Double(7 - daysAgo) / 7.0
                let baseValue: Int

                if daysAgo == 0 {
                    // Today should be exactly 10
                    baseValue = 10
                } else {
                    baseValue = Int(3.5 + (6.5 * progress))
                }

                let variance = daysAgo == 0 ? 0 : Int.random(in: -1...1)
                let finalValue = max(1, min(10, baseValue + variance))

                let value = HabitValue.graph(value: finalValue)
                recordEntity.valueData = try? encoder.encode(value)
            }

        default:
            break
        }
    }
}

// MARK: - BackupSyncView
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
