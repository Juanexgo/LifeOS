import Foundation
import LocalAuthentication

/// App-launch / sensitive-screen biometric gate. Stateless wrapper around
/// `LAContext` — call sites just say "let me through" and get back yes/no.
public struct BiometricGate: Sendable {
    public enum AuthError: Error, Sendable, Equatable {
        case unavailable
        case userCancelled
        case authenticationFailed
        case other(String)
    }

    public enum Biometry: Sendable, Equatable {
        case none, touchID, faceID, opticID
    }

    public init() {}

    /// What this device supports. Use to tailor strings ("Use Face ID" vs.
    /// "Use Touch ID") in the UI.
    public func availableBiometry() -> Biometry {
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        switch ctx.biometryType {
        case .faceID:  return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default:       return .none
        }
    }

    /// Request authentication. Returns `true` on success, throws on failure.
    /// Falls back to device passcode if biometrics fail.
    public func authenticate(reason: String) async throws -> Bool {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw AuthError.unavailable
        }

        do {
            return try await ctx.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch let err as LAError {
            switch err.code {
            case .userCancel, .appCancel, .systemCancel: throw AuthError.userCancelled
            case .authenticationFailed:                  throw AuthError.authenticationFailed
            default:                                     throw AuthError.other(err.localizedDescription)
            }
        }
    }
}
