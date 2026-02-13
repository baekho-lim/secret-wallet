import ArgumentParser
import SecretWalletCore

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List all stored secrets"
    )

    func run() throws {
        let secrets = MetadataStore.list()

        if secrets.isEmpty {
            print("No secrets stored.")
            print("Run 'secret-wallet add <name>' to add one.")
            return
        }

        print("Stored secrets:")
        print("")
        for secret in secrets {
            let biometricIcon = secret.biometric ? "🔐" : "🔓"
            print("  \(biometricIcon) \(secret.name) → $\(secret.envName)")
        }
    }
}
