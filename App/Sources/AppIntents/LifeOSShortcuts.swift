import AppIntents

/// AppShortcuts surface — what appears in Spotlight, Settings → Shortcuts,
/// and Siri's discovery. Each phrase pattern uses `\(.applicationName)`
/// so it survives display-name localization changes.
struct LifeOSShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .navy

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add task to \(.applicationName)",
                "New \(.applicationName) task",
                "Remember in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focus in \(.applicationName)",
                "Deep work in \(.applicationName)",
                "Focus session in \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "timer"
        )
    }
}
