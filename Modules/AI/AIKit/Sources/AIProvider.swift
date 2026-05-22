import Foundation

/// The single seam every part of LifeOS uses to talk to a model. Concrete
/// providers (FoundationModels, MLX, Ollama, DeepSeek) implement this and
/// nothing else; the rest of the app depends only on this protocol.
public protocol AIProvider: Sendable {
    /// Stable identifier — must match a canonical `AIProviderID` constant.
    var id: AIProviderID { get }

    /// What this provider supports. The router uses this to filter candidates.
    var capabilities: AICapabilities { get }

    /// Human-readable display name for Settings UI.
    var displayName: String { get }

    /// Is the provider ready to serve requests right now? (model loaded, key
    /// present, server reachable — provider-specific). Should be cheap; cache
    /// internally.
    func isAvailable() async -> Bool

    /// Stream a response. The returned stream MUST emit at least one chunk
    /// with `isFinal == true` (possibly empty `delta`) before terminating.
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, any Error>
}

/// Errors raised by AIKit. Providers may throw their own typed errors inside
/// the stream — those are re-thrown verbatim.
public enum AIError: Error, Sendable, Equatable {
    /// No provider is registered with the router at all.
    case noProviderRegistered
    /// No registered provider can satisfy the request's required capabilities.
    case noCapableProvider(required: AICapabilities)
    /// Provider was selected but reported itself unavailable.
    case providerUnavailable(AIProviderID)
    /// Personal-class request fell through every on-device provider.
    /// We refuse to escalate to cloud — fail closed.
    case personalRequestEscalationBlocked
    /// Provider returned a malformed response.
    case malformedResponse(String)
    /// Caller cancelled.
    case cancelled
}
