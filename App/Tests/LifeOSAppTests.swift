import Testing
import AIKit

@Suite("AIRouter")
struct AIRouterTests {

    @Test("Empty router throws noProviderRegistered")
    func emptyRouter() async throws {
        let router = AIRouter()
        await #expect(throws: AIError.noProviderRegistered) {
            _ = try await router.stream(.prompt("hello"))
        }
    }

    @Test("Personal-class requests refuse to fall back to cloud")
    func personalDoesNotEscalate() async throws {
        let router = AIRouter()
        await router.register(StubProvider(id: .deepSeek, available: true))
        await #expect(throws: AIError.personalRequestEscalationBlocked) {
            _ = try await router.stream(
                AIRequest(messages: [.init(role: .user, content: "hi")],
                          privacyClass: .personal)
            )
        }
    }

    @Test("Capable + available provider wins")
    func selectsCapable() async throws {
        let router = AIRouter()
        await router.register(StubProvider(id: .foundationModels, available: true))
        let stream = try await router.stream(.prompt("hi"))
        var collected = ""
        for try await chunk in stream { collected += chunk.delta }
        #expect(collected == "stubbed")
    }
}

private struct StubProvider: AIProvider {
    let id: AIProviderID
    let available: Bool
    var capabilities: AICapabilities { [.streaming, .onDevice] }
    var displayName: String { "Stub" }
    func isAvailable() async -> Bool { available }
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AIChunk, any Error> {
        AsyncThrowingStream { c in
            c.yield(AIChunk(delta: "stubbed", isFinal: true))
            c.finish()
        }
    }
}
