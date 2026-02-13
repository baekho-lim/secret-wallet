import ArgumentParser
import Foundation

@main
struct SecretWallet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "secret-wallet",
        abstract: "Keychain-based credential manager for AI agents",
        version: "0.3.0-alpha",
        subcommands: [Init.self, Add.self, Get.self, List.self, Remove.self, Inject.self, Setup.self]
    )
}

/// Write a message to stderr.
func stderr(_ message: String) {
    FileHandle.standardError.write(Data(message.utf8))
}
