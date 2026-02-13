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
}
