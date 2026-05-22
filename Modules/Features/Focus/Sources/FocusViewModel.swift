import Foundation
import Observation
import SwiftData
import PersistenceKit

/// The live state of a Focus session. Owns the countdown, exposes the
/// remaining time as a computed `@Observable` property. SwiftUI re-renders
/// any time `tick` advances.
///
/// The timer uses `Task.sleep` rather than `Timer` — easier to cancel
/// cleanly and stays on the main actor where view updates need it.
@MainActor
@Observable
public final class FocusViewModel {
    public enum Phase: Sendable, Equatable {
        case idle
        case running(startedAt: Date, plannedSeconds: Int, intent: String)
        case paused(remainingSeconds: Int, plannedSeconds: Int, intent: String)
    }

    public private(set) var phase: Phase = .idle
    /// Drives view updates. Incremented every second while running.
    public private(set) var tick: Int = 0

    private var tickerTask: Task<Void, Never>? = nil

    public init() {}

    // MARK: - Public API

    public func start(intent: String, plannedSeconds: Int) {
        phase = .running(startedAt: .now, plannedSeconds: plannedSeconds, intent: intent)
        startTicker()
    }

    public func pause() {
        guard case let .running(startedAt, planned, intent) = phase else { return }
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let remaining = max(planned - elapsed, 0)
        tickerTask?.cancel()
        phase = .paused(remainingSeconds: remaining, plannedSeconds: planned, intent: intent)
    }

    public func resume() {
        guard case let .paused(remaining, planned, intent) = phase else { return }
        // Effective new start time as if the session began `planned - remaining` seconds ago.
        let effectiveStart = Date.now.addingTimeInterval(-Double(planned - remaining))
        phase = .running(startedAt: effectiveStart, plannedSeconds: planned, intent: intent)
        startTicker()
    }

    /// Stop the session and persist it. Pass the model context from the view.
    public func stop(saving context: ModelContext, completed: Bool) {
        defer { phase = .idle; tickerTask?.cancel(); tick = 0 }

        switch phase {
        case .idle:
            return
        case .running(let startedAt, let planned, let intent):
            let session = FocusSession(
                intent: intent,
                startedAt: startedAt,
                plannedSeconds: planned,
                completedAt: .now,
                wasCancelled: !completed
            )
            context.insert(session)
            try? context.save()
        case .paused(let remaining, let planned, let intent):
            let elapsed = planned - remaining
            let session = FocusSession(
                intent: intent,
                startedAt: .now.addingTimeInterval(-Double(elapsed)),
                plannedSeconds: planned,
                completedAt: .now,
                wasCancelled: !completed
            )
            context.insert(session)
            try? context.save()
        }
    }

    // MARK: - Derived state

    public var remainingSeconds: Int {
        switch phase {
        case .idle: return 0
        case .running(let startedAt, let planned, _):
            return max(planned - Int(Date.now.timeIntervalSince(startedAt)), 0)
        case .paused(let remaining, _, _):
            return remaining
        }
    }

    public var totalSeconds: Int {
        switch phase {
        case .idle: return 0
        case .running(_, let planned, _): return planned
        case .paused(_, let planned, _): return planned
        }
    }

    public var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    public var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    public var isPaused: Bool {
        if case .paused = phase { return true }
        return false
    }

    public var intentText: String {
        switch phase {
        case .idle: return ""
        case .running(_, _, let intent), .paused(_, _, let intent): return intent
        }
    }

    // MARK: - Private

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.tick &+= 1
                if self.remainingSeconds <= 0, case .running = self.phase {
                    // Timer ran out — caller should observe and save.
                    self.tickerTask?.cancel()
                    return
                }
            }
        }
    }
}
