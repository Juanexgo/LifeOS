import Foundation
import HealthKit

/// Read-only adapter over HealthKit. Reads "today" snapshot + last-7-days
/// history for the metrics the dashboard cares about.
///
/// Free Apple ID can read HealthKit data. We never write — that keeps the
/// entitlement footprint small and the privacy story simple.
public actor HealthKitBridge {
    public struct Snapshot: Sendable, Equatable {
        public let steps: Int
        public let activeKilocalories: Int
        public let exerciseMinutes: Int
        public let restingHeartRate: Int?      // bpm — nil if no sample today
        public let date: Date

        public static let empty = Snapshot(
            steps: 0, activeKilocalories: 0, exerciseMinutes: 0,
            restingHeartRate: nil, date: .now
        )
    }

    public struct DailyPoint: Identifiable, Sendable, Equatable {
        public let id: Date
        public var date: Date { id }
        public let steps: Int
        public let calories: Int
    }

    public enum Status: Sendable {
        case notDetermined, denied, authorized, unavailable
    }

    private let store: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil

    public init() {}

    // MARK: - Permissions

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
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .appleExerciseTime,
            .restingHeartRate
        ]
        let raw: [HKObjectType?] = identifiers.map { HKObjectType.quantityType(forIdentifier: $0) }
        let read = Set(raw.compactMap { $0 })
        try await store.requestAuthorization(toShare: [], read: read)
    }

    // MARK: - Reads

    public func todaySnapshot() async -> Snapshot {
        if store == nil { return .empty }
        async let steps    = todaySum(.stepCount,          unit: .count())
        async let cals     = todaySum(.activeEnergyBurned, unit: .kilocalorie())
        async let exercise = todaySum(.appleExerciseTime,  unit: .minute())
        async let hr       = mostRecentValue(.restingHeartRate, unit: HKUnit(from: "count/min"))
        return await Snapshot(
            steps: Int(steps),
            activeKilocalories: Int(cals),
            exerciseMinutes: Int(exercise),
            restingHeartRate: hr.map(Int.init),
            date: .now
        )
    }

    /// Last 7 calendar days (including today), oldest first.
    public func weekHistory() async -> [DailyPoint] {
        if store == nil { return [] }
        let cal = Calendar.current
        let endDate = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: .now)!)
        let startDate = cal.date(byAdding: .day, value: -7, to: endDate)!

        async let stepsByDay = bucketedDailySum(
            identifier: .stepCount, unit: .count(),
            from: startDate, to: endDate
        )
        async let calsByDay = bucketedDailySum(
            identifier: .activeEnergyBurned, unit: .kilocalorie(),
            from: startDate, to: endDate
        )

        let steps = await stepsByDay
        let cals = await calsByDay

        // Merge into DailyPoint, indexed by day start.
        var bydate: [Date: (steps: Int, cals: Int)] = [:]
        for (d, v) in steps { bydate[d, default: (0, 0)].steps = Int(v) }
        for (d, v) in cals  { bydate[d, default: (0, 0)].cals  = Int(v) }

        return bydate
            .map { DailyPoint(id: $0.key, steps: $0.value.steps, calories: $0.value.cals) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Private

    private func todaySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
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
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private func mostRecentValue(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let store, let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func bucketedDailySum(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async -> [Date: Double] {
        guard let store, let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [:] }
        let cal = Calendar.current
        let interval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: cal.startOfDay(for: start),
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, _ in
                var out: [Date: Double] = [:]
                collection?.enumerateStatistics(from: start, to: end) { stats, _ in
                    let day = cal.startOfDay(for: stats.startDate)
                    out[day] = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                }
                continuation.resume(returning: out)
            }
            store.execute(query)
        }
    }
}
