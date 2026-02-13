import ArgumentParser
import Foundation
import LocalAuthentication
import SecretWalletCore

struct Inject: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Inject secrets as environment variables and run a command"
    )

    @Argument(parsing: .captureForPassthrough, help: "Command to run with injected environment variables")
    var command: [String] = []

    func run() throws {
        guard !command.isEmpty else {
            print("❌ No command specified")
            print("Usage: secret-wallet inject -- <command>")
            throw ExitCode.failure
        }

        let secrets = MetadataStore.list()

        if secrets.isEmpty {
            print("⚠️ No secrets stored. Running command without injection.")
        }

        var env = ProcessInfo.processInfo.environment
        var injectedCount = 0

        let authContext = LAContext()
        authContext.touchIDAuthenticationAllowableReuseDuration = 10

        // Pre-authenticate once if any secrets require biometric
        let hasBiometric = secrets.contains { $0.biometric }
        if hasBiometric {
            guard BiometricService.preAuthenticate(
                reason: "Authenticate to inject secrets",
                context: authContext
            ) != nil else {
                stderr("❌ Authentication cancelled\n")
                throw ExitCode.failure
            }
        }

        for secret in secrets {
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
            print("❌ Failed to execute command: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}
