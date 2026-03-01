import ArgumentParser
import Foundation
import SecretWalletCore

struct Inject: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Inject secrets as environment variables and run a command"
    )

    @Option(name: .long, help: "Inject only these secret names (repeatable)")
    var only: [String] = []

    @Option(name: .long, help: "Inject only secrets with these env var names (repeatable)")
    var onlyEnv: [String] = []

    @Flag(name: .long, help: "Explicitly inject all stored secrets")
    var all: Bool = false

    @Flag(name: .long, help: "Show which secrets would be loaded (no Keychain access, no command execution)")
    var dryRun: Bool = false

    @Argument(parsing: .captureForPassthrough, help: "Command to run with injected environment variables")
    var command: [String] = []

    func run() throws {
        guard dryRun || !command.isEmpty else {
            stderr("❌ No command specified\n")
            stderr("Usage: secret-wallet inject [--only NAME] [--only-env ENV] [--all] -- <command>\n")
            throw ExitCode.failure
        }

        if all && (!only.isEmpty || !onlyEnv.isEmpty) {
            stderr("❌ --all cannot be used with --only or --only-env\n")
            throw ExitCode.failure
        }

        let allSecrets = MetadataStore.list()
        let requestedNames = Set(only.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let requestedEnvs = Set(onlyEnv.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let hasFilters = !requestedNames.isEmpty || !requestedEnvs.isEmpty

        let targetSecrets: [SecretMetadata]
        if hasFilters {
            targetSecrets = allSecrets.filter { secret in
                requestedNames.contains(secret.name) || requestedEnvs.contains(secret.envName)
            }
        } else {
            targetSecrets = allSecrets
        }

        if hasFilters {
            let foundNames = Set(targetSecrets.map(\.name))
            let foundEnvs = Set(targetSecrets.map(\.envName))

            let missingNames = requestedNames.subtracting(foundNames)
            for name in missingNames.sorted() {
                stderr("⚠️ Secret not found: '\(name)'\n")
            }
            let missingEnvs = requestedEnvs.subtracting(foundEnvs)
            for envName in missingEnvs.sorted() {
                stderr("⚠️ Env mapping not found: '\(envName)'\n")
            }
        }

        if hasFilters && targetSecrets.isEmpty {
            stderr("❌ No matching secrets for provided filters\n")
            throw ExitCode.failure
        }

        if dryRun {
            print("Dry run: \(targetSecrets.count) secret(s) would be loaded")
            for secret in targetSecrets.sorted(by: { $0.name < $1.name }) {
                let biometricLabel = secret.biometric ? " [biometric]" : ""
                print("  - \(secret.name) -> $\(secret.envName)\(biometricLabel)")
            }
            if command.isEmpty {
                print("Command: (none)")
            } else {
                print("Command: \(command.joined(separator: " "))")
            }
            return
        }

        if !hasFilters && targetSecrets.isEmpty {
            stderr("⚠️ No secrets stored. Running command without injection.\n")
        }

        var env = ProcessInfo.processInfo.environment
        var injectedCount = 0
        let authContext = BiometricService.createBatchContext()

        // Pre-authenticate once if any secrets require biometric
        let hasBiometric = targetSecrets.contains { $0.biometric }
        if hasBiometric {
            guard BiometricService.preAuthenticate(
                reason: "Authenticate to inject secrets",
                context: authContext
            ) != nil else {
                stderr("❌ Authentication cancelled\n")
                throw ExitCode.failure
            }
        }

        for secret in targetSecrets {
            do {
                let value = try KeychainManager.get(
                    key: secret.name,
                    prompt: "Authenticate to inject '\(secret.name)'",
                    context: secret.biometric ? authContext : nil,
                    requiresAuth: secret.biometric
                )
                env[secret.envName] = value
                injectedCount += 1
            } catch {
                stderr("⚠️ Failed to load '\(secret.name)': \(error.localizedDescription)\n")
            }
        }

        if injectedCount > 0 {
            stderr("✅ \(injectedCount) secret(s) injected\n")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = command
        process.environment = env

        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                throw ExitCode(process.terminationStatus)
            }
        } catch let error as ExitCode {
            throw error
        } catch {
            stderr("❌ Failed to execute command: \(error.localizedDescription)\n")
            throw ExitCode.failure
        }
    }
}
