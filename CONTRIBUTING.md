# Contributing to Secret Wallet

Thank you for your interest in contributing to Secret Wallet! This project aims to improve AI agent security through macOS Keychain integration.

---

## 🚀 Quick Links

- **GitHub**: https://github.com/baekho-lim/secret-wallet
- **Issues**: [Bug Reports](https://github.com/baekho-lim/secret-wallet/issues/new?template=bug_report.md) | [Feature Requests](https://github.com/baekho-lim/secret-wallet/issues/new?template=feature_request.md)
- **Security**: See [SECURITY.md](SECURITY.md) for vulnerability reporting
- **Discussions**: [GitHub Discussions](https://github.com/baekho-lim/secret-wallet/discussions)
- **PR Process**: [docs/PR_PRECHECK_PROCESS.md](docs/PR_PRECHECK_PROCESS.md)
- **Repo Lanes**: [docs/OPENCLAW_REPO_LANES.md](docs/OPENCLAW_REPO_LANES.md)
- **Recent PR Retro**: [docs/PR_RETRO_OPENCLAW_2026-02-27.md](docs/PR_RETRO_OPENCLAW_2026-02-27.md)

---

## 🤝 How to Contribute

### Repository Lanes (Fixed)

Use this routing rule before writing code:

- Secret Wallet CLI/Swift/docs: `baekho-lim/secret-wallet` repository
- OpenClaw plugin package/release: `baekho-lim/openclaw-secret-wallet` repository
- OpenClaw upstream PR prep: `baekho-lim/openclaw-fresh` fork repository

Full policy and sync flow:
- [docs/OPENCLAW_REPO_LANES.md](docs/OPENCLAW_REPO_LANES.md)

### 1. Found a Bug?

Use our [Bug Report template](https://github.com/baekho-lim/secret-wallet/issues/new?template=bug_report.md) to report issues.

**Include**:
- macOS version (e.g., macOS 14.2)
- Swift version (`swift --version`)
- Steps to reproduce
- Expected vs actual behavior
- Logs or screenshots

### 2. Have a Feature Idea?

Open a [Feature Request](https://github.com/baekho-lim/secret-wallet/issues/new?template=feature_request.md).

**Consider**:
- Does it align with the security-first philosophy?
- Would it benefit OpenClaw or other AI agents?
- Is it feasible on macOS Keychain?

### 3. Security Vulnerability?

**DO NOT** open a public issue. Follow the responsible disclosure process in [SECURITY.md](SECURITY.md).

Email: bh@baekho.io with subject `[SECURITY] secret-wallet vulnerability`

---

## 🤖 AI-Generated / AI-Assisted Contributions Welcome

This project was built with **Claude Code** assistance. AI-generated contributions are encouraged!

### Guidelines for AI-Coded PRs

If you used AI assistance (Claude, ChatGPT, Copilot, etc.), please:

1. **Mark it in the PR title**
   - Example: `[AI] Add secret rotation feature`
   - Or use tags: `[Claude]`, `[GPT]`, `[Copilot]`

2. **Describe testing coverage**
   - "Tested manually on macOS 14"
   - "Unit tests added (80% coverage)"
   - "Needs integration testing"

3. **Share prompts (optional but helpful)**
   ```
   Example prompt:
   "Implement automatic credential rotation with 90-day expiry.
   Use macOS Keychain metadata to track creation dates."
   ```

4. **Confirm understanding**
   - Review the generated code
   - Ensure it matches security principles (Defense in Depth)
   - Verify no hardcoded secrets or vulnerabilities

**Why we welcome AI contributions**:
- Faster iteration on security features
- Diverse problem-solving approaches
- Transparency builds trust

---

## 📋 Pull Request Checklist

Before submitting a PR, ensure:

### Preflight (Required)
- [ ] Run `./scripts/pr-preflight.sh <cli|swift|full>` for your change scope
- [ ] Optionally validate commit format locally: `./scripts/pr-preflight.sh cli --check-commit`

### Code Quality
- [ ] Code builds successfully (`swift build`)
- [ ] All tests pass (`swift test`)
- [ ] Code follows Swift style guidelines
- [ ] No compiler warnings

### Security Review
- [ ] No hardcoded secrets (API keys, passwords)
- [ ] Input validation for user-provided data
- [ ] Keychain operations use proper ACLs
- [ ] Error messages don't leak sensitive info
- [ ] Review [SECURITY.md](SECURITY.md) checklist

### Documentation
- [ ] Update README.md if adding features
- [ ] If README.md changed, sync all translated README files
- [ ] Run `./scripts/check-readme-i18n.sh`
- [ ] Add inline comments for complex logic
- [ ] Update CHANGELOG.md (if applicable)

### Testing
- [ ] Unit tests for new functions
- [ ] Manual testing on macOS 12+ (if available)
- [ ] Edge cases covered (empty input, invalid keys, etc.)

### Git Hygiene
- [ ] Clear commit messages (see below)
- [ ] Squash commits if needed (keep history clean)
- [ ] No merge conflicts

---

## 📝 Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) standard:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code refactoring (no behavior change)
- `test`: Adding tests
- `chore`: Build process, dependencies
- `ci`: CI pipeline/workflow changes
- `build`: Build system or packaging changes
- `perf`: Performance improvements

**Required rule**:
- Use only the format above. Custom prefixes like `[~]`, `[^]`, `[+]` are not allowed.
- Keep subject imperative and concise (`fix(inject): reduce auth prompts with --only`).

**Validation**:
- PR title and commit messages are validated in CI.
- Non-conforming messages must be rewritten before merge.

**Examples**:
```
feat(keychain): Add biometric authentication for high-security secrets

Implements TouchID/FaceID verification before retrieving secrets
marked with --biometric flag. Uses LocalAuthentication framework
with LAPolicy.deviceOwnerAuthenticationWithBiometrics.

Closes #12
```

```
fix(inject): Prevent credential leakage to parent process

Environment variables are now set only in child process memory.
Parent process (secret-wallet) never has credentials in its env.

Security impact: Mitigates process memory dump attacks.
```

---

## 🏗️ Development Setup

### Prerequisites

- macOS 13.0 or later
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 5.9+

### Clone and Build

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet
```

**CLI tool:**
```bash
swift build
swift run secret-wallet init
```

**GUI app:**
```bash
cd App
swift build
open .build/debug/SecretWalletApp
```

### Run Tests

```bash
# Integration tests (CLI)
./scripts/manual-test.sh

# Manual testing
swift run secret-wallet add test-key
swift run secret-wallet get test-key
swift run secret-wallet remove test-key
```

### Project Structure

```
secret-wallet/
├── Sources/secret-wallet/main.swift   # CLI tool
├── App/                                # GUI app (separate Package.swift)
│   ├── Package.swift
│   └── SecretWalletApp/
│       ├── Views/                      # SwiftUI views
│       ├── Services/                   # Keychain, Metadata, Biometric
│       └── Models/                     # Data models
├── scripts/                            # Shell scripts
└── docs/                               # Architecture docs
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed technical design.

---

## 🎯 Current Focus & Roadmap

### Done
- [x] CLI MVP (init, add, get, list, remove, inject)
- [x] Shell integration (aliases, tab completion)
- [x] SwiftUI GUI app (macOS)

### Next
- [ ] GUI polish + .dmg distribution
- [ ] Multi-profile support (dev/staging/prod)
- [ ] Windows support (Tauri + Credential Manager)

**Want to work on something?** Check [Good First Issues](https://github.com/baekho-lim/secret-wallet/labels/good%20first%20issue).

---

## 🧪 Testing Guidelines

### Test Coverage Target: 80%+

**Required tests**:
- Unit tests for KeychainManager
- Unit tests for MetadataStore
- Integration tests for CLI commands
- Edge case tests (empty input, missing keys)

**Optional but encouraged**:
- Security tests (injection attacks, path traversal)
- Performance tests (Keychain latency)
- Biometric simulation tests

---

## 🔒 Security Principles

All contributions must adhere to:

### Defense in Depth
- Never store plaintext credentials
- Use Keychain ACLs (biometric when possible)
- Isolate credentials to child process memory
- Validate all user input

### Threat Model Awareness
- Assume attacker has physical device access
- Assume attacker can dump process memory
- Assume attacker can read filesystem

### Secure Defaults
- Biometric auth recommended (not required)
- Metadata stored separately from secrets
- No logging of credential values

---

## 📚 Resources

### Relevant Documentation
- [macOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [LocalAuthentication Framework](https://developer.apple.com/documentation/localauthentication)
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)

### Related Projects
- [OpenClaw](https://github.com/openclaw/openclaw) - Target integration platform
- [Moltbot](https://github.com/pjgeorg/moltbot) - AI agent framework

---

## 🙏 Acknowledgments

This project originated as a security enhancement proposal for OpenClaw. Special thanks to:
- **OpenClaw maintainers** for inspiring AI agent security improvements
- **Claude Code** for AI-assisted development
- **Swift community** for excellent tooling

---

## 📧 Contact

**Maintainer**: Baekho Lim
- Email: bh@baekho.io
- GitHub: [@baekho-lim](https://github.com/baekho-lim)

For general questions, use [GitHub Discussions](https://github.com/baekho-lim/secret-wallet/discussions).
For security issues, see [SECURITY.md](SECURITY.md).

---

**Thank you for contributing to a more secure AI ecosystem!** 🔐
