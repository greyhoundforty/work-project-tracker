#!/usr/bin/env python3
"""
scripts/populate-xcassets.py

Copies the correct PNG from build/AppIcon.iconset into
Charter/Assets.xcassets/AppIcon.appiconset/ for every slot
declared in Contents.json, then rewrites Contents.json cleanly.

If Contents.json is missing or empty it creates one from scratch.

Usage:
    python scripts/populate-xcassets.py
    python scripts/populate-xcassets.py --dry-run
    python scripts/populate-xcassets.py --iconset build/AppIcon.iconset
    python scripts/populate-xcassets.py --xcassets Charter/Assets.xcassets/AppIcon.appiconset
"""

import argparse
import json
import shutil
import sys
from pathlib import Path

# ── macOS AppIcon slot definitions ────────────────────────────────────────────
# Each entry = (size_pt, scale, pixel_size)
# These are the standard macOS slots Xcode expects.
MACOS_SLOTS = [
    ("16x16",  "1x",  16),
    ("16x16",  "2x",  32),
    ("32x32",  "1x",  32),
    ("32x32",  "2x",  64),
    ("128x128","1x",  128),
    ("128x128","2x",  256),
    ("256x256","1x",  256),
    ("256x256","2x",  512),
    ("512x512","1x",  512),
    ("512x512","2x",  1024),
]

# ── Iconset filename map: pixel_size → filename in .iconset ───────────────────
ICONSET_FILENAME = {
    16:   "icon_16x16.png",
    32:   "icon_16x16@2x.png",   # 32px is the @2x of 16pt
    64:   "icon_32x32@2x.png",
    128:  "icon_128x128.png",
    256:  "icon_128x128@2x.png",
    512:  "icon_256x256@2x.png",
    1024: "icon_512x512@2x.png",
}

# For slots where size_pt px == pixel_size (1x slots not covered above)
ICONSET_FILENAME_1X = {
    32:   "icon_32x32.png",
    256:  "icon_256x256.png",
    512:  "icon_512x512.png",
}


def iconset_source(size_pt: str, scale: str, pixel_size: int) -> str:
    """Return the iconset filename that should supply this xcassets slot."""
    # @2x slots use the @2x iconset file
    if scale == "2x":
        return ICONSET_FILENAME[pixel_size]
    # 1x slots: some pixel sizes have a dedicated 1x file
    if pixel_size in ICONSET_FILENAME_1X:
        return ICONSET_FILENAME_1X[pixel_size]
    return ICONSET_FILENAME[pixel_size]


def xcassets_filename(size_pt: str, scale: str, pixel_size: int) -> str:
    """Canonical filename to use inside the appiconset folder."""
    # Use a clear naming convention: Charter-{pixel_size}.png
    # We include pixel size (not pt) so the name is unambiguous.
    return f"Charter-{pixel_size}.png"


def build_contents_json(slots) -> dict:
    """Build a valid Contents.json for an macOS appiconset."""
    images = []
    for size_pt, scale, pixel_size in slots:
        images.append({
            "filename": xcassets_filename(size_pt, scale, pixel_size),
            "idiom":    "mac",
            "scale":    scale,
            "size":     size_pt,
        })
    return {
        "images": images,
        "info": {
            "author":  "xcode",
            "version": 1,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Populate xcassets AppIcon from iconset.")
    parser.add_argument("--iconset",  default="build/AppIcon.iconset",
                        help="Path to the .iconset directory")
    parser.add_argument("--xcassets", default="Charter/Assets.xcassets/AppIcon.appiconset",
                        help="Path to the appiconset directory")
    parser.add_argument("--dry-run",  action="store_true",
                        help="Preview actions without writing any files")
    args = parser.parse_args()

    dry     = args.dry_run
    iconset = Path(args.iconset)
    xcasset = Path(args.xcassets)

    tag  = "[dry] " if dry else ""
    ok   = lambda m: print(f"  ✅  {m}")
    err  = lambda m: print(f"  ❌  {m}")
    info = lambda m: print(f"  →   {m}")

    # ── Validate source ───────────────────────────────────────────────────────
    if not iconset.is_dir():
        err(f"Iconset not found: {iconset}")
        err("Run  mise run icon  to generate it first.")
        sys.exit(1)

    if not dry:
        xcasset.mkdir(parents=True, exist_ok=True)

    print(f"\n  Source : {iconset}")
    print(f"  Target : {xcasset}")
    print(f"  Mode   : {'DRY RUN' if dry else 'LIVE'}\n")

    errors = 0

    # ── Copy each slot ────────────────────────────────────────────────────────
    for size_pt, scale, pixel_size in MACOS_SLOTS:
        src_name = iconset_source(size_pt, scale, pixel_size)
        dst_name = xcassets_filename(size_pt, scale, pixel_size)
        src      = iconset / src_name
        dst      = xcasset / dst_name

        if not src.exists():
            err(f"Missing in iconset: {src_name}  (needed for {size_pt} @{scale})")
            errors += 1
            continue

        src_bytes = src.stat().st_size
        info(f"{tag}cp  {src_name:30s}  →  {dst_name}  ({src_bytes:,} bytes)")

        if not dry:
            shutil.copy2(src, dst)

    # ── Write Contents.json ───────────────────────────────────────────────────
    contents      = build_contents_json(MACOS_SLOTS)
    contents_path = xcasset / "Contents.json"
    contents_json = json.dumps(contents, indent=2) + "\n"

    info(f"{tag}Writing Contents.json")

    if not dry:
        contents_path.write_text(contents_json, encoding="utf-8")

    if dry:
        print("\n  Contents.json preview:")
        for line in contents_json.splitlines()[:20]:
            print(f"    {line}")
        if len(contents_json.splitlines()) > 20:
            print("    ...")

    # ── Summary ───────────────────────────────────────────────────────────────
    print()
    if errors:
        err(f"{errors} source file(s) missing — check your iconset.")
        sys.exit(1)
    elif dry:
        print("  Dry run complete. Run without --dry-run to apply.")
    else:
        ok(f"All {len(MACOS_SLOTS)} slots populated.")
        ok("Contents.json written.")
        print()
        print("  Next: clean build in Xcode  ⇧⌘K  then  ⌘R")


if __name__ == "__main__":
    main()
