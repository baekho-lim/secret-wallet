## Summary

- What changed?
- Why is this needed?

## Root Cause

- What was the actual root cause of the issue?

## Fix

- What was changed to fix the root cause?
- Any trade-offs or compatibility notes?

## Validation

- Local commands run:
  - `./scripts/pr-preflight.sh <cli|swift|full>`
- Additional manual checks:
  - (if any)

## PR Precheck Checklist

Reference: [docs/PR_PRECHECK_PROCESS.md](docs/PR_PRECHECK_PROCESS.md)

- [ ] Branch is based on latest upstream target branch
- [ ] Scope is correct (code/docs split when needed)
- [ ] Ran `./scripts/pr-preflight.sh <cli|swift|full>` for this change scope
- [ ] If needed, ran `./scripts/pr-preflight.sh cli --check-commit`
- [ ] Commit/PR title follows Conventional Commits
- [ ] If `README.md` changed, synced all i18n README files and ran `./scripts/check-readme-i18n.sh`
- [ ] PR description includes problem, root cause, fix, and validation evidence

## Related

- Issue/PR links:
- Retro reference (optional): [docs/PR_RETRO_OPENCLAW_2026-02-27.md](docs/PR_RETRO_OPENCLAW_2026-02-27.md)
