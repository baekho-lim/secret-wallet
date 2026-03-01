#!/bin/bash
# Swift build-smoke path for core + GUI packages.
# Use SKIP_GUI=1 to skip App build on headless/dev shells.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Swift toolchain"
swift --version

echo "==> Build core package (debug + release)"
cd "$PROJECT_ROOT"
swift build
swift build -c release

if swift package describe | grep -q "testTarget"; then
  echo "==> Running swift test"
  swift test
else
  echo "==> No Swift testTarget defined; skipping swift test"
fi

if [ "${SKIP_GUI:-0}" = "1" ]; then
  echo "==> SKIP_GUI=1 set; skipping App build"
else
  echo "==> Build GUI package (release)"
  cd "$PROJECT_ROOT/App"
  swift build -c release
fi
