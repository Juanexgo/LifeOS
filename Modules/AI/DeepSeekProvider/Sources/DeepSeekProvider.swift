import Foundation
import AIKit
import NetworkingKit
import SecurityKit

/// Cloud provider — DeepSeek's OpenAI-compatible Chat Completions API.
/// Streams via SSE. Key read from Keychain at every request, never cached.
public final class DeepSeekProvider: AIProvider {
    public let id: AIProviderID = .deepSeek
    public let displayName = "DeepSeek (Cloud)"
    public let capabilities: AICapabilities = [
        .streaming, .toolUse, .longContext, .structured
    ]

    private let endpoint: URL
    private let model: String
    private let http: HTTPClient
    private let keychain: Keychain

    public init(
        endpoint: URL = URL(string: "https://api.deepseek.com")!,
        model: String = "deepseek-chat",
        keychain: Keychain
    ) {
        self.endpoint = endpoint
        self.model = model
        self.keychain = keychain
        self.http = HTTPClient(config: .init(baseURL: endpoint, timeout: 120))
    }

    public func isAvailable() async -> Bool {
        // Cheap availability — just key presence. We don't pre-flight the API.
        await keychain.exists(.deepSeekAPIKey)
    }

    public func stream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, any Error> {
        let httpClient = http
        let modelName = model
        let keychainRef = keychain
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let apiKey: String
                    do {
                        apiKey = try await keychainRef.get(.deepSeekAPIKey, prompt: "Use DeepSeek")
                    } catch Keychain.KeychainError.itemNotFound {
                        throw AIError.providerUnavailable(.deepSeek)
                    } catch Keychain.KeychainError.userCancelled {
                        throw AIError.cancelled
                    }

                    let body = DSChatRequest(
                        model: modelName,
                        messages: request.messages.map { DSMessage(role: $0.role.rawValue, content: $0.content) },
                        stream: true,
                        temperature: request.temperature,
                        max_tokens: request.maxTokens
                    )
                    let baseReq = try HTTPRequest.json(path: "/chat/completions", body: body)
                    let httpReq = HTTPRequest(
                        path: baseReq.path,
                        method: baseReq.method,
                        headers: [
                            "Authorization": "Bearer \(apiKey)",
                            "Content-Type": "application/json",
                            "Accept": "text/event-stream"
                        ],
                        body: baseReq.body
                    )

                    let lines = await httpClient.streamLines(httpReq)
                    let events = SSEParser.events(from: lines)

                    for try await event in events {
                        if event.data == "[DONE]" {
                            continuation.yield(AIChunk(delta: "", isFinal: true))
                            break
                        }
                        guard let data = event.data.data(using: .utf8) else { continue }
                        let chunk = try? JSONDecoder().decode(DSChunk.self, from: data)
                        guard let delta = chunk?.choices.first?.delta.content, !delta.isEmpty else { continue }
                        continuation.yield(AIChunk(delta: delta))
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

private struct DSChatRequest: Encodable, Sendable {
    let model: String
    let messages: [DSMessage]
    let stream: Bool
    let temperature: Double?
    let max_tokens: Int?
}

private struct DSMessage: Codable, Sendable {
    let role: String
    let content: String
}

private struct DSChunk: Decodable, Sendable {
    struct Choice: Decodable, Sendable {
        struct Delta: Decodable, Sendable { let content: String? }
        let delta: Delta
    }
    let choices: [Choice]
}
