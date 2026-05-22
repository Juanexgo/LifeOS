import Foundation
import SwiftData

/// Markdown-backed note. Body stays a plain `String` so it can round-trip
/// through clipboard, export, AI summarisation (Phase 4b), etc. Rendering
/// happens at view-time via `AttributedString(markdown:)`.
@Model
public final class Note {
    public var id: UUID
    public var title: String
    public var body: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }
}

public extension Note {
    /// First non-empty line of the body, used as a list preview when the
    /// title is blank.
    var bodyPreview: String {
        body
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces)
            ?? ""
    }

    var displayTitle: String {
        if !title.isEmpty { return title }
        let firstLine = bodyPreview
        if !firstLine.isEmpty { return firstLine }
        return "Untitled"
    }

    /// Update timestamps when content changes. Call from view on save.
    func touch() {
        updatedAt = .now
    }
}
