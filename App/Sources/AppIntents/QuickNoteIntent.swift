import AppIntents
import SwiftData
import Foundation
import PersistenceKit

/// "Hey Siri, note that the dentist appointment is at 4 PM." Stores a
/// quick note. First line becomes the title; the rest goes to body.
struct QuickNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Note"
    static let description = IntentDescription(
        "Save a quick note to LifeOS",
        categoryName: "Notes",
        searchKeywords: ["note", "remember", "jot", "write"]
    )
    static let openAppWhenRun = false
    static let isDiscoverable = true

    @Parameter(title: "Content")
    var content: String

    static var parameterSummary: some ParameterSummary {
        Summary("Note \(\.$content) in LifeOS")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try PersistenceFactory.liveContainer()
        let ctx = ModelContext(container)

        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let title = lines.first ?? "Quick note"
        let body  = lines.count > 1 ? lines.dropFirst().joined(separator: "\n") : ""

        let note = Note(title: title, body: body)
        ctx.insert(note)
        try ctx.save()
        return .result(dialog: IntentDialog("Saved your note"))
    }
}
