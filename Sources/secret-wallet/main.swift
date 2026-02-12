import ArgumentParser
import Foundation
import Security
import LocalAuthentication

// MARK: - Main Entry Point

@main
struct SecretWallet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "secret-wallet",
        abstract: "Keychain-based credential manager for AI agents",
        version: "0.1.0",
        subcommands: [Init.self, Add.self, Get.self, List.self, Remove.self, Inject.self, Setup.self]
    )
}

// MARK: - Init Command

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Initialize secret-wallet (verify Keychain access)"
    )

    func run() throws {
        print("🔐 Initializing Secret Wallet...")

        // Test Keychain access
        let testKey = "secret-wallet-test"
        let testValue = "init-test-\(UUID().uuidString)"

        do {
            try KeychainManager.save(key: testKey, value: testValue)
            let retrieved = try KeychainManager.get(key: testKey)
            try KeychainManager.delete(key: testKey)

            if retrieved == testValue {
                print("✅ macOS Keychain connected")
                let context = LAContext()
                var authError: NSError?
                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                    print("✅ TouchID/FaceID available (enable per secret with --biometric)")
                } else {
                    let reason = authError?.localizedDescription ?? "unknown"
                    print("⚠️ TouchID/FaceID unavailable: \(reason)")
                }
                print("")
                print("Usage:")
                print("  secret-wallet add <name>        # Add a secret")
                print("  secret-wallet get <name>        # Retrieve a secret")
                print("  secret-wallet list              # List stored secrets")
                print("  secret-wallet inject -- <cmd>   # Run command with secrets as env vars")
            } else {
                throw SecretWalletError.keychainTestFailed
            }
        } catch {
            print("❌ Failed to access Keychain: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

// MARK: - Add Command

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

        // Read secret without echo
        let secret = readSecretFromStdin()

        guard !secret.isEmpty else {
            print("❌ Secret value is empty")
            throw ExitCode.failure
        }

        do {
            // Store actual secret in Keychain
            let biometricApplied = try KeychainManager.save(key: name, value: secret, biometric: biometric)

            // Store metadata (env var name mapping)
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

        // Disable echo for password input
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
            // Restore terminal settings
            tcsetattr(STDIN_FILENO, TCSANOW, &oldTermios)
            print("") // New line after hidden input
        }

        return readLine(strippingNewline: true) ?? ""
    }
}

// MARK: - Get Command

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
            let value = try KeychainManager.get(
                key: name,
                prompt: "Authenticate to access '\(name)'"
            )
            // Output only the value (for piping)
            print(value, terminator: "")
        } catch {
            FileHandle.standardError.write("❌ Failed to retrieve: \(error.localizedDescription)\n".data(using: .utf8)!)
            throw ExitCode.failure
        }
    }
}

// MARK: - List Command

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

// MARK: - Remove Command

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
            try KeychainManager.delete(
                key: name,
                prompt: "Authenticate to delete '\(name)'"
            )
            try MetadataStore.delete(name: name)
            print("✅ '\(name)' deleted")
        } catch {
            print("❌ Failed to delete: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

// MARK: - Inject Command

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

        // Build environment with secrets
        var env = ProcessInfo.processInfo.environment
        var injectedCount = 0

        let authContext = LAContext()
        authContext.touchIDAuthenticationAllowableReuseDuration = 10

        for secret in secrets {
            do {
                let value = try KeychainManager.get(
                    key: secret.name,
                    prompt: "Authenticate to inject '\(secret.name)'",
                    context: authContext
                )
                env[secret.envName] = value
                injectedCount += 1
            } catch {
                FileHandle.standardError.write("⚠️ Failed to load '\(secret.name)': \(error.localizedDescription)\n".data(using: .utf8)!)
            }
        }

        if injectedCount > 0 {
            FileHandle.standardError.write("✅ \(injectedCount) secret(s) injected\n".data(using: .utf8)!)
        }

        // Execute command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = command
        process.environment = env

        // Forward stdin/stdout/stderr
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

// MARK: - Setup Command

struct Setup: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Install shell completions and aliases"
    )

    func run() throws {
        let shellName = ProcessInfo.processInfo.environment["SHELL"].flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "zsh"

        guard shellName == "zsh" || shellName == "bash" else {
            print("❌ Unsupported shell: \(shellName) (zsh/bash only)")
            throw ExitCode.failure
        }

        let rcFile = shellName == "zsh" ? "\(NSHomeDirectory())/.zshrc" : "\(NSHomeDirectory())/.bashrc"
        let marker = "# >>> secret-wallet shell integration >>>"
        let endMarker = "# <<< secret-wallet shell integration <<<"

        // Read existing content (atomic read-check-write)
        let existing = (try? String(contentsOfFile: rcFile, encoding: .utf8)) ?? ""

        if existing.contains(marker) {
            print("✅ Shell integration already installed in \(rcFile)")
            print("   To reinstall, remove the secret-wallet block first.")
            return
        }

        let snippet = """

        \(marker)
        alias sw='secret-wallet'
        alias swa='secret-wallet add'
        alias swg='secret-wallet get'
        alias swl='secret-wallet list'
        alias swr='secret-wallet remove'
        swi() { secret-wallet inject -- "$@"; }
        \(endMarker)
        """

        // Atomic write: append snippet to existing content
        let newContent = existing + snippet
        do {
            try newContent.write(to: URL(fileURLWithPath: rcFile), atomically: true, encoding: .utf8)
        } catch {
            print("❌ Failed to write to \(rcFile): \(error.localizedDescription)")
            throw ExitCode.failure
        }

        print("✅ Shell integration installed in \(rcFile)")
        print("")
        print("Available shortcuts:")
        print("  sw   → secret-wallet")
        print("  swa  → secret-wallet add")
        print("  swg  → secret-wallet get")
        print("  swl  → secret-wallet list")
        print("  swr  → secret-wallet remove")
        print("  swi  → secret-wallet inject --")
        print("")
        print("Run 'source \(rcFile)' or open a new terminal to activate.")
    }
}

// MARK: - Keychain Manager

enum KeychainManager {
    private static let service = "com.secret-wallet"

    /// Returns `true` if biometric was actually applied, `false` if it fell back to non-biometric.
    @discardableResult
    static func save(key: String, value: String, biometric: Bool = false) throws -> Bool {
        // Delete without LAContext to avoid biometric prompt on overwrite
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard let data = value.data(using: .utf8) else {
            throw SecretWalletError.encodingFailed
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        var biometricApplied = false

        if biometric {
            var error: Unmanaged<CFError>?
            if let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            ) {
                query[kSecAttrAccessControl as String] = access
                biometricApplied = true
            } else {
                // Fallback to non-biometric if ACL creation fails
                query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        var status = SecItemAdd(query as CFDictionary, nil)

        // -34018 (errSecMissingEntitlement): retry without biometric ACL
        if status == errSecMissingEntitlement && biometricApplied {
            query.removeValue(forKey: kSecAttrAccessControl as String)
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            biometricApplied = false
            status = SecItemAdd(query as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw SecretWalletError.keychainError(status)
        }

        return biometricApplied
    }

    static func get(key: String, prompt: String? = nil, context: LAContext? = nil) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var authQuery = query
        if let context {
            authQuery[kSecUseAuthenticationContext as String] = context
        }
        if let prompt {
            authQuery[kSecUseOperationPrompt as String] = prompt
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(authQuery as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                throw SecretWalletError.notFound(key)
            }
            throw SecretWalletError.keychainError(status)
        }

        return value
    }

    static func delete(key: String, prompt: String? = nil, context: LAContext? = nil) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        if let context {
            query[kSecUseAuthenticationContext as String] = context
        }
        if let prompt {
            query[kSecUseOperationPrompt as String] = prompt
        }

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretWalletError.keychainError(status)
        }
    }
}

// MARK: - Metadata Store

struct SecretMetadata: Codable {
    let name: String
    let envName: String
    let biometric: Bool
}

enum MetadataStore {
    private static var metadataURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = appSupport.appendingPathComponent("secret-wallet")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("metadata.json")
    }

    static func save(_ metadata: SecretMetadata) throws {
        var all = list()
        all.removeAll { $0.name == metadata.name }
        all.append(metadata)

        let data = try JSONEncoder().encode(all)
        try data.write(to: metadataURL, options: .atomic)

        // Set file permissions to 600
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: metadataURL.path)
    }

    static func list() -> [SecretMetadata] {
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: metadataURL)
            return try JSONDecoder().decode([SecretMetadata].self, from: data)
        } catch {
            FileHandle.standardError.write("⚠️ Metadata corrupted: \(error.localizedDescription)\n".data(using: .utf8)!)
            return []
        }
    }

    static func delete(name: String) throws {
        var all = list()
        all.removeAll { $0.name == name }

        let data = try JSONEncoder().encode(all)
        try data.write(to: metadataURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: metadataURL.path)
    }
}

// MARK: - Errors

enum SecretWalletError: LocalizedError {
    case keychainTestFailed
    case encodingFailed
    case accessControlFailed
    case keychainError(OSStatus)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .keychainTestFailed:
            return "Failed to access secure storage"
        case .encodingFailed:
            return "Failed to encode data"
        case .accessControlFailed:
            return "Could not set up biometric protection"
        case .keychainError(let status):
            return Self.describeOSStatus(status)
        case .notFound(let key):
            return "Key '\(key)' not found"
        }
    }

    private static func describeOSStatus(_ status: OSStatus) -> String {
        switch status {
        case errSecDuplicateItem:          // -25299
            return "A key with this name already exists in Keychain"
        case errSecItemNotFound:           // -25300
            return "Key not found in secure storage"
        case errSecAuthFailed:             // -25293
            return "Authentication failed -- check your fingerprint or password"
        case errSecUserCanceled:           // -128
            return "Authentication was cancelled"
        case errSecInteractionNotAllowed:  // -25308
            return "Authentication is not available right now"
        case errSecMissingEntitlement:     // -34018
            return "App needs code signing for biometric protection"
        case errSecIO:                     // -61
            return "Keychain database error -- restart your Mac and try again"
        case errSecDecode:                 // -26275
            return "Stored data is corrupted"
        case errSecParam:                  // -50
            return "Internal error: invalid Keychain parameters"
        default:
            return "Keychain error (OSStatus \(status))"
        }
    }
}
