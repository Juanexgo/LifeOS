import Foundation

/// Incremental output from a streaming `AIProvider`.
public struct AIChunk: Sendable, Equatable {
    /// New text appended since the last chunk. NOT the full message so far.
    public let delta: String
    /// `true` when the provider has finished. After this, the stream terminates.
    public let isFinal: Bool
    /// Optional token-usage telemetry. Providers fill what they can.
    public let usage: AIUsage?

    public init(delta: String, isFinal: Bool = false, usage: AIUsage? = nil) {
        self.delta = delta
        self.isFinal = isFinal
        self.usage = usage
    }
}

public struct AIUsage: Sendable, Equatable, Codable {
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?

    public init(promptTokens: Int? = nil, completionTokens: Int? = nil, totalTokens: Int? = nil) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
}
