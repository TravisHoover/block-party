import UIKit

enum Haptics {
    static func pickUp() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func place() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func clear() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func gameOver() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
