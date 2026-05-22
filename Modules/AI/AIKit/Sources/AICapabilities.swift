import Foundation

/// Identifies an `AIProvider` implementation. String-backed so settings and
/// preferences can serialise it.
public struct AIProviderID: Hashable, Sendable, Codable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }

    // Canonical IDs — keep stable; users persist these in preferences.
    public static let foundationModels: Self = "foundationModels"
    public static let mlx:              Self = "mlx"
    public static let ollama:           Self = "ollama"
    public static let deepSeek:         Self = "deepSeek"
}

/// What a provider can do. Used by `AIRouter` to skip providers that can't
/// satisfy a request.
public struct AICapabilities: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let streaming    = AICapabilities(rawValue: 1 << 0)
    public static let toolUse      = AICapabilities(rawValue: 1 << 1)
    public static let vision       = AICapabilities(rawValue: 1 << 2)
    public static let onDevice     = AICapabilities(rawValue: 1 << 3)
    public static let longContext  = AICapabilities(rawValue: 1 << 4)
    public static let structured   = AICapabilities(rawValue: 1 << 5) // JSON / typed output
    public static let embeddings   = AICapabilities(rawValue: 1 << 6)
}
