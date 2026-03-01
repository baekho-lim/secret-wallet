# PR Retrospective: OpenClaw Plugin Contribution (2026-02-27)

## Scope

- Code PR: `openclaw/openclaw#28462`
- Docs PR: `openclaw/openclaw#28464`

## What Broke, Why, and How We Fixed It

1. Rebase exploded with thousands of conflicts.
Cause:
- Work started from a copied repository instead of a clean fork tracking upstream history.
Fix:
- Created a fresh fork from upstream `main`, replayed only required commits, and split code/docs PRs.

2. Repo-wide TypeScript failures appeared in unrelated areas.
Cause:
- Local module override (`types/openclaw-plugin-sdk.d.ts`) plus `tsconfig` path alias shadowed `openclaw/plugin-sdk`.
Fix:
- Removed the override and path mapping; used local structural typing in the plugin entry.

3. Windows config/plugin validation tests failed.
Cause:
- Monorepo plugin discovery runs before build; extension entry pointed to `./dist/index.js` which does not exist yet in that phase.
Fix:
- Switched monorepo extension entry to `./index.ts`.
- Kept `dist`-based packaging behavior in the standalone plugin repository.

## Outcome

- Both PRs are open, clean, and CI-green.
- Windows test shards that were pending/failing now pass.

## Guardrails For Next PR

- Always branch from a fresh fork synced with upstream `main`.
- Do not add repo-wide module overrides unless strictly required and scoped.
- Keep monorepo runtime entry and standalone package entry rules separate.
- Split code PR and docs/community PR when scope is mixed.
- Run the preflight process in [docs/PR_PRECHECK_PROCESS.md](./PR_PRECHECK_PROCESS.md) before opening PR.
