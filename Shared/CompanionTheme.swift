import SwiftUI

enum CompanionTheme {
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.25)
    static let secondaryInk = Color(red: 0.35, green: 0.40, blue: 0.52)
    static let warmWhite = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let mist = Color(red: 0.92, green: 0.95, blue: 1.00)
    static let sky = Color(red: 0.43, green: 0.64, blue: 0.93)
    static let cobalt = Color(red: 0.18, green: 0.35, blue: 0.69)
    static let gold = Color(red: 0.91, green: 0.65, blue: 0.22)
    static let rose = Color(red: 0.91, green: 0.42, blue: 0.48)

    static func background(for phase: DayPhase) -> [Color] {
        switch phase {
        case .morning:
            [Color(red: 0.98, green: 0.95, blue: 0.88), Color(red: 0.85, green: 0.91, blue: 1.00)]
        case .afternoon:
            [Color(red: 0.94, green: 0.97, blue: 1.00), Color(red: 0.78, green: 0.87, blue: 0.98)]
        case .evening:
            [Color(red: 0.91, green: 0.86, blue: 0.95), Color(red: 0.66, green: 0.72, blue: 0.90)]
        case .night:
            [Color(red: 0.10, green: 0.14, blue: 0.27), Color(red: 0.18, green: 0.23, blue: 0.42)]
        }
    }

    static func foreground(for phase: DayPhase) -> Color {
        phase == .night ? warmWhite : ink
    }

    static func secondaryForeground(for phase: DayPhase) -> Color {
        phase == .night ? warmWhite.opacity(0.72) : secondaryInk
    }
}
