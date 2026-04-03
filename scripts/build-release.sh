#!/usr/bin/env bash
# build-release.sh — Archive, sign, package, notarize, and staple Charter.app
# as a distributable DMG.
#
# Required env vars (set in .env locally, GitHub secrets in CI):
#   CODESIGN_IDENTITY, APPLE_ID, APPLE_TEAM_ID, APP_SPECIFIC_PASSWORD
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env if present (local dev)
if [ -f "$ROOT/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.env"
  set +a
fi

# Validate required env vars
for var in CODESIGN_IDENTITY APPLE_ID APPLE_TEAM_ID APP_SPECIFIC_PASSWORD; do
  if [ -z "${!var:-}" ]; then
    echo "Error: $var is not set. See .env.example."
    exit 1
  fi
done

PROJECT="$ROOT/Charter.xcodeproj"
SCHEME="Charter"
BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/Charter.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTS="$ROOT/assets/ExportOptions.plist"
BG="$ROOT/assets/dmg-background.png"
VERSION="${MARKETING_VERSION:-$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$ROOT/Charter/Info.plist")}"
DMG_PATH="$BUILD_DIR/Charter-${VERSION}.dmg"
XCODE_MARKETING_VERSION="${MARKETING_VERSION:-$VERSION}"
XCODE_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:-${GITHUB_RUN_NUMBER:-1}}"


mkdir -p "$BUILD_DIR"

# Prerequisite file checks
if [ ! -f "$EXPORT_OPTS" ]; then
  echo "Error: ExportOptions.plist not found at $EXPORT_OPTS"
  exit 1
fi
if grep -q "REPLACE_WITH_TEAM_ID" "$EXPORT_OPTS"; then
  echo "Error: ExportOptions.plist still contains placeholder team ID."
  echo "  Edit $EXPORT_OPTS and replace REPLACE_WITH_TEAM_ID with your 10-char team ID."
  exit 1
fi

# ── 1. Generate icons (ensures appiconset and dmg-background.png are populated) ──
echo "==> Generating icons..."
bash "$SCRIPT_DIR/generate-icons.sh"

if [ ! -f "$BG" ]; then
  echo "Error: DMG background not found at $BG after generate-icons.sh"
  exit 1
fi

# ── 2. Archive ────────────────────────────────────────────────────────────────
echo "==> Archiving $SCHEME $VERSION..."
XCODE_LOG=$(mktemp /tmp/xcodebuild-archive.XXXXXX.log)
set +e
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE" \
  CODE_SIGN_IDENTITY="$CODESIGN_IDENTITY" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  MARKETING_VERSION="$XCODE_MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$XCODE_PROJECT_VERSION" \
  2>&1 | tee "$XCODE_LOG"
XCODE_STATUS=${PIPESTATUS[0]}
set -e
grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" "$XCODE_LOG" || true
rm -f "$XCODE_LOG"
if [ "$XCODE_STATUS" -ne 0 ]; then
  echo "Error: xcodebuild archive failed (exit $XCODE_STATUS)"
  exit 1
fi

# ── 3. Export signed .app ─────────────────────────────────────────────────────
echo "==> Exporting signed app..."
rm -rf "$EXPORT_DIR"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTS" \
  MARKETING_VERSION="$XCODE_MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$XCODE_PROJECT_VERSION"
  
APP="$EXPORT_DIR/Charter.app"
if [ ! -d "$APP" ]; then
  echo "Error: Export failed — Charter.app not found at $APP"
  exit 1
fi

# ── 4. Create DMG ─────────────────────────────────────────────────────────────
echo "==> Creating DMG..."
rm -f "$DMG_PATH"
create-dmg \
  --volname "Charter" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 128 \
  --icon "Charter.app" 160 200 \
  --hide-extension "Charter.app" \
  --app-drop-link 440 200 \
  --background "$BG" \
  "$DMG_PATH" \
  "$APP"

# ── 5. Notarize ───────────────────────────────────────────────────────────────
echo "==> Notarizing (this takes 1–5 minutes)..."
xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD" \
  --wait

# ── 6. Staple ─────────────────────────────────────────────────────────────────
echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo ""
echo "✓ Release complete: $DMG_PATH"
