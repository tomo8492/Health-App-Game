#!/usr/bin/env python3
"""
VITA CITY — Pixel Art Building Generator
========================================
13 building archetypes × 5 axis colors = 65 PNG sprites
Output: tools/pixel_art_output/building_<archetype>_<axis>.png
Canvas: 16×20 "pixels" × scale 4 → 64×80 pt (matches BuildingTextureGenerator)

Usage: python3 tools/generate_pixel_art.py
"""

from PIL import Image, ImageDraw
import os, sys

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "pixel_art_output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

SCALE  = 4     # each logical pixel → 4×4 real pixels
GRID_W = 16
GRID_H = 20

# ── Axis palettes (R,G,B) ──────────────────────────────────────────────────
AXES = {
    "exercise":  ( 51, 199,  89),
    "diet":      (255, 149,   0),
    "alcohol":   (175,  82, 222),
    "sleep":     (  0, 122, 255),
    "lifestyle": (255,  45,  85),
}

def dk(c, f=0.60): return tuple(max(0, int(x * f)) for x in c)
def lt(c, f=1.25): return tuple(min(255, int(x * f)) for x in c)
def r(c, a=255):   return (*c, a)

def make_palette(rgb):
    return {
        '.': (0,   0,   0,   0),          # transparent
        'B': r(rgb),                        # primary body
        'D': r(dk(rgb, 0.65)),             # dark body
        'R': r(lt(rgb, 1.20)),             # roof (lighter)
        'P': r(dk(rgb, 0.82)),             # mid shadow
        'W': (255, 238, 140, 215),         # window glow
        'F': r(dk(rgb, 0.35)),             # door (very dark)
        'G': (162, 158, 150, 255),         # ground strip
        'E': ( 72, 185,  82, 255),         # grass
        'U': ( 30, 144, 255, 255),         # water
        'O': (255, 210,   0, 255),         # gold / CP
        'N': (135,  90,  55, 255),         # brown (trunk)
        'T': ( 50, 140,  60, 255),         # tree leaf
        'X': (255, 255, 255, 180),         # white accent
        'S': (  0,   0,   0,  35),         # subtle shadow
    }

# ── Pixel grids (16 wide × 20 tall, row 0 = TOP) ──────────────────────────
#
# Legend:
#   .  transparent    B  body        D  dark body    R  roof
#   P  mid body       W  window      F  door/floor   G  ground strip
#   E  grass green    U  water blue  O  gold          N  trunk brown
#   T  tree leaf      X  white       S  shadow
#
GRIDS = {

    # ── House (generic residential) ───────────────────────────────────────
    "house": [
        "................",   #  0
        "................",   #  1
        ".......RR.......",   #  2
        "......RRRR......",   #  3
        ".....RRRRRR.....",   #  4
        "....RRRRRRRR....",   #  5
        "...RRRRRRRRRR...",   #  6
        "..RRRRRRRRRRRR..",   #  7
        "..DDDDDDDDDDDD..",   #  8
        "..DWWD....DWWD..",   #  9
        "..DWWD....DWWD..",   # 10
        "..DDDDDDDDDDDD..",   # 11
        "..DDDDDFFDDDDD..",   # 12
        "..DDDDDFFDDDDD..",   # 13
        "..DDDDDFFDDDDD..",   # 14
        "..DDDDDFFDDDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Gym (exercise) ────────────────────────────────────────────────────
    "gym": [
        "................",   #  0
        "..BBBBBBBBBBBB..",   #  1
        "..BBBBBBBBBBBB..",   #  2
        "..RRRRRRRRRRRR..",   #  3
        "..DDDDDDDDDDDD..",   #  4
        "..DWWWDDDDWWWD..",   #  5
        "..DWWWDDDDWWWD..",   #  6
        "..DWWWDDDDWWWD..",   #  7
        "..DDDDDDDDDDDD..",   #  8
        "..DDXXXXDXXXXDD.",   #  9  ← fitness equipment silhouette
        "..DDXXXXDXXXXDD.",   # 10
        "..DDDDDDDDDDDD..",   # 11
        "..DDDDDFFDDDDD..",   # 12
        "..DDDDDFFDDDDD..",   # 13
        "..DDDDDFFDDDDD..",   # 14
        "..DDDDDFFDDDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Stadium (exercise) ────────────────────────────────────────────────
    "stadium": [
        "................",   #  0
        "....BBBBBBBB....",   #  1
        "...BBBBBBBBBB...",   #  2
        "..BBBBBBBBBBBB..",   #  3
        "..BDDDDDDDDDDB..",   #  4
        "..BDDEEEEEEDDB..",   #  5
        "..BDEEEEEEEEDB..",   #  6
        "..BDDEEEEEEDDB..",   #  7
        "..BDDDDDDDDDDB..",   #  8
        "..BBBBBBBBBBBB..",   #  9
        "...RRRRRRRRRR...",   # 10
        "....DDDDDDDD....",   # 11
        "....DDDDDDDD....",   # 12
        "....DDDDDDDD....",   # 13
        "....DDDDDDDD....",   # 14
        "....DDDDDDDD....",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Park (exercise / lifestyle) ───────────────────────────────────────
    "park": [
        "................",   #  0
        "..TTT...TTT.....",   #  1
        ".TTTTT.TTTTT....",   #  2
        ".TTTTT.TTTTT.TT.",   #  3
        "..TTT...TTT.TTTT",   #  4
        "...N.....N..TTTT",   #  5
        "...N.....N...TT.",   #  6
        "EEEEEEEEEEEE.N..",   #  7
        "EEEEEEEEEEEEENEE",   #  8
        "EEEXXXEEEEEEEEEE",   #  9
        "EEEXXXEEEEEEEEEE",   # 10
        "EEEEEEEEEEEEEEEE",   # 11
        "EEEEEEEEEEEEEEEE",   # 12
        "EEEEEEEEEEEEEEEE",   # 13
        "EEEEEEEEEEEEEEEE",   # 14
        "EEEEEEEEEEEEEEEE",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Pool (exercise) ───────────────────────────────────────────────────
    "pool": [
        "................",   #  0
        "..BBBBBBBBBBBB..",   #  1
        "..BUUUUUUUUUUB..",   #  2
        "..BUUUUUUUUUUB..",   #  3
        "..BXXXXXXXXXXXB.",   #  4  ← wave line (17 wide — trimmed to 16 below)
        "..BUUUUUUUUUUB..",   #  5
        "..BUUUUUUUUUUB..",   #  6
        "..BXXXXXXXXXXXB.",   #  7
        "..BUUUUUUUUUUB..",   #  8
        "..BUUUUUUUUUUB..",   #  9
        "..BBBBBBBBBBBB..",   # 10
        "....DDDDDDDD....",   # 11
        "....DDDDDDDD....",   # 12
        "....DDDDDFFDDD..",   # 13
        "....DDDDDFFDDD..",   # 14
        "....DDDDDFFDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Shop (general store) ──────────────────────────────────────────────
    "shop": [
        "................",   #  0
        "....RRRRRRRRRR..",   #  1
        "...RBBBBBBBBBBR.",   #  2
        "..RBBBBBBBBBBBRR",   #  3
        "..DDDDDDDDDDDDDD",   #  4
        "..BBBBBBBBBBBBDD",   #  5  ← awning stripe
        "..DDDDDDDDDDDDDD",   #  6
        "..DDDDDDDDDDDDDD",   #  7
        "..DWWWDDDDWWWDDD",   #  8
        "..DWWWDDDDWWWDDD",   #  9
        "..DWWWDDDDWWWDDD",   # 10
        "..DXXXXXXXXXXXDD",   # 11  ← sign board
        "..DDDDDFFDDDDDDD",   # 12
        "..DDDDDFFDDDDDDD",   # 13
        "..DDDDDFFDDDDDDD",   # 14
        "..DDDDDFFDDDDDDD",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Market (farmers market / diet) ────────────────────────────────────
    "market": [
        "................",   #  0
        "...BBBBBBBBBB...",   #  1
        "..BBBBBBBBBBBB..",   #  2
        ".BB.BB.BB.BB.BB.",   #  3  ← scalloped awning
        "..DDDDDDDDDDDD..",   #  4
        "..DDDDDDDDDDDD..",   #  5
        "..DOODBOODBOODD.",   #  6  ← colourful produce
        "..DOODBOODBOODD.",   #  7
        "..DDDDDDDDDDDD..",   #  8
        "..DDDDDDDDDDDD..",   #  9
        "..DWWWDDDDWWWDD.",   # 10
        "..DWWWDDDDWWWDD.",   # 11
        "..DDDDDFFDDDDD..",   # 12
        "..DDDDDFFDDDDD..",   # 13
        "..DDDDDFFDDDDD..",   # 14
        "..DDDDDFFDDDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Cafe (diet / lifestyle) ───────────────────────────────────────────
    "cafe": [
        "..NN............",   #  0  ← chimney
        "..NN............",   #  1
        "..RRRRRRRRRRRR..",   #  2
        "..RRRRRRRRRRRR..",   #  3
        "..DDDDDDDDDDDD..",   #  4
        "..DWWWDDDDWWWDD.",   #  5
        "..DWWWDDDDWWWDD.",   #  6
        "..DWWWDDDDWWWDD.",   #  7
        "..DDDDDDDDDDDD..",   #  8
        "..DOOOOOOOOOODD.",   #  9  ← cafe sign in gold
        "..DDDDDDDDDDDD..",   # 10
        "..DWWWDDDDWWWDD.",   # 11
        "..DDDDDFFDDDDD..",   # 12
        "..DDDDDFFDDDDD..",   # 13
        "..DDDDDFFDDDDD..",   # 14
        "..DDDDDFFDDDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Tower (tall building / sleep) ─────────────────────────────────────
    "tower": [
        "................",   #  0
        ".......RR.......",   #  1
        "......RRRR......",   #  2
        ".....BBBBBB.....",   #  3
        "......BBBB......",   #  4
        "......BWWB......",   #  5
        "......BBBB......",   #  6
        "......BWWB......",   #  7
        "......BBBB......",   #  8
        "......BWWB......",   #  9
        "......BBBB......",   # 10
        "......BWWB......",   # 11
        "......BBBB......",   # 12
        ".....BBBBBB.....",   # 13
        "....BBBBBBBB....",   # 14
        "...BBBBBBBBBB...",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Clinic (sleep / health) ───────────────────────────────────────────
    "clinic": [
        "................",   #  0
        "..RRRRRRRRRRRR..",   #  1
        "..RRRRRRRRRRRR..",   #  2
        "..DDDDDDDDDDDD..",   #  3
        "..DDDDXXXXDDDD..",   #  4  ← cross (vertical)
        "..DDXXXXXXXXDD..",   #  5  ← cross (horizontal)
        "..DDDDXXXXDDDD..",   #  6
        "..DDDDDDDDDDDD..",   #  7
        "..DWWDDDDDWWDD..",   #  8
        "..DWWDDDDDWWDD..",   #  9
        "..DDDDDDDDDDDD..",   # 10
        "..DWWDDDDDWWDD..",   # 11
        "..DWWDDDDDWWDD..",   # 12
        "..DDDDDFFDDDDD..",   # 13
        "..DDDDDFFDDDDD..",   # 14
        "..DDDDDFFDDDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Library (lifestyle) ───────────────────────────────────────────────
    "library": [
        "................",   #  0
        ".......RR.......",   #  1
        "......RRRR......",   #  2
        ".....RRRRRR.....",   #  3
        "....RRRRRRRRRR..",   #  4
        "...RRRRRRRRRRRR.",   #  5
        "..RRRRRRRRRRRRRR",   #  6
        "..DDDDDDDDDDDDDD",   #  7
        "..BDDDDDDDDDDBD.",   #  8  ← columns
        "..BDDWWDDDWWDBD.",   #  9
        "..BDDWWDDDWWDBD.",   # 10
        "..BDDDDDDDDDDBD.",   # 11
        "..BDDDDFFDDDDBD.",   # 12
        "..BDDDDFFDDDDBD.",   # 13
        "..BDDDDFFDDDDBD.",   # 14
        "..BDDDDFFDDDDBD.",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Town Hall (lifestyle / city center) ───────────────────────────────
    "townhall": [
        ".......OO.......",   #  0  ← flag gold
        ".......BB.......",   #  1  ← flag pole
        "......BBBB......",   #  2
        ".....BBBBBB.....",   #  3  ← dome
        "....BBBBBBBBBB..",   #  4
        "..BBBBBBBBBBBBBB",   #  5
        "..XDDDDDDDDDDDXD",   #  6  ← columns
        "..XDWWDDDDDWWDXD",   #  7
        "..XDWWDDDDDWWDXD",   #  8
        "..XDDDDDDDDDDXDD",   #  9
        "..XDWWDDDDDWWDXD",   # 10
        "..XDWWDDDDDWWDXD",   # 11
        "..XDDDDFFDDDDXDD",   # 12
        "..XDDDDFFDDDDXDD",   # 13
        "..XDDDDFFDDDDXDD",   # 14
        "..XDDDDFFDDDDXDD",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Monument (streak tower / lifestyle) ───────────────────────────────
    "monument": [
        "................",   #  0
        ".......OO.......",   #  1  ← gold tip
        "......OOOO......",   #  2
        "......BBBB......",   #  3
        "......BBBB......",   #  4
        ".....BBWWBB.....",   #  5  ← marker
        "......BBBB......",   #  6
        "......BBBB......",   #  7
        "......BBBB......",   #  8
        "......BBBB......",   #  9
        "......BBBB......",   # 10
        "......BBBB......",   # 11
        "......BBBB......",   # 12
        ".....BBBBBB.....",   # 13
        "....BBBBBBBB....",   # 14
        "...BBBBBBBBBB...",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],
}

# ── Validation ────────────────────────────────────────────────────────────
errors = []
for name, grid in GRIDS.items():
    if len(grid) != GRID_H:
        errors.append(f"{name}: expected {GRID_H} rows, got {len(grid)}")
    for r_idx, row in enumerate(grid):
        if len(row) != GRID_W:
            errors.append(f"{name} row {r_idx}: expected {GRID_W} cols, got {len(row)} — '{row}'")

if errors:
    print("❌ Validation errors:")
    for e in errors: print(" ", e)
    sys.exit(1)
print(f"✅ All {len(GRIDS)} grids validated ({GRID_W}×{GRID_H})")

# ── Render ─────────────────────────────────────────────────────────────────
def render(grid, palette):
    img = Image.new("RGBA", (GRID_W * SCALE, GRID_H * SCALE), (0, 0, 0, 0))
    px  = img.load()
    for row_i, row in enumerate(grid):
        for col_i, ch in enumerate(row):
            color = palette.get(ch, (255, 0, 255, 255))  # magenta = unknown char
            for dy in range(SCALE):
                for dx in range(SCALE):
                    px[col_i * SCALE + dx, row_i * SCALE + dy] = color
    return img

count = 0
for axis_name, axis_rgb in AXES.items():
    palette = make_palette(axis_rgb)
    for arch_name, grid in GRIDS.items():
        img  = render(grid, palette)
        path = os.path.join(OUTPUT_DIR, f"building_{arch_name}_{axis_name}.png")
        img.save(path)
        count += 1

print(f"✅ Generated {count} PNG files → {OUTPUT_DIR}/")

# ── Generate preview sheet ────────────────────────────────────────────────
COLS        = len(GRIDS)
ROWS        = len(AXES)
THUMB_W     = GRID_W * SCALE
THUMB_H     = GRID_H * SCALE
PAD         = 6
LABEL_H     = 14
SHEET_W     = COLS * (THUMB_W + PAD) + PAD
SHEET_H     = ROWS * (THUMB_H + PAD + LABEL_H) + PAD + 24  # +24 for header

sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (28, 28, 36, 255))
draw  = ImageDraw.Draw(sheet)

arch_names = list(GRIDS.keys())
axis_names = list(AXES.keys())

for row_i, axis_name in enumerate(axis_names):
    palette = make_palette(AXES[axis_name])
    y_off   = PAD + 24 + row_i * (THUMB_H + PAD + LABEL_H)

    # axis label
    draw.text((PAD, y_off - LABEL_H), axis_name.upper(), fill=(200, 200, 200, 255))

    for col_i, arch_name in enumerate(arch_names):
        x_off = PAD + col_i * (THUMB_W + PAD)
        thumb = render(GRIDS[arch_name], palette)
        sheet.paste(thumb, (x_off, y_off), thumb)

        # arch name (tiny)
        draw.text((x_off, y_off + THUMB_H + 1), arch_name[:8], fill=(140, 140, 140, 255))

# column headers
for col_i, arch_name in enumerate(arch_names):
    x_off = PAD + col_i * (THUMB_W + PAD)
    draw.text((x_off, PAD), arch_name[:8], fill=(240, 240, 100, 255))

sheet_path = os.path.join(OUTPUT_DIR, "_PREVIEW_SHEET.png")
sheet.save(sheet_path)
print(f"✅ Preview sheet → {sheet_path}")
print(f"\n📂 Open: {OUTPUT_DIR}/")
