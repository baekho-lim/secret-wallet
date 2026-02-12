# Architecture

> Technical design and security model of Secret Wallet

## Overview

Secret Wallet provides two interfaces -- a CLI tool and a SwiftUI GUI app -- built on shared core services that interact with macOS Keychain and a local metadata store.

```
                    +-----------------+     +------------------+
                    |   GUI App       |     |   CLI Tool       |
                    |   (SwiftUI)     |     |   (ArgumentParser)|
                    +--------+--------+     +--------+---------+
                             |                       |
                    +--------+-----------------------+---------+
                    |            Shared Core                    |
                    |                                           |
                    |  KeychainManager   MetadataStore          |
                    |  BiometricService  SecretMetadata          |
                    +--------+-----------------------+---------+
                             |                       |
                    +--------+--------+     +--------+---------+
                    | macOS Keychain  |     | metadata.json    |
                    | (AES-256-GCM)  |     | (App Support)    |
                    +-----------------+     +------------------+
```

## Components

### GUI App (`App/SecretWalletApp/`)

Native macOS SwiftUI app targeting macOS 13+. No external dependencies.

| File | Responsibility |
|------|---------------|
| `SecretWalletApp.swift` | App entry point, window configuration |
| `Views/DashboardView.swift` | Main screen: key list, search, empty state, error alerts |
| `Views/AddKeyView.swift` | 3-step add flow: service select, name, paste key |
| `Views/KeyCardView.swift` | Individual key card with copy/delete actions |

Design principles:
- No technical jargon in UI text ("Save Securely" not "Write to Keychain")
- Maximum 5 interactive elements per screen
- Errors shown as alerts, never silently swallowed

### CLI Tool (`Sources/secret-wallet/`)

Command-line tool using Swift Argument Parser. Single-file implementation (`main.swift`).

Commands: `init`, `add`, `get`, `list`, `remove`, `inject`, `setup`

### Shared Services (`App/SecretWalletApp/Services/`)

These are extracted from the CLI and shared via identical Keychain service name and metadata path.

#### KeychainManager

Wraps Security framework for CRUD operations on Keychain items.

```
Service:  "com.secret-wallet"
Account:  key name (e.g., "openai-key")
Value:    API key string (encrypted at rest by Keychain)
ACL:      kSecAttrAccessibleWhenUnlockedThisDeviceOnly
          + .biometryCurrentSet (if biometric enabled)
```

Key decisions:
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` prevents iCloud Keychain sync
- `.biometryCurrentSet` invalidates access when biometrics change (e.g., new fingerprint added)
- `LAContext.localizedReason` used instead of deprecated `kSecUseOperationPrompt`
- Delete-before-save pattern to handle Keychain update semantics

#### MetadataStore

JSON file persistence for key metadata (names, env var mappings, service info).

```
Path: ~/Library/Application Support/secret-wallet/metadata.json
Permissions: 0o600 (owner read/write only)
Encoding: JSON with ISO 8601 dates
```

Key decisions:
- Atomic writes (`.atomic` option) prevent partial file corruption
- Serial DispatchQueue prevents read-modify-write race conditions
- `guard let` on Application Support directory (no force unwraps)

#### BiometricService

Thin wrapper around LocalAuthentication to detect biometric availability.

Returns human-readable names: "Touch ID", "Face ID", "Optic ID", "Password".

### Models (`App/SecretWalletApp/Models/`)

#### SecretMetadata

```swift
struct SecretMetadata: Codable, Identifiable {
    let name: String        // Keychain account name
    let envName: String     // Environment variable name for inject
    let biometric: Bool     // Whether TouchID is required
    var serviceName: String? // AI service ID (e.g., "openai")
    var createdAt: Date?    // Creation timestamp
}
```

`displayName` computed property resolves `serviceName` to human-readable label via `AIService.all`.

#### AIService

Static list of supported AI service presets:

| ID | Name | Default Env Var | Color |
|----|------|----------------|-------|
| openai | OpenAI | OPENAI_API_KEY | green |
| anthropic | Anthropic | ANTHROPIC_API_KEY | orange |
| google | Google AI | GOOGLE_API_KEY | blue |
| openrouter | OpenRouter | OPENROUTER_API_KEY | purple |
| other | Other | API_KEY | gray |

Colors are resolved to SwiftUI `Color` via a single `swiftUIColor` computed property (DRY).

---

## Security Model

### Defense in Depth (7 Layers)

| Layer | Component | What It Protects Against |
|-------|-----------|------------------------|
| 7 | Process Isolation | Parent process memory dump |
| 6 | Runtime Injection | Static config file theft |
| 5 | Biometric Auth | Unauthorized access |
| 4 | Keychain Encryption | Filesystem theft |
| 3 | Keychain ACL | Cross-app access |
| 2 | Secure Enclave | Hardware key extraction |
| 1 | FileVault | Physical device theft |

### Clipboard Security

When a key is copied to clipboard:
1. Key value is retrieved from Keychain (TouchID prompt if enabled)
2. Value placed on `NSPasteboard`
3. `changeCount` is captured (not the value itself)
4. After 30 seconds, clipboard is cleared **only if nothing else was copied**

The closure does **not** capture the secret value -- it compares `changeCount` instead.

### Memory Hygiene

- `@State private var keyValue` is explicitly set to `""` after Keychain save
- CLI `inject` command passes secrets via `ProcessInfo.processInfo.environment` only to child
- Parent process environment is never modified

### Thread Safety

MetadataStore uses a serial `DispatchQueue` to serialize all read-modify-write operations:
```swift
private static let queue = DispatchQueue(label: "com.secret-wallet.metadata")
```

### What Is NOT Protected

- Root-level process memory inspection (requires SIP bypass)
- Physical coercion (forcing biometric unlock)
- Compromised macOS kernel
- Social engineering

---

## Data Flow

### Adding a Key (GUI)

```
User taps "Add Key"
  -> Selects service preset (e.g., OpenAI)
  -> Types friendly name
  -> Pastes API key into SecureField
  -> Toggles TouchID
  -> Taps "Save Securely"
    -> keyValue trimmed of whitespace
    -> KeychainManager.save(key, value, biometric)
      -> SecItemAdd with kSecAttrAccessControl
    -> MetadataStore.save(metadata)
      -> queue.sync { readAll -> modify -> writeAll }
    -> keyValue = "" (clear from memory)
    -> dismiss sheet
```

### Copying a Key (GUI)

```
User taps copy icon on KeyCard
  -> KeychainManager.get(key, prompt)
    -> LAContext with localizedReason
    -> TouchID prompt (if biometric)
    -> SecItemCopyMatching
  -> NSPasteboard.setString(value)
  -> Capture changeCount
  -> After 30s: if changeCount unchanged, clear clipboard
```

### Injecting Credentials (CLI)

```
secret-wallet inject -- moltbot chat "Hello"
  -> MetadataStore.list()
  -> For each secret:
     -> KeychainManager.get(key, prompt)
     -> TouchID prompt (if biometric)
  -> Build env dict: existing env + secret env vars
  -> Process.launchedProcess(url, args, env)
    -> Child process has credentials in its env
    -> Parent process env unchanged
  -> Child exits -> credentials destroyed
```

---

## Build System

### CLI (root `Package.swift`)

```swift
// swift-tools-version: 5.9
// Platform: macOS 12+
// Dependency: swift-argument-parser 1.3.0..<1.6.0
```

```bash
swift build -c release
# Output: .build/release/secret-wallet
```

### GUI (`App/Package.swift`)

```swift
// swift-tools-version: 5.9
// Platform: macOS 13+
// No external dependencies
// Linked frameworks: Security, LocalAuthentication
```

```bash
cd App && swift build -c release
# Output: App/.build/release/SecretWalletApp
```

---

## File Permissions

| File | Permissions | Why |
|------|------------|-----|
| `metadata.json` | `0o600` | Owner-only read/write, contains key names |
| Keychain items | OS-managed | AES-256-GCM, Secure Enclave |
| `~/.zshrc` additions | User default | Shell aliases (no secrets) |
