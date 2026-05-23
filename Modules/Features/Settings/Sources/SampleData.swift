#if DEBUG
import Foundation
import SwiftData
import PersistenceKit

/// Realistic seed data for screenshots and demos. Only compiled in Debug.
///
/// Call once from the Settings screen's `Debug` section. Wipes existing
/// records of each seeded type before inserting — so it's idempotent.
public enum SampleData {
    @MainActor
    public static func seed(into ctx: ModelContext) {
        wipe(ctx)
        seedTasks(ctx)
        seedNotes(ctx)
        seedFocusSessions(ctx)
        seedExpenses(ctx)
        try? ctx.save()
    }

    @MainActor
    public static func wipe(_ ctx: ModelContext) {
        try? ctx.delete(model: TaskItem.self)
        try? ctx.delete(model: Note.self)
        try? ctx.delete(model: FocusSession.self)
        try? ctx.delete(model: Expense.self)
        try? ctx.save()
    }

    // MARK: - Seeds

    @MainActor
    private static func seedTasks(_ ctx: ModelContext) {
        let now = Date.now
        let cal = Calendar.current
        let items: [(String, TaskPriority, Date?, Bool)] = [
            ("Review pull requests", .high, now, false),
            ("Prepare 1:1 notes for Maria", .medium, now, false),
            ("Pay rent", .high, cal.date(byAdding: .day, value: 1, to: now), false),
            ("Refactor AIRouter test suite", .low, cal.date(byAdding: .day, value: 2, to: now), false),
            ("Read 'Designing Data-Intensive Applications' ch. 7", .none, cal.date(byAdding: .day, value: 7, to: now), false),
            ("Send slides to design team", .medium, nil, false),
            ("Book flights for WWDC", .high, cal.date(byAdding: .day, value: 14, to: now), false),
            ("Cancel unused subscription", .low, nil, false),
            ("Call dentist", .medium, nil, true),
            ("Buy groceries", .none, cal.date(byAdding: .day, value: -1, to: now), true),
            ("Backup photos to disk", .low, nil, true),
            ("Update LinkedIn profile", .medium, nil, false)
        ]
        for (title, p, due, done) in items {
            let task = TaskItem(
                title: title,
                dueDate: due,
                isCompleted: done,
                completedAt: done ? cal.date(byAdding: .hour, value: -Int.random(in: 1...8), to: now) : nil,
                priority: p
            )
            ctx.insert(task)
        }
    }

    @MainActor
    private static func seedNotes(_ ctx: ModelContext) {
        let cal = Calendar.current
        let notes: [(String, String, Bool, Int)] = [
            ("Project ideas",
             "# Things to ship this quarter\n\n- **LifeOS v0.4** — widgets + Live Activities\n- AI summarisation of weekly journal\n- Habit streaks tab\n- Apple Watch companion\n\n*Pick max 2 to actually focus on.*",
             true, 0),
            ("1:1 Maria prep",
             "## Topics\n\n1. Q3 roadmap review\n2. Team capacity — are we overcommitted?\n3. Their feedback on the modular refactor\n\n## My asks\n- Time off in August\n- More design partnership on Assistant flows",
             false, 1),
            ("Recipes — focaccia",
             "**500 g** strong flour\n**350 g** water\n**10 g** salt\n**4 g** instant yeast\n**30 ml** olive oil\n\nMix, fold every 30 min × 3, cold proof overnight. Bake 220 °C / 25 min.",
             false, 3),
            ("Quotes I want to remember",
             "> The best architecture is the one that lets you change your mind cheaply.\n\n> Privacy isn't a feature, it's the absence of features that betray you.",
             true, 7),
            ("Books to read",
             "- Designing Data-Intensive Applications\n- The Pragmatic Programmer (re-read)\n- Tidy First? — Kent Beck\n- The Mom Test",
             false, 14)
        ]
        for (title, body, pin, daysAgo) in notes {
            let updated = cal.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            let note = Note(
                title: title,
                body: body,
                createdAt: cal.date(byAdding: .day, value: -daysAgo - 1, to: .now) ?? .now,
                updatedAt: updated,
                isPinned: pin
            )
            ctx.insert(note)
        }
    }

    @MainActor
    private static func seedFocusSessions(_ ctx: ModelContext) {
        let cal = Calendar.current
        let runs: [(intent: String, minutes: Int, hoursAgo: Int, cancelled: Bool)] = [
            ("Review pull requests", 25, 2, false),
            ("Write AIRouter tests", 45, 5, false),
            ("Draft README", 25, 8, true),
            ("Refactor providers", 50, 24, false),
            ("Plan next sprint", 25, 30, false)
        ]
        for r in runs {
            let started = cal.date(byAdding: .hour, value: -r.hoursAgo, to: .now) ?? .now
            let session = FocusSession(
                intent: r.intent,
                startedAt: started,
                plannedSeconds: r.minutes * 60,
                completedAt: started.addingTimeInterval(Double(r.minutes * 60) * (r.cancelled ? 0.4 : 1.0)),
                wasCancelled: r.cancelled
            )
            ctx.insert(session)
        }
    }

    @MainActor
    private static func seedExpenses(_ ctx: ModelContext) {
        let cal = Calendar.current
        let items: [(Double, String, ExpenseCategory, Int)] = [
            (1450.00, "Rent",           .home,          0),
            (89.50,   "Spotify family", .subscriptions, 0),
            (180.00,  "Groceries — Costco", .food,      1),
            (45.00,   "Coffee shop",    .food,          2),
            (320.00,  "Uber to airport",.transport,     3),
            (24.99,   "iCloud+",        .subscriptions, 5),
            (75.00,   "Gym",            .health,        7),
            (220.00,  "Concert tickets",.fun,           12),
            (40.00,   "Pharmacy",       .health,        14)
        ]
        let currency = Locale.current.currency?.identifier ?? "USD"
        for (amount, note, cat, daysAgo) in items {
            let date = cal.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            let exp = Expense(
                amount: amount,
                note: note,
                date: date,
                category: cat,
                currencyCode: currency
            )
            ctx.insert(exp)
        }
    }
}
#endif
