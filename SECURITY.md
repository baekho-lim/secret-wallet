# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

---

## Reporting a Vulnerability

**DO NOT** open public GitHub issues for security vulnerabilities.

### Responsible Disclosure Process

1. **Email**: bh@baekho.io
2. **Subject**: `[SECURITY] secret-wallet vulnerability`
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact (credential leakage, privilege escalation, etc.)
   - Affected versions
   - Suggested fix (if available)

### Response Timeline

- **Initial response**: Within 48 hours
- **Triage**: Within 5 business days
- **Fix timeline**: Depends on severity
  - Critical: 1-7 days
  - High: 7-14 days
  - Medium: 14-30 days
  - Low: Best effort

### Disclosure Policy

- **Embargo period**: 90 days (or until patch is released)
- **Credit**: Security researchers will be acknowledged in CHANGELOG
- **CVE assignment**: For critical vulnerabilities affecting multiple users

---

## Security Principles

Secret Wallet is designed with **Defense in Depth**:

### 1. Zero Plaintext Credentials
- No secrets in configuration files
- No secrets in environment variables (parent process)
- No secrets in logs or error messages

### 2. Hardware-Backed Security
- Secure Enclave (T2/M1/M2 chips)
- Biometric authentication (TouchID/FaceID)
- Keychain encryption (AES-256-GCM)

### 3. Process Isolation
- Credentials only in child process memory
- Parent process never has secrets in environment
- Ephemeral credential lifecycle

### 4. Access Control
- Keychain ACLs (biometric policy)
- OS-level permission enforcement
- User consent required for access

---

## Threat Model

### In-Scope Threats

| Threat | Mitigation |
|--------|------------|
| **Plaintext credential theft** | Keychain encryption |
| **Accidental git commit** | No credentials in filesystem |
| **Process memory dump** | Process isolation + ephemeral env vars |
| **Malware keylogging** | Hardware Secure Enclave (biometric) |
| **Physical device theft** | Biometric authentication required |
| **Backup exposure** | Keychain excluded from iCloud by default |
| **Supply chain attack** | Swift Package Manager lock file |

### Out-of-Scope Threats

- **Physical coercion** (forcing user to unlock with biometrics)
- **Compromised macOS kernel** (assumes trusted OS)
- **Hardware implants** (assumes trusted hardware)
- **Social engineering** (user tricked into revealing secrets)

---

## Known Security Considerations

### 1. Biometric Bypass on Stolen Devices

**Issue**: If an attacker steals a device and can unlock biometrics (e.g., forced fingerprint), they can access secrets.

**Mitigation**:
- User should enable FileVault (full-disk encryption)
- Lost Mode should be activated via Find My
- Secrets should be rotated if device is compromised

### 2. Keychain Access from Same User

**Issue**: Any process running as the same user can attempt Keychain access.

**Mitigation**:
- Biometric-protected secrets require TouchID per access
- Keychain Access.app can be used to review ACLs
- macOS sandboxing limits cross-app access

### 3. Metadata Leakage

**Issue**: Secret names are stored in `~/.secret-wallet/metadata.json` in plaintext.

**Mitigation**:
- Metadata reveals only names (e.g., "openai-key"), not values
- File permissions: `chmod 600` (user-only read/write)
- Future: Encrypt metadata with device-specific key

### 4. Child Process Memory Dump

**Issue**: Attacker with root access can dump child process memory and extract credentials.

**Mitigation**:
- Requires root or debugger attachment (needs SIP bypass)
- Credentials exist only during child process lifetime
- Future: Use `mlock()` to prevent swapping to disk

---

## Security Checklist for Contributors

Before submitting a PR with security implications:

- [ ] **No hardcoded secrets** (API keys, passwords, tokens)
- [ ] **Input validation** (sanitize user input, prevent injection)
- [ ] **Keychain ACLs** (use biometric policy where appropriate)
- [ ] **Error handling** (no secrets in error messages or logs)
- [ ] **Process isolation** (credentials only in child process)
- [ ] **Audit logging** (log access patterns, not values)
- [ ] **Dependency review** (check Swift packages for vulnerabilities)

---

## Security Audit History

| Date | Auditor | Scope | Findings |
|------|---------|-------|----------|
| 2026-02-02 | Self (Baekho Lim) | Initial design review | See [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md) |

*External audits welcome. Contact bh@baekho.io.*

---

## Related Security Resources

### Official Documentation
- [macOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [Keychain Services Programming Guide](https://developer.apple.com/documentation/security/keychain_services)
- [Local Authentication Framework](https://developer.apple.com/documentation/localauthentication)

### Industry Standards
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)
- [NIST SP 800-63B: Digital Identity Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)

---

## Security Contact

**Primary**: bh@baekho.io
**PGP Key**: (Coming soon)

For non-security issues, use [GitHub Issues](https://github.com/baekho-lim/secret-wallet/issues).

---

**Last updated**: 2026-02-02
