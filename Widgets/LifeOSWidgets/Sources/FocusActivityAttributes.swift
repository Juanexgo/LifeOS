import ActivityKit
import Foundation

/// Shape of the data on the Focus Live Activity. Lives in the Widgets target
/// because the extension renders it — the main app references the same file
/// via target-membership (Tuist links it into both).
///
/// `ContentState` is what changes during the activity (remaining seconds,
/// pause flag). `Attributes` (this struct) is set once at start.
public struct FocusActivityAttributes: ActivityAttributes {
    public typealias ContentState = State

    public struct State: Codable, Hashable, Sendable {
        public var remainingSeconds: Int
        public var totalSeconds: Int
        public var isPaused: Bool

        public init(remainingSeconds: Int, totalSeconds: Int, isPaused: Bool) {
            self.remainingSeconds = remainingSeconds
            self.totalSeconds = totalSeconds
            self.isPaused = isPaused
        }

        public var progress: Double {
            guard totalSeconds > 0 else { return 0 }
            return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
        }
    }

    public let intent: String

    public init(intent: String) {
        self.intent = intent
    }
}
