#!/usr/bin/env python3
"""
generate_charter_svg.py
━━━━━━━━━━━━━━━━━━━━━━━
Generates the Charter wax-seal macOS icon as a standalone SVG.
No dependencies beyond the Python standard library.

USAGE
─────
  # Default: 1024px Navy/Amber icon → charter-icon.svg
  python scripts/generate_charter_svg.py

  # Custom size
  python scripts/generate_charter_svg.py --size 512

  # Custom colors
  python scripts/generate_charter_svg.py --bg "#FFFFFF" --ring "#1A2340" --c "#1A2340"

  # Multiple sizes at once (useful for macOS icon set)
  python scripts/generate_charter_svg.py --all-sizes

  # No squircle clipping (flat square, useful for Figma import)
  python scripts/generate_charter_svg.py --no-squircle

  # Output to specific path
  python scripts/generate_charter_svg.py --size 512 --out assets/icon-512.svg

MISE TASK
─────────
  Add to your mise.toml:

    [tasks.icon]
    description = "Generate Charter SVG icon assets"
    run = "python scripts/generate_charter_svg.py --all-sizes"

IMPORTING INTO FIGMA
────────────────────
  File → Import → select any generated SVG.
  The mark is fully vector; ungroup to edit individual elements.
  Use --no-squircle if you want to apply your own corner mask in Figma.

CONVERTING TO PNG (for macOS .icns)
────────────────────────────────────
  brew install librsvg
  rsvg-convert -w 1024 -h 1024 charter-icon.svg -o charter-icon-1024.png

  Then use iconutil or Image2Icon to build the .icns from the PNGs.
"""

import math
import argparse
import sys
from pathlib import Path


# ── Design tokens ─────────────────────────────────────────────────────────────
NAVY  = "#1A2340"
AMBER = "#E8A530"

# macOS icon sizes (for --all-sizes)
MACOS_SIZES = [16, 32, 64, 128, 256, 512, 1024]


# ── Core geometry + SVG builder ────────────────────────────────────────────────

def build_svg(
    size:             int   = 1024,
    bg:               str   = NAVY,
    fg_ring:          str   = AMBER,
    fg_c:             str   = AMBER,
    squircle:         bool  = True,
    corner_radius_pct: float = 0.22,
) -> str:
    """
    Returns a self-contained SVG string for the Charter wax-seal mark.

    All geometry is parametric — every measurement is derived from `size`
    so the mark scales perfectly to any resolution.

    Parameters
    ──────────
    size              Overall width/height in px
    bg                Background fill color
    fg_ring           Color for the outer ring, inner ring, ticks, and pips
    fg_c              Color for the C letterform
    squircle          If True, clips to a macOS-style rounded square
    corner_radius_pct Corner radius as a fraction of size (0.22 ≈ macOS default)
    """
    cx = cy = size / 2

    # ── Ring geometry ──
    pad      = size * 0.08          # inset from edge
    Ro       = size / 2 - pad       # outer ring radius
    Ri       = Ro - size * 0.055    # inner ring radius
    Rm       = (Ro + Ri) / 2        # midpoint (for pip placement)

    # ── Stroke weights (scale with size) ──
    sw_outer = size * 0.022
    sw_inner = size * 0.013
    sw_tick  = size * 0.020
    sw_c     = size * 0.100         # the bold C stroke
    pip_r    = sw_tick * 0.38       # pip dot radius

    # ── Squircle corner radius ──
    cr = size * corner_radius_pct

    # ── 8 radial tick marks ──
    # Evenly spaced at cardinal + diagonal bearings, starting at 12 o'clock (-90°)
    ticks = []
    for i in range(8):
        a  = (i * 45 - 90) * math.pi / 180
        ticks.append((
            cx + Ri * math.cos(a), cy + Ri * math.sin(a),   # inner point
            cx + Ro * math.cos(a), cy + Ro * math.sin(a),   # outer point
        ))

    # ── 8 pip dots (sit between the ticks, on the midpoint ring) ──
    pips = []
    for i in range(8):
        a = ((i + 0.5) * 45 - 90) * math.pi / 180
        pips.append((cx + Rm * math.cos(a), cy + Rm * math.sin(a)))

    # ── C letterform arc ──
    # A circular arc with an 82° gap on the right side.
    # Start point = top of the gap, end point = bottom of the gap.
    Rc  = Ri * 0.62                            # C radius
    sA  = (82 / 2) * math.pi / 180            # half the gap angle in radians
    sx  = cx + Rc * math.cos(sA)              # start x (top-right)
    sy  = cy - Rc * math.sin(sA)              # start y (top-right)
    ex  = cx + Rc * math.cos(-sA)             # end x   (bottom-right)
    ey  = cy + Rc * math.sin(sA)              # end y   (bottom-right)
    # SVG arc: large-arc-flag=1 sweeps the long way around (the left 278°)
    arc = f"M {sx:.2f} {sy:.2f} A {Rc:.2f} {Rc:.2f} 0 1 0 {ex:.2f} {ey:.2f}"

    # ── Assemble SVG ──
    def f(n): return f"{n:.2f}"

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg"',
        f'     width="{size}" height="{size}" viewBox="0 0 {size} {size}">',
        f'',
        f'  <!-- Charter wax-seal mark -->',
        f'  <!-- size={size}  bg={bg}  ring={fg_ring}  C={fg_c} -->',
        f'',
        f'  <defs>',
    ]

    if squircle:
        lines += [
            f'    <!-- Squircle clip (macOS icon shape) -->',
            f'    <clipPath id="sq">',
            f'      <rect width="{size}" height="{size}" rx="{f(cr)}" ry="{f(cr)}"/>',
            f'    </clipPath>',
        ]

    lines += [
        f'    <!-- Subtle depth gradient (brightens top-left, darkens bottom-right) -->',
        f'    <radialGradient id="depth" cx="35%" cy="30%" r="65%">',
        f'      <stop offset="0%"   stop-color="#ffffff" stop-opacity="0.07"/>',
        f'      <stop offset="100%" stop-color="#000000" stop-opacity="0.10"/>',
        f'    </radialGradient>',
        f'  </defs>',
        f'',
        f'  <!-- Background -->',
        f'  <rect id="bg" width="{size}" height="{size}"',
        f'        rx="{f(cr) if squircle else "0"}" fill="{bg}"/>',
        f'',
        f'  <!-- Seal mark -->',
        f'  <g id="seal"' + (' clip-path="url(#sq)"' if squircle else '') + '>',
        f'',
        f'    <!-- Outer ring -->',
        f'    <circle cx="{f(cx)}" cy="{f(cy)}" r="{f(Ro)}"',
        f'            stroke="{fg_ring}" stroke-width="{f(sw_outer)}" fill="none"/>',
        f'',
        f'    <!-- Inner ring (slightly transparent) -->',
        f'    <circle cx="{f(cx)}" cy="{f(cy)}" r="{f(Ri)}"',
        f'            stroke="{fg_ring}" stroke-width="{f(sw_inner)}" fill="none" opacity="0.55"/>',
        f'',
        f'    <!-- Radial tick marks (8 × evenly spaced, cardinal + diagonal) -->',
    ]

    for x1, y1, x2, y2 in ticks:
        lines.append(
            f'    <line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}"'
            f' stroke="{fg_ring}" stroke-width="{f(sw_tick)}" opacity="0.6"/>'
        )

    lines += [
        f'',
        f'    <!-- Pip dots between ticks (8 × on midpoint ring) -->',
    ]

    for px, py in pips:
        lines.append(
            f'    <circle cx="{f(px)}" cy="{f(py)}" r="{f(pip_r)}"'
            f' fill="{fg_ring}" opacity="0.35"/>'
        )

    lines += [
        f'',
        f'    <!-- C letterform: bold arc, 82° gap opening on the right -->',
        f'    <path d="{arc}"',
        f'          stroke="{fg_c}" stroke-width="{f(sw_c)}"',
        f'          stroke-linecap="round" fill="none"/>',
        f'',
        f'  </g>',
        f'',
        f'  <!-- Depth overlay (applies gradient on top of everything) -->',
        f'  <rect width="{size}" height="{size}"',
        f'        rx="{f(cr) if squircle else "0"}" fill="url(#depth)"/>',
        f'',
        f'</svg>',
    ]

    return "\n".join(lines)


# ── CLI ────────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(
        description="Generate the Charter wax-seal SVG icon.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--size",        type=int,   default=1024,   help="Icon size in px (default: 1024)")
    p.add_argument("--bg",          type=str,   default=NAVY,   help=f"Background color (default: {NAVY})")
    p.add_argument("--ring",        type=str,   default=AMBER,  help=f"Ring/tick color  (default: {AMBER})")
    p.add_argument("--c",           type=str,   default=AMBER,  help=f"C stroke color   (default: {AMBER})")
    p.add_argument("--out",         type=str,   default=None,   help="Output file path (default: charter-icon-{size}.svg)")
    p.add_argument("--all-sizes",   action="store_true",        help=f"Generate all macOS sizes: {MACOS_SIZES}")
    p.add_argument("--no-squircle", action="store_true",        help="Skip squircle clipping (flat square, better for Figma)")
    args = p.parse_args()

    squircle = not args.no_squircle

    if args.all_sizes:
        out_dir = Path(args.out) if args.out else Path(".")
        out_dir.mkdir(parents=True, exist_ok=True)
        for sz in MACOS_SIZES:
            svg  = build_svg(sz, bg=args.bg, fg_ring=args.ring, fg_c=args.c, squircle=squircle)
            path = out_dir / f"charter-icon-{sz}.svg"
            path.write_text(svg, encoding="utf-8")
            print(f"  ✅  {path}  ({len(svg):,} bytes)")
        print(f"\nGenerated {len(MACOS_SIZES)} icons in {out_dir}/")
    else:
        svg  = build_svg(args.size, bg=args.bg, fg_ring=args.ring, fg_c=args.c, squircle=squircle)
        path = Path(args.out) if args.out else Path(f"charter-icon-{args.size}.svg")
        path.write_text(svg, encoding="utf-8")
        print(f"✅  {path}  ({len(svg):,} bytes)")


if __name__ == "__main__":
    main()
