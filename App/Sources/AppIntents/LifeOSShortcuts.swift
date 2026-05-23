import AppIntents

/// AppShortcuts surface — what appears in Spotlight, Settings → Shortcuts,
/// and Siri's discovery panel.
///
/// Each phrase uses `\(.applicationName)` so it survives a display-name
/// localisation change. Apple recommends 5+ phrases per intent — we lean
/// toward natural English/Spanish forms users actually say.
struct LifeOSShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .navy

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add task to \(.applicationName)",
                "New \(.applicationName) task",
                "Remember in \(.applicationName)",
                "Create task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: WhatsDueIntent(),
            phrases: [
                "What's due in \(.applicationName)",
                "What's due today in \(.applicationName)",
                "My \(.applicationName) tasks",
                "Show my \(.applicationName) tasks"
            ],
            shortTitle: "What's Due",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focus in \(.applicationName)",
                "Deep work in \(.applicationName)",
                "Focus session in \(.applicationName)",
                "Pomodoro in \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: QuickNoteIntent(),
            phrases: [
                "Note in \(.applicationName)",
                "New note in \(.applicationName)",
                "Save a note in \(.applicationName)",
                "Remember this in \(.applicationName)"
            ],
            shortTitle: "Quick Note",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log expense in \(.applicationName)",
                "I spent in \(.applicationName)",
                "Add expense to \(.applicationName)",
                "Record spending in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "dollarsign.circle"
        )
        AppShortcut(
            intent: TodaySpendingIntent(),
            phrases: [
                "How much have I spent in \(.applicationName)",
                "Today's spending in \(.applicationName)",
                "What did I spend in \(.applicationName)",
                "My \(.applicationName) total today"
            ],
            shortTitle: "Today's Spending",
            systemImageName: "creditcard"
        )
    }
}
