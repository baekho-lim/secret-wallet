import ArgumentParser
import Foundation
import SecretWalletCore

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Add a secret to Keychain"
    )

    @Argument(help: "Name of the secret (e.g., OPENROUTER_KEY)")
    var name: String

    @Option(name: .shortAndLong, help: "Environment variable name (defaults to secret name)")
    var envName: String?

    @Flag(name: .shortAndLong, help: "Require TouchID for access")
    var biometric: Bool = false

    func run() throws {
        let envVar = envName ?? name.uppercased().replacingOccurrences(of: "-", with: "_")

        print("🔑 Adding '\(name)' (env var: \(envVar))")
        print("Enter value (input is hidden):")

        let secret = readSecretFromStdin()

        guard !secret.isEmpty else {
            print("❌ Secret value is empty")
            throw ExitCode.failure
        }

        do {
            let biometricApplied = try KeychainManager.save(key: name, value: secret, biometric: biometric)

            let metadata = SecretMetadata(name: name, envName: envVar, biometric: biometricApplied)
            do {
                try MetadataStore.save(metadata)
            } catch {
                try? KeychainManager.delete(key: name)
                throw error
            }

            print("✅ Saved to Keychain (no plaintext files)")
            if biometricApplied {
                print("🔐 Biometric authentication required for access")
            } else if biometric && !biometricApplied {
                print("⚠️ Biometric unavailable -- saved with standard protection")
            }
        } catch {
            print("❌ Failed to save: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    private func readSecretFromStdin() -> String {
        if isatty(STDIN_FILENO) == 0 {
            return readLine(strippingNewline: true) ?? ""
        }

        var oldTermios = termios()
        guard tcgetattr(STDIN_FILENO, &oldTermios) == 0 else {
            return readLine(strippingNewline: true) ?? ""
        }
        var newTermios = oldTermios
        newTermios.c_lflag &= ~UInt(ECHO)
        guard tcsetattr(STDIN_FILENO, TCSANOW, &newTermios) == 0 else {
            return readLine(strippingNewline: true) ?? ""
        }

        defer {
            tcsetattr(STDIN_FILENO, TCSANOW, &oldTermios)
            print("")
        }

        return readLine(strippingNewline: true) ?? ""
    }
}
