import Foundation

/// A unit of work for an `AIProvider`. Immutable; cheap to copy across actors.
public struct AIRequest: Sendable {
    public let messages: [AIMessage]
    public let privacyClass: AIPrivacyClass
    public let required: AICapabilities
    public let preferredProvider: AIProviderID?
    public let temperature: Double?
    public let maxTokens: Int?
    /// Free-form provider hints (model name, system prompt overrides). Providers
    /// only read keys they know about; unknown keys are ignored.
    public let providerHints: [String: String]

    public init(
        messages: [AIMessage],
        privacyClass: AIPrivacyClass = .general,
        required: AICapabilities = [.streaming],
        preferredProvider: AIProviderID? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        providerHints: [String: String] = [:]
    ) {
        self.messages = messages
        self.privacyClass = privacyClass
        self.required = required
        self.preferredProvider = preferredProvider
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.providerHints = providerHints
    }
}

public extension AIRequest {
    /// Convenience for a single user prompt with no history.
    static func prompt(
        _ text: String,
        privacyClass: AIPrivacyClass = .general,
        required: AICapabilities = [.streaming]
    ) -> AIRequest {
        AIRequest(
            messages: [AIMessage(role: .user, content: text)],
            privacyClass: privacyClass,
            required: required
        )
    }
}
