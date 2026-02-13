import ArgumentParser
import Foundation
import SecretWalletCore

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Initialize secret-wallet (verify Keychain access)"
    )

    func run() throws {
        print("🔐 Initializing Secret Wallet...")

        let testKey = "secret-wallet-test"
        let testValue = "init-test-\(UUID().uuidString)"

        do {
            try KeychainManager.save(key: testKey, value: testValue)
            let retrieved = try KeychainManager.get(key: testKey)
            try KeychainManager.delete(key: testKey)

            if retrieved == testValue {
                print("✅ macOS Keychain connected")
                if BiometricService.isAvailable {
                    print("✅ \(BiometricService.biometricTypeName) available (enable per secret with --biometric)")
                } else {
                    print("⚠️ \(BiometricService.biometricTypeName) unavailable")
                }
                print("")
                print("Usage:")
                print("  secret-wallet add <name>        # Add a secret")
                print("  secret-wallet get <name>        # Retrieve a secret")
                print("  secret-wallet list              # List stored secrets")
                print("  secret-wallet inject -- <cmd>   # Run command with secrets as env vars")
            } else {
                throw SecretWalletError.keychainTestFailed
            }
        } catch {
            stderr("❌ Failed to access Keychain: \(error.localizedDescription)\n")
            throw ExitCode.failure
        }
    }
}
