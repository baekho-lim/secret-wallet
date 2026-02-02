---
name: Feature Request
about: Suggest a new feature or enhancement
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## 💡 Feature Description

A clear and concise description of the feature you'd like to see.

---

## 🎯 Problem Statement

What problem does this feature solve?

Example:
> Currently, users must manually rotate secrets every 90 days. An automatic rotation reminder would reduce security risks.

---

## 💻 Proposed Solution

How should this feature work?

Example:
```bash
# Proposed command
secret-wallet add my-key --expire-in 90d

# After 90 days
secret-wallet list
# Output: ⚠️ my-key expires in 3 days
```

---

## 🔄 Alternatives Considered

Have you considered other approaches?

---

## 🔒 Security Considerations

Does this feature have security implications?

- [ ] This feature handles credentials
- [ ] This feature requires biometric auth
- [ ] This feature modifies Keychain ACLs
- [ ] No security impact

---

## 🌍 Use Case

Who would benefit from this feature?

- [ ] OpenClaw users
- [ ] AI agent developers
- [ ] Security researchers
- [ ] General macOS users

---

## 📚 Additional Context

Any mockups, diagrams, or references?

---

## ✅ Checklist

- [ ] I have searched existing issues for duplicates
- [ ] This aligns with Secret Wallet's security-first philosophy
- [ ] I am willing to contribute a PR (optional)
