import Foundation
import AIKit

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Wraps Apple's on-device `FoundationModels` framework (iOS 26+). This is
/// LifeOS's PRIMARY provider — on-device, free, private.
///
/// The whole implementation lives behind `#if canImport(FoundationModels)`
/// so the framework's absence (e.g. building from CLT without full Xcode,
/// or running on a platform where Apple hasn't shipped it) doesn't break
/// the build.
public final class FoundationModelsProvider: AIProvider {
    public let id: AIProviderID = .foundationModels
    public let displayName = "Apple Intelligence (On-device)"
    public let capabilities: AICapabilities = [
        .streaming, .onDevice, .structured
    ]

    public init() {}

    public func isAvailable() async -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:           return true
            case .unavailable:         return false
            @unknown default:          return false
            }
        }
        #endif
        return false
    }

    public func stream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, any Error> {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return Self.runStream(request)
        }
        #endif
        return AsyncThrowingStream { continuation in
            continuation.finish(throwing: AIError.providerUnavailable(.foundationModels))
        }
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func runStream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Build a session with system prompt as instructions.
                    let systemPrompt = request.messages.first(where: { $0.role == .system })?.content
                        ?? "You are LifeOS, an on-device assistant for productivity, focus, and personal organization. Keep replies concise, helpful, and warm."

                    let session = LanguageModelSession(
                        instructions: Instructions(systemPrompt)
                    )

                    // Provide prior turns as context — Apple's framework keeps
                    // its own session memory, but rebuilding ensures parity
                    // with stateless cloud providers.
                    let userTurn = request.messages.last(where: { $0.role == .user })?.content ?? ""
                    guard !userTurn.isEmpty else {
                        continuation.yield(AIChunk(delta: "", isFinal: true))
                        continuation.finish()
                        return
                    }

                    let stream = session.streamResponse(to: userTurn)

                    var emitted = ""
                    for try await partial in stream {
                        // The framework yields a `Snapshot` value whose
                        // `.content` holds the cumulative text so far —
                        // NOT a delta. We compute the delta ourselves.
                        let cumulative = partial.content
                        if cumulative.count > emitted.count {
                            let delta = String(cumulative.dropFirst(emitted.count))
                            emitted = cumulative
                            continuation.yield(AIChunk(delta: delta))
                        }
                        if Task.isCancelled { break }
                    }
                    continuation.yield(AIChunk(delta: "", isFinal: true))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    #endif
}
