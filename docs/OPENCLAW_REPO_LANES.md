# OpenClaw Repo Lanes (Fixed Model)

This project uses a fixed two-lane model for OpenClaw plugin work.

## Repositories and Roles

1. Source package repo (publish lane)
   - Repo: `https://github.com/baekho-lim/openclaw-secret-wallet`
   - Purpose: plugin package source of truth, npm release, standalone docs/tests

2. OpenClaw fork repo (upstream PR lane)
   - Repo: `https://github.com/baekho-lim/openclaw-fresh`
   - Purpose: prepare PR-ready changes against OpenClaw monorepo

3. OpenClaw upstream (target)
   - Repo: `https://github.com/openclaw/openclaw`
   - Purpose: final community review and merge target

## Hard Rules

1. Plugin feature/fix starts in the source package repo first.
2. Upstream PR work is done only in the fork lane.
3. Never commit directly to upstream.
4. Keep code PR and docs/community-listing PR split.
5. Use `codex/*` branch names in the fork lane.

## Why This Model

- Prevents giant rebase conflicts from long-lived mixed-history branches.
- Separates release concerns (npm package) from upstream integration concerns.
- Keeps review scope small and easier for maintainers.

## Sync Flow (Package -> Fork -> Upstream)

1. Implement and validate in `openclaw-secret-wallet`.
2. Mirror plugin changes into `openclaw-fresh/extensions/secret-wallet`.
3. Apply monorepo-specific adjustments only in fork lane when required.
4. Open PR from fork branch to `openclaw/openclaw:main`.

## Known Monorepo vs Standalone Differences

These differences can be intentional and must be verified when syncing:

1. `openclaw.extensions` entry
   - standalone package: often `./dist/index.js`
   - monorepo integration: may require source entry during validation phases
2. Packaging contents (`files`)
3. Type resolution strategy for `openclaw/plugin-sdk`

## PR Checklist (Lane Gate)

- [ ] I know which lane this change belongs to (package or fork).
- [ ] Branch is based on latest `main` of the target lane.
- [ ] Scope is split (code vs docs/community listing).
- [ ] Local preflight passed for the lane.
- [ ] PR description includes root cause, fix, and validation evidence.
