import AppIntents
import SwiftData
import Foundation
import PersistenceKit

/// "Hey Siri, how much have I spent today in LifeOS." Returns today's
/// expense total as a Double so it can be piped into other shortcuts.
struct TodaySpendingIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Spending"
    static let description = IntentDescription(
        "Get how much you've spent today",
        categoryName: "Finance",
        searchKeywords: ["spent", "today", "money", "total", "expenses"]
    )
    static let openAppWhenRun = false
    static let isDiscoverable = true

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Double> {
        let container = try PersistenceFactory.liveContainer()
        let ctx = ModelContext(container)

        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start }
        )
        let todays = (try? ctx.fetch(descriptor)) ?? []
        let total = todays.map(\.amount).reduce(0, +)

        let currencyCode = todays.first?.currencyCode
            ?? Locale.current.currency?.identifier
            ?? "USD"
        let formatted = total.formatted(.currency(code: currencyCode))

        let dialog: IntentDialog
        if todays.isEmpty {
            dialog = IntentDialog("Nothing logged today.")
        } else if todays.count == 1 {
            dialog = IntentDialog("You've spent \(formatted) today, one entry.")
        } else {
            dialog = IntentDialog("You've spent \(formatted) today across \(todays.count) entries.")
        }
        return .result(value: total, dialog: dialog)
    }
}
