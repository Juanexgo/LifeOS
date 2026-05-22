import Foundation
import AIKit
import NetworkingKit

/// Talks to a local Ollama server. Default endpoint is the loopback that
/// works on macOS dev machines. On iPhone you'd point this at a Mac mini
/// or other host on the same network via Settings.
///
/// `final class` with `let` properties — all stored state is immutable and
/// Sendable, so the type is implicitly Sendable. The HTTPClient handles its
/// own internal isolation as an actor.
public final class OllamaProvider: AIProvider {
    public let id: AIProviderID = .ollama
    public let displayName = "Ollama (Local server)"
    public let capabilities: AICapabilities = [
        .streaming, .toolUse, .longContext
    ]

    public let endpoint: URL
    public let model: String
    private let http: HTTPClient

    public init(
        endpoint: URL = URL(string: "http://localhost:11434")!,
        model: String = "llama3.2"
    ) {
        self.endpoint = endpoint
        self.model = model
        self.http = HTTPClient(config: .init(baseURL: endpoint, timeout: 120))
    }

    public func isAvailable() async -> Bool {
        // Short timeout — Ollama is either local-fast or not there.
        let probeClient = HTTPClient(config: .init(baseURL: endpoint, timeout: 2))
        do {
            _ = try await probeClient.sendRaw(HTTPRequest(path: "/api/tags"))
            return true
        } catch {
            return false
        }
    }

    public func stream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, any Error> {
        let httpClient = http
        let modelName = model
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let body = OllamaChatRequest(
                        model: modelName,
                        messages: request.messages.map { OllamaMessage(role: $0.role.rawValue, content: $0.content) },
                        stream: true,
                        options: OllamaOptions(
                            temperature: request.temperature,
                            num_predict: request.maxTokens
                        )
                    )
                    let httpReq = try HTTPRequest.json(path: "/api/chat", body: body)
                    let lines = await httpClient.streamLines(httpReq)

                    for try await line in lines {
                        guard !line.isEmpty,
                              let data = line.data(using: .utf8) else { continue }
                        let chunk = try JSONDecoder().decode(OllamaChatChunk.self, from: data)
                        if !chunk.message.content.isEmpty {
                            continuation.yield(AIChunk(delta: chunk.message.content))
                        }
                        if chunk.done {
                            continuation.yield(AIChunk(
                                delta: "",
                                isFinal: true,
                                usage: AIUsage(
                                    promptTokens: chunk.prompt_eval_count,
                                    completionTokens: chunk.eval_count
                                )
                            ))
                            break
                        }
                        if Task.isCancelled { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// MARK: - Wire types

private struct OllamaChatRequest: Encodable, Sendable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    let options: OllamaOptions
}

private struct OllamaMessage: Codable, Sendable {
    let role: String
    let content: String
}

private struct OllamaOptions: Encodable, Sendable {
    let temperature: Double?
    let num_predict: Int?
}

private struct OllamaChatChunk: Decodable, Sendable {
    let message: OllamaMessage
    let done: Bool
    let prompt_eval_count: Int?
    let eval_count: Int?
}
