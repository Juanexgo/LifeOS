import Foundation
import HealthKit

/// Read-only adapter over HealthKit. Pulls today's step count and active
/// calories — the bare minimum for a "how was your day" glance. Heart-rate,
/// sleep, mindful minutes wait for Phase 7.
///
/// Free Apple ID can read HealthKit data. Writing requires production
/// signing in some categories. We're read-only here.
public actor HealthKitBridge {
    public struct Snapshot: Sendable, Equatable {
        public let steps: Int
        public let activeKilocalories: Int
        public let date: Date

        public static let empty = Snapshot(steps: 0, activeKilocalories: 0, date: .now)
    }

    public enum Status: Sendable {
        case notDetermined, denied, authorized, unavailable
    }

    private let store: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil

    public init() {}

    public func status() -> Status {
        guard let store else { return .unavailable }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return .unavailable
        }
        switch store.authorizationStatus(for: stepType) {
        case .notDetermined: return .notDetermined
        case .sharingDenied: return .denied
        case .sharingAuthorized: return .authorized
        @unknown default: return .unavailable
        }
    }

    public func requestAccess() async throws {
        guard let store else { return }
        let raw: [HKObjectType?] = [
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        ]
        let read = Set(raw.compactMap { $0 })
        try await store.requestAuthorization(toShare: [], read: read)
    }

    public func todaySnapshot() async -> Snapshot {
        guard let store else { return .empty }
        async let steps = sum(quantityType: .stepCount, unit: HKUnit.count())
        async let cals  = sum(quantityType: .activeEnergyBurned, unit: HKUnit.kilocalorie())
        return await Snapshot(steps: Int(steps), activeKilocalories: Int(cals), date: .now)
    }

    private func sum(quantityType id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let store, let type = HKObjectType.quantityType(forIdentifier: id) else { return 0 }
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? Date.now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let v = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: v)
            }
            store.execute(query)
        }
    }
}
