import Foundation
import SwiftData
import AIKit
import SecurityKit
import PersistenceKit
import FoundationModelsProvider
import MLXProvider
import OllamaProvider
import DeepSeekProvider

/// Composition root. The ONE place in the codebase that knows about every
/// concrete type.
@MainActor
final class AppContainer {
    let keychain: Keychain
    let aiRouter: AIRouter
    let modelContainer: ModelContainer

    init() {
        self.keychain = Keychain()
        self.aiRouter = AIRouter()
        do {
            self.modelContainer = try PersistenceFactory.liveContainer()
        } catch {
            fatalError("Failed to build ModelContainer: \(error)")
        }

        Task { await self.registerAIProviders() }
    }

    private func registerAIProviders() async {
        // On-device — always registered.
        await aiRouter.register(FoundationModelsProvider())
        await aiRouter.register(MLXProvider())

        // Local server — endpoint and model come from Settings preferences.
        let endpointString = UserDefaults.standard.string(forKey: "ollama.endpoint")
            ?? "http://localhost:11434"
        let model = UserDefaults.standard.string(forKey: "ollama.model") ?? "llama3.2"
        let endpoint = URL(string: endpointString) ?? URL(string: "http://localhost:11434")!
        await aiRouter.register(OllamaProvider(endpoint: endpoint, model: model))

        // Cloud — provider checks Keychain at call-time, safe to register even
        // when no key is set.
        await aiRouter.register(DeepSeekProvider(keychain: keychain))
    }
}
