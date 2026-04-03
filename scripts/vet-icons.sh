#!/usr/bin/env bash
# scripts/vet-icons.sh
#
# Validates all Charter app icon assets using sips.
# Checks dimensions, file existence, and flags anything off-spec.
#
# Usage:
#   bash scripts/vet-icons.sh                    # checks all known icon locations
#   bash scripts/vet-icons.sh --iconset          # only check build/AppIcon.iconset
#   bash scripts/vet-icons.sh --xcassets         # only check Charter/Assets.xcassets
#   bash scripts/vet-icons.sh --fix              # regenerate icons after reporting issues

set -euo pipefail

# ── Locations to check ────────────────────────────────────────────────────────
ICONSET_DIR="build/AppIcon.iconset"
XCASSETS_DIR="Charter/Assets.xcassets/AppIcon.appiconset"

# ── Expected iconset spec (macOS .iconset format) ─────────────────────────────
# filename → expected pixel dimension (square)
declare -A ICONSET_SPEC=(
    ["icon_16x16.png"]=16
    ["icon_16x16@2x.png"]=32
    ["icon_32x32.png"]=32
    ["icon_32x32@2x.png"]=64
    ["icon_128x128.png"]=128
    ["icon_128x128@2x.png"]=256
    ["icon_256x256.png"]=256
    ["icon_256x256@2x.png"]=512
    ["icon_512x512.png"]=512
    ["icon_512x512@2x.png"]=1024
)


# ── Counters ──────────────────────────────────────────────────────────────────
ERRORS=0
WARNINGS=0
CHECKED=0

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()   { echo "  ✅  $*"; }
err()  { echo "  ❌  $*"; ERRORS=$((ERRORS + 1)); }
warn() { echo "  ⚠️   $*"; WARNINGS=$((WARNINGS + 1)); }
step() { echo; echo "── $* ──────────────────────────────────────────────────"; }

# Use sips to get pixel width of a PNG — || true prevents pipefail exit on bad files
get_width() {
    sips -g pixelWidth  "$1" 2>/dev/null | awk '/pixelWidth/  {print $2}' || true
}

get_height() {
    sips -g pixelHeight "$1" 2>/dev/null | awk '/pixelHeight/ {print $2}' || true
}

# Check a single file against an expected size
check_file() {
    local path="$1"
    local expected="$2"
    local label="$3"

    CHECKED=$((CHECKED + 1))

    if [[ ! -f "$path" ]]; then
        err "MISSING  $label (expected ${expected}×${expected})"
        return
    fi

    local w h
    w=$(get_width  "$path")
    h=$(get_height "$path")

    if [[ -z "$w" || -z "$h" ]]; then
        err "UNREADABLE  $label — sips could not read file"
        return
    fi

    if [[ "$w" != "$expected" || "$h" != "$expected" ]]; then
        err "WRONG SIZE  $label — got ${w}×${h}, expected ${expected}×${expected}"
    else
        ok "${expected}×${expected}  $label"
    fi

    # Extra: warn if the file is suspiciously small (suggests it was downsampled
    # from a source that was too low-res, leaving blurry results)
    local filesize
    filesize=$(stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null)
    local min_bytes=$(( expected * expected / 4 ))   # rough floor: ~1/4 byte per px
    if (( filesize < min_bytes )); then
        warn "  $label may be low quality (${filesize} bytes for ${expected}px icon)"
    fi
}

# ── Parse args ────────────────────────────────────────────────────────────────
CHECK_ICONSET=true
CHECK_XCASSETS=true
RUN_FIX=false

for arg in "$@"; do
    case "$arg" in
        --iconset)   CHECK_XCASSETS=false ;;
        --xcassets)  CHECK_ICONSET=false  ;;
        --fix)       RUN_FIX=true         ;;
    esac
done

# ── Check .iconset ─────────────────────────────────────────────────────────────
if $CHECK_ICONSET; then
    step "Checking $ICONSET_DIR"

    if [[ ! -d "$ICONSET_DIR" ]]; then
        warn "$ICONSET_DIR not found — skipping (run mise run icon to generate)"
    else
        for filename in $(echo "${!ICONSET_SPEC[@]}" | tr ' ' '\n' | sort); do
            expected="${ICONSET_SPEC[$filename]}"
            check_file "$ICONSET_DIR/$filename" "$expected" "$filename"
        done

        # Check for unexpected files in the iconset
        echo
        echo "  Extra files in $ICONSET_DIR:"
        unexpected=0
        while IFS= read -r -d '' f; do
            base=$(basename "$f")
            if [[ -z "${ICONSET_SPEC[$base]+_}" ]]; then
                warn "Unexpected file: $base"
                unexpected=$((unexpected + 1))
            fi
        done < <(find "$ICONSET_DIR" -name "*.png" -print0)
        (( unexpected == 0 )) && echo "    none"
    fi
fi

# ── Check xcassets ─────────────────────────────────────────────────────────────
if $CHECK_XCASSETS; then
    step "Checking $XCASSETS_DIR"

    if [[ ! -d "$XCASSETS_DIR" ]]; then
        warn "$XCASSETS_DIR not found — skipping"
    else
        CONTENTS="$XCASSETS_DIR/Contents.json"

        if [[ ! -f "$CONTENTS" ]]; then
            err "Contents.json missing from $XCASSETS_DIR"
            err "Run: python scripts/populate-xcassets.py"
        else
            # Parse Contents.json with Python — bash JSON parsing is unreliable
            # Extract lines of "filename|width_px" based on size+scale fields
            python3 - "$CONTENTS" << 'PYEOF'
import json, sys
from pathlib import Path

contents_path = Path(sys.argv[1])
xcassets_dir  = contents_path.parent

try:
    data = json.loads(contents_path.read_text())
except Exception as e:
    print(f"  ❌  Could not parse Contents.json: {e}")
    sys.exit(1)

errors = 0
checked = 0

for img in data.get("images", []):
    filename = img.get("filename", "")
    size_pt  = img.get("size", "")     # e.g. "16x16"
    scale    = img.get("scale", "1x")  # e.g. "1x" or "2x"

    if not filename:
        print(f"  ⚠️   Slot {size_pt} @{scale} has no filename in Contents.json")
        continue

    # Compute expected pixel size from pt size and scale
    try:
        pt = int(size_pt.split("x")[0])
        sc = int(scale.replace("x", ""))
        expected_px = pt * sc
    except ValueError:
        print(f"  ⚠️   Could not parse size '{size_pt}' scale '{scale}'")
        continue

    filepath = xcassets_dir / filename
    checked += 1

    if not filepath.exists():
        print(f"  ❌  MISSING  {filename}  (expected {expected_px}×{expected_px})")
        errors += 1
        continue

    import subprocess
    result = subprocess.run(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(filepath)],
        capture_output=True, text=True
    )
    w = h = None
    for line in result.stdout.splitlines():
        if "pixelWidth"  in line: w = int(line.split()[-1])
        if "pixelHeight" in line: h = int(line.split()[-1])

    if w is None or h is None:
        print(f"  ❌  UNREADABLE  {filename}")
        errors += 1
    elif w != expected_px or h != expected_px:
        print(f"  ❌  WRONG SIZE  {filename} — got {w}×{h}, expected {expected_px}×{expected_px}")
        errors += 1
    else:
        print(f"  ✅  {expected_px}×{expected_px}  {filename}")

print()
print(f"  Checked {checked} slots, {errors} error(s)")
if errors:
    print("  Run: python scripts/populate-xcassets.py")
    sys.exit(1)
PYEOF
        fi
    fi
fi

# ── Check the dock icon specifically ──────────────────────────────────────────
step "Dock icon sanity check (512pt / 1024px @2x)"

# The dock uses the 512pt slot, rendered at 1024px on Retina displays.
# Common issue: source image is correct size but was exported at a lower
# logical resolution, making it appear too large in the dock.

DOCK_CANDIDATES=(
    "$ICONSET_DIR/icon_512x512@2x.png"
    "$XCASSETS_DIR/Charter-1024.png"
)

for candidate in "${DOCK_CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then
        w=$(get_width  "$candidate")
        h=$(get_height "$candidate")
        dpi=$(sips -g dpiWidth "$candidate" 2>/dev/null | awk '/dpiWidth/ {print $2}')

        echo "  File:   $candidate"
        echo "  Size:   ${w}×${h} px"
        echo "  DPI:    ${dpi:-unknown}"

        if [[ "$w" == "1024" && "$h" == "1024" ]]; then
            ok "Dimensions correct (1024×1024)"
        else
            err "Expected 1024×1024, got ${w}×${h}"
        fi

        # Dock icon appearing too large is almost always a DPI mismatch.
        # macOS expects 72 dpi for PNG icons (it uses pixel count, not DPI,
        # but some tools embed 144 dpi which can confuse older tooling).
        if [[ -n "${dpi:-}" ]] && awk "BEGIN { exit ($dpi > 100) ? 0 : 1 }" 2>/dev/null; then
            warn "DPI is ${dpi} — some tools embed 144dpi in @2x exports."
            warn "Fix with: sips --setProperty dpiWidth 72 --setProperty dpiHeight 72 \"$candidate\""
        fi

        echo
    fi
done

# ── Optional fix ──────────────────────────────────────────────────────────────
if $RUN_FIX; then
    step "Applying fixes"

    # Normalise DPI on all icon PNGs to 72
    echo "  Setting dpiWidth/dpiHeight to 72 on all icon PNGs..."
    for dir in "$ICONSET_DIR" "$XCASSETS_DIR"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' f; do
            sips --setProperty dpiWidth 72 \
                 --setProperty dpiHeight 72 \
                 "$f" --out "$f" &>/dev/null
            echo "    fixed: $f"
        done < <(find "$dir" -name "*.png" -print0)
    done
    ok "DPI normalised. Rebuild in Xcode (⇧⌘K then ⌘R)."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
step "Summary"
echo "  Checked : $CHECKED files"
echo "  Errors  : $ERRORS"
echo "  Warnings: $WARNINGS"
echo

if (( ERRORS > 0 )); then
    echo "  ❌  Fix the errors above, then rerun: bash scripts/vet-icons.sh"
    echo "      To regenerate icons:              mise run icon"
    echo "      To also fix DPI issues:           bash scripts/vet-icons.sh --fix"
    exit 1
elif (( WARNINGS > 0 )); then
    echo "  ⚠️   All sizes correct but warnings need attention."
    echo "      Run with --fix to normalise DPI automatically."
    exit 0
else
    echo "  ✅  All icon assets look good."
    exit 0
fi
