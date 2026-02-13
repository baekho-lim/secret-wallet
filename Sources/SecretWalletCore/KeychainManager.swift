import Foundation
import Security
import LocalAuthentication

public enum KeychainManager {
    private static let service = "com.secret-wallet"

    /// Returns `true` if biometric was actually applied, `false` if it fell back to non-biometric.
    @discardableResult
    public static func save(key: String, value: String, biometric: Bool = false) throws -> Bool {
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

    public static func get(
        key: String,
        prompt: String? = nil,
        context: LAContext? = nil,
        requiresAuth: Bool = false
    ) throws -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        // Only attach LAContext for biometric-protected items.
        // For non-biometric items, adding LAContext to unsigned apps triggers macOS password dialog.
        if requiresAuth {
            if let context {
                query[kSecUseAuthenticationContext as String] = context
            } else {
                guard let authedContext = BiometricService.preAuthenticate(
                    reason: prompt ?? "Authenticate to access secret"
                ) else {
                    throw SecretWalletError.keychainError(errSecUserCanceled)
                }
                query[kSecUseAuthenticationContext as String] = authedContext
            }
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                throw SecretWalletError.notFound(key)
            }
            // Fallback: if biometric item was saved without ACL (unsigned build),
            // retry without auth context
            if requiresAuth && (status == errSecMissingEntitlement || status == errSecInteractionNotAllowed) {
                var fallbackQuery = query
                fallbackQuery.removeValue(forKey: kSecUseAuthenticationContext as String)
                var fallbackResult: AnyObject?
                let fallbackStatus = SecItemCopyMatching(fallbackQuery as CFDictionary, &fallbackResult)
                if fallbackStatus == errSecSuccess,
                   let data = fallbackResult as? Data,
                   let value = String(data: data, encoding: .utf8) {
                    return value
                }
                throw SecretWalletError.keychainError(fallbackStatus)
            }
            throw SecretWalletError.keychainError(status)
        }

        return value
    }

    public static func delete(
        key: String,
        prompt: String? = nil,
        context: LAContext? = nil,
        requiresAuth: Bool = false
    ) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        if requiresAuth {
            if let context {
                query[kSecUseAuthenticationContext as String] = context
            } else {
                guard let authedContext = BiometricService.preAuthenticate(
                    reason: prompt ?? "Authenticate to delete secret"
                ) else {
                    throw SecretWalletError.keychainError(errSecUserCanceled)
                }
                query[kSecUseAuthenticationContext as String] = authedContext
            }
        }

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            if requiresAuth && (status == errSecMissingEntitlement || status == errSecInteractionNotAllowed) {
                var fallbackQuery = query
                fallbackQuery.removeValue(forKey: kSecUseAuthenticationContext as String)
                let fallbackStatus = SecItemDelete(fallbackQuery as CFDictionary)
                guard fallbackStatus == errSecSuccess || fallbackStatus == errSecItemNotFound else {
                    throw SecretWalletError.keychainError(fallbackStatus)
                }
                return
            }
            throw SecretWalletError.keychainError(status)
        }
    }
}
