import SwiftUI
import UIKit

/// Haptic vocabulary. Two surfaces:
///   1. SwiftUI: `.sensoryFeedback(.lifeOS(.tap), trigger:)` — preferred.
///   2. Imperative: `Haptics.tap()` — for non-view code (view models, services).
///
/// Centralising means we never call `UIImpactFeedbackGenerator` directly from
/// feature code, so the haptic language stays consistent.
public enum HapticEvent: Sendable {
    case tap        // soft, light tick — list selections, toggles
    case commit     // firm tick — confirm an action
    case success    // double pulse — task completed
    case warn       // attention — undo banner, mild error
    case error      // alert — destructive failure
}

public enum Haptics {
    @MainActor public static func tap()     { play(.tap) }
    @MainActor public static func commit()  { play(.commit) }
    @MainActor public static func success() { play(.success) }
    @MainActor public static func warn()    { play(.warn) }
    @MainActor public static func error()   { play(.error) }

    @MainActor public static func play(_ event: HapticEvent) {
        switch event {
        case .tap:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
        case .commit:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.85)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warn:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - SwiftUI integration

public extension SensoryFeedback {
    /// Map a LifeOS event onto SwiftUI's `SensoryFeedback`.
    static func lifeOS(_ event: HapticEvent) -> SensoryFeedback {
        switch event {
        case .tap:     return .impact(weight: .light, intensity: 0.6)
        case .commit:  return .impact(weight: .heavy, intensity: 0.9)
        case .success: return .success
        case .warn:    return .warning
        case .error:   return .error
        }
    }
}
