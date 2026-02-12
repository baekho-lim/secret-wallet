# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0-alpha] - 2026-02-12

### Added
- **SwiftUI GUI app** (macOS 13+) -- native desktop app for managing API keys without terminal
  - Dashboard view with key card list, search, and empty state
  - Add Key flow: service presets (OpenAI, Anthropic, Google AI, OpenRouter) + name + paste
  - Key cards with copy-to-clipboard and delete actions
  - TouchID/FaceID toggle per key
  - Error dialogs for failed operations (no silent failures)
  - Save success animation (checkmark overlay + auto-dismiss)
  - Auto-refresh dashboard when app gains focus (reflects CLI changes)
  - Hover feedback on copy/delete action buttons
- AI service presets with icons and default env var names
- Shared storage between CLI and GUI (same Keychain service + metadata file)
- AppDelegate for window activation and Dock click handling

### Fixed
- Biometric ACL `errSecMissingEntitlement` (-34018) on unsigned apps -- two-stage fallback to non-biometric
- Delete-before-save uses direct `SecItemDelete` without LAContext (avoids biometric prompt on overwrite)
- Error message positioned above Save button (was hidden inside ScrollView)
- Biometric toggle defaults to `BiometricService.isAvailable` (was always `true`)
- CLI `KeychainManager.save()` aligned with GUI: same fallback pattern, returns `Bool` for actual biometric status

### Security
- Clipboard auto-clear after 30 seconds (using changeCount, not secret comparison)
- API key value cleared from `@State` immediately after Keychain save
- Thread-safe MetadataStore with serial DispatchQueue
- Deprecated `kSecUseOperationPrompt` replaced with `LAContext.localizedReason`
- Input validation: whitespace trimming on key values before save

## [0.2.0] - 2026-02-10

### Added
- Shell integration: aliases (`sw`, `swa`, `swg`, `swl`, `swr`, `swi`)
- Tab completion for secret names in `get` and `remove` commands
- `setup` subcommand to install shell aliases and completions
- `scripts/setup-shell.sh` for standalone shell configuration

## [0.1.0] - 2026-02-02

### Added
- Initial release: macOS Keychain-based credential manager for AI agents
- Core commands:
  - `init` - Verify Keychain access
  - `add <name>` - Store secret with optional biometric protection
  - `get <name>` - Retrieve secret (prompts TouchID/FaceID if enabled)
  - `list` - Show all stored secret names
  - `remove <name>` - Delete secret from Keychain
  - `inject -- <command>` - Run command with secrets as environment variables
- Defense in Depth security model with 7 independent layers
- Biometric authentication support (TouchID/FaceID) via LocalAuthentication framework
- Process isolation: credentials injected only in child process, never in parent
- Metadata store for environment variable mapping (`~/Library/Application Support/secret-wallet/metadata.json`)
- Keychain integration with AES-256-GCM encryption at rest
- Swift 5.9+ implementation with swift-argument-parser

### Security
- Zero plaintext credentials in filesystem - all secrets encrypted in macOS Keychain
- Biometric ACLs for sensitive secrets (`kSecAttrAccessControl` with `.biometryCurrentSet`)
- Child process isolation prevents credential exposure to parent shell environment
- macOS Secure Enclave integration for hardware-backed encryption (T2/M1/M2 chips)
- FileVault prerequisite for full defense in depth
- 6 attack vectors mitigated:
  1. Plaintext credential theft (Keychain encryption)
  2. Accidental git commit (no plaintext files)
  3. Process memory dump (process isolation)
  4. Malware keylogging (biometric authentication)
  5. Physical device theft (Secure Enclave + biometric)
  6. Backup exposure (device-only Keychain items)
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` prevents iCloud Keychain sync
- Terminal echo disabled during secret input to prevent shoulder surfing

### Documentation
- Comprehensive README with Defense in Depth diagram and usage examples
- SECURITY.md with threat model and responsible disclosure policy
- CONTRIBUTING.md with AI-assisted contribution guidelines
- LICENSE (MIT)
- CI/CD pipeline for Swift builds (.github/workflows/ci.yml)
- Issue templates for bug reports, feature requests, and security reports

[Unreleased]: https://github.com/baekho-lim/secret-wallet/compare/v0.3.0-alpha...HEAD
[0.3.0-alpha]: https://github.com/baekho-lim/secret-wallet/compare/v0.2.0...v0.3.0-alpha
[0.2.0]: https://github.com/baekho-lim/secret-wallet/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/baekho-lim/secret-wallet/releases/tag/v0.1.0
