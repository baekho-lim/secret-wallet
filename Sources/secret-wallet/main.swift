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
        subcommands: [Init.self, Add.self, Get.self, List.self, Remove.self, Inject.self]
    )
}

// MARK: - Init Command

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Initialize secret-wallet (verify Keychain access)"
    )

    func run() throws {
        print("🔐 Secret Wallet 초기화 중...")

        // Test Keychain access
        let testKey = "secret-wallet-test"
        let testValue = "init-test-\(UUID().uuidString)"

        do {
            try KeychainManager.save(key: testKey, value: testValue)
            let retrieved = try KeychainManager.get(key: testKey)
            try KeychainManager.delete(key: testKey)

            if retrieved == testValue {
                print("✅ macOS Keychain 연동 완료")
                let context = LAContext()
                var authError: NSError?
                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                    print("✅ TouchID/FaceID 사용 가능 (비밀 추가 시 활성화)")
                } else {
                    let reason = authError?.localizedDescription ?? "알 수 없음"
                    print("⚠️ TouchID/FaceID 사용 불가: \(reason)")
                }
                print("")
                print("사용법:")
                print("  secret-wallet add <name>        # 비밀 추가")
                print("  secret-wallet get <name>        # 비밀 조회")
                print("  secret-wallet list              # 저장된 비밀 목록")
                print("  secret-wallet inject -- <cmd>   # 환경변수 주입 후 명령 실행")
            } else {
                throw SecretWalletError.keychainTestFailed
            }
        } catch {
            print("❌ Keychain 접근 실패: \(error.localizedDescription)")
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

        print("🔑 '\(name)' 비밀 추가 (환경변수: \(envVar))")
        print("값을 입력하세요 (입력 내용은 표시되지 않음):")

        // Read secret without echo
        let secret = readSecretFromStdin()

        guard !secret.isEmpty else {
            print("❌ 비밀 값이 비어있습니다")
            throw ExitCode.failure
        }

        do {
            // Store actual secret in Keychain
            try KeychainManager.save(key: name, value: secret, biometric: biometric)

            // Store metadata (env var name mapping)
            let metadata = SecretMetadata(name: name, envName: envVar, biometric: biometric)
            do {
                try MetadataStore.save(metadata)
            } catch {
                try? KeychainManager.delete(key: name)
                throw error
            }

            print("✅ Keychain에 저장됨 (파일 없음)")
            if biometric {
                print("🔐 TouchID 인증 필요")
            }
        } catch {
            print("❌ 저장 실패: \(error.localizedDescription)")
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

    @Argument(help: "Name of the secret")
    var name: String

    func run() throws {
        do {
            let value = try KeychainManager.get(
                key: name,
                prompt: "secret-wallet에서 '\(name)' 비밀을 사용하려면 인증이 필요합니다."
            )
            // Output only the value (for piping)
            print(value, terminator: "")
        } catch {
            FileHandle.standardError.write("❌ 조회 실패: \(error.localizedDescription)\n".data(using: .utf8)!)
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
            print("저장된 비밀이 없습니다.")
            print("'secret-wallet add <name>'으로 추가하세요.")
            return
        }

        print("저장된 비밀 목록:")
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

    @Argument(help: "Name of the secret to remove")
    var name: String

    func run() throws {
        do {
            try KeychainManager.delete(
                key: name,
                prompt: "secret-wallet에서 '\(name)' 비밀을 삭제하려면 인증이 필요합니다."
            )
            try MetadataStore.delete(name: name)
            print("✅ '\(name)' 삭제됨")
        } catch {
            print("❌ 삭제 실패: \(error.localizedDescription)")
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
            print("❌ 실행할 명령어를 지정하세요")
            print("사용법: secret-wallet inject -- <command>")
            throw ExitCode.failure
        }

        let secrets = MetadataStore.list()

        if secrets.isEmpty {
            print("⚠️ 저장된 비밀이 없습니다. 명령어만 실행합니다.")
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
                    prompt: "secret-wallet에서 '\(secret.name)' 비밀을 사용하려면 인증이 필요합니다.",
                    context: authContext
                )
                env[secret.envName] = value
                injectedCount += 1
            } catch {
                FileHandle.standardError.write("⚠️ '\(secret.name)' 로드 실패: \(error.localizedDescription)\n".data(using: .utf8)!)
            }
        }

        if injectedCount > 0 {
            FileHandle.standardError.write("✅ \(injectedCount)개 비밀 주입됨\n".data(using: .utf8)!)
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
            print("❌ 명령 실행 실패: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

// MARK: - Keychain Manager

enum KeychainManager {
    private static let service = "com.secret-wallet"

    static func save(key: String, value: String, biometric: Bool = false) throws {
        // Delete existing item first
        try? delete(key: key)

        guard let data = value.data(using: .utf8) else {
            throw SecretWalletError.encodingFailed
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        if biometric {
            // Require biometric authentication
            var error: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            ) else {
                throw SecretWalletError.accessControlFailed
            }
            query[kSecAttrAccessControl as String] = access
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw SecretWalletError.keychainError(status)
        }
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
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
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
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode([SecretMetadata].self, from: data) else {
            return []
        }
        return metadata
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
            return "Keychain 테스트 실패"
        case .encodingFailed:
            return "데이터 인코딩 실패"
        case .accessControlFailed:
            return "Access Control 생성 실패"
        case .keychainError(let status):
            return "Keychain 오류: \(status)"
        case .notFound(let key):
            return "'\(key)' 비밀을 찾을 수 없음"
        }
    }
}
