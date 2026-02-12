import Foundation

enum SecretWalletError: LocalizedError {
    case keychainTestFailed
    case encodingFailed
    case accessControlFailed
    case keychainError(OSStatus)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .keychainTestFailed:
            return "Failed to access secure storage"
        case .encodingFailed:
            return "Failed to save the key"
        case .accessControlFailed:
            return "Could not set up fingerprint protection"
        case .keychainError(let status):
            return "Storage error (code: \(status))"
        case .notFound(let key):
            return "Key '\(key)' not found"
        }
    }
}
