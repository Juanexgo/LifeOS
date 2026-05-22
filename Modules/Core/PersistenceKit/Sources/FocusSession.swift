import Foundation
import SwiftData

/// A focused work session. We persist completed/cancelled sessions for
/// analytics (Phase 5c). The currently-running session is held in memory
/// by `FocusViewModel`; only on completion or cancel do we write.
@Model
public final class FocusSession {
    public var id: UUID
    public var intent: String
    public var startedAt: Date
    /// Planned duration in seconds. Pomodoro defaults: 25 / 50 / custom.
    public var plannedSeconds: Int
    /// Actual end time. nil if cancelled mid-flight.
    public var completedAt: Date?
    /// True if the user stopped before the timer ran out.
    public var wasCancelled: Bool

    public init(
        id: UUID = UUID(),
        intent: String,
        startedAt: Date = .now,
        plannedSeconds: Int,
        completedAt: Date? = nil,
        wasCancelled: Bool = false
    ) {
        self.id = id
        self.intent = intent
        self.startedAt = startedAt
        self.plannedSeconds = plannedSeconds
        self.completedAt = completedAt
        self.wasCancelled = wasCancelled
    }
}

public extension FocusSession {
    var actualDuration: TimeInterval {
        guard let end = completedAt else { return 0 }
        return end.timeIntervalSince(startedAt)
    }

    var actualMinutes: Int { Int(actualDuration / 60) }
}
