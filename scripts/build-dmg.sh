#!/bin/bash
set -euo pipefail

# Build Secret Wallet GUI as .app bundle and package into DMG
# Usage: scripts/build-dmg.sh [VERSION]
# Requires: create-dmg (brew install create-dmg)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="${1:-0.3.0}"
APP_NAME="Secret Wallet"
BUNDLE_NAME="SecretWallet"
DIST_DIR="$ROOT_DIR/dist"

echo "Building ${APP_NAME} v${VERSION}..."

# Check dependencies
if ! command -v create-dmg &>/dev/null; then
    echo "Error: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

# 1. Build GUI release binary
echo "Compiling GUI (release)..."
cd "$ROOT_DIR/App" && swift build -c release
cd "$ROOT_DIR"

# Detect architecture-specific build path
RELEASE_BIN="$ROOT_DIR/App/.build/release/SecretWalletApp"
if [ ! -f "$RELEASE_BIN" ]; then
    # Fallback: architecture-specific path
    RELEASE_BIN=$(find "$ROOT_DIR/App/.build" -name "SecretWalletApp" -path "*/release/*" -type f | head -1)
    if [ -z "$RELEASE_BIN" ]; then
        echo "Error: SecretWalletApp binary not found"
        exit 1
    fi
fi

# 2. Create .app bundle structure
APP_BUNDLE="$DIST_DIR/${BUNDLE_NAME}.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy files
cp "$RELEASE_BIN" "$APP_BUNDLE/Contents/MacOS/"
cp "$ROOT_DIR/App/Resources/Info.plist" "$APP_BUNDLE/Contents/"
cp "$ROOT_DIR/App/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

# 4. Inject version into Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" \
    "$APP_BUNDLE/Contents/Info.plist"

echo "App bundle: $APP_BUNDLE"

# 5. Optional: Code sign if DEVELOPER_ID is set
if [ -n "${DEVELOPER_ID:-}" ]; then
    echo "Signing with: $DEVELOPER_ID"
    codesign --deep --force --verify --verbose \
        --sign "$DEVELOPER_ID" \
        --options runtime \
        --entitlements "$ROOT_DIR/App/Resources/entitlements.plist" \
        "$APP_BUNDLE"
else
    echo "Skipping code signing (set DEVELOPER_ID to enable)"
fi

# 6. Create DMG
DMG_PATH="$DIST_DIR/${BUNDLE_NAME}-${VERSION}.dmg"
rm -f "$DMG_PATH"

echo "Creating DMG..."
create-dmg \
    --volname "${APP_NAME} ${VERSION}" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 160 \
    --icon "${BUNDLE_NAME}.app" 180 170 \
    --app-drop-link 480 170 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_BUNDLE" \
    || true  # create-dmg returns 2 on success without code signing

# Verify DMG was created
if [ -f "$DMG_PATH" ]; then
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo ""
    echo "DMG created: $DMG_PATH ($DMG_SIZE)"
    echo ""
    echo "To install: open $DMG_PATH"
else
    echo "Error: DMG creation failed"
    exit 1
fi
