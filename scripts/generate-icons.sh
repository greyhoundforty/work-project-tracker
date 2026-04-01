#!/usr/bin/env bash
# generate-icons.sh — Rasterize SVG sources into all required macOS icon sizes
# and produce AppIcon.appiconset + AppIcon.icns + assets/dmg-background.png
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SVG="$ROOT/assets/icon/icon.svg"
BG_SVG="$ROOT/assets/dmg-background.svg"
ICONSET="$ROOT/build/AppIcon.iconset"
APPICONSET="$ROOT/EngagementTracker/Assets.xcassets/AppIcon.appiconset"

if ! command -v rsvg-convert &>/dev/null; then
  echo "Error: rsvg-convert not found. Install with: brew install librsvg"
  exit 1
fi

for f in "$SVG" "$BG_SVG"; do
  if [ ! -f "$f" ]; then
    echo "Error: required source file not found: $f"
    exit 1
  fi
done

mkdir -p "$ICONSET" "$APPICONSET"

rasterize() {
  local size=$1
  local out=$2
  rsvg-convert -w "$size" -h "$size" "$SVG" -o "$out"
  echo "  Generated ${size}x${size}: $(basename "$out")"
}

echo "==> Generating icon sizes..."
rasterize 16   "$ICONSET/icon_16x16.png"
rasterize 32   "$ICONSET/icon_16x16@2x.png"
rasterize 32   "$ICONSET/icon_32x32.png"
rasterize 64   "$ICONSET/icon_32x32@2x.png"
rasterize 128  "$ICONSET/icon_128x128.png"
rasterize 256  "$ICONSET/icon_128x128@2x.png"
rasterize 256  "$ICONSET/icon_256x256.png"
rasterize 512  "$ICONSET/icon_256x256@2x.png"
rasterize 512  "$ICONSET/icon_512x512.png"
rasterize 1024 "$ICONSET/icon_512x512@2x.png"

echo "==> Building .icns..."
iconutil -c icns "$ICONSET" -o "$ROOT/build/AppIcon.icns"

echo "==> Copying PNGs to AppIcon.appiconset..."
cp "$ICONSET"/*.png "$APPICONSET/"

echo "==> Generating DMG background..."
rsvg-convert -w 600 -h 400 "$BG_SVG" -o "$ROOT/assets/dmg-background.png"

echo ""
echo "Done."
echo "  AppIcon.appiconset: $APPICONSET"
echo "  AppIcon.icns:       $ROOT/build/AppIcon.icns"
echo "  DMG background:     $ROOT/assets/dmg-background.png"
