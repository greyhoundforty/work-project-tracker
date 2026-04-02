# Design: Sparkle Auto-Update Integration

**Date:** 2026-04-02

## Goal

When a new tag release is pushed to GitHub, running instances of Charter automatically detect the update at launch and users can also manually trigger a check from the Settings view.

## Architecture

Four components with single responsibilities:

1. **`UpdaterService`** — owns the `SPUUpdater` instance, starts background checks on launch, exposes manual check for the UI
2. **App-side config** — Sparkle SPM dependency, `Info.plist` feed URL + public key, network entitlement
3. **`gh-pages` branch** — hosts `index.html` (marketing site) and `appcast.xml` (Sparkle feed)
4. **CI additions** — after each DMG release, generates and pushes updated `appcast.xml` to `gh-pages`

## App-side Changes

### Dependency

Add via Swift Package Manager in Xcode:
- URL: `https://github.com/sparkle-project/Sparkle`
- Version: `2.x.x` (up-to-date 2.x at time of integration)
- Link `Sparkle` framework to the Charter target only

### `Info.plist` additions

```xml
<key>SUFeedURL</key>
<string>https://greyhoundforty.github.io/charter-app/appcast.xml</string>
<key>SUPublicEDKey</key>
<string><!-- public half of generated EdDSA key pair --></string>
```

### `Charter.entitlements` addition

```xml
<key>com.apple.security.network.client</key>
<true/>
```

The app currently has an empty entitlements dict (no sandbox). This single key is the only addition needed.

### `Charter/Services/UpdaterService.swift` (new file)

An `@Observable` class that:
- Holds an `SPUStandardUpdaterController` configured with the feed URL from `Info.plist`
- Calls `updater.checkForUpdatesInBackground()` on init for the automatic launch check
- Exposes `checkForUpdates()` which calls `updaterController.checkForUpdates(nil)` for the manual button

Instantiated once in `EngagementTrackerApp` and passed into the SwiftUI environment so `SettingsView` can call it.

### `SettingsView` addition

A new "Updates" `Section` inserted above the existing "Danger Zone" section:

```swift
Section {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text("Check for Updates")
            Text("Current version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        Spacer()
        Button("Check Now") { updaterService.checkForUpdates() }
    }
} header: {
    Text("Updates")
}
```

## Infrastructure

### One-time key generation (local, pre-implementation)

Run Sparkle's `generate_keys` tool to produce an EdDSA key pair:
- Public key → `SUPublicEDKey` in `Info.plist`
- Private key → GitHub Secret named `SPARKLE_PRIVATE_KEY`

The private key is never committed to the repository.

### `gh-pages` branch

Orphan branch at the root of `greyhoundforty/charter-app`:

```
index.html        ← charter-site.html content (text updates deferred)
appcast.xml       ← initially minimal empty feed; CI populates on first release
```

GitHub Pages enabled on this branch, serving at `https://greyhoundforty.github.io/charter-app/`.

### `appcast.xml` initial content

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Charter</title>
    <link>https://greyhoundforty.github.io/charter-app/appcast.xml</link>
    <description>Charter release feed</description>
    <language>en</language>
  </channel>
</rss>
```

`generate_appcast` appends `<item>` entries to this on each release.

### CI additions to `release.yml`

Two steps inserted after the existing "Create GitHub Release" step:

**Step 1 — Generate appcast:**
```yaml
- name: Generate appcast
  env:
    SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
  run: |
    # Download Sparkle tools
    SPARKLE_VERSION=2.6.4
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" \
      -o sparkle.tar.xz
    mkdir -p sparkle-tools
    tar -xJf sparkle.tar.xz -C sparkle-tools

    # Check out gh-pages into a subdirectory
    git clone --branch gh-pages --depth 1 \
      "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }}.git" \
      gh-pages-dir

    # Copy DMG into a folder for generate_appcast
    mkdir -p release-dmg
    cp build/Charter-*.dmg release-dmg/

    # Generate/update appcast.xml
    ./sparkle-tools/bin/generate_appcast \
      --ed-key-file <(echo "$SPARKLE_PRIVATE_KEY") \
      --download-url-prefix "https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/" \
      --link "https://greyhoundforty.github.io/charter-app/" \
      release-dmg/

    cp release-dmg/appcast.xml gh-pages-dir/appcast.xml
```

**Step 2 — Push to gh-pages:**
```yaml
- name: Push updated appcast to gh-pages
  run: |
    cd gh-pages-dir
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add appcast.xml
    git commit -m "chore: update appcast for ${{ github.ref_name }}" || echo "No changes"
    git push
```

## Release Flow (end-to-end)

1. Push `v0.3.0` tag → CI builds, signs, notarizes, uploads `Charter-0.3.0.dmg` to GitHub Releases
2. CI generates EdDSA signature for the DMG and updates `appcast.xml` on `gh-pages`
3. Charter running on a user's Mac checks `appcast.xml` at launch → Sparkle compares versions → shows standard update prompt if newer
4. User clicks "Check Now" in Settings → same Sparkle flow on demand

## Out of Scope

- Updating the marketing copy in `charter-site.html` (deferred)
- Delta (binary diff) updates — `generate_appcast` can generate these but requires DMG history; not included in initial implementation
- Mac App Store distribution (incompatible with Sparkle)
