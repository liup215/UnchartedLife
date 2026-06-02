#!/usr/bin/env python3
"""
Generate SVG sprite assets for the Prologue scene molecules.
Six sugars: Glucose, Fructose, Galactose, Sucrose, Lactose, Maltose.
Style: Sci-fi bioluminescent, dark background, educational labels.
"""

import math
from pathlib import Path

# ---------------------------------------------------------------------------
#  Style constants
# ---------------------------------------------------------------------------
BG_COLOR   = "#0A0A1A"      # dark navy
STROKE_W   = 4
FONT_SMALL = 14
FONT_MED   = 16
FONT_BIG   = 20
GLOW_COL   = "#00FFFF"

# ---------------------------------------------------------------------------
#  Geometry helpers
# ---------------------------------------------------------------------------
def ngon(cx, cy, r, n, rot_deg=0):
    """Return list of (x,y) vertices for a regular n-gon."""
    pts = []
    for i in range(n):
        ang = math.radians(rot_deg + i * 360 / n)
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts

def poly_line(pts, close=False):
    """SVG <polyline> or <polygon> points string."""
    s = " ".join(f"{x:.3f},{y:.3f}" for x, y in pts)
    return s + (f" {pts[0][0]:.3f},{pts[0][1]:.3f}" if close else "")

# ---------------------------------------------------------------------------
#  SVG building blocks
# ---------------------------------------------------------------------------
SVG_HEADER = """<svg width="512" height="512" viewBox="-200 -200 400 400" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="glow" x="-50%%" y="-50%%" width="200%%" height="200%%">
      <feGaussianBlur stdDeviation="4" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <filter id="strongGlow" x="-50%%" y="-50%%" width="200%%" height="200%%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <rect x="-200" y="-200" width="400" height="400" fill="%(bg)s" rx="0"/>
"""

SVG_FOOTER = "</svg>\n"

def hex_path(points):
    """Create SVG <path> d attribute from list of (x,y)."""
    if not points:
        return ""
    d = f"M {points[0][0]:.2f} {points[0][1]:.2f}"
    for x, y in points[1:]:
        d += f" L {x:.2f} {y:.2f}"
    d += " Z"
    return d

def draw_atom(cx, cy, r, color, label=None, label_color="#FFFFFF", glow="glow"):
    """Draw a glowing carbon/nitrogen/oxygen sphere + optional text label."""
    parts = [f'  <circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r:.2f}" fill="{color}" stroke="{GLOW_COL}" stroke-width="2" filter="url(#{glow})" />\n']
    if label:
        parts.append(f'  <text x="{cx:.2f}" y="{cy:.2f}" fill="{label_color}" font-size="{FONT_SMALL}px" font-family="Arial, sans-serif" font-weight="bold" text-anchor="middle" dominant-baseline="central">{label}</text>\n')
    return "".join(parts)

def draw_bond(p1, p2, color, width=STROKE_W, glow="glow"):
    x1, y1 = p1
    x2, y2 = p2
    return f'  <line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke="{color}" stroke-width="{width}" stroke-linecap="round" filter="url(#{glow})" />\n'

def draw_label(x, y, text, color="#FFFFFF", size=FONT_MED, anchor="middle"):
    return f'  <text x="{x:.2f}" y="{y:.2f}" fill="{color}" font-size="{size}px" font-family="Arial, sans-serif" font-weight="bold" text-anchor="{anchor}" dominant-baseline="central">{text}</text>\n'

def draw_oh_group(x, y, direction, color="#FF00FF"):
    """Draw an -OH label with a short line pointing to a carbon."""
    # direction: "up", "down", "left", "right", or (dx,dy) tuple
    offsets = {"up": (0, -35), "down": (0, 35), "left": (-35, 0), "right": (35, 0)}
    dx, dy = offsets.get(direction, direction)
    tx, ty = x + dx, y + dy
    line = f'  <line x1="{x:.2f}" y1="{y:.2f}" x2="{tx:.2f}" y2="{ty:.2f}" stroke="{color}" stroke-width="3" stroke-linecap="round" />\n'
    text = f'  <text x="{tx:.2f}" y="{ty:.2f}" fill="{color}" font-size="{FONT_MED}px" font-family="Arial, sans-serif" font-weight="bold" text-anchor="middle" dominant-baseline="central">OH</text>\n'
    return line + text

# ---------------------------------------------------------------------------
#  Individual molecule generators
# ---------------------------------------------------------------------------
def _halo_background():
    """Soft radial glow behind molecule (transparent-friendly)."""
    return ('  <defs>\n'
            '    <radialGradient id="bgHalo" cx="50%" cy="50%" r="50%">\n'
            '      <stop offset="0%" stop-color="#0A0A1A" stop-opacity="0.95"/>\n'
            '      <stop offset="70%" stop-color="#0A0A1A" stop-opacity="0.6"/>\n'
            '      <stop offset="100%" stop-color="#0A0A1A" stop-opacity="0.0"/>\n'
            '    </radialGradient>\n'
            '  </defs>\n'
            '  <circle cx="0" cy="0" r="180" fill="url(#bgHalo)" />\n')

def mol_glucose():
    """Glucose: hexagonal pyranose ring, alpha configuration, C4-OH down."""
    r = 90
    pts = ngon(0, 0, r, 6, rot_deg=30)  # 6 vertices, flat top / bottom

    svg = SVG_HEADER % {"bg": "transparent"}
    svg += _halo_background()
    # Ring bonds
    for i in range(6):
        svg += draw_bond(pts[i], pts[(i+1)%6], "#00FF88")  # green glow bonds
    # Oxygen at center
    svg += draw_atom(0, 0, 18, "#00FFFF", label="O", label_color="#000000", glow="strongGlow")
    # C1 - C6 atoms + labels
    colors = ["#00FF88"]*6
    labels = [f"C{i+1}" for i in range(6)]
    label_colors = ["#FFFFFF"]*6
    label_colors[0] = "#FFFF00"  # C1 highlighted
    for i in range(6):
        svg += draw_atom(pts[i][0], pts[i][1], 14, colors[i], label=labels[i], label_color=label_colors[i])
    # -OH groups on each carbon (simplified: all pointing outward)
    # C1 OH down (alpha)
    svg += draw_oh_group(pts[0][0], pts[0][1], "down", "#FF00FF")   # C1-OH alpha down
    svg += draw_oh_group(pts[1][0], pts[1][1], "up",   "#00FFFF")   # C2-OH
    svg += draw_oh_group(pts[2][0], pts[2][1], "down", "#00FFFF")   # C3-OH
    svg += draw_oh_group(pts[3][0], pts[3][1], "up",   "#00FFFF")   # C4-OH
    svg += draw_oh_group(pts[4][0], pts[4][1], "down", "#00FFFF")   # C5-OH
    # CH2OH on C5 position (special)
    # Actually C5 carries CH2OH, C6 is the CH2OH carbon itself. Let's simplify:
    # C6 is outside the ring in the chair, but for Haworth we put CH2OH on C5.
    # For simplicity in 2D sprite, we attach CH2OH label to C5 outward.
    svg += draw_oh_group(pts[4][0], pts[4][1], (0, 50), "#FFFFFF")  # CH2OH simplified
    svg += draw_label(0, 140, "Glucose", "#00FF88", size=28)
    svg += draw_label(0, 170, "α-D-Pyranose", "#888888", size=16)
    svg += SVG_FOOTER
    return svg

def mol_fructose():
    """Fructose: pentagonal furanose ring. 5-membered distinct from hexagon."""
    r = 90
    pts = ngon(0, 0, r, 5, rot_deg=18)  # 5-gon, start at top-ish
    svg = SVG_HEADER % {"bg": "transparent"}
    svg += _halo_background()
    # Ring bonds (orange)
    for i in range(5):
        svg += draw_bond(pts[i], pts[(i+1)%5], "#FF8800")
    # Oxygen at center
    svg += draw_atom(0, 0, 18, "#FFAA00", label="O", label_color="#000000", glow="strongGlow")
    # C1 - C5 atoms + labels
    for i in range(5):
        svg += draw_atom(pts[i][0], pts[i][1], 14, "#FF8800", label=f"C{i+1}")
    # OH groups outward
    svg += draw_oh_group(pts[0][0], pts[0][1], "up",   "#00FFFF")   # C1-OH
    svg += draw_oh_group(pts[1][0], pts[1][1], "down", "#00FFFF")   # C2-OH
    svg += draw_oh_group(pts[2][0], pts[2][1], "up",   "#00FFFF")   # C3-OH
    svg += draw_oh_group(pts[3][0], pts[3][1], "down", "#00FFFF")   # C4-OH
    # C5 CH2OH simplified
    svg += draw_oh_group(pts[4][0], pts[4][1], (0, 55), "#FFFFFF")
    svg += draw_label(0, -140, "Ketone", "#FF00FF", size=14)  # fructose = ketose
    svg += draw_label(0, 140, "Fructose", "#FF8800", size=28)
    svg += draw_label(0, 170, "β-D-Furanose", "#888888", size=16)
    svg += SVG_FOOTER
    return svg

def mol_galactose():
    """Galactose: hexagonal, C4 epimer difference highlighted in magenta."""
    r = 90
    pts = ngon(0, 0, r, 6, rot_deg=30)
    svg = SVG_HEADER % {"bg": "transparent"}
    svg += _halo_background()
    # Ring bonds
    for i in range(6):
        svg += draw_bond(pts[i], pts[(i+1)%6], "#88FF00")
    # Oxygen at center
    svg += draw_atom(0, 0, 18, "#00FFFF", label="O", label_color="#000000", glow="strongGlow")
    # C1 - C6 labels, C4 in MAGENTA
    label_colors = ["#FFFFFF"]*6
    label_colors[3] = "#FF00FF"  # C4 highlighted
    for i in range(6):
        svg += draw_atom(pts[i][0], pts[i][1], 14, "#88FF00", label=f"C{i+1}", label_color=label_colors[i])
    # OH groups
    svg += draw_oh_group(pts[0][0], pts[0][1], "up",   "#FF00FF") if True else ""
    # C1 OH down (alpha)
    svg += draw_oh_group(pts[0][0], pts[0][1], "down", "#FF00FF")   # C1 OH
    svg += draw_oh_group(pts[1][0], pts[1][1], "up",   "#00FFFF")   # C2 OH
    svg += draw_oh_group(pts[2][0], pts[2][1], "down", "#00FFFF")   # C3 OH
    # C4 OH UP (the epimer difference!)
    svg += draw_oh_group(pts[3][0], pts[3][1], "up",   "#FF00FF")   # C4 OH UP = difference
    svg += draw_oh_group(pts[4][0], pts[4][1], "up",   "#00FFFF")   # C5 OH
    svg += draw_oh_group(pts[4][0], pts[4][1], (0, 50), "#FFFFFF")  # CH2OH
    svg += draw_label(0, 140, "Galactose", "#88FF00", size=28)
    svg += draw_label(0, 170, "C4 Epimer of Glucose", "#FF00FF", size=16)
    svg += SVG_FOOTER
    return svg

def mol_sucrose():
    """Sucrose: Glucose (hex) + Fructose (pent) connected. Red warning color."""
    r_hex = 70
    r_pen = 55
    # Hex on left
    pts_hex = ngon(-80, 0, r_hex, 6, rot_deg=30)
    # Pent on right
    pts_pen = ngon(80, 0, r_pen, 5, rot_deg=18)
    svg = SVG_HEADER % {"bg": BG_COLOR}
    # Hex ring
    for i in range(6):
        svg += draw_bond(pts_hex[i], pts_hex[(i+1)%6], "#FF4444")
    # Pent ring
    for i in range(5):
        svg += draw_bond(pts_pen[i], pts_pen[(i+1)%5], "#FF4444")
    # Bridge bond between C1(α-Glc) and C2(β-Fru)
    svg += draw_bond(pts_hex[0], pts_pen[2], "#FFFFFF", width=6, glow="strongGlow")  # glycosidic bond
    # Oxygens at centers
    svg += draw_atom(-80, 0, 14, "#FF4444", label="O", label_color="#000000")
    svg += draw_atom(80, 0, 14, "#FF4444", label="O", label_color="#000000")
    # Labels
    svg += draw_label(-80, 95, "Glc", "#FF8888", size=16)
    svg += draw_label(80, 75, "Fru", "#FF8888", size=16)
    svg += draw_label(0, 140, "Sucrose", "#FF4444", size=28)
    svg += draw_label(0, 170, "α-1,2 β-glycosidic bond", "#888888", size=14)
    svg += SVG_FOOTER
    return svg

def mol_lactose():
    """Lactose: Galactose + Glucose. Purple."""
    r = 65
    pts1 = ngon(-75, 0, r, 6, rot_deg=30)   # Gal on left
    pts2 = ngon(75, 0, r, 6, rot_deg=30)    # Glc on right
    svg = SVG_HEADER % {"bg": "transparent"}
    svg += _halo_background()
    for i in range(6):
        svg += draw_bond(pts1[i], pts1[(i+1)%6], "#BB44FF")
        svg += draw_bond(pts2[i], pts2[(i+1)%6], "#BB44FF")
    # Beta-1,4 bond: C1 of Gal (pts1[0]) to C4 of Glc (pts2[3])
    svg += draw_bond(pts1[0], pts2[3], "#FFFFFF", width=6, glow="strongGlow")
    svg += draw_atom(-75, 0, 14, "#BB44FF", label="O", label_color="#000000")
    svg += draw_atom(75, 0, 14, "#BB44FF", label="O", label_color="#000000")
    svg += draw_label(-75, 90, "Gal", "#DD88FF", size=16)
    svg += draw_label(75, 90, "Glc", "#DD88FF", size=16)
    svg += draw_label(0, 150, "Lactose", "#BB44FF", size=28)
    svg += draw_label(0, 180, "β-1,4 bond", "#888888", size=14)
    svg += SVG_FOOTER
    return svg

def mol_maltose():
    """Maltose: Glucose + Glucose. Blue."""
    r = 65
    pts1 = ngon(-75, 0, r, 6, rot_deg=30)   # Glc 1
    pts2 = ngon(75, 0, r, 6, rot_deg=30)    # Glc 2
    svg = SVG_HEADER % {"bg": "transparent"}
    svg += _halo_background()
    for i in range(6):
        svg += draw_bond(pts1[i], pts1[(i+1)%6], "#4488FF")
        svg += draw_bond(pts2[i], pts2[(i+1)%6], "#4488FF")
    # Alpha-1,4 bond: C1 of Glc1 (pts1[0]) to C4 of Glc2 (pts2[3])
    svg += draw_bond(pts1[0], pts2[3], "#FFFFFF", width=6, glow="strongGlow")
    svg += draw_atom(-75, 0, 14, "#4488FF", label="O", label_color="#000000")
    svg += draw_atom(75, 0, 14, "#4488FF", label="O", label_color="#000000")
    svg += draw_label(-75, 90, "Glc", "#88BBFF", size=16)
    svg += draw_label(75, 90, "Glc", "#88BBFF", size=16)
    svg += draw_label(0, 150, "Maltose", "#4488FF", size=28)
    svg += draw_label(0, 180, "α-1,4 bond", "#888888", size=14)
    svg += SVG_FOOTER
    return svg

# ---------------------------------------------------------------------------
#  Main
# ---------------------------------------------------------------------------
FILES = {
    "mol_glucose.svg":  mol_glucose,
    "mol_fructose.svg":  mol_fructose,
    "mol_galactose.svg": mol_galactose,
    "mol_sucrose.svg":   mol_sucrose,
    "mol_lactose.svg":   mol_lactose,
    "mol_maltose.svg":   mol_maltose,
}

if __name__ == "__main__":
    out_dir = Path(__file__).parent
    for fname, builder in FILES.items():
        (out_dir / fname).write_text(builder(), encoding="utf-8")
        print(f"Generated {fname}")
    print(f"\nDone! 6 SVG files written to: {out_dir}")
