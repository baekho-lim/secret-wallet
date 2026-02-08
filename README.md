# Secret Wallet 🔐

> Secure credential management for AI agents using macOS Keychain

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2012+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Secret Wallet is a command-line tool that leverages macOS Keychain to securely store and inject API credentials for AI agents like OpenClaw (Moltbot), preventing credential exposure in configuration files or environment variables.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Solution: Secret Agent Pattern](#solution-secret-agent-pattern)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Security Model](#security-model)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## Problem Statement

AI agents like OpenClaw require API credentials (OpenAI, Anthropic, etc.) stored in plaintext configuration files:

```json
{
  "apiKey": "sk-proj-xxxxxxxxxxxxx"  // ❌ Plaintext exposure
}
```

**Risks:**
- ❌ Credentials visible in filesystem
- ❌ Accidental git commits
- ❌ Process memory dumps
- ❌ Backup/sync services exposure

---

## Solution: Secret Agent Pattern

Secret Wallet implements a **Defense in Depth** security model:

```
┌─────────────────────────────────────────┐
│  Layer 7: Process Isolation            │ ← Env vars only in child process
├─────────────────────────────────────────┤
│  Layer 6: Runtime Injection             │ ← Just-in-time credential delivery
├─────────────────────────────────────────┤
│  Layer 5: Biometric Authentication      │ ← TouchID/FaceID verification
├─────────────────────────────────────────┤
│  Layer 4: Encrypted Storage             │ ← macOS Keychain encryption
├─────────────────────────────────────────┤
│  Layer 3: OS-Level Access Control       │ ← Keychain ACL enforcement
├─────────────────────────────────────────┤
│  Layer 2: Secure Enclave (T2/M1 chips) │ ← Hardware-backed encryption
├─────────────────────────────────────────┤
│  Layer 1: Physical Device Security      │ ← Device encryption (FileVault)
└─────────────────────────────────────────┘
```

**Key Benefits:**
- ✅ Zero plaintext credentials in config files
- ✅ Biometric authentication for sensitive secrets
- ✅ Credentials never touch disk (except encrypted Keychain)
- ✅ Process isolation (env vars only in target process)

---

## Features

### Core Commands

| Command | Description | Biometric Support |
|---------|-------------|-------------------|
| `init` | Verify Keychain access | ❌ |
| `add <name>` | Store a secret | ✅ Optional (`--biometric`) |
| `get <name>` | Retrieve a secret | ✅ If enabled |
| `list` | List all secrets (names only) | ❌ |
| `remove <name>` | Delete a secret | ✅ If enabled |
| `inject -- <cmd>` | Inject secrets as env vars and run command | ✅ If enabled |

### Security Features

- **Biometric Authentication**: TouchID/FaceID for sensitive credentials
- **Keychain Integration**: OS-level encrypted storage
- **Metadata Separation**: Secret names stored separately from values
- **Process Isolation**: Credentials only in child process memory
- **Audit Trail**: Keychain access logs via Console.app

---

## Installation

### Prerequisites

- macOS 12.0 or later
- Xcode Command Line Tools

### Build from Source

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet
swift build -c release
cp .build/release/secret-wallet /usr/local/bin/
```

### Verify Installation

```bash
secret-wallet --version
# Output: 0.1.0
```

---

## Quick Start

### 1. Initialize

```bash
secret-wallet init
```

**Output:**
```
🔐 Secret Wallet 초기화 중...
✅ macOS Keychain 연동 완료
✅ TouchID/FaceID 사용 가능 (비밀 추가 시 활성화)
```

### 2. Add Secrets

#### Standard Secret (No Biometric)
```bash
secret-wallet add OPENAI_API_KEY
# Paste your API key when prompted
```

#### High-Security Secret (Biometric Required)
```bash
secret-wallet add ANTHROPIC_API_KEY --biometric --env-name ANTHROPIC_API_KEY
# TouchID/FaceID prompt appears on access
```

### 3. List Secrets

```bash
secret-wallet list
```

**Output:**
```
저장된 비밀 목록:

  🔓 OPENAI_API_KEY → $OPENAI_API_KEY
  🔐 ANTHROPIC_API_KEY → $ANTHROPIC_API_KEY
```

### 4. Inject and Run

```bash
secret-wallet inject -- moltbot chat "Hello"
```

**What happens:**
1. Retrieves all secrets from Keychain
2. Sets environment variables (e.g., `ANTHROPIC_API_KEY=sk-ant-xxx`)
3. Spawns `moltbot chat "Hello"` with injected env vars
4. Credentials **never** touch disk or parent process

---

## Usage

### Command Reference

#### `init` - Initialize Keychain Access

```bash
secret-wallet init
```

Verifies read/write access to macOS Keychain.

---

#### `add` - Store a Secret

```bash
secret-wallet add <name> [--biometric] [--env-name <VAR_NAME>]
```

**Arguments:**
- `<name>`: Unique identifier for the secret
- `--biometric`: Require TouchID/FaceID for retrieval
- `--env-name <VAR_NAME>`: Environment variable name for `inject` command

**Example:**
```bash
# Add OpenAI API key with biometric protection
secret-wallet add openai-key --biometric --env-name OPENAI_API_KEY

# Paste key when prompted:
# sk-proj-xxxxxxxxxxxxxxxx
```

---

#### `get` - Retrieve a Secret

```bash
secret-wallet get <name>
```

**Example:**
```bash
secret-wallet get openai-key
# TouchID/FaceID prompt appears (if biometric was enabled)
# Output: sk-proj-xxxxxxxxxxxxxxxx
```

---

#### `list` - List All Secrets

```bash
secret-wallet list
```

**Output:**
```
저장된 비밀 목록:

  🔐 openai-key → $OPENAI_API_KEY
  🔐 anthropic-key → $ANTHROPIC_API_KEY
  🔓 github-token → $GITHUB_TOKEN
```

---

#### `remove` - Delete a Secret

```bash
secret-wallet remove <name>
```

**Example:**
```bash
secret-wallet remove openai-key
# TouchID/FaceID prompt appears (if biometric was enabled)
# Output: ✅ 'openai-key' 삭제됨
```

---

#### `inject` - Inject Environment Variables

```bash
secret-wallet inject -- <command> [args...]
```

**How it works:**
1. Reads metadata from `~/Library/Application Support/secret-wallet/metadata.json`
2. Retrieves all secrets from Keychain (with biometric auth if needed)
3. Sets environment variables in child process
4. Executes `<command>` with injected variables
5. Credentials destroyed when child process exits

**Example:**
```bash
# Run Moltbot with injected credentials
secret-wallet inject -- moltbot chat "Explain quantum computing"

# Run custom script
secret-wallet inject -- python train_model.py

# Run with existing env vars preserved
export MODEL=gpt-4
secret-wallet inject -- moltbot --model $MODEL chat "Hello"
```

**Security Note:**
- Parent process (`secret-wallet`) **never** has credentials in environment
- Credentials only exist in child process (`moltbot`) memory
- No credential leakage to shell history or logs

---

## Security Model

### Threat Model

| Threat | Mitigation |
|--------|------------|
| **Plaintext credential theft** | Encrypted Keychain storage |
| **Accidental git commit** | Credentials never in filesystem |
| **Process memory dump** | Process isolation + ephemeral env vars |
| **Unauthorized access** | Biometric authentication (TouchID/FaceID) |
| **Backup exposure** | Keychain excluded from iCloud backups by default |
| **Malware keylogging** | Hardware-backed Secure Enclave (T2/M1 chips) |

### Defense Layers Explained

#### Layer 1-2: Physical + Hardware
- **FileVault**: Full-disk encryption (AES-256)
- **Secure Enclave**: Crypto keys never leave hardware (T2/M1/M2 chips)

#### Layer 3-4: OS + Storage
- **Keychain ACL**: Only authorized apps can access secrets
- **AES-256-GCM**: Encryption at rest

#### Layer 5-6: Application
- **Biometric Auth**: TouchID/FaceID verification before retrieval
- **Runtime Injection**: Credentials loaded just-in-time

#### Layer 7: Process
- **Memory Isolation**: Secrets only in child process memory space
- **Ephemeral Credentials**: Destroyed when process exits

---

## Architecture

### File Structure

```
secret-wallet/
├── Sources/
│   └── secret-wallet/
│       └── main.swift          # 410 lines
├── Package.swift               # Swift Package Manager config
└── ~/Library/Application Support/
    └── secret-wallet/
        └── metadata.json       # Secret names + env var mapping
```

### Metadata Schema

```json
[
  {
    "name": "openai-key",
    "envName": "OPENAI_API_KEY",
    "biometric": true
  }
]
```

### Keychain Storage

| Service | Account | Value | Access Control |
|---------|---------|-------|----------------|
| `com.secret-wallet` | `openai-key` | `sk-proj-xxx...` | Biometric (if enabled) |
| `com.secret-wallet` | `github-token` | `ghp_xxx...` | Password only |

**Service Name**: `com.secret-wallet`
**Account**: Secret name (e.g., `openai-key`)

---

## Use Cases

### 1. OpenClaw (Moltbot) Integration

**Before (Insecure):**
```json
// ~/.openclaw/agents/main/agent/auth-profiles.json
{
  "profiles": {
    "anthropic": {
      "type": "token",
      "token": "sk-ant-xxxxxxxx"  // ❌ Plaintext
    }
  }
}
```

**After (Secure):**
```bash
# Store credential securely
secret-wallet add anthropic-key --biometric --env-name ANTHROPIC_API_KEY

# Run Moltbot with injected credential
secret-wallet inject -- moltbot chat "Hello world"
```

**Moltbot reads from environment:**
```javascript
// Moltbot checks ANTHROPIC_API_KEY first
const apiKey = process.env.ANTHROPIC_API_KEY || readFromAuthProfiles()
```

---

### 2. Multi-Agent Workflow

```bash
# Store multiple API keys
secret-wallet add openai --biometric --env-name OPENAI_API_KEY
secret-wallet add anthropic --biometric --env-name ANTHROPIC_API_KEY
secret-wallet add deepseek --biometric --env-name DEEPSEEK_API_KEY

# Run agent with all credentials injected
secret-wallet inject -- ./multi-agent-orchestrator.sh
```

---

### 3. CI/CD Pipeline (Local Dev)

```bash
# Development
secret-wallet add github-token --env-name GITHUB_TOKEN
secret-wallet inject -- gh pr create --title "Feature X"

# Deployment
secret-wallet add vercel-token --env-name VERCEL_TOKEN
secret-wallet inject -- vercel deploy --prod
```

---

## Comparison

| Solution | Storage | Biometric | Process Isolation | Ease of Use |
|----------|---------|-----------|-------------------|-------------|
| **Plaintext Config** | ❌ Filesystem | ❌ | ❌ | ✅✅✅ |
| **Environment Variables** | ❌ Shell history | ❌ | ❌ | ✅✅ |
| **1Password CLI** | ✅ Encrypted vault | ✅ | ⚠️ Partial | ✅ |
| **Secret Wallet** | ✅ Keychain | ✅ | ✅ | ✅✅ |

---

## Roadmap

- [ ] **v0.2.0**: Automatic secret rotation (notify when key expires)
- [ ] **v0.3.0**: Multi-profile support (dev/staging/prod)
- [ ] **v0.4.0**: Audit logging (track secret access)
- [ ] **v0.5.0**: Linux support (libsecret integration)
- [ ] **v1.0.0**: Browser extension for password autofill

---

## Contributing

Contributions are welcome! This project originated as a security enhancement proposal for [OpenClaw](https://github.com/transitive-bullshit/OpenClaw).

### Development Setup

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet
swift build
swift run secret-wallet init
```

### Testing

```bash
# Run unit tests (TODO)
swift test

# Manual testing
swift run secret-wallet add test-key
swift run secret-wallet get test-key
swift run secret-wallet remove test-key
```

### Code Style

- Swift 5.9+ with strict concurrency checking
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Maximum 80 characters per line
- Comprehensive inline documentation

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- **OpenClaw Team**: Inspiration for AI agent security
- **Apple Security Framework**: Keychain and biometric APIs
- **Swift Argument Parser**: Elegant CLI interface

---

## Contact

**Author**: Baekho Lim
**Email**: bh@baekho.io
**GitHub**: [@baekho-lim](https://github.com/baekho-lim)

---

## FAQ

### Q: Why not use environment variables?

**A:** Environment variables are visible to:
- Shell history (`~/.zsh_history`)
- Parent processes (`ps eww <pid>`)
- Crash dumps and logs

Secret Wallet ensures credentials only exist in the target process memory.

---

### Q: Can I use this on Linux?

**A:** Not yet. macOS Keychain is required. Linux support (via `libsecret`) is planned for v0.5.0.

---

### Q: What happens if I lose my TouchID data?

**A:** Secrets remain in Keychain but become inaccessible. You'll need to:
1. Re-enroll biometrics in System Preferences
2. Or remove secrets manually via Keychain Access.app

---

### Q: How do I migrate from plaintext config?

```bash
# 1. Store secret securely
secret-wallet add my-api-key --biometric --env-name API_KEY

# 2. Remove from plaintext config
sed -i '' '/apiKey/d' config.json

# 3. Update application to check env var first
export API_KEY=$(secret-wallet get my-api-key)
./my-app
```

---

### Q: Is this more secure than 1Password CLI?

**A:** Both are secure. Secret Wallet offers:
- ✅ Native macOS integration (no third-party dependency)
- ✅ Process isolation (credentials never in parent process)
- ❌ No cross-platform sync (1Password advantage)

Choose based on your threat model.

---

**Made with ❤️ for the AI agent security community**
