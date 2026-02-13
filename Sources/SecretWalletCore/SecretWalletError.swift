import Foundation
import Security

public enum SecretWalletError: LocalizedError {
    case keychainTestFailed
    case encodingFailed
    case accessControlFailed
    case keychainError(OSStatus)
    case notFound(String)

    public var errorDescription: String? {
        switch self {
        case .keychainTestFailed:
            return "Failed to access secure storage"
        case .encodingFailed:
            return "Failed to save the key"
        case .accessControlFailed:
            return "Could not set up fingerprint protection"
        case .keychainError(let status):
            return Self.describeOSStatus(status)
        case .notFound(let key):
            return "Key '\(key)' not found"
        }
    }

    private static func describeOSStatus(_ status: OSStatus) -> String {
        switch status {
        case errSecDuplicateItem:          // -25299
            return "A key with this name already exists in Keychain"
        case errSecItemNotFound:           // -25300
            return "Key not found in secure storage"
        case errSecAuthFailed:             // -25293
            return "Authentication failed -- check your fingerprint or password"
        case errSecUserCanceled:           // -128
            return "Authentication was cancelled"
        case errSecInteractionNotAllowed:  // -25308
            return "Authentication is not available right now"
        case errSecMissingEntitlement:     // -34018
            return "App needs code signing for biometric protection"
        case errSecIO:                     // -61
            return "Keychain database error -- restart your Mac and try again"
        case errSecDecode:                 // -26275
            return "Stored data is corrupted"
        case errSecParam:                  // -50
            return "Internal error: invalid Keychain parameters"
        default:
            return "Keychain error (OSStatus \(status))"
        }
    }
}
