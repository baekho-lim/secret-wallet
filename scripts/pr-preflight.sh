#!/bin/bash
# Unified pre-PR local validation for Secret Wallet.
# Modes:
#   cli   - fast CLI gate
#   swift - CLI gate + Swift smoke gate
#   full  - CLI gate + Swift smoke gate + full integration

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/pr-preflight.sh [cli|swift|full] [--check-commit]

Examples:
  ./scripts/pr-preflight.sh
  ./scripts/pr-preflight.sh swift
  ./scripts/pr-preflight.sh full --check-commit
EOF
}

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="cli"
CHECK_COMMIT=0

for arg in "$@"; do
  case "$arg" in
    cli|swift|full)
      MODE="$arg"
      ;;
    --check-commit)
      CHECK_COMMIT=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

check_commit_message() {
  local msg
  msg="$(git -C "$PROJECT_ROOT" log -1 --pretty=%s)"
  local pattern='^(feat|fix|docs|refactor|test|chore|ci|build|perf)(\([A-Za-z0-9._/-]+\))?: .+'
  if [[ "$msg" =~ $pattern ]]; then
    echo "==> Commit message format OK: $msg"
  else
    echo "ERROR: HEAD commit message is not Conventional Commits compliant:" >&2
    echo "  $msg" >&2
    echo "Expected format: type(scope): subject" >&2
    exit 1
  fi
}

run_shared_checks() {
  echo "==> Running README i18n consistency check"
  "$PROJECT_ROOT/scripts/check-readme-i18n.sh"
}

echo "==> PR preflight mode: $MODE"

cd "$PROJECT_ROOT"

case "$MODE" in
  cli)
    "$PROJECT_ROOT/scripts/test-cli-fast.sh"
    run_shared_checks
    ;;
  swift)
    "$PROJECT_ROOT/scripts/test-cli-fast.sh"
    "$PROJECT_ROOT/scripts/test-swift-smoke.sh"
    run_shared_checks
    ;;
  full)
    "$PROJECT_ROOT/scripts/test-cli-fast.sh"
    "$PROJECT_ROOT/scripts/test-swift-smoke.sh"
    "$PROJECT_ROOT/scripts/test-full.sh" --full
    run_shared_checks
    ;;
esac

if [ "$CHECK_COMMIT" = "1" ]; then
  check_commit_message
fi

echo "==> PR preflight completed successfully"
