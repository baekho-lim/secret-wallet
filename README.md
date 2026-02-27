# Secret Wallet

> Zero-config API key security for macOS developers -- CLI + GUI

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Languages: **English** | [한국어](README.ko.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

Secret Wallet replaces plaintext `.env` files with macOS Keychain encryption. No account needed. No subscription. Just install and your API keys are hardware-encrypted.

```bash
brew install baekho-lim/tap/secret-wallet
secret-wallet add OPENAI_KEY
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

---

## Why Not `.env` Files?

```
.env file:
  OPENAI_API_KEY=sk-proj-xxxxx     ← plaintext on disk
  SUPABASE_KEY=eyJhbGciOiJI...     ← any process can read
                                    ← one git add mistake = leaked
```

| Aspect | `.env` files | Secret Wallet |
|--------|-------------|---------------|
| Storage | Plaintext on disk | macOS Keychain (AES-256-GCM) |
| Git risk | One mistake = exposed | Nothing to commit |
| Access control | File permissions (anyone can `cat`) | OS Keychain ACL (app-level) |
| Process isolation | Loaded globally via `dotenv` | Child process only, destroyed on exit |
| Hardware backing | None | Secure Enclave (biometric keys) |
| Cost | Free | Free |
| Setup | Create file, add to `.gitignore` | `brew install`, done |

---

## Installation

### Homebrew (recommended)

```bash
brew install baekho-lim/tap/secret-wallet
```

### Build from source

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet
swift build -c release
cp .build/release/secret-wallet /usr/local/bin/
```

### GUI App

```bash
cd secret-wallet/App
swift build -c release
open .build/release/SecretWalletApp
```

### Shell Aliases (optional)

```bash
secret-wallet setup    # Installs aliases to ~/.zshrc
source ~/.zshrc
```

| Shortcut | Full Command | Description |
|----------|-------------|-------------|
| `sw` | `secret-wallet` | Base command |
| `swa KEY` | `secret-wallet add KEY` | Add secret |
| `swg KEY` | `secret-wallet get KEY` | Get secret |
| `swl` | `secret-wallet list` | List secrets |
| `swr KEY` | `secret-wallet remove KEY` | Remove secret |
| `swi cmd` | `secret-wallet inject --only OPENAI_KEY -- cmd` | Inject & run |

---

## Quick Start

### 1. Add your first key

```bash
secret-wallet add OPENAI_KEY
# Enter value (hidden input): sk-proj-xxxxxxxx
```

### 2. Verify

```bash
secret-wallet list
# OPENAI_KEY  (env: OPENAI_KEY)  biometric: no

secret-wallet status
# { "version": "0.3.0-alpha", "secrets": { "total": 1 }, ... }
```

### 3. Use in your project

```bash
# Run any command with keys injected as environment variables
secret-wallet inject --only OPENAI_KEY -- npm run dev

# Your app reads process.env.OPENAI_KEY as usual
# When the process exits, the keys are gone from memory
```

---

## Migrating from `.env` Files

Secret Wallet includes a migration tool that scans `.env` files and imports secrets in bulk.

### Scan your projects

```bash
# Find all .env files
./scripts/migrate-env.sh --scan ~/projects
```

### Preview (no changes)

```bash
./scripts/migrate-env.sh .env.local --dry-run --all
```

Output:
```
Found 7 secret(s) to import:
  [DRY-RUN] Would import: DATABASE_URL
  [DRY-RUN] Would import: SUPABASE_SERVICE_ROLE_KEY
  [DRY-RUN] Would import: OPENAI_API_KEY
  ...

━━━ Migration Summary ━━━
  Imported:        7
  Public (skipped): 3    ← NEXT_PUBLIC_* are not secrets
```

### Import

```bash
# Interactive (confirm each key)
./scripts/migrate-env.sh .env.local

# Import all at once
./scripts/migrate-env.sh .env.local --all
```

**What gets imported:**
- API keys, tokens, passwords, database URLs
- Anything that looks like a secret

**What gets skipped automatically:**
- `NEXT_PUBLIC_*` (public, not secrets)
- URLs, ports, log levels (config, not secrets)
- Keys that already exist in Secret Wallet (no duplicates)

> **Your `.env` files are never modified or deleted.** After verifying the migration, you decide when to remove them.

---

## CLI Reference

### Commands

| Command | Description | JSON Support |
|---------|-------------|-------------|
| `init` | Verify Keychain access | -- |
| `add <name>` | Store a secret | -- |
| `get <name>` | Retrieve a secret | `--json` |
| `list` | List all secrets (names only) | `--json` |
| `remove <name>` | Delete a secret | -- |
| `inject [filters] -- <cmd>` | Run command with selected secrets as env vars | -- |
| `status` | System health check (JSON) | Always JSON |
| `setup` | Install shell aliases | -- |

### Options

```bash
# Add with custom env var name
secret-wallet add my-key --env-name CUSTOM_ENV_VAR

# Add with TouchID protection (optional, not required)
secret-wallet add production-db --biometric

# Get as JSON (for scripting)
secret-wallet get OPENAI_KEY --json
# {"name":"OPENAI_KEY","value":"sk-proj-...","biometric":false}

# List as JSON (for integrations)
secret-wallet list --json
# [{"name":"OPENAI_KEY","envName":"OPENAI_KEY","biometric":"false"}, ...]

# System status (always JSON)
secret-wallet status

# Inject only one secret (recommended for fewer auth prompts)
secret-wallet inject --only OPENAI_KEY -- npm run dev

# Inject by environment variable mapping
secret-wallet inject --only-env OPENAI_API_KEY -- npm run dev

# Explicitly inject everything (legacy/default behavior)
secret-wallet inject --all -- npm run dev

# Preview which secrets would be loaded (no Keychain access, no execution)
secret-wallet inject --dry-run --only OPENAI_KEY -- npm run dev
```

### Process Isolation

```bash
secret-wallet inject --only OPENAI_KEY -- node server.js
```

What happens:
1. Selected secrets are retrieved from Keychain (default: all, or filtered by `--only` / `--only-env`)
2. Environment variables set **only in the child process**
3. `node server.js` runs with `process.env.OPENAI_KEY` etc.
4. Process exits -- credentials destroyed
5. Parent shell **never** has the secrets

### Why repeated password prompts happen

If you store many secrets and run `inject` repeatedly, macOS can prompt for approval/authentication many times.

Common causes:
1. Default `inject` loads all stored secrets
2. Automation/tests call `inject` multiple times in a row
3. Agent tools repeatedly call `get` / `inject`

How to reduce prompts:
1. Load only what you need: `secret-wallet inject --only OPENAI_KEY -- <cmd>`
2. Use `--dry-run` first to verify scope before execution
3. Reserve full injection (`--all` or no filters) for trusted workflows

### Legacy compatibility mode (inject all)

`secret-wallet inject -- <cmd>` and `secret-wallet inject --all -- <cmd>` still work for backward compatibility.

Use this only for trusted workflows where loading every stored secret is intentional.

### Use in package.json

```json
{
  "scripts": {
    "dev": "secret-wallet inject --only OPENAI_KEY -- next dev",
    "build": "secret-wallet inject --only OPENAI_KEY -- next build"
  }
}
```

Then `npm run dev` works exactly as before, but with no `.env` file on disk.

---

## Testing

Run fast CLI validation (recommended for most changes):

```bash
./scripts/test-cli-fast.sh
```

Run Swift smoke validation (core + GUI build):

```bash
./scripts/test-swift-smoke.sh
```

Run full integration suite:

```bash
./scripts/test-full.sh --full
```

Detailed matrix and release gating guidance:
- `docs/TESTING_STRATEGY.md`

### Release tracks

- Full release (`v*` tags): CLI + GUI artifacts
- CLI-only release (`cli-v*` tags): CLI artifact only, faster ship path

---

## GUI App

A native SwiftUI app for managing keys without the terminal.

### Features

- **Dashboard** -- All keys as cards with service icons and colors
- **Add Key** -- Three-step flow: select service, name, paste key
- **Service Presets** -- OpenAI (green), Anthropic (orange), Google AI (blue), OpenRouter (purple)
- **Copy** -- One-click copy with optional TouchID, auto-clears clipboard after 30 seconds
- **Search** -- Filter keys (appears with 4+ keys)
- **Shared Storage** -- GUI and CLI share the same Keychain and metadata

---

## Security Model

### Defense in Depth (7 layers)

```
┌─────────────────────────────────────────┐
│  Layer 7: Process Isolation             │  Env vars only in child process
├─────────────────────────────────────────┤
│  Layer 6: Runtime Injection             │  Just-in-time credential delivery
├─────────────────────────────────────────┤
│  Layer 5: Biometric Authentication      │  TouchID / FaceID (optional)
├─────────────────────────────────────────┤
│  Layer 4: Encrypted Storage             │  macOS Keychain (AES-256-GCM)
├─────────────────────────────────────────┤
│  Layer 3: OS-Level Access Control       │  Keychain ACL enforcement
├─────────────────────────────────────────┤
│  Layer 2: Secure Enclave               │  Hardware key storage (biometric keys)
├─────────────────────────────────────────┤
│  Layer 1: Physical Device Security      │  FileVault full-disk encryption
└─────────────────────────────────────────┘
```

**Layers 1, 3-4, 6-7 are always active.** Layer 5 (biometric) and Layer 2 (Secure Enclave) are fully engaged only for biometric-protected keys. Non-biometric keys are still encrypted by Keychain (Layer 4) and protected by OS-level ACLs (Layer 3).

Even without TouchID, Secret Wallet provides 5 active security layers -- compared to `.env` files which have zero.

### Threat Mitigations

| Threat | How Secret Wallet Protects You |
|--------|-------------------------------|
| Plaintext credential theft | Keys encrypted in Keychain, never as files |
| Accidental git commit | No credential files exist to commit |
| Malicious npm package | Keychain ACL blocks unauthorized app access |
| Process memory dump | Credentials isolated to child process only |
| Unauthorized access | TouchID/FaceID required (if enabled) |
| Backup/sync exposure | Keychain items flagged device-only (no iCloud) |
| Clipboard sniffing | Auto-clear after 30 seconds (GUI) |

For the full threat model, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Comparison

| | `.env` files | 1Password CLI | Secret Wallet |
|---|---|---|---|
| **Price** | Free | $3/month | **Free** |
| **Account required** | No | Yes (email + master password) | **No** |
| **Setup time** | Create file | Install + sign in + vault setup | **`brew install`** |
| **Encryption** | None | AES-256-GCM (cloud) | **AES-256-GCM (local Keychain)** |
| **Hardware security** | None | None | **Secure Enclave (biometric keys)** |
| **Biometric** | No | App unlock only | **Per-key TouchID** |
| **Process isolation** | No (`dotenv` loads globally) | Partial (`op run`) | **Full (child process only)** |
| **Cross-platform** | Yes | Yes | macOS only |
| **Team sharing** | Copy files | Vault sharing | Not supported |
| **GUI** | No | Separate app | **Built-in** |
| **`.env` migration** | -- | Manual | **`migrate-env.sh` tool** |
| **AI agent plugin** | -- | OpenClaw skill | **OpenClaw plugin** |

**Best for:**
- `.env` files -- quick prototyping, cross-platform teams
- 1Password CLI -- enterprise teams, multi-platform, audit compliance
- **Secret Wallet** -- solo macOS developers who want zero-config hardware security

---

## Architecture

### Project Structure

```
secret-wallet/
├── Sources/
│   ├── SecretWalletCore/            # Shared library (CLI + GUI)
│   │   ├── KeychainManager.swift    # Keychain CRUD + biometric ACL
│   │   ├── MetadataStore.swift      # JSON persistence (thread-safe)
│   │   ├── BiometricService.swift   # TouchID/FaceID detection
│   │   ├── SecretMetadata.swift     # Key metadata model (Codable)
│   │   └── SecretWalletError.swift  # User-friendly error types
│   └── secret-wallet/               # CLI tool
│       ├── SecretWallet.swift       # @main entry, subcommand registry
│       └── Commands/
│           ├── AddCommand.swift     # secret-wallet add
│           ├── GetCommand.swift     # secret-wallet get (--json)
│           ├── ListCommand.swift    # secret-wallet list (--json)
│           ├── RemoveCommand.swift  # secret-wallet remove
│           ├── InjectCommand.swift  # secret-wallet inject
│           ├── StatusCommand.swift  # secret-wallet status
│           ├── InitCommand.swift    # secret-wallet init
│           └── SetupCommand.swift   # secret-wallet setup
├── App/                             # GUI app (separate Package.swift)
│   └── SecretWalletApp/
│       ├── SecretWalletApp.swift    # @main entry point
│       ├── Views/                   # SwiftUI views
│       ├── Services/                # Keychain, Metadata, Biometric
│       └── Models/                  # AIService presets
├── scripts/
│   ├── migrate-env.sh              # .env bulk migration tool
│   ├── setup-shell.sh              # Shell alias installer
│   ├── manual-test.sh              # Integration test suite
│   ├── build-dmg.sh                # DMG packager
│   └── generate-icon.sh            # App icon generator
├── docs/                            # Architecture documentation
├── Package.swift                    # CLI + Core build config
└── CHANGELOG.md
```

### Shared Storage

Both CLI and GUI use the same backend:

| Component | Location | Shared? |
|-----------|----------|---------|
| **Keychain** | macOS Keychain (service: `com.secret-wallet`) | Yes |
| **Metadata** | `~/Library/Application Support/secret-wallet/metadata.json` | Yes |

Keys added in the GUI appear in `secret-wallet list`, and vice versa.

---

## Use Cases

### Next.js / Node.js Project

```bash
# Before: .env.local with 8 plaintext keys
# After:
./scripts/migrate-env.sh .env.local --all
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

### OpenClaw / AI Agents

```bash
secret-wallet add anthropic --env-name ANTHROPIC_API_KEY
secret-wallet inject --only anthropic -- moltbot chat "Hello"
```

Secret Wallet also has an [OpenClaw plugin](https://github.com/baekho-lim/openclaw/tree/main/extensions/secret-wallet) that lets AI agents access keys directly via tool calls.

### Multi-Key Workflows

```bash
secret-wallet add openai --env-name OPENAI_API_KEY
secret-wallet add anthropic --env-name ANTHROPIC_API_KEY
secret-wallet add supabase --env-name SUPABASE_SERVICE_ROLE_KEY
secret-wallet inject --only openai --only anthropic --only supabase -- ./multi-agent-orchestrator.sh
```

### Vercel / CI Deployment

```bash
secret-wallet add vercel-token --env-name VERCEL_TOKEN
secret-wallet inject --only vercel-token -- vercel deploy --prod
```

---

## Roadmap

- [x] **v0.1.0**: CLI MVP (init, add, get, list, remove, inject)
- [x] **v0.2.0**: Shell integration (aliases, tab completion, setup)
- [x] **v0.3.0-alpha**: SwiftUI GUI app + JSON output + status command
- [ ] **v0.3.0**: GUI polish + .dmg distribution
- [ ] **v0.4.0**: `.env` migration CLI subcommand (`secret-wallet import .env`)
- [ ] **v0.5.0**: Multi-profile support (dev/staging/prod namespaces)
- [ ] **v0.6.0**: Secret rotation + expiry alerts
- [ ] **v1.0.0**: Stable release

---

## FAQ

**Q: Do I need TouchID for every `npm run dev`?**
No. TouchID is **optional and per-key**. Keys added without `--biometric` work instantly without any prompt. Only use `--biometric` for high-security keys (production DB, payment API, etc.).

**Q: Why do I get repeated password prompts?**
Usually because `inject` is loading too many secrets or being called repeatedly by scripts/agents. Use filters (`--only`, `--only-env`) so each run touches only the required keys.

**Q: Is it safe without TouchID?**
Yes. Even without biometric, you still get 5 security layers: Keychain encryption (AES-256-GCM), OS-level ACL, process isolation, runtime injection, and FileVault. Biometric-protected keys additionally get Secure Enclave hardware backing. `.env` files have zero of these layers.

**Q: Can the GUI and CLI share keys?**
Yes. Both use the same Keychain service (`com.secret-wallet`) and metadata file.

**Q: How do I use this in `package.json`?**
```json
{ "scripts": { "dev": "secret-wallet inject --only OPENAI_KEY -- next dev" } }
```
Then `npm run dev` works as usual -- no `.env` file needed.

**Q: What about CI/CD (GitHub Actions, Vercel)?**
Secret Wallet is for local development. In CI/CD, use the platform's built-in secret management (GitHub Secrets, Vercel Environment Variables). Your production and development secrets stay separate.

**Q: Can I use this on Linux/Windows?**
Not yet. macOS only. For cross-platform teams, consider 1Password CLI or platform-specific secret managers.

**Q: What happens if I delete Secret Wallet?**
Your keys remain in macOS Keychain. Reinstall Secret Wallet to access them again, or use macOS Keychain Access app to manage them directly.

**Q: How is this different from 1Password?**
1Password is a cloud-based password manager for teams ($3/month, account required). Secret Wallet is a free, local, zero-config tool specifically for developer API keys on macOS. They solve different problems -- Secret Wallet is for developers who don't want to pay for or set up a password manager just to secure their `.env` files.

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet && swift build    # CLI
cd App && swift build              # GUI
```

This project was built with [Claude Code](https://claude.com/claude-code). AI-assisted contributions are encouraged -- just note it in your PR.

---

## License

MIT License -- See [LICENSE](LICENSE) for details.

---

**Author**: [Baekho Lim](https://github.com/baekho-lim) (bh@baekho.io)
