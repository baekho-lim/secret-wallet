#!/bin/bash
# Validate README translation coverage and sync metadata.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_FILE="$PROJECT_ROOT/README.md"
LANG_FILES=(
  "$PROJECT_ROOT/README.ko.md"
  "$PROJECT_ROOT/README.ja.md"
  "$PROJECT_ROOT/README.zh-CN.md"
  "$PROJECT_ROOT/README.fr.md"
  "$PROJECT_ROOT/README.de.md"
)

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

if command -v rg >/dev/null 2>&1; then
  FIND_CMD="rg"
else
  FIND_CMD="grep -E"
fi

extract_heading_shape() {
  local file="$1"
  # We compare heading levels order (##/###) to ensure section structure parity.
  if [ "$FIND_CMD" = "rg" ]; then
    rg '^(##|###) ' "$file" | sed -E 's/^((##|###)) .*/\1/'
  else
    grep -E '^(##|###) ' "$file" | sed -E 's/^((##|###)) .*/\1/'
  fi
}

echo "Checking README i18n files..."

if [ ! -f "$BASE_FILE" ]; then
  echo "❌ Missing base README: $BASE_FILE"
  exit 1
fi

extract_heading_shape "$BASE_FILE" > "$tmpdir/base.shape"

for file in "${LANG_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing translation file: $file"
    exit 1
  fi

  if [ "$FIND_CMD" = "rg" ]; then
    LANG_OK=$(rg -q '^Languages: \[English\]\(README.md\)' "$file" && echo yes || echo no)
  else
    LANG_OK=$(grep -Eq '^Languages: \[English\]\(README.md\)' "$file" && echo yes || echo no)
  fi
  if [ "$LANG_OK" != "yes" ]; then
    echo "❌ Language selector missing or malformed: $file"
    exit 1
  fi

  if [ "$FIND_CMD" = "rg" ]; then
    SYNC_OK=$(rg -q '^> Last synced with `README.md` commit: `[0-9a-f]{7,40}`$' "$file" && echo yes || echo no)
  else
    SYNC_OK=$(grep -Eq '^> Last synced with `README.md` commit: `[0-9a-f]{7,40}`$' "$file" && echo yes || echo no)
  fi
  if [ "$SYNC_OK" != "yes" ]; then
    echo "❌ Missing sync metadata line: $file"
    exit 1
  fi

  extract_heading_shape "$file" > "$tmpdir/current.shape"
  if ! diff -u "$tmpdir/base.shape" "$tmpdir/current.shape" > /dev/null; then
    echo "❌ Heading structure mismatch vs README.md: $file"
    echo "   Run: diff -u <(rg '^(##|###) ' README.md) <(rg '^(##|###) ' $(basename "$file"))"
    exit 1
  fi
done

echo "✅ README i18n check passed."
