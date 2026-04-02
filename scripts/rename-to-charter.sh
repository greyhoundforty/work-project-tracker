#!/usr/bin/env bash
# scripts/rename-to-charter.sh
#
# Renames the project from Manifest → Charter.
# Run once from the repo root. Safe to inspect with --dry-run first.
#
# Usage:
#   bash scripts/rename-to-charter.sh           # live run
#   bash scripts/rename-to-charter.sh --dry-run # preview only
#
# After running:
#   xcodegen generate
#   open Charter.xcodeproj

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
OLD="Manifest"
NEW="Charter"
OLD_LOWER="manifest"
NEW_LOWER="charter"

DRY=false
[[ "${1:-}" == "--dry-run" ]] && DRY=true

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "  $*"; }
step() { echo; echo "── $* ──────────────────────────────────────────────────"; }
warn() { echo "  ⚠️  $*"; }

run() {
    # Prints command in dry-run mode, executes it otherwise
    if $DRY; then
        echo "  [dry] $*"
    else
        eval "$@"
    fi
}

# In-place sed that works on both GNU and BSD (macOS) sed
sedi() {
    local file="$1"; shift
    if $DRY; then
        # Show what would change (first 3 matches only)
        grep -n "${OLD}\|${OLD_LOWER}" "$file" 2>/dev/null | head -3 \
            | sed "s/^/  [dry]   /" || true
    else
        # macOS sed needs an explicit backup extension; we delete it after
        sed -i.bak "$@" "$file" && rm -f "${file}.bak"
    fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────
step "Preflight"

if [[ ! -f "project.yml" ]]; then
    echo "❌  Run this from the repo root (project.yml not found)"
    exit 1
fi

if ! command -v xcodegen &>/dev/null; then
    warn "xcodegen not found — install with: brew install xcodegen"
    warn "You'll need to run 'xcodegen generate' manually after this script."
fi

if $DRY; then
    echo "  DRY RUN — no files will be changed"
fi

# ── Step 1: Replace content in text files ─────────────────────────────────────
# Do this BEFORE renaming directories so paths are still predictable.
step "Step 1: Replacing content in text files"

# Build list of files that contain "Manifest" or "manifest"
# Exclude: build artifacts, .git, .venv, xcarchive, derived data
CONTENT_FILES=$(grep -rl "${OLD}\|${OLD_LOWER}" . \
    --include="*.swift"    \
    --include="*.yml"      \
    --include="*.yaml"     \
    --include="*.sh"       \
    --include="*.md"       \
    --include="*.plist"    \
    --include="*.svg"      \
    --include="*.json"     \
    --include="*.toml"     \
    --include="*.xcscheme" \
    --include="*.pbxproj"  \
    --include="*.py"       \
    --include="gen-icons"  \
    --include="release"    \
    --include="build-release" \
    2>/dev/null \
    | grep -v "^\./\.git"            \
    | grep -v "^\./\.venv"           \
    | grep -v "\.xcarchive"          \
    | grep -v "DerivedData"          \
    | grep -v "rename-to-charter"    \
    || true)

if [[ -z "$CONTENT_FILES" ]]; then
    log "No files with Manifest references found."
else
    while IFS= read -r f; do
        log "Updating: $f"
        sedi "$f" \
            -e "s/${OLD}/${NEW}/g" \
            -e "s/${OLD_LOWER}/${NEW_LOWER}/g"
    done <<< "$CONTENT_FILES"
fi

# ── Step 2: Rename directories ─────────────────────────────────────────────────
# Order matters — rename children before parents.
step "Step 2: Renaming directories"

rename_dir() {
    local src="$1" dst="$2"
    if [[ -d "$src" ]]; then
        log "mv $src → $dst"
        run "mv \"$src\" \"$dst\""
    else
        log "skip (not found): $src"
    fi
}

# Test directories first
rename_dir "ManifestTests"          "CharterTests"

# Main source directory
rename_dir "${OLD}"                  "${NEW}"

# Xcode project — rename after content has been updated so pbxproj refs match
rename_dir "${OLD}.xcodeproj"       "${NEW}.xcodeproj"

# Build artefacts (optional — safe to delete these; xcodegen will recreate)
if [[ -d "build/${OLD}.xcarchive" ]]; then
    log "Removing stale xcarchive: build/${OLD}.xcarchive"
    run "rm -rf \"build/${OLD}.xcarchive\""
fi

# ── Step 3: Rename the xcscheme file ──────────────────────────────────────────
step "Step 3: Renaming xcscheme"

SCHEME_SRC="${NEW}.xcodeproj/xcshareddata/xcschemes/${OLD}.xcscheme"
SCHEME_DST="${NEW}.xcodeproj/xcshareddata/xcschemes/${NEW}.xcscheme"

if $DRY; then
    log "[dry] mv $SCHEME_SRC → $SCHEME_DST"
elif [[ -f "$SCHEME_SRC" ]]; then
    mv "$SCHEME_SRC" "$SCHEME_DST"
    log "Renamed xcscheme → ${NEW}.xcscheme"
else
    log "xcscheme already renamed or not found — skipping"
fi

# ── Step 4: Update the mise gen-icons task path ───────────────────────────────
step "Step 4: Checking mise tasks"

TASK_FILE="mise/tasks/gen-icons"
if [[ -f "$TASK_FILE" ]]; then
    log "Updating $TASK_FILE"
    sedi "$TASK_FILE" \
        -e "s/${OLD}/${NEW}/g" \
        -e "s/${OLD_LOWER}/${NEW_LOWER}/g"
fi

# ── Step 5: Regenerate Xcode project ──────────────────────────────────────────
step "Step 5: Regenerating Xcode project"

if $DRY; then
    log "[dry] xcodegen generate"
elif command -v xcodegen &>/dev/null; then
    log "Running xcodegen generate..."
    xcodegen generate
    log "✅  Xcode project regenerated"
else
    warn "xcodegen not available — run manually: xcodegen generate"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
step "Done"

if $DRY; then
    echo "  Dry run complete. Run without --dry-run to apply changes."
else
    echo "  ✅  Rename complete."
    echo
    echo "  Next steps:"
    echo "    1. Open Charter.xcodeproj and verify the scheme + targets"
    echo "    2. Check Build Settings → Product Name is 'Charter'"
    echo "    3. Clean build folder: ⇧⌘K"
    echo "    4. Build and run: ⌘R"
    echo
    echo "  If SwiftData migrations fail on first launch, delete the app"
    echo "  from the simulator/device and reinstall (bundle ID changed)."
fi
