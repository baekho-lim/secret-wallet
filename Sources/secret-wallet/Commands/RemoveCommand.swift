import ArgumentParser
import SecretWalletCore

struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Remove a secret from Keychain"
    )

    @Argument(help: "Name of the secret to remove", completion: .custom { _ in
        MetadataStore.list().map(\.name)
    })
    var name: String

    func run() throws {
        do {
            let metadata = MetadataStore.list().first { $0.name == name }
            try KeychainManager.delete(
                key: name,
                prompt: "Authenticate to delete '\(name)'",
                requiresAuth: metadata?.biometric ?? false
            )
            try MetadataStore.delete(name: name)
            print("✅ '\(name)' deleted")
        } catch {
            stderr("❌ Failed to delete: \(error.localizedDescription)\n")
            throw ExitCode.failure
        }
    }
}
