import SwiftUI

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

enum CompanionFeedback {
    @MainActor
    static func play(for reaction: CompanionReaction) {
#if os(iOS)
        switch reaction {
        case .rapidTap, .bodyPoke:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
        case .longPress:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.75)
        case .headPat, .hatTouch:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
        case .chirp:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .idle, .sleepy:
            UISelectionFeedbackGenerator().selectionChanged()
        }
#elseif os(watchOS)
        switch reaction {
        case .rapidTap, .bodyPoke, .longPress:
            WKInterfaceDevice.current().play(.directionDown)
        case .headPat, .hatTouch:
            WKInterfaceDevice.current().play(.click)
        case .chirp:
            WKInterfaceDevice.current().play(.success)
        case .idle, .sleepy:
            WKInterfaceDevice.current().play(.start)
        }
#endif
    }
}
