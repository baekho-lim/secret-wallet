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

    @Flag(name: .long, help: "Output as JSON with metadata")
    var json: Bool = false

    func run() throws {
        do {
            let metadata = MetadataStore.list().first { $0.name == name }
            let value = try KeychainManager.get(
                key: name,
                prompt: "Authenticate to access '\(name)'",
                requiresAuth: metadata?.biometric ?? false
            )

            if json {
                let result: [String: String] = [
                    "name": name,
                    "value": value,
                    "envName": metadata?.envName ?? name,
                    "biometric": (metadata?.biometric ?? false) ? "true" : "false",
                ]
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(result)
                print(String(data: data, encoding: .utf8) ?? "{}")
            } else {
                print(value, terminator: "")
            }
        } catch {
            stderr("❌ Failed to retrieve: \(error.localizedDescription)\n")
            throw ExitCode.failure
        }
    }
}
