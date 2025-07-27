import Foundation
import SwiftUI

struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var color: CodableColor
    var type: HabitType
    var goal: Goal?
    var history: [DayRecord]
    
    init(id: UUID = UUID(), name: String, icon: String, color: Color, type: HabitType, goal: Goal? = nil, history: [DayRecord] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = CodableColor(color: color)
        self.type = type
        self.goal = goal
        self.history = history
    }
}

enum HabitType: Codable, Equatable {
    case binary
    case numeric(target: Int)
    case graph(scale: Int)
    
    var displayName: String {
        switch self {
        case .binary:
            return "On/Off"
        case .numeric:
            return "Count"
        case .graph:
            return "Graph"
        }
    }
}

struct DayRecord: Codable, Equatable {
    let id: UUID
    let date: Date
    var value: HabitValue
    
    init(id: UUID = UUID(), date: Date, value: HabitValue) {
        self.id = id
        self.date = date
        self.value = value
    }
}

enum HabitValue: Codable, Equatable {
    case binary(completed: Bool)
    case numeric(value: Int)
    case graph(value: Int)
}

struct Goal: Codable, Equatable {
    let value: Int
    let period: Period
    
    enum Period: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
}

struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}
