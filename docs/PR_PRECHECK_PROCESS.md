# PR Precheck Process (Internal, v1)

Use this before opening any PR to reduce CI churn and review turnaround time.

## 0) Choose The Correct Lane First

Before coding, decide the target lane:

1. Secret Wallet core lane
   - repo: `baekho-lim/secret-wallet`
   - scope: CLI/Swift/GUI/docs for Secret Wallet
2. Plugin source package lane
   - repo: `baekho-lim/openclaw-secret-wallet`
   - scope: plugin package source, npm release
3. OpenClaw fork PR lane
   - repo: `baekho-lim/openclaw-fresh`
   - scope: upstream PR-ready integration in monorepo

Reference:
- [docs/OPENCLAW_REPO_LANES.md](./OPENCLAW_REPO_LANES.md)

## 1) Start Clean From Upstream

1. Sync upstream first.
2. Create a new branch from upstream `main` (or target base).
3. Use branch names with `codex/` prefix.

Why:
- Prevents large rebase conflicts and hidden drift from old/local history.

## 2) Split Scope Early

1. Keep code changes and docs/community listing changes in separate PRs.
2. Keep PRs small enough to explain in one screen.

Why:
- Smaller scope speeds CI and review, and isolates failures.

## 3) Run Local Preflight (Secret Wallet)

Choose mode by impact:

- CLI-only changes:
  - `./scripts/pr-preflight.sh cli`
- Core/Swift/GUI-related changes:
  - `./scripts/pr-preflight.sh swift`
- Release candidate or risky refactor:
  - `./scripts/pr-preflight.sh full`

Optional commit format gate:
- `./scripts/pr-preflight.sh cli --check-commit`

## 4) Run Local Preflight (OpenClaw Plugin in Monorepo)

From OpenClaw workspace:

```bash
pnpm --filter @baekho-lim/openclaw-secret-wallet clean
pnpm --filter @baekho-lim/openclaw-secret-wallet test
pnpm --filter @baekho-lim/openclaw-secret-wallet build
pnpm --filter @baekho-lim/openclaw-secret-wallet pack:smoke
pnpm vitest run --config vitest.unit.config.ts src/config/config.plugin-validation.test.ts src/config/config.nix-integration-u3-u5-u9.test.ts
```

## 5) Enforce Standards Before Push

1. Conventional Commits only:
   - `type(scope): subject`
   - allowed type: `feat|fix|docs|refactor|test|chore|ci|build|perf`
2. If `README.md` changed, sync all translated READMEs and run:
   - `./scripts/check-readme-i18n.sh`
3. Ensure PR body includes:
   - problem
   - root cause
   - fix
   - validation evidence
4. Confirm lane routing:
   - package changes are in package lane
   - upstream integration diffs are in fork lane

## 6) CI Triage Quick Map

- Failing config/plugin validation after plugin edits:
  - check extension entry path and build-time assumptions first
- Sudden repo-wide TS failures:
  - check for global `tsconfig` path overrides or ambient module shadowing
- Massive rebase conflicts:
  - verify branch base and whether history came from forked upstream

## 7) Go/No-Go Checklist

- [ ] Scope split is correct (code vs docs)
- [ ] Local preflight passed for the target impact level
- [ ] Commit/PR title format is compliant
- [ ] CI critical checks are green
- [ ] Rollback plan (or revert commit) is clear
