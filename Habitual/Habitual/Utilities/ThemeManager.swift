import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("accentColorData") private var accentColorData: Data?
    
    @Published var accentColor: Color = .blue {
        didSet {
            saveAccentColor()
        }
    }
    
    init() {
        loadAccentColor()
    }
    
    private func saveAccentColor() {
        let uiColor = UIColor(accentColor)
        accentColorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
    }
    
    private func loadAccentColor() {
        guard let data = accentColorData,
              let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor else {
            return
        }
        accentColor = Color(uiColor)
    }
}
