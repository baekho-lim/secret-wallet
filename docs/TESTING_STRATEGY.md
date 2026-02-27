# Testing Strategy

This document defines a practical test path for a mixed Swift project:
- CLI (`Sources/secret-wallet`)
- Shared Core (`Sources/SecretWalletCore`)
- GUI (`App/SecretWalletApp`)

The goal is to keep local feedback fast while preserving release confidence.

## Test Layers

### 1) CLI fast gate (default for most changes)

Use when:
- command behavior changes (`add/get/list/remove/inject`)
- docs/scripts/metadata handling changes
- prompt-frequency mitigation logic changes

Run:

```bash
./scripts/test-cli-fast.sh
```

What it covers:
- release build of CLI binary
- P0 integration suite (`scripts/test-full.sh`)
- key flows including `inject --only`, `--only-env`, `--dry-run`, and conflict handling

### 2) Swift smoke gate (core + app build confidence)

Use when:
- shared core APIs change (`KeychainManager`, `MetadataStore`, `BiometricService`)
- GUI depends on changed core behavior
- release candidate validation

Run:

```bash
./scripts/test-swift-smoke.sh
```

Headless/minimal mode:

```bash
SKIP_GUI=1 ./scripts/test-swift-smoke.sh
```

What it covers:
- Swift toolchain sanity
- core package debug/release build
- `swift test` if/when test targets are added
- GUI package release build (unless skipped)

### 3) Full integration gate (release or risky refactor)

Run:

```bash
./scripts/test-full.sh --full
```

Use for:
- release tags
- authentication / Keychain behavior changes
- migration script changes

### 4) Manual GUI checklist

For visual and UX validation, run:

```bash
open docs/test-gui-checklist.md
```

## Recommended By Change Type

- CLI-only logic change:
  - `./scripts/test-cli-fast.sh`
- Core Swift change affecting CLI + GUI:
  - `./scripts/test-cli-fast.sh`
  - `./scripts/test-swift-smoke.sh`
- Release candidate:
  - `./scripts/test-cli-fast.sh`
  - `./scripts/test-swift-smoke.sh`
  - `./scripts/test-full.sh --full`
  - GUI manual checklist

## Why Swift Validation Feels Expensive (and how to reduce pain)

Common pain points:
- Keychain/biometric behavior is environment dependent
- GUI verification is slower than CLI
- release pipeline mixes CLI + GUI packaging

Practical mitigation:
1. Keep `inject` tests in non-biometric path by default (`--only` + non-biometric secrets)
2. Use tiered gates:
   - fast CLI gate every change
   - Swift smoke for core/UI touching changes
   - full integration only for risky or release changes
3. Decouple release tracks:
   - CLI-only tags for rapid shipping
   - full GUI+CLI tags for complete desktop release

