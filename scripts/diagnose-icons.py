#!/usr/bin/env python3
"""
scripts/diagnose-icons.py

Reads Contents.json from the appiconset, checks every declared slot,
lists orphaned files not referenced by Contents.json, and reports DPI
on the dock-critical 512pt/1024px image.

Usage:
    python scripts/diagnose-icons.py
    python scripts/diagnose-icons.py --xcassets Charter/Assets.xcassets/AppIcon.appiconset
    python scripts/diagnose-icons.py --fix      # deletes orphans + normalises DPI
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def sips_props(path: Path) -> dict:
    """Return a dict of sips properties for a PNG."""
    result = subprocess.run(
        ["sips", "-g", "all", str(path)],
        capture_output=True, text=True
    )
    props = {}
    for line in result.stdout.splitlines():
        line = line.strip()
        if ": " in line:
            k, _, v = line.partition(": ")
            props[k.strip()] = v.strip()
    return props


def px_size(size_pt: str, scale: str) -> int:
    """Convert a size string like '512x512' + scale '2x' to pixel count."""
    pt = int(size_pt.split("x")[0])
    sc = int(scale.replace("x", ""))
    return pt * sc


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--xcassets",
        default="Charter/Assets.xcassets/AppIcon.appiconset",
        help="Path to appiconset directory",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Delete orphaned files and normalise DPI to 72",
    )
    args = parser.parse_args()

    xcasset = Path(args.xcassets)
    contents_path = xcasset / "Contents.json"

    RESET  = "\033[0m"
    GREEN  = "\033[32m"
    RED    = "\033[31m"
    YELLOW = "\033[33m"
    BOLD   = "\033[1m"
    ok     = lambda m: print(f"  {GREEN}✅{RESET}  {m}")
    err    = lambda m: print(f"  {RED}❌{RESET}  {m}")
    warn   = lambda m: print(f"  {YELLOW}⚠️ {RESET}  {m}")
    info   = lambda m: print(f"      {m}")

    # ── Validate paths ────────────────────────────────────────────────────────
    if not xcasset.is_dir():
        err(f"Directory not found: {xcasset}")
        sys.exit(1)

    if not contents_path.exists():
        err(f"Contents.json not found in {xcasset}")
        err("Run: python scripts/populate-xcassets.py")
        sys.exit(1)

    try:
        contents = json.loads(contents_path.read_text())
    except json.JSONDecodeError as e:
        err(f"Could not parse Contents.json: {e}")
        sys.exit(1)

    images = contents.get("images", [])

    # ── Build set of declared filenames ───────────────────────────────────────
    declared = set()
    slots = []
    for img in images:
        fname = img.get("filename", "")
        size  = img.get("size", "")
        scale = img.get("scale", "1x")
        if fname:
            declared.add(fname)
        slots.append((fname, size, scale))

    # ── All PNGs physically present in the directory ──────────────────────────
    present = {f.name for f in xcasset.glob("*.png")}

    orphans  = sorted(present - declared)
    missing  = sorted(declared - present)

    # ── Section 1: Slot check ─────────────────────────────────────────────────
    print(f"\n{BOLD}── Slot check ({xcasset}){RESET}")
    print(f"   {len(slots)} slots declared in Contents.json\n")

    slot_errors = 0
    for fname, size_pt, scale in slots:
        if not fname:
            warn(f"Slot {size_pt} @{scale} has no filename assigned in Contents.json")
            slot_errors += 1
            continue

        expected = px_size(size_pt, scale)
        fpath = xcasset / fname

        if not fpath.exists():
            err(f"MISSING  {fname}  (slot {size_pt} @{scale}, expected {expected}×{expected})")
            slot_errors += 1
            continue

        props = sips_props(fpath)
        w = int(props.get("pixelWidth",  0))
        h = int(props.get("pixelHeight", 0))
        dpi_w = props.get("dpiWidth", "?")
        dpi_h = props.get("dpiHeight", "?")

        if w != expected or h != expected:
            err(f"WRONG SIZE  {fname}  got {w}×{h}, expected {expected}×{expected}")
            slot_errors += 1
        else:
            ok(f"{expected:>4}×{expected:<4}  {fname}")

        # DPI annotation — flag anything that isn't 72
        try:
            dpi_val = float(dpi_w)
            if dpi_val != 72.0:
                warn(f"  DPI is {dpi_w} (should be 72) — likely cause of oversized dock icon")
                if args.fix:
                    subprocess.run([
                        "sips",
                        "--setProperty", "dpiWidth",  "72",
                        "--setProperty", "dpiHeight", "72",
                        str(fpath), "--out", str(fpath),
                    ], capture_output=True)
                    info("→ DPI normalised to 72")
        except ValueError:
            pass

    # ── Section 2: Orphans ────────────────────────────────────────────────────
    print(f"\n{BOLD}── Orphaned files (in directory but not in Contents.json){RESET}")
    if not orphans:
        ok("None — directory is clean")
    else:
        for name in orphans:
            fpath = xcasset / name
            props = sips_props(fpath)
            w = props.get("pixelWidth", "?")
            h = props.get("pixelHeight", "?")
            warn(f"{name}  ({w}×{h}px) — not assigned to any slot")

        print()
        if args.fix:
            for name in orphans:
                (xcasset / name).unlink()
                info(f"Deleted: {name}")
            ok(f"Removed {len(orphans)} orphaned file(s)")
        else:
            print(f"  To remove them run:")
            print(f"    python scripts/diagnose-icons.py --fix")
            print()
            print(f"  Or manually:")
            for name in orphans:
                print(f"    rm \"{xcasset / name}\"")

    # ── Section 3: Missing slots ──────────────────────────────────────────────
    if missing:
        print(f"\n{BOLD}── Missing files (in Contents.json but not on disk){RESET}")
        for name in missing:
            err(f"{name}")
        print()
        print("  Run: python scripts/populate-xcassets.py")

    # ── Section 4: Dock icon deep check ───────────────────────────────────────
    print(f"\n{BOLD}── Dock icon deep check (512pt @2x = 1024px){RESET}")

    # Find the file assigned to the 512x512 @2x slot
    dock_file = None
    for fname, size_pt, scale in slots:
        if size_pt == "512x512" and scale == "2x" and fname:
            dock_file = xcasset / fname
            break

    if not dock_file or not dock_file.exists():
        err("Could not find 512x512 @2x file")
    else:
        props = sips_props(dock_file)
        w       = props.get("pixelWidth",  "?")
        h       = props.get("pixelHeight", "?")
        dpi_w   = props.get("dpiWidth",    "?")
        dpi_h   = props.get("dpiHeight",   "?")
        space   = props.get("space",       "?")
        has_alpha = props.get("hasAlpha",  "?")
        fmt     = props.get("format",      "?")

        print(f"  File      : {dock_file.name}")
        print(f"  Dimensions: {w}×{h} px")
        print(f"  DPI       : {dpi_w} × {dpi_h}")
        print(f"  Format    : {fmt}")
        print(f"  Colorspace: {space}")
        print(f"  Has alpha : {has_alpha}")
        print(f"  File size : {dock_file.stat().st_size:,} bytes")
        print()

        issues = 0
        if w == "1024" and h == "1024":
            ok("Dimensions correct (1024×1024)")
        else:
            err(f"Wrong dimensions: {w}×{h} (need 1024×1024)")
            issues += 1

        try:
            if float(dpi_w) == 72.0:
                ok("DPI correct (72)")
            else:
                err(f"DPI is {dpi_w} — macOS may render this icon larger than expected")
                err("Fix: python scripts/diagnose-icons.py --fix")
                issues += 1
        except (ValueError, TypeError):
            warn(f"Could not parse DPI: {dpi_w}")

        if issues == 0:
            print()
            warn("If dock icon still appears large, the SVG source may have too much")
            warn("padding. The icon mark should fill ~85% of the canvas, not 60-70%.")

    # ── Summary ───────────────────────────────────────────────────────────────
    print(f"\n{BOLD}── Summary{RESET}")
    total_issues = slot_errors + len(orphans) + len(missing)
    if total_issues == 0:
        ok("All clear. Clean build in Xcode (⇧⌘K) then rebuild (⌘R).")
    else:
        if orphans and not args.fix:
            warn(f"{len(orphans)} orphan(s) — run with --fix to delete them")
        if slot_errors:
            err(f"{slot_errors} slot error(s) — run populate-xcassets.py")
        if missing:
            err(f"{len(missing)} missing file(s) — run populate-xcassets.py")


if __name__ == "__main__":
    main()
