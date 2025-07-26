import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var reminderTime = Date()
    @State private var showingAbout = false
    @State private var showingExport = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                    
                }
                
                Section("Reminders") {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
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
                
                Section("Support") {
                    NavigationLink("Help & FAQ") {
                        HelpView()
                    }
                    
                    Button("Rate Habitual") {
                        requestAppReview()
                    }
                    
                    Button("About") {
                        showingAbout = true
                    }
                }
                
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Habitual")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExport) {
                ExportView()
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

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Habitual")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Build better habits, one day at a time")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    Link("Contact Support", destination: URL(string: "mailto:pat@codeofhonor.com")!)
                }
                
                Spacer()
                
                Text("Made with ❤️")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
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
