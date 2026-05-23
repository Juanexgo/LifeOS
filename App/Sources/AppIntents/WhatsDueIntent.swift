import AppIntents
import SwiftData
import Foundation
import PersistenceKit

/// "Hey Siri, what's due in LifeOS today." Returns a chainable string array
/// of pending task titles and speaks a summary.
struct WhatsDueIntent: AppIntent {
    static let title: LocalizedStringResource = "What's Due Today"
    static let description = IntentDescription(
        "Get the list of LifeOS tasks due today",
        categoryName: "Tasks",
        searchKeywords: ["due", "today", "tasks", "agenda", "what"]
    )
    static let openAppWhenRun = false
    static let isDiscoverable = true

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[String]> {
        let container = try PersistenceFactory.liveContainer()
        let ctx = ModelContext(container)

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.isCompletedRaw == 0 },
            sortBy: [
                SortDescriptor(\.priorityRaw, order: .reverse),
                SortDescriptor(\.dueDate)
            ]
        )
        let all = (try? ctx.fetch(descriptor)) ?? []
        let cal = Calendar.current
        let dueToday = all.filter { task in
            guard let due = task.dueDate else { return false }
            return cal.isDateInToday(due) || due < .now
        }

        let titles = dueToday.map { $0.title.isEmpty ? "Untitled" : $0.title }

        let dialog: IntentDialog
        switch titles.count {
        case 0:
            dialog = IntentDialog("You're clear for today.")
        case 1:
            dialog = IntentDialog("One thing due today: \(titles[0]).")
        case 2:
            dialog = IntentDialog("Two things due today: \(titles[0]) and \(titles[1]).")
        default:
            dialog = IntentDialog("\(titles.count) tasks due today. The top ones are: \(titles.prefix(3).joined(separator: ", ")).")
        }
        return .result(value: titles, dialog: dialog)
    }
}
