import Foundation
import Security
import LocalAuthentication

enum KeychainManager {
    private static let service = "com.secret-wallet"

    static func save(key: String, value: String, biometric: Bool = false) throws {
        try? delete(key: key)

        guard let data = value.data(using: .utf8) else {
            throw SecretWalletError.encodingFailed
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        if biometric {
            var error: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            ) else {
                throw SecretWalletError.accessControlFailed
            }
            query[kSecAttrAccessControl as String] = access
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw SecretWalletError.keychainError(status)
        }
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
