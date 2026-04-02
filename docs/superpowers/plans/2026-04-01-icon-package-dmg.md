# Charter — Icon, Packaging & Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the app to Charter, add a warm/bold brain-inbox icon, and build a signed/notarized DMG pipeline that works locally via `mise run package` and in GitHub Actions on version tags.

**Architecture:** The pipeline is three independent pieces — icon generation (SVG → PNG sizes → `.appiconset`), local release script (archive → sign → DMG → notarize → staple), and CI workflow (same script, cert injected from secrets). All three share the same env-var contract so local and CI behaviour are identical.

**Tech Stack:** XcodeGen, xcodebuild, `create-dmg` (Homebrew), `librsvg` (Homebrew), `xcrun notarytool`, `xcrun stapler`, GitHub Actions (`macos-14` runner)

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Modify | `project.yml` | Rename target + bundle ID to Charter |
| Modify | `EngagementTracker/Info.plist` | Update display name + bundle ID |
| Modify | `.mise.toml` | Update scheme/project refs + add `package` task |
| Create | `assets/icon/icon.svg` | Warm brain-inbox vector source |
| Create | `assets/dmg-background.svg` | DMG window background source |
| Create | `scripts/generate-icons.sh` | SVG → PNG sizes → AppIcon.appiconset |
| Create | `EngagementTracker/Assets.xcassets/AppIcon.appiconset/Contents.json` | Asset catalog charter |
| Create | `assets/ExportOptions.plist` | xcodebuild archive export config |
| Create | `scripts/build-release.sh` | Full archive → sign → DMG → notarize pipeline |
| Create | `.env.example` | Documents required env vars |
| Create | `.github/workflows/release.yml` | Tag-triggered CI release |
| Modify | `.gitignore` | Add `.env`, `build/` entries |

---

## Task 1: Rename App to Charter

**Files:**
- Modify: `project.yml`
- Modify: `EngagementTracker/Info.plist`
- Modify: `.mise.toml`

- [ ] **Step 1: Update project.yml**

Replace the entire file contents with:

```yaml
name: Charter
options:
  bundleIdPrefix: com.greyhoundforty
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "16.0"
  createIntermediateGroups: true
  groupSortPosition: top

packages:
  MarkdownUI:
    url: https://github.com/gonzalezreal/swift-markdown-ui.git
    from: 2.4.1

settings:
  base:
    SWIFT_VERSION: "5.9"
    ENABLE_HARDENED_RUNTIME: YES

targets:
  Charter:
    type: application
    platform: macOS
    sources:
      - EngagementTracker
    settings:
      base:
        PRODUCT_NAME: Charter
        INFOPLIST_FILE: EngagementTracker/Info.plist
        CODE_SIGN_STYLE: Automatic
        PRODUCT_BUNDLE_IDENTIFIER: com.greyhoundforty.Charter
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    entitlements:
      path: EngagementTracker/EngagementTracker.entitlements
    dependencies:
      - sdk: SwiftData.framework
      - package: MarkdownUI

  CharterTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - EngagementTrackerTests
    dependencies:
      - target: Charter
    settings:
      base:
        PRODUCT_NAME: CharterTests
        GENERATE_INFOPLIST_FILE: YES
```

- [ ] **Step 2: Update Info.plist**

Replace the three name/ID entries:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Charter</string>
    <key>CFBundleDisplayName</key>
    <string>Charter</string>
    <key>CFBundleIdentifier</key>
    <string>com.greyhoundforty.Charter</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 3: Update .mise.toml**

Replace entire file with updated scheme/project/container references:

```toml
[tasks.run]
description = "Build and launch Charter without opening Xcode"
run = """
set -e

# Kill any running instance first
pkill -x Charter 2>/dev/null || true

# Build
xcodebuild \
  -project Charter.xcodeproj \
  -scheme Charter \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Debug \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"

# Resolve the built products dir and launch
APP_DIR=$(xcodebuild \
  -project Charter.xcodeproj \
  -scheme Charter \
  -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | awk '/BUILT_PRODUCTS_DIR/ { print $3; exit }')

echo "Launching $APP_DIR/Charter.app"
open "$APP_DIR/Charter.app"
"""

[tasks.build]
description = "Build Charter via xcodebuild"
run = """
xcodebuild \
  -project Charter.xcodeproj \
  -scheme Charter \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Debug \
  build
"""

[tasks.clean]
description = "Clean Charter build products"
run = """
xcodebuild \
  -project Charter.xcodeproj \
  -scheme Charter \
  clean
"""

[tasks."clean-build"]
description = "Clean then build"
run = """
xcodebuild \
  -project Charter.xcodeproj \
  -scheme Charter \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Debug \
  clean build
"""

[tasks.test]
description = "Run unit tests"
run = """
xcodebuild \
  -project Charter.xcodeproj \
  -scheme CharterTests \
  -destination 'platform=macOS,arch=arm64' \
  test
"""

[tasks."db-backup"]
description = "Backup SwiftData store to ~/Desktop/Charter-backups/"
run = """
BACKUP_DIR="$HOME/Desktop/Charter-backups"
DB_DIR="$HOME/Library/Containers/com.greyhoundforty.Charter/Data/Library/Application Support"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEST="$BACKUP_DIR/$TIMESTAMP"

mkdir -p "$DEST"

if [ -d "$DB_DIR" ]; then
  cp -R "$DB_DIR/." "$DEST/"
  echo "Backed up to $DEST"
else
  echo "No database directory found at $DB_DIR (app may not have been run yet)"
fi
"""

[tasks.package]
description = "Build, sign, notarize, and package Charter as a DMG"
run = "scripts/build-release.sh"
```

- [ ] **Step 4: Regenerate Xcode project**

```bash
xcodegen generate
```

Expected: `Generating project Charter` and `Charter.xcodeproj` appears in the project root. The old `EngagementTracker.xcodeproj` directory is replaced.

- [ ] **Step 5: Verify the build**

```bash
mise run build 2>&1 | tail -5
```

Expected output ends with: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

Remove the old project file (xcodegen created `Charter.xcodeproj` but `EngagementTracker.xcodeproj` is still tracked):

```bash
git rm -r --cached EngagementTracker.xcodeproj 2>/dev/null || true
git add project.yml EngagementTracker/Info.plist .mise.toml Charter.xcodeproj
git commit -m "feat: rename app to Charter"
```

---

## Task 2: Create Icon and DMG Background SVG Sources

**Files:**
- Create: `assets/icon/icon.svg`
- Create: `assets/dmg-background.svg`

- [ ] **Step 1: Create assets directories**

```bash
mkdir -p assets/icon
```

- [ ] **Step 2: Create the icon SVG**

Write `assets/icon/icon.svg`:

```svg
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="brainGrad" x1="20%" y1="0%" x2="80%" y2="100%">
      <stop offset="0%" stop-color="#FB923C"/>
      <stop offset="100%" stop-color="#DC2626"/>
    </linearGradient>
    <linearGradient id="trayGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#92400E"/>
      <stop offset="100%" stop-color="#451A03"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="1024" height="1024" fill="#1C1917"/>

  <!-- Brain: left lobe -->
  <ellipse cx="410" cy="390" rx="195" ry="170" fill="url(#brainGrad)"/>
  <!-- Brain: right lobe -->
  <ellipse cx="614" cy="390" rx="195" ry="170" fill="url(#brainGrad)"/>
  <!-- Fill center gap between lobes -->
  <rect x="410" y="228" width="204" height="304" fill="url(#brainGrad)"/>
  <!-- Center sulcus (dividing line between lobes) -->
  <line x1="512" y1="236" x2="512" y2="530" stroke="#7C2D12" stroke-width="16" stroke-linecap="round"/>

  <!-- Brain stem connecting to inbox tray -->
  <rect x="462" y="518" width="100" height="64" rx="10" fill="url(#brainGrad)"/>

  <!-- Inbox tray body -->
  <rect x="296" y="562" width="432" height="152" rx="24" fill="url(#trayGrad)"/>
  <!-- Tray shelf line -->
  <rect x="320" y="674" width="384" height="14" rx="7" fill="#FED7AA" opacity="0.45"/>

  <!-- Wires in from left -->
  <line x1="80"  y1="312" x2="238" y2="362" stroke="#F97316" stroke-width="22" stroke-linecap="round"/>
  <line x1="56"  y1="430" x2="218" y2="430" stroke="#F97316" stroke-width="22" stroke-linecap="round"/>
  <line x1="80"  y1="548" x2="238" y2="498" stroke="#F97316" stroke-width="22" stroke-linecap="round"/>
  <!-- Input node dots -->
  <circle cx="54"  cy="312" r="26" fill="#FDBA74"/>
  <circle cx="30"  cy="430" r="26" fill="#FDBA74"/>
  <circle cx="54"  cy="548" r="26" fill="#FDBA74"/>

  <!-- Wires out to right -->
  <line x1="786" y1="362" x2="944" y2="312" stroke="#F97316" stroke-width="22" stroke-linecap="round"/>
  <line x1="806" y1="430" x2="968" y2="430" stroke="#F97316" stroke-width="22" stroke-linecap="round"/>
  <line x1="786" y1="498" x2="944" y2="548" stroke="#F97316" stroke-width="22" stroke-linecap="round"/>
  <!-- Output node dots -->
  <circle cx="970" cy="312" r="26" fill="#FDBA74"/>
  <circle cx="994" cy="430" r="26" fill="#FDBA74"/>
  <circle cx="970" cy="548" r="26" fill="#FDBA74"/>
</svg>
```

- [ ] **Step 3: Create the DMG background SVG**

Write `assets/dmg-background.svg`:

```svg
<svg width="600" height="400" viewBox="0 0 600 400" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1C1917"/>
      <stop offset="100%" stop-color="#292524"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="600" height="400" fill="url(#bgGrad)"/>

  <!-- Subtle grid lines for depth -->
  <line x1="0" y1="200" x2="600" y2="200" stroke="#3C3835" stroke-width="1" opacity="0.5"/>
  <line x1="300" y1="0" x2="300" y2="400" stroke="#3C3835" stroke-width="1" opacity="0.5"/>

  <!-- App name wordmark -->
  <text
    x="300" y="220"
    text-anchor="middle"
    font-family="-apple-system, 'SF Pro Display', Helvetica, sans-serif"
    font-size="48"
    font-weight="700"
    letter-spacing="-1"
    fill="#F97316"
    opacity="0.18"
  >MANIFEST</text>

  <!-- Drag arrow hint at center-bottom -->
  <text
    x="300" y="360"
    text-anchor="middle"
    font-family="-apple-system, Helvetica, sans-serif"
    font-size="13"
    fill="#78716C"
  >Drag Charter to Applications to install</text>
</svg>
```

- [ ] **Step 4: Commit**

```bash
git add assets/
git commit -m "feat: add icon and DMG background SVG sources"
```

---

## Task 3: Create Icon Generation Script

**Files:**
- Create: `scripts/generate-icons.sh`
- Create: `EngagementTracker/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Install librsvg if needed**

```bash
brew list librsvg 2>/dev/null || brew install librsvg
```

Expected: either "librsvg" (already installed) or installation completes.

- [ ] **Step 2: Create the generation script**

Write `scripts/generate-icons.sh`:

```bash
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
```

- [ ] **Step 3: Make the script executable**

```bash
chmod +x scripts/generate-icons.sh
```

- [ ] **Step 4: Create AppIcon.appiconset/Contents.json**

Write `EngagementTracker/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16",   "filename" : "icon_16x16.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16",   "filename" : "icon_16x16@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32",   "filename" : "icon_32x32.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32",   "filename" : "icon_32x32@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128", "filename" : "icon_128x128.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128", "filename" : "icon_128x128@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256", "filename" : "icon_256x256.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256", "filename" : "icon_256x256@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512", "filename" : "icon_512x512.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512", "filename" : "icon_512x512@2x.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

- [ ] **Step 5: Run the script**

```bash
scripts/generate-icons.sh
```

Expected: 10 lines of "Generated NxN: ..." then "Done." with three output paths. No errors.

- [ ] **Step 6: Verify output files exist**

```bash
ls EngagementTracker/Assets.xcassets/AppIcon.appiconset/*.png | wc -l
```

Expected: `10`

```bash
ls -lh assets/dmg-background.png
```

Expected: a file of roughly 10–50KB.

- [ ] **Step 7: Build and verify icon appears**

```bash
mise run build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`. Open `mise run run` and confirm Charter shows the brain-inbox icon in the Dock.

- [ ] **Step 8: Update .gitignore to exclude generated PNG files from appiconset (keep Contents.json)**

Add to `.gitignore`:

```
# Generated icon PNGs (rebuilt by scripts/generate-icons.sh)
EngagementTracker/Assets.xcassets/AppIcon.appiconset/*.png

# Local env (secrets)
.env

# Release build output
build/
```

- [ ] **Step 9: Commit**

```bash
git add scripts/generate-icons.sh \
        EngagementTracker/Assets.xcassets/AppIcon.appiconset/Contents.json \
        assets/dmg-background.png \
        .gitignore
git commit -m "feat: add icon generation script and AppIcon.appiconset"
```

---

## Task 4: Create ExportOptions.plist and .env.example

**Files:**
- Create: `assets/ExportOptions.plist`
- Create: `.env.example`

- [ ] **Step 1: Create ExportOptions.plist**

Write `assets/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
    <key>teamID</key>
    <string>REPLACE_WITH_TEAM_ID</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
```

> **Note:** Replace `REPLACE_WITH_TEAM_ID` with your 10-character Apple Team ID (visible at developer.apple.com → Membership). This file is committed — it contains no secrets, only the team ID which is public in your signing cert.

- [ ] **Step 2: Create .env.example**

Write `.env.example`:

```bash
# Copy this file to .env and fill in your values.
# .env is gitignored — never commit it.
#
# How to get each value:
#
# CODESIGN_IDENTITY: Run `security find-identity -v -p codesigning` after importing
#   your Developer ID Application cert. Copy the full string, e.g.:
#   "Developer ID Application: Your Name (XXXXXXXXXX)"
#
# APPLE_ID: Your Apple ID email address used for the Developer Program.
#
# APPLE_TEAM_ID: 10-character team ID from developer.apple.com → Membership.
#
# APP_SPECIFIC_PASSWORD: Generate at appleid.apple.com → Sign-In and Security
#   → App-Specific Passwords. Label it "Charter notarytool".

CODESIGN_IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)"
APPLE_ID="you@example.com"
APPLE_TEAM_ID="XXXXXXXXXX"
APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

- [ ] **Step 3: Commit**

```bash
git add assets/ExportOptions.plist .env.example
git commit -m "feat: add ExportOptions.plist and .env.example"
```

---

## Task 5: Create Build Release Script

**Files:**
- Create: `scripts/build-release.sh`

- [ ] **Step 1: Create the script**

Write `scripts/build-release.sh`:

```bash
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
VERSION=$(defaults read "$ROOT/EngagementTracker/Info.plist" CFBundleShortVersionString)
DMG_PATH="$BUILD_DIR/Charter-${VERSION}.dmg"

mkdir -p "$BUILD_DIR"

# ── 1. Generate icons (ensures appiconset is populated) ──────────────────────
echo "==> Generating icons..."
bash "$SCRIPT_DIR/generate-icons.sh"

# ── 2. Archive ────────────────────────────────────────────────────────────────
echo "==> Archiving $SCHEME $VERSION..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE" \
  CODE_SIGN_IDENTITY="$CODESIGN_IDENTITY" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" || true

# ── 3. Export signed .app ─────────────────────────────────────────────────────
echo "==> Exporting signed app..."
rm -rf "$EXPORT_DIR"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTS"

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
```

- [ ] **Step 2: Make the script executable**

```bash
chmod +x scripts/build-release.sh
```

- [ ] **Step 3: Validate shell syntax**

```bash
bash -n scripts/build-release.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add scripts/build-release.sh
git commit -m "feat: add build-release.sh pipeline script"
```

---

## Task 6: Create GitHub Actions Release Workflow

**Files:**
- Create: `.github/workflows/release.yml`

- [ ] **Step 1: Create the workflow directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Write the workflow**

Write `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-release:
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install build tools
        run: brew install create-dmg librsvg

      - name: Import Developer ID certificate
        env:
          CERT_P12: ${{ secrets.DEVELOPER_ID_CERT_P12 }}
          CERT_PASSWORD: ${{ secrets.DEVELOPER_ID_CERT_PASSWORD }}
        run: |
          KEYCHAIN_PATH="$RUNNER_TEMP/build.keychain"
          CERT_PATH="$RUNNER_TEMP/cert.p12"
          KEYCHAIN_PASSWORD=$(uuidgen)

          echo "$CERT_P12" | base64 --decode -o "$CERT_PATH"

          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security import "$CERT_PATH" \
            -P "$CERT_PASSWORD" \
            -A -t cert -f pkcs12 \
            -k "$KEYCHAIN_PATH"
          security list-keychain -d user -s "$KEYCHAIN_PATH"
          security set-key-partition-list \
            -S apple-tool:,apple: \
            -s -k "$KEYCHAIN_PASSWORD" \
            "$KEYCHAIN_PATH"

      - name: Build, sign, notarize, and package
        env:
          CODESIGN_IDENTITY: ${{ secrets.CODESIGN_IDENTITY }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APP_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
        run: bash scripts/build-release.sh

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: build/Charter-*.dmg
          generate_release_notes: true
```

- [ ] **Step 3: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))" && echo "YAML OK"
```

Expected: `YAML OK`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "feat: add GitHub Actions release workflow"
```

---

## Task 7: Verify End-to-End Locally (Pre-Signing Smoke Test)

This task confirms the pipeline runs correctly before you have signing credentials set up. It exercises everything up to the point where a real cert is needed.

- [ ] **Step 1: Confirm all scripts are in place**

```bash
ls -la scripts/
```

Expected: `build-release.sh`, `generate-icons.sh` both present and executable (`-rwxr-xr-x`).

- [ ] **Step 2: Confirm icon PNGs are generated**

```bash
scripts/generate-icons.sh
ls EngagementTracker/Assets.xcassets/AppIcon.appiconset/*.png | wc -l
```

Expected: `10`

- [ ] **Step 3: Confirm app builds with icon**

```bash
mise run build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Confirm the app launches as "Charter"**

```bash
mise run run
```

Expected: app launches, title bar shows "Charter", Dock shows the brain-inbox icon.

- [ ] **Step 5: Final commit of any remaining tracked files**

```bash
git status
```

If any tracked files show modifications (e.g., `Charter.xcodeproj/project.pbxproj` from the build), commit them:

```bash
git add Charter.xcodeproj
git commit -m "chore: sync generated xcodeproj after icon integration"
```

---

## Secrets Setup Reference (for when you have your Developer Account)

This is not a task — it's a reference for when you're ready to do a real signed build.

**Export your Developer ID certificate as .p12:**
1. Open Keychain Access → login keychain
2. Find "Developer ID Application: Your Name (TEAM_ID)"
3. Right-click → Export → save as `cert.p12` with a strong password
4. `base64 -i cert.p12 | pbcopy` — that's your `DEVELOPER_ID_CERT_P12` secret value

**Generate an App-Specific Password:**
1. Go to appleid.apple.com → Sign-In and Security → App-Specific Passwords
2. Click `+`, label it "Charter notarytool"
3. Copy the `xxxx-xxxx-xxxx-xxxx` value — that's `APP_SPECIFIC_PASSWORD`

**Add secrets to GitHub:**
Settings → Secrets and variables → Actions → New repository secret:
- `DEVELOPER_ID_CERT_P12` (base64 cert)
- `DEVELOPER_ID_CERT_PASSWORD` (p12 password)
- `CODESIGN_IDENTITY` (e.g. `Developer ID Application: Ryan Tiffany (XXXXXXXXXX)`)
- `APPLE_ID` (your Apple ID email)
- `APPLE_TEAM_ID` (10-char team ID)
- `APP_SPECIFIC_PASSWORD` (app-specific password)

**Update ExportOptions.plist:**
Replace `REPLACE_WITH_TEAM_ID` in `assets/ExportOptions.plist` with your actual team ID.

**Trigger a release:**
```bash
git tag v0.2.0
git push origin v0.2.0
```
