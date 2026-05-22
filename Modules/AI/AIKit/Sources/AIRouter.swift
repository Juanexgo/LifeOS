import Foundation

/// User-configurable provider ordering. Defaults match the architecture doc:
///   personal → on-device chain only
///   general  → on-device first, cloud as last resort
///   heavy    → MLX (large local) → cloud
public struct AIRoutingPreferences: Sendable, Codable, Equatable {
    public var personalChain: [AIProviderID]
    public var generalChain:  [AIProviderID]
    public var heavyChain:    [AIProviderID]

    public init(
        personalChain: [AIProviderID],
        generalChain:  [AIProviderID],
        heavyChain:    [AIProviderID]
    ) {
        self.personalChain = personalChain
        self.generalChain  = generalChain
        self.heavyChain    = heavyChain
    }

    public static let `default` = AIRoutingPreferences(
        // Personal: never cloud. On-device only. Order = preference.
        personalChain: [.foundationModels, .mlx],
        // General: prefer on-device, allow cloud fallback.
        generalChain:  [.foundationModels, .ollama, .deepSeek],
        // Heavy: MLX can run bigger local models; cloud accepted.
        heavyChain:    [.mlx, .ollama, .deepSeek]
    )
}

/// Actor — providers can be registered/unregistered concurrently (settings
/// screen, app launch, key rotation) and a stream lookup needs a consistent
/// snapshot.
public actor AIRouter {
    private var providers: [AIProviderID: any AIProvider] = [:]
    private(set) public var preferences: AIRoutingPreferences

    public init(preferences: AIRoutingPreferences = .default) {
        self.preferences = preferences
    }

    public func register(_ provider: any AIProvider) {
        providers[provider.id] = provider
    }

    public func unregister(_ id: AIProviderID) {
        providers.removeValue(forKey: id)
    }

    public func updatePreferences(_ prefs: AIRoutingPreferences) {
        self.preferences = prefs
    }

    public func registered() -> [AIProviderID] {
        Array(providers.keys)
    }

    /// Resolve the request to a provider and return its stream.
    public func stream(_ request: AIRequest) async throws -> AsyncThrowingStream<AIChunk, any Error> {
        guard !providers.isEmpty else { throw AIError.noProviderRegistered }

        let chain = candidateChain(for: request)

        // If caller forced a provider, honor it strictly (no fallback).
        if let forced = request.preferredProvider {
            guard let provider = providers[forced] else {
                throw AIError.providerUnavailable(forced)
            }
            try ensureCanSatisfy(provider, request)
            guard await provider.isAvailable() else {
                throw AIError.providerUnavailable(forced)
            }
            return provider.stream(request)
        }

        // Otherwise walk the chain, first capable + available wins.
        for id in chain {
            guard let provider = providers[id] else { continue }
            guard provider.capabilities.contains(request.required) else { continue }
            if await provider.isAvailable() {
                return provider.stream(request)
            }
        }

        // For personal-class requests, we intentionally fail closed rather
        // than spilling private data into a cloud provider that happens to
        // be available.
        if request.privacyClass == .personal {
            throw AIError.personalRequestEscalationBlocked
        }

        throw AIError.noCapableProvider(required: request.required)
    }

    // MARK: - Private

    private func candidateChain(for request: AIRequest) -> [AIProviderID] {
        switch request.privacyClass {
        case .personal: return preferences.personalChain
        case .general:  return preferences.generalChain
        case .heavy:    return preferences.heavyChain
        }
    }

    private func ensureCanSatisfy(_ provider: any AIProvider, _ request: AIRequest) throws {
        guard provider.capabilities.contains(request.required) else {
            throw AIError.noCapableProvider(required: request.required)
        }
    }
}
