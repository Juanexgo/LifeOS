import Foundation
import EventKit

/// Minimal EventKit reader. Lives inside the Dashboard feature for now
/// because it's the only consumer. If a second consumer appears (Focus
/// scheduling, AI context) we promote to its own `Integrations/EventKitBridge`
/// module.
///
/// Permission flow: caller invokes `loadTodayEvents()` and we trigger the
/// access prompt the first time. Subsequent calls reuse the granted access.
@MainActor
public final class EventKitBridge {
    public struct Event: Identifiable, Sendable, Equatable {
        public let id: String
        public let title: String
        public let startDate: Date
        public let endDate: Date
        public let isAllDay: Bool
        public let calendarColor: CGColor?

        public var timeRangeString: String {
            if isAllDay { return "All day" }
            let f = Date.FormatStyle.dateTime.hour().minute()
            return "\(startDate.formatted(f)) – \(endDate.formatted(f))"
        }
    }

    public enum Status: Sendable {
        case notDetermined
        case denied
        case authorized
        case unavailable
    }

    private let store = EKEventStore()

    public init() {}

    public func currentStatus() -> Status {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:       return .notDetermined
        case .denied, .restricted: return .denied
        case .fullAccess, .writeOnly: return .authorized
        case .authorized:          return .authorized   // legacy pre-iOS 17
        @unknown default:          return .unavailable
        }
    }

    /// Request access if not yet determined, then return today's events.
    /// Returns an empty array (not nil) on denied/no-events for simpler
    /// view code.
    public func loadTodayEvents() async -> [Event] {
        let granted: Bool
        do {
            granted = try await store.requestFullAccessToEvents()
        } catch {
            return []
        }
        guard granted else { return [] }

        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let raw = store.events(matching: predicate)

        return raw.sorted { $0.startDate < $1.startDate }.map {
            Event(
                id: $0.eventIdentifier ?? UUID().uuidString,
                title: $0.title ?? "(Untitled)",
                startDate: $0.startDate,
                endDate: $0.endDate,
                isAllDay: $0.isAllDay,
                calendarColor: $0.calendar?.cgColor
            )
        }
    }
}
