import ArgumentParser
import Foundation
import SecretWalletCore

struct Get: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Get a secret from Keychain (outputs to stdout)"
    )

    @Argument(help: "Name of the secret", completion: .custom { _ in
        MetadataStore.list().map(\.name)
    })
    var name: String

    func run() throws {
        do {
            let metadata = MetadataStore.list().first { $0.name == name }
            let value = try KeychainManager.get(
                key: name,
                prompt: "Authenticate to access '\(name)'",
                requiresAuth: metadata?.biometric ?? false
            )
            print(value, terminator: "")
        } catch {
            stderr("❌ Failed to retrieve: \(error.localizedDescription)\n")
            throw ExitCode.failure
        }
    }
}
