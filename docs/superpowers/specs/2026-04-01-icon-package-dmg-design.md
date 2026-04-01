# Manifest — Icon, Packaging & Distribution Design

**Date:** 2026-04-01
**Branch:** `emdash/feat-icon-package-dmg-885`
**Status:** Approved

---

## Overview

Rename the app from "Engagement Tracker" to **Manifest**, add a custom app icon, and build a signed/notarized DMG packaging pipeline that works both locally and in GitHub Actions CI.

**Goal:** Coworkers can download a `.dmg`, drag Manifest to Applications, and open it with zero Gatekeeper friction.

---

## 1. App Rename

Rename the app display name and bundle identifier from "EngagementTracker" to "Manifest" throughout the project.

**Changes required:**
- `project.yml` — update `name`, `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER` (`com.greyhoundforty.Manifest`)
- `EngagementTracker/Info.plist` — `CFBundleName`, `CFBundleDisplayName`
- Regenerate `.xcodeproj` via `xcodegen generate` after `project.yml` changes
- Source directory rename is optional — internal folder name does not affect the shipped app

---

## 2. App Icon

### Concept
A "brain inbox" — an organic brain shape with an inbox tray at the bottom and wires (connections) entering and exiting from the sides. Style: **warm/bold** — orange-to-red gradient brain on a dark background.

### Tooling
Icon generation is fully scripted so the source is version-controlled and reproducible.

**Files:**
```
assets/
  icon/
    icon.svg          # Vector source (brain-inbox, warm palette)
  dmg-background.png  # 600×400 DMG window background (generated)
scripts/
  generate-icons.sh   # SVG → PNG sizes → AppIcon.appiconset + .icns
```

### Generation pipeline (`scripts/generate-icons.sh`)
1. Uses `rsvg-convert` (or `qlmanage`/`sips` as fallback) to rasterize `icon.svg` to PNG
2. Produces all required macOS icon sizes: 16, 32, 64, 128, 256, 512, 1024px (plus @2x variants)
3. Assembles `AppIcon.iconset/`, runs `iconutil -c icns` to produce `AppIcon.icns`
4. Copies PNG set into `EngagementTracker/Assets.xcassets/AppIcon.appiconset/`
5. Generates `assets/dmg-background.png` (dark background, "Manifest" wordmark in warm orange)

**Dependencies:** `librsvg` (`brew install librsvg`) for SVG rasterization. Falls back to `sips` for simple cases.

### Icon sizes produced
| Size | Files |
|------|-------|
| 16×16 | `icon_16x16.png`, `icon_16x16@2x.png` |
| 32×32 | `icon_32x32.png`, `icon_32x32@2x.png` |
| 128×128 | `icon_128x128.png`, `icon_128x128@2x.png` |
| 256×256 | `icon_256x256.png`, `icon_256x256@2x.png` |
| 512×512 | `icon_512x512.png`, `icon_512x512@2x.png` |
| 1024×1024 | `icon_512x512@2x.png` (App Store / large) |

---

## 3. Build & Release Script

A single script handles the full local release pipeline.

**File:** `scripts/build-release.sh`

### Pipeline steps
```
xcodebuild archive
  → .xcarchive (in build/)

xcodebuild -exportArchive
  → Manifest.app (signed with Developer ID Application cert)
  → Requires: ExportOptions.plist

create-dmg
  → Manifest-<version>.dmg
  → Custom background (assets/dmg-background.png)
  → 600×400 window, app icon left, Applications alias right
  → Volume name: "Manifest"

xcrun notarytool submit
  → Sends DMG to Apple notarization service
  → Waits for approval (--wait flag)

xcrun stapler staple
  → Attaches notarization ticket to DMG
  → Output: build/Manifest-<version>.dmg (ready to distribute)
```

### ExportOptions.plist
```
assets/ExportOptions.plist
```
Specifies:
- `method`: `developer-id`
- `signingStyle`: `manual`
- `signingCertificate`: `Developer ID Application: <name> (<TEAM_ID>)`
- `teamID`: `<TEAM_ID>`

### Environment variables (read by script)
| Variable | Purpose |
|----------|---------|
| `CODESIGN_IDENTITY` | Full name of Developer ID Application cert |
| `APPLE_ID` | Apple ID email for notarytool |
| `APPLE_TEAM_ID` | 10-character team ID |
| `APP_SPECIFIC_PASSWORD` | App-specific password for notarytool |

Loaded from `.env` locally (gitignored), from GitHub Actions secrets in CI.

### mise task
```toml
# .mise.toml addition
[tasks.package]
description = "Build, sign, notarize, and package Manifest as a DMG"
run = "scripts/build-release.sh"
```

---

## 4. DMG Layout

| Property | Value |
|----------|-------|
| Window size | 600 × 400 |
| Background | `assets/dmg-background.png` (dark, warm orange wordmark) |
| App icon position | Left (160, 200) |
| Applications alias position | Right (440, 200) |
| Volume name | `Manifest` |
| Output filename | `Manifest-<CFBundleShortVersionString>.dmg` |

---

## 5. GitHub Actions CI

**File:** `.github/workflows/release.yml`

### Trigger
```yaml
on:
  push:
    tags:
      - 'v*'
```

### Job: `build-and-release`
Runs on `macos-14` (Apple Silicon runner, Xcode 16 pre-installed).

**Steps:**
1. Checkout code
2. Install `create-dmg` via Homebrew
3. Import Developer ID certificate into a temporary keychain from `DEVELOPER_ID_CERT_P12` secret
4. Run `scripts/build-release.sh`
5. Create GitHub Release and upload `build/Manifest-*.dmg` as a release asset

### Required GitHub Secrets
| Secret | Value |
|--------|-------|
| `DEVELOPER_ID_CERT_P12` | Base64-encoded .p12 certificate export |
| `DEVELOPER_ID_CERT_PASSWORD` | Password used when exporting the .p12 |
| `APPLE_ID` | Apple ID email |
| `APPLE_TEAM_ID` | 10-character team ID |
| `APP_SPECIFIC_PASSWORD` | App-specific password (generated at appleid.apple.com) |

### Cost note
`macos-14` GitHub-hosted runners cost ~10× standard Linux runners. Recommend triggering only on version tags (not every push) to keep CI costs low.

---

## 6. File Inventory

### New files
```
assets/
  icon/
    icon.svg
  dmg-background.png        # generated by generate-icons.sh
  ExportOptions.plist
scripts/
  generate-icons.sh
  build-release.sh
.github/
  workflows/
    release.yml
.env.example                # Documents required env vars (no secrets)
```

### Modified files
```
project.yml                 # App rename, bundle ID update
EngagementTracker/Info.plist
.mise.toml                  # Add `package` task
.gitignore                  # Add .env, build/
```

### Generated (not committed)
```
EngagementTracker/Assets.xcassets/AppIcon.appiconset/   # from generate-icons.sh
build/                                                   # xcodebuild output
```

---

## 7. Out of Scope

- App Store submission (different signing, entitlements, and review process)
- Auto-update mechanism (Sparkle framework)
- Detailed icon redesign — current programmatic icon is a placeholder; a ground-up design can replace `assets/icon/icon.svg` at any time without changing the pipeline
