import AppIntents
import SwiftData
import PersistenceKit

/// "Hey Siri, start focus session in LifeOS." Opens the app on the Focus tab.
struct StartFocusIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Focus Session"
    static let description = IntentDescription("Start a deep work session in LifeOS")
    static let openAppWhenRun = true

    @Parameter(title: "Intent", default: "Deep work")
    var intent: String

    @Parameter(title: "Minutes", default: 25)
    var minutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Focus on \(\.$intent) for \(\.$minutes) minutes")
    }

    func perform() async throws -> some IntentResult {
        let container = try PersistenceFactory.liveContainer()
        let context = ModelContext(container)
        // Persist a "starts now, ends in N minutes" session record.
        let session = FocusSession(
            intent: intent,
            startedAt: .now,
            plannedSeconds: max(minutes, 1) * 60
        )
        context.insert(session)
        try context.save()
        return .result()
    }
}
