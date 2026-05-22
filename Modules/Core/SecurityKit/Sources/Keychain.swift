import Foundation
import Security
import LocalAuthentication

/// Thin Keychain wrapper. Scoped to the LifeOS service so we don't collide
/// with other apps' generic password items.
///
/// Design notes:
///   - We never persist secrets to UserDefaults, SwiftData, or any file.
///   - The DeepSeek API key (when the user opts in to that provider) will be
///     stored here under the key `ProviderKey.deepSeek` — biometric-gated.
///   - We accept a `Sendable` value, store it as UTF-8 data. Binary blobs
///     should base64 first.
public actor Keychain {
    public enum KeychainError: Error, Equatable, Sendable {
        case unhandled(OSStatus)
        case itemNotFound
        case invalidData
        case biometryUnavailable
        case userCancelled
    }

    /// Canonical key identifiers. Add new cases here; never use raw strings
    /// at call sites.
    public struct Key: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: StringLiteralType) { self.rawValue = value }

        /// API key for the optional DeepSeek cloud provider. Biometric-gated.
        public static let deepSeekAPIKey: Key = "ai.deepseek.apiKey"
        /// API key for any future Ollama remote endpoint (self-hosted with auth).
        public static let ollamaAPIKey: Key = "ai.ollama.apiKey"
    }

    private let service: String

    public init(service: String = "com.juancanul.LifeOS") {
        self.service = service
    }

    /// Write a secret. If `requireBiometry` is true the item is bound to the
    /// current biometric set — invalidated automatically if the user adds/
    /// removes a finger or face.
    public func set(_ value: String, for key: Key, requireBiometry: Bool = true) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        // Remove any existing item — Keychain "update" semantics are unforgiving.
        SecItemDelete(query as CFDictionary)

        query[kSecValueData as String] = data

        if requireBiometry {
            var accessError: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.biometryCurrentSet, .or, .devicePasscode],
                &accessError
            ) else {
                throw KeychainError.biometryUnavailable
            }
            query[kSecAttrAccessControl as String] = access
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    /// Read a secret. Triggers a biometric prompt if the item was stored with
    /// `requireBiometry`.
    public func get(_ key: Key, prompt: String = "Authenticate to unlock") throws -> String {
        let context = LAContext()
        context.localizedReason = prompt

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return value
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        case errSecUserCanceled:
            throw KeychainError.userCancelled
        default:
            throw KeychainError.unhandled(status)
        }
    }

    public func delete(_ key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }

    public func exists(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}
