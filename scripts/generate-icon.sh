#!/bin/bash
set -euo pipefail

# Generate Secret Wallet app icon (.icns) from a Swift-rendered image
# Uses AppKit to draw a lock.shield SF Symbol programmatically

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT="$ROOT_DIR/App/Resources/AppIcon.icns"
TEMP_DIR=$(mktemp -d)

trap "rm -rf $TEMP_DIR" EXIT

# Generate 1024x1024 PNG via Swift
cat > "$TEMP_DIR/icon.swift" << 'SWIFT'
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

// Background: rounded rect with gradient
let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: size * 0.22, yRadius: size * 0.22)

// Gradient: dark blue to teal
let gradient = NSGradient(colors: [
    NSColor(red: 0.10, green: 0.12, blue: 0.25, alpha: 1.0),
    NSColor(red: 0.08, green: 0.22, blue: 0.35, alpha: 1.0),
])!
gradient.draw(in: bgPath, angle: -45)

// Draw SF Symbol "lock.shield.fill"
if let sfImage = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.45, weight: .medium)
    let configured = sfImage.withSymbolConfiguration(config)!

    let symbolSize = configured.size
    let x = (size - symbolSize.width) / 2
    let y = (size - symbolSize.height) / 2

    // White symbol
    NSColor.white.withAlphaComponent(0.95).set()
    let symbolRect = NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height)
    configured.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.95)
}

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to create PNG\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
try! pngData.write(to: url)
print("Generated: \(url.path)")
SWIFT

# Compile and run
swiftc -o "$TEMP_DIR/icon" "$TEMP_DIR/icon.swift" -framework AppKit 2>&1
"$TEMP_DIR/icon" "$TEMP_DIR/icon_1024.png"

# Create iconset with all required sizes
ICONSET="$TEMP_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"

declare -a SIZES=(16 32 128 256 512)
for s in "${SIZES[@]}"; do
    sips -z "$s" "$s" "$TEMP_DIR/icon_1024.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null 2>&1
    s2=$((s * 2))
    sips -z "$s2" "$s2" "$TEMP_DIR/icon_1024.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null 2>&1
done
# 512@2x = 1024
cp "$TEMP_DIR/icon_1024.png" "$ICONSET/icon_512x512@2x.png"

# Convert to .icns
iconutil -c icns "$ICONSET" -o "$OUTPUT"

echo "Icon generated: $OUTPUT"
