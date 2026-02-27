#!/bin/bash
# Fast validation path for CLI-focused changes.
# Runs release build + P0 integration suite (no GUI build).

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BINARY="$PROJECT_ROOT/.build/release/secret-wallet"

echo "==> Building CLI (release)"
cd "$PROJECT_ROOT"
swift build -c release

echo "==> Running CLI P0 integration tests"
chmod +x ./scripts/test-full.sh
BINARY="$BINARY" ./scripts/test-full.sh
