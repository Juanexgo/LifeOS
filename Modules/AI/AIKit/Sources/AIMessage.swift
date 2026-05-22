import Foundation

/// Role of a message in a conversation.
public enum AIRole: String, Sendable, Codable, CaseIterable {
    case system
    case user
    case assistant
    case tool
}

/// A single message in a conversation. Immutable by design — append a new
/// message to mutate state. Equatable so SwiftUI diffing stays cheap.
public struct AIMessage: Sendable, Codable, Identifiable, Equatable, Hashable {
    public let id: UUID
    public let role: AIRole
    public let content: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        role: AIRole,
        content: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

/// Privacy class drives provider routing. The router NEVER promotes a
/// `.personal` request to a cloud provider — that's a compile-time intent
/// expressed at the call site.
public enum AIPrivacyClass: String, Sendable, Codable {
    /// Touches user data the user expects to never leave the device.
    /// Examples: journal, finances, health.
    case personal
    /// Reasonable to use cloud as fallback if local providers fail.
    case general
    /// Heavy compute, large context, or vision — cloud is acceptable.
    case heavy
}
