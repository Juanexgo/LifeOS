import Foundation
import AIKit

/// MLX-Swift backed provider. Loads larger transformer models (3B–8B) that
/// Apple Intelligence won't run directly. Used for `.heavy` privacy class
/// when the user has explicitly downloaded a local model.
///
/// Phase 1: stub. Phase 4: add `mlx-swift` SPM dependency, load a model from
/// the app's Documents directory, expose a `loadModel(_:)` API the Settings
/// screen drives.
public struct MLXProvider: AIProvider {
    public let id: AIProviderID = .mlx
    public let displayName = "MLX (Local large model)"
    public let capabilities: AICapabilities = [
        .streaming, .onDevice, .longContext
    ]

    public init() {}

    public func isAvailable() async -> Bool {
        // PHASE 4: check whether a model is loaded into memory.
        false
    }

    public func stream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AIError.providerUnavailable(id))
        }
    }
}
