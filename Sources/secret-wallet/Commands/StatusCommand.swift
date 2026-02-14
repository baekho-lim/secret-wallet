import ArgumentParser
import Foundation
import SecretWalletCore

struct Status: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show Secret Wallet status (JSON output for integrations)"
    )

    func run() throws {
        let secrets = MetadataStore.list()

        let output = StatusOutput(
            version: "0.3.0-alpha",
            keychainService: "com.secret-wallet",
            biometric: .init(
                available: BiometricService.isAvailable,
                type: BiometricService.biometricTypeName
            ),
            secrets: .init(
                total: secrets.count,
                biometricProtected: secrets.filter(\.biometric).count,
                standard: secrets.filter { !$0.biometric }.count
            ),
            secretNames: secrets.map(\.name)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(output)
        print(String(data: data, encoding: .utf8) ?? "{}")
    }
}

private struct StatusOutput: Encodable {
    let version: String
    let keychainService: String
    let biometric: BiometricInfo
    let secrets: SecretsInfo
    let secretNames: [String]

    struct BiometricInfo: Encodable {
        let available: Bool
        let type: String
    }

    struct SecretsInfo: Encodable {
        let total: Int
        let biometricProtected: Int
        let standard: Int
    }
}
