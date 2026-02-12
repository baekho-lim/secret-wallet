import Foundation
import Security
import LocalAuthentication

enum KeychainManager {
    private static let service = "com.secret-wallet"

    /// Returns `true` if biometric was actually applied, `false` if it fell back to non-biometric.
    @discardableResult
    static func save(key: String, value: String, biometric: Bool = false) throws -> Bool {
        // Delete without LAContext to avoid biometric prompt on overwrite
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard let data = value.data(using: .utf8) else {
            throw SecretWalletError.encodingFailed
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        var biometricApplied = false

        if biometric {
            var error: Unmanaged<CFError>?
            if let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            ) {
                query[kSecAttrAccessControl as String] = access
                biometricApplied = true
            } else {
                // Fallback to non-biometric if ACL creation fails
                query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        var status = SecItemAdd(query as CFDictionary, nil)

        // -34018 (errSecMissingEntitlement): unsigned app can't use biometric ACL
        // Retry without biometric protection
        if status == errSecMissingEntitlement && biometricApplied {
            query.removeValue(forKey: kSecAttrAccessControl as String)
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            biometricApplied = false
            status = SecItemAdd(query as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw SecretWalletError.keychainError(status)
        }

        return biometricApplied
    }

    static func get(key: String, prompt: String? = nil, context: LAContext? = nil) throws -> String {
        let authContext = context ?? LAContext()
        if let prompt {
            authContext.localizedReason = prompt
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: authContext,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                throw SecretWalletError.notFound(key)
            }
            throw SecretWalletError.keychainError(status)
        }

        return value
    }

    static func delete(key: String, prompt: String? = nil, context: LAContext? = nil) throws {
        let authContext = context ?? LAContext()
        if let prompt {
            authContext.localizedReason = prompt
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseAuthenticationContext as String: authContext,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretWalletError.keychainError(status)
        }
    }
}
