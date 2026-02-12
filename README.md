# Secret Wallet

> Secure API key management for macOS -- CLI + GUI

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Secret Wallet protects your API keys using macOS Keychain and biometric authentication (TouchID/FaceID). Available as both a **CLI tool** for developers and a **SwiftUI desktop app** for everyone.

**No plaintext config files. No `.env` exposure. Just fingerprint and go.**

---

## Table of Contents

- [Why Secret Wallet?](#why-secret-wallet)
- [Two Ways to Use](#two-ways-to-use)
- [Installation](#installation)
- [GUI App](#gui-app)
- [CLI Usage](#cli-usage)
- [Security Model](#security-model)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## Why Secret Wallet?

AI tools like OpenClaw/Moltbot, Cursor, and Windsurf need API keys. Most people store them in plaintext:

```json
// ~/.openclaw/auth-profiles.json
{ "token": "sk-proj-xxxxxxxxxxxxx" }  // Exposed!
```

**This is dangerous:**
- Visible in filesystem, git history, backups
- Any process can read them
- One malware = all keys stolen (see [CVE-2026-25253](https://github.com/transitive-bullshit/OpenClaw/security/advisories))

**Secret Wallet fixes this** by storing keys in macOS Keychain (AES-256-GCM, hardware-backed) and requiring TouchID to access them.

---

## Two Ways to Use

### GUI App (for everyone)

A native macOS SwiftUI app. No terminal needed.

- Add keys by selecting a service and pasting
- Copy with one click + TouchID
- Auto-clears clipboard after 30 seconds
- Presets for OpenAI, Anthropic, Google AI, OpenRouter

### CLI Tool (for developers)

A command-line tool with process isolation.

- Inject keys as env vars into child processes
- Shell aliases (`sw`, `swa`, `swg`, `swl`, `swr`, `swi`)
- Tab completion for key names
- Zero credentials in parent process memory

**Both share the same Keychain storage and metadata** -- keys added in the GUI are available in the CLI, and vice versa.

---

## Installation

### Prerequisites

- macOS 13.0 or later
- Xcode Command Line Tools (`xcode-select --install`)

### GUI App

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet/App
swift build -c release
open .build/release/SecretWalletApp
```

### CLI Tool

```bash
cd secret-wallet
swift build -c release
cp .build/release/secret-wallet /usr/local/bin/
secret-wallet setup  # Install shell aliases
source ~/.zshrc
```

### Shell Aliases (CLI)

| Shortcut | Full Command | Description |
|----------|-------------|-------------|
| `sw` | `secret-wallet` | Base command |
| `swa KEY -b` | `secret-wallet add KEY --biometric` | Add secret |
| `swg KEY` | `secret-wallet get KEY` | Get secret |
| `swl` | `secret-wallet list` | List secrets |
| `swr KEY` | `secret-wallet remove KEY` | Remove secret |
| `swi cmd` | `secret-wallet inject -- cmd` | Inject & run |

---

## GUI App

### Dashboard

The main screen shows all your saved keys as cards:

- Service icon and color (OpenAI = green, Anthropic = orange, etc.)
- Key name and environment variable mapping
- TouchID badge for biometric-protected keys
- Copy and Delete buttons on each card
- Search bar (appears when you have 4+ keys)

### Adding a Key

Three-step flow:

1. **Select Service** -- Choose from presets (OpenAI, Anthropic, Google AI, OpenRouter, Other)
2. **Name** -- Give your key a friendly name
3. **Paste Key** -- Paste your API key (shown as dots, never in plaintext)

Toggle TouchID protection, then hit "Save Securely".

### Copying a Key

Click the copy icon on any card. TouchID prompt appears (if enabled). Key is copied to clipboard and **auto-cleared after 30 seconds**.

### Deleting a Key

Click the trash icon. Confirm in the dialog. The key is permanently removed from Keychain.

---

## CLI Usage

### Quick Start

```bash
# 1. Initialize
secret-wallet init

# 2. Add a key with biometric protection
secret-wallet add openai-key --biometric --env-name OPENAI_API_KEY

# 3. Run a command with injected credentials
secret-wallet inject -- moltbot chat "Hello"
```

### Commands

| Command | Description | Biometric |
|---------|-------------|-----------|
| `init` | Verify Keychain access | -- |
| `add <name>` | Store a secret | Optional (`--biometric`) |
| `get <name>` | Retrieve a secret | If enabled |
| `list` | List all secrets | -- |
| `remove <name>` | Delete a secret | If enabled |
| `inject -- <cmd>` | Run command with secrets as env vars | If enabled |
| `setup` | Install shell aliases | -- |

### Process Isolation (inject)

```bash
secret-wallet inject -- moltbot chat "Hello"
```

What happens:
1. Retrieves all secrets from Keychain (TouchID if needed)
2. Sets env vars **only in the child process**
3. Spawns `moltbot` with injected credentials
4. Credentials destroyed when process exits
5. Parent shell **never** sees the secrets

---

## Security Model

Secret Wallet implements **Defense in Depth** with 7 layers:

```
┌─────────────────────────────────────────┐
│  Layer 7: Process Isolation             │  Env vars only in child process
├─────────────────────────────────────────┤
│  Layer 6: Runtime Injection             │  Just-in-time credential delivery
├─────────────────────────────────────────┤
│  Layer 5: Biometric Authentication      │  TouchID / FaceID verification
├─────────────────────────────────────────┤
│  Layer 4: Encrypted Storage             │  macOS Keychain (AES-256-GCM)
├─────────────────────────────────────────┤
│  Layer 3: OS-Level Access Control       │  Keychain ACL enforcement
├─────────────────────────────────────────┤
│  Layer 2: Secure Enclave (T2/M1/M2)    │  Hardware-backed encryption
├─────────────────────────────────────────┤
│  Layer 1: Physical Device Security      │  FileVault full-disk encryption
└─────────────────────────────────────────┘
```

### Threat Mitigations

| Threat | How Secret Wallet Protects You |
|--------|-------------------------------|
| Plaintext credential theft | Keys encrypted in Keychain, never in files |
| Accidental git commit | No credentials in filesystem at all |
| Process memory dump | Credentials isolated to child process only |
| Unauthorized access | TouchID/FaceID required before retrieval |
| Backup/sync exposure | Keychain items flagged device-only (no iCloud) |
| Clipboard sniffing | Auto-clear after 30 seconds |

For the full threat model, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Architecture

### Project Structure

```
secret-wallet/
├── Sources/secret-wallet/
│   └── main.swift              # CLI tool (swift-argument-parser)
├── App/
│   ├── Package.swift           # GUI app build config
│   └── SecretWalletApp/
│       ├── SecretWalletApp.swift    # @main entry point
│       ├── Views/
│       │   ├── DashboardView.swift  # Main screen (key list, search)
│       │   ├── AddKeyView.swift     # Add key flow (3 steps)
│       │   └── KeyCardView.swift    # Key card component
│       ├── Services/
│       │   ├── KeychainManager.swift    # Keychain CRUD + biometric
│       │   ├── MetadataStore.swift      # JSON persistence (thread-safe)
│       │   └── BiometricService.swift   # TouchID/FaceID detection
│       └── Models/
│           ├── SecretMetadata.swift     # Key metadata (Codable)
│           ├── SecretWalletError.swift  # User-friendly errors
│           └── AIService.swift          # Service presets
├── scripts/
│   ├── setup-shell.sh          # Shell alias installer
│   └── manual-test.sh          # Integration test suite (7 tests)
├── Package.swift               # CLI build config
└── ~/Library/Application Support/secret-wallet/
    └── metadata.json           # Shared metadata (CLI + GUI)
```

### Shared Storage

Both CLI and GUI use the same backend:

| Component | Location | Shared? |
|-----------|----------|---------|
| **Keychain** | macOS Keychain (service: `com.secret-wallet`) | Yes |
| **Metadata** | `~/Library/Application Support/secret-wallet/metadata.json` | Yes |

Keys added in the GUI appear in `secret-wallet list`, and vice versa.

### Metadata Schema

```json
[
  {
    "name": "openai-key",
    "envName": "OPENAI_API_KEY",
    "biometric": true,
    "serviceName": "openai",
    "createdAt": "2026-02-12T10:00:00Z"
  }
]
```

---

## Use Cases

### OpenClaw / Moltbot

```bash
# Before: plaintext key in auth-profiles.json
# After:
secret-wallet add anthropic-key --biometric --env-name ANTHROPIC_API_KEY
secret-wallet inject -- moltbot chat "Hello"
```

### Multi-Agent Workflows

```bash
secret-wallet add openai --biometric --env-name OPENAI_API_KEY
secret-wallet add anthropic --biometric --env-name ANTHROPIC_API_KEY
secret-wallet inject -- ./multi-agent-orchestrator.sh
```

### Local CI/CD

```bash
secret-wallet add vercel-token --env-name VERCEL_TOKEN
secret-wallet inject -- vercel deploy --prod
```

---

## Comparison

| Solution | Encrypted | Biometric | Process Isolation | GUI |
|----------|-----------|-----------|-------------------|-----|
| Plaintext `.env` | No | No | No | -- |
| 1Password CLI | Yes | Yes | Partial | Separate app |
| **Secret Wallet** | **Yes (Keychain)** | **Yes** | **Yes** | **Built-in** |

---

## Roadmap

- [x] **v0.1.0**: CLI MVP (init, add, get, list, remove, inject)
- [x] **v0.2.0**: Shell integration (aliases, tab completion, setup)
- [x] **v0.3.0-alpha**: SwiftUI GUI app (macOS)
- [ ] **v0.3.0**: GUI polish + .dmg distribution
- [ ] **v0.4.0**: Multi-profile support (dev/staging/prod)
- [ ] **v0.5.0**: Windows support (Tauri + Credential Manager)

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

```bash
# CLI
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet && swift build

# GUI
cd App && swift build
```

This project was built with [Claude Code](https://claude.com/claude-code). AI-assisted contributions are encouraged -- just note it in your PR.

---

## License

MIT License -- See [LICENSE](LICENSE) for details.

---

## FAQ

**Q: Can the GUI and CLI share keys?**
Yes. Both use the same Keychain service (`com.secret-wallet`) and metadata file.

**Q: What happens if TouchID fails?**
The operation is cancelled. Your key stays safely in Keychain. Try again.

**Q: Can I use this on Linux/Windows?**
Not yet. macOS only for now. Windows support via Tauri is planned for v0.5.0.

**Q: How do I migrate from `.env` files?**
```bash
secret-wallet add my-key --biometric --env-name API_KEY
# Then delete the .env entry and use: secret-wallet inject -- your-app
```

---

**Author**: [Baekho Lim](https://github.com/baekho-lim) (bh@baekho.io)
