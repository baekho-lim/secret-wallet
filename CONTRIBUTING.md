# Contributing to Secret Wallet

Thank you for your interest in contributing to Secret Wallet! This project aims to improve AI agent security through macOS Keychain integration.

---

## 🚀 Quick Links

- **GitHub**: https://github.com/baekho-lim/secret-wallet
- **Issues**: [Bug Reports](https://github.com/baekho-lim/secret-wallet/issues/new?template=bug_report.md) | [Feature Requests](https://github.com/baekho-lim/secret-wallet/issues/new?template=feature_request.md)
- **Security**: See [SECURITY.md](SECURITY.md) for vulnerability reporting
- **Discussions**: [GitHub Discussions](https://github.com/baekho-lim/secret-wallet/discussions)

---

## 🤝 How to Contribute

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

- macOS 12.0 or later
- Xcode Command Line Tools
- Swift 5.9+

### Clone and Build

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet
swift build
swift run secret-wallet init
```

### Run Tests

```bash
swift test
```

### Manual Testing

```bash
# Build and test locally
swift build
.build/debug/secret-wallet init
.build/debug/secret-wallet add test-key
.build/debug/secret-wallet get test-key
.build/debug/secret-wallet remove test-key
```

---

## 🎯 Current Focus & Roadmap

### Short-term (v0.2.0)
- [ ] Automatic secret rotation
- [ ] Audit logging (track access)
- [ ] OpenClaw native integration

### Medium-term (v0.3.0)
- [ ] Multi-profile support (dev/staging/prod)
- [ ] Secret expiration warnings
- [ ] Import/export (encrypted backup)

### Long-term (v1.0.0)
- [ ] Linux support (libsecret)
- [ ] Windows support (Credential Manager)
- [ ] Browser extension integration

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
- [OpenClaw](https://github.com/transitive-bullshit/OpenClaw) - Target integration platform
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
