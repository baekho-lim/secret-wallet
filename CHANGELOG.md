# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/baekho-lim/secret-wallet/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/baekho-lim/secret-wallet/releases/tag/v0.1.0
