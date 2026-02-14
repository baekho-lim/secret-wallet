import ArgumentParser
import Foundation
import SecretWalletCore

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List all stored secrets"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    func run() throws {
        let secrets = MetadataStore.list()

        if json {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let items = secrets.map { secret in
                [
                    "name": secret.name,
                    "envName": secret.envName,
                    "biometric": secret.biometric ? "true" : "false",
                    "serviceName": secret.serviceName ?? "",
                ]
            }
            let data = try encoder.encode(items)
            print(String(data: data, encoding: .utf8) ?? "[]")
            return
        }

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
