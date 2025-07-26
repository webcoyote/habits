import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false {
        didSet {
            objectWillChange.send()
        }
    }
}
