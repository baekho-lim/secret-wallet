import Foundation
import LocalAuthentication

public enum BiometricService {
    public static var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    public static var biometricTypeName: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Password"
        }
        switch context.biometryType {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        case .none: return "Password"
        @unknown default: return "Biometric"
        }
    }

    /// Pre-authenticate via TouchID (or macOS password fallback) before Keychain access.
    /// Synchronous version for CLI use. Do NOT call from Swift concurrency Task context.
    /// Returns an authenticated LAContext, or nil if the user cancelled.
    public static func preAuthenticate(
        reason: String,
        context: LAContext? = nil
    ) -> LAContext? {
        let ctx = context ?? LAContext()
        let semaphore = DispatchSemaphore(value: 0)
        var success = false

        let policy: LAPolicy = isAvailable
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        ctx.evaluatePolicy(policy, localizedReason: reason) { result, _ in
            success = result
            semaphore.signal()
        }

        semaphore.wait()
        return success ? ctx : nil
    }

    /// Async version for GUI (SwiftUI Task) use. Safe in Swift concurrency context.
    public static func preAuthenticateAsync(
        reason: String,
        context: LAContext? = nil
    ) async throws -> LAContext {
        let ctx = context ?? LAContext()

        let policy: LAPolicy = isAvailable
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        try await ctx.evaluatePolicy(policy, localizedReason: reason)
        return ctx
    }

    /// Create a configured LAContext for batch biometric operations.
    /// The reuse duration allows a single TouchID prompt to cover multiple Keychain accesses.
    public static func createBatchContext(reuseDuration: TimeInterval = 10) -> LAContext {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = reuseDuration
        return context
    }
}
