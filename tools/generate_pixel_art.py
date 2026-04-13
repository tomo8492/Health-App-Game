#!/usr/bin/env python3
"""
VITA CITY — Pixel Art Building Generator  v2
=============================================
15 building archetypes × 5 axis colors = 75 PNG sprites
+ 2 decoration types (fountain, streetlight) × 5 colors = 10 PNG sprites
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
        'D': r(dk(rgb, 0.65)),             # dark body (shaded front wall)
        'R': r(lt(rgb, 1.22)),             # roof (lighter)
        'H': r(lt(rgb, 1.10)),             # highlight body (lit left edge)
        'K': r(dk(rgb, 0.42)),             # very dark (deep shadow / right edge)
        'P': r(dk(rgb, 0.82)),             # mid shadow
        'W': (255, 240, 150, 210),         # window warm glow
        'Y': (200, 230, 255, 200),         # window cool (night/sleep)
        'F': r(dk(rgb, 0.30)),             # door (very dark)
        'G': (148, 138, 120, 255),         # ground strip
        'E': ( 58, 168,  68, 255),         # grass green
        'U': ( 60, 158, 220, 255),         # water blue
        'Q': (130, 200, 240, 200),         # water highlight
        'O': (255, 210,   0, 255),         # gold / CP
        'N': (120,  75,  35, 255),         # brown (trunk / wood)
        'T': ( 45, 135,  55, 255),         # tree leaf dark
        'L': ( 75, 175,  75, 255),         # tree leaf light
        'X': (255, 255, 255, 190),         # white accent / window glare
        'C': (162, 156, 146, 255),         # concrete / stone gray
        'A': (210, 205, 194, 200),         # light stone accent
        'S': (  0,   0,   0,  40),         # subtle shadow
        'Z': (  0,   0,   0, 100),         # medium shadow line
    }

# ── Pixel grids (16 wide × 20 tall, row 0 = TOP) ──────────────────────────
#
# Legend:
#   .  transparent    B  body        D  dark body    R  roof
#   H  highlight      K  deep shadow P  mid shadow   W  window warm
#   Y  window cool    F  door        G  ground       E  grass
#   U  water          Q  water hi    O  gold         N  brown/trunk
#   T  leaf dark      L  leaf light  X  white acc    C  concrete
#   A  light stone    S  shadow      Z  shadow line
#
GRIDS = {

    # ── House (generic residential) ───────────────────────────────────────
    "house": [
        "................",   #  0
        ".....NN.........",   #  1  chimney
        ".....NN.........",   #  2  chimney
        "......HRRRRR....",   #  3  roof peak
        ".....HRRRRRRD...",   #  4  roof
        "....HRRRRRRRRDD.",   #  5  roof
        "...HRRRRRRRRRRDD",   #  6  roof base
        "..HRRRRRRRRRRRRK",   #  7  roof overhang
        "..BBBBBBBBBBBBBK",   #  8  wall top
        "..BWWBBBBBBBWWBK",   #  9  windows
        "..BWWBBBBBBBWWBK",   # 10  windows
        "..BXWBBBBBBBWXBK",   # 11  window sill
        "..BBBBBBBBBBBBBK",   # 12
        "..BBBBBFFFBBBBBK",   # 13  door
        "..BBBBBFFFBBBBBK",   # 14
        "..BBBBBFFFBBBBBK",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Gym (exercise axis) ───────────────────────────────────────────────
    "gym": [
        "................",   #  0
        "..RRRRRRRRRRRR..",   #  1  roof slab
        "..RRRRRRRRRRRRK.",   #  2  roof edge
        "..BBBBBBBBBBBBK.",   #  3  parapet
        "..BBBBBBBBBBBDK.",   #  4  facade top
        "..BWWWBBBBWWWBK.",   #  5  high windows
        "..BWWWBBBBWWWBK.",   #  6
        "..BXXXBBBBXXXBK.",   #  7  window glare
        "..BBBBBBBBBBBBK.",   #  8
        "..BXXBXBXXBXBBK.",   #  9  dumbbell silhouette
        "..BXBBBBBBBBXBK.",   # 10
        "..BXXBXBXXBXBBK.",   # 11
        "..BBBBBBBBBBBBK.",   # 12
        "..BBBBFFBBBBBBK.",   # 13  double door
        "..BBBBFFBBBBBBK.",   # 14
        "..BBBBFFBBBBBBK.",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Stadium (exercise axis) ───────────────────────────────────────────
    "stadium": [
        "................",   #  0
        "....RRRRRRRR....",   #  1  roof arc
        "...RBBBBBBBBR...",   #  2  roof ring
        "..RBBBBBBBBBBR..",   #  3  outer wall
        "..RBDDDDDDDDBR..",   #  4
        "..RBDEEEEEEEDR..",   #  5  inner field
        "..RBDEEXEEEDR...",   #  6  center circle
        "..RBDEEEEEEEDR..",   #  7
        "..RBDDDDDDDDBR..",   #  8
        "..RBBBBBBBBBBR..",   #  9
        "...RRRRRRRRRR...",   # 10  roof lip
        "....DDDDDDDD....",   # 11  outer walls
        "....DDWDDDWD....",   # 12  windows
        "....DDWDDDWD....",   # 13
        "....DDDDDDDD....",   # 14
        "....DDDDFFDD....",   # 15  entry
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Park (exercise / lifestyle) ───────────────────────────────────────
    "park": [
        "................",   #  0
        "...LLLLL...LLLLL",   #  1  treetops
        "..LLTLLL..LLTLL.",   #  2
        ".LLLTLLLL.LLTLLL",   #  3
        "..LLLLL....LLLLL",   #  4
        "...NNN......NNN.",   #  5  trunks
        "...NNN......NNN.",   #  6
        "EEEEEEEEEEEEEEE.",   #  7  grass
        "EEECCCCCCEEEEEEE",   #  8  path
        "EEECEEEECEEEEEEE",   #  9
        "EEECEEEECEEEEEEE",   # 10
        "EEECEEEECCEEEEE.",   # 11
        "EEECCCCCCEEEEEEE",   # 12  path cross
        "EEEEEEEEEEEEEEEE",   # 13
        "EEEEEEEEEEEEEEEE",   # 14
        "EEEEEEEEEEEEEEEE",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Pool (exercise axis) ──────────────────────────────────────────────
    "pool": [
        "................",   #  0
        "..BBBBBBBBBBBB..",   #  1  pool building roof
        "..BRRRRRRRRRBB..",   #  2
        "..BBBBBBBBBBBB..",   #  3
        "..BUUUUUUUUUUB..",   #  4  water
        "..BQQUUUUUUQUB..",   #  5  wave highlight
        "..BUUUUUUUUUUB..",   #  6
        "..BQQUUUUUUQUB..",   #  7
        "..BUUUUUUUUUUB..",   #  8
        "..BQQUUUUUUQUB..",   #  9
        "..BUUUUUUUUUUB..",   # 10
        "..BBBBBBBBBBBB..",   # 11  edge
        "....DDDDDDDD....",   # 12  changing rooms
        "....DDWDDWDD....",   # 13
        "....DDDDFFDD....",   # 14
        "....DDDDFFDD....",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Shop (general store / retail) ─────────────────────────────────────
    "shop": [
        "................",   #  0
        "....RBBBBBBBRR..",   #  1  sloped awning
        "...RBBBBBBBBBRR.",   #  2
        "..RBBBBBBBBBBBR.",   #  3  awning edge
        "..DBBBBBBBBBBDD.",   #  4  awning underside
        "..DDDDDDDDDDDD..",   #  5  facade
        "..DOOOOOOOOODD..",   #  6  shop sign (gold)
        "..DXXXXXXXXDDD..",   #  7  sign text
        "..DDDDDDDDDDDD..",   #  8
        "..DWWWDDDDWWWDD.",   #  9  display windows
        "..DWWWDDDDWWWDD.",   # 10
        "..DXXXDDDDXXXDD.",   # 11  window glare
        "..DDDDDDDDDDDD..",   # 12
        "..DDDDFFDDDDDD..",   # 13  door
        "..DDDDFFDDDDDD..",   # 14
        "..DDDDFFDDDDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Market (farmers market / diet axis) ───────────────────────────────
    "market": [
        "................",   #  0
        "...BBBBBBBBBBB..",   #  1  tent ridge
        "..BBBBBBBBBBBBB.",   #  2  tent slope
        ".BB.BB.BB.BB.BB.",   #  3  scalloped edge
        "..DDDDDDDDDDDD..",   #  4  stall front
        "..DOOOBOOOBOOOD.",   #  5  produce: gold/body/gold
        "..DOOOBOOOBOOOD.",   #  6
        "..DEEEBEEEBEEED.",   #  7  produce: grass/body
        "..DDDDDDDDDDDD..",   #  8
        "..DWWWDDDDWWWDD.",   #  9  windows
        "..DWWWDDDDWWWDD.",   # 10
        "..DDDDDDDDDDDD..",   # 11
        "..DDDDDFFDDDDD..",   # 12  door
        "..DDDDDFFDDDDD..",   # 13
        "..DDDDDFFDDDDD..",   # 14
        "..DDDDDDDDDDDD..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Cafe (restaurant / diet & lifestyle) ──────────────────────────────
    "cafe": [
        "..NN............",   #  0  chimney
        "..NNXXX.........",   #  1  chimney + smoke
        "..RRRRRRRRRRRR..",   #  2  curved roof
        "..RHHRRRRRRRDDK.",   #  3  roof shading
        "..BBBBBBBBBBBBK.",   #  4  facade
        "..BWWWBBBBWWWBK.",   #  5  windows
        "..BWWWBBBBWWWBK.",   #  6
        "..BXXXBBBBXXXBK.",   #  7  window glare
        "..BBBBBBBBBBBBK.",   #  8
        "..BOOOOOOOOOOBK.",   #  9  cafe sign (gold)
        "..BXXXXXXXXXXBK.",   # 10  sign text
        "..BBBBBBBBBBBBK.",   # 11
        "..BBBBFFBBBBBBK.",   # 12  door
        "..BBBBFFBBBBBBK.",   # 13
        "..BBBBFFBBBBBBK.",   # 14
        "..BBBBBBBBBBBBK.",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Tower (tall building / sleep axis) ────────────────────────────────
    "tower": [
        "................",   #  0
        "......HRRR......",   #  1  spire tip
        ".....HRRRRRD....",   #  2  spire
        ".....BBBBBBD....",   #  3
        "......BBBBDK....",   #  4  narrowing
        "......BWWBDK....",   #  5  windows
        "......BBBDK.....",   #  6
        "......BWWBDK....",   #  7
        "......BBBDK.....",   #  8
        "......BWWBDK....",   #  9
        "......BBBDK.....",   # 10
        ".....BBBBBDK....",   # 11  widening
        "....BBBBBBBDK...",   # 12
        "...BBBBBBBBBDK..",   # 13
        "..BBBBBBBBBBBDK.",   # 14
        "..BBBBBBBBBBBDK.",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Clinic (medical / sleep axis) ─────────────────────────────────────
    "clinic": [
        "................",   #  0
        "..RRRRRRRRRRRR..",   #  1  flat roof
        "..RHHRRRRRRRRDK.",   #  2  roof shading
        "..BBBBBBBBBBBBK.",   #  3  parapet
        "..BBBBXXXXBBBBK.",   #  4  red cross vertical
        "..BBXXXXXXXXBBK.",   #  5  red cross horizontal — X = white here = cross
        "..BBBBXXXXBBBBK.",   #  6
        "..BBBBBBBBBBBBK.",   #  7
        "..BWWBBBBBBWWBK.",   #  8  windows
        "..BWWBBBBBBWWBK.",   #  9
        "..BXXBBBBBBXXBK.",   # 10  glare
        "..BBBBBBBBBBBBK.",   # 11
        "..BBBBFFBBBBBBK.",   # 12  door
        "..BBBBFFBBBBBBK.",   # 13
        "..BBBBFFBBBBBBK.",   # 14
        "..BBBBBBBBBBBBK.",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Library (lifestyle axis) — Greek temple ───────────────────────────
    "library": [
        "................",   #  0
        "................",   #  1
        "..RRRRRRRRRRRR..",   #  2  flat pediment
        "..RHHRRRRRRRDRK.",   #  3  pediment shading
        "..RRRRRRRRRRRR..",   #  4
        "..XXXXXXXXXXXX..",   #  5  white ledge
        "..BBDWWWWWWDBBK.",   #  6  columns(B) + bookshelf(W)
        "..BBDWWWWWWDBBK.",   #  7
        "..BBDWWWWWWDBBK.",   #  8
        "..BBDOXOXOXDBBK.",   #  9  book spines O=gold X=white
        "..BBDDDDDDDDBBK.",   # 10  transom
        "..BBDDDFFDDDBBK.",   # 11  door
        "..BBDDDFFDDDBBK.",   # 12
        "..BBDDDFFDDDBBK.",   # 13
        "..BBDDDFFDDDBBK.",   # 14
        "..BBDDDDDDDDBBK.",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Town Hall (lifestyle / city center) ───────────────────────────────
    "townhall": [
        ".......OO.......",   #  0  gold flag
        ".......BB.......",   #  1  flagpole
        "......HBBBD.....",   #  2  dome top
        ".....HBBBBBDK...",   #  3  dome
        "....HBBBBBBBBDK.",   #  4  dome base
        "..HBBBBBBBBBBBDK",   #  5  broad facade
        "..XBBBBBBBBBBBDK",   #  6  columns line
        "..XBWWBBBBBWWBDK",   #  7  windows
        "..XBWWBBBBBWWBDK",   #  8
        "..XBXXBBBBBXXBDK",   #  9  glare
        "..XBBBBBBBBBBBBK",   # 10
        "..XBWWBBBBBWWBDK",   # 11
        "..XBBBBBBBBBBBDK",   # 12
        "..XBBBBFFBBBBBDK",   # 13  door
        "..XBBBBFFBBBBBDK",   # 14
        "..XBBBBFFBBBBBDK",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Monument (streak tower / lifestyle) ───────────────────────────────
    "monument": [
        "................",   #  0
        ".......OO.......",   #  1  gold tip
        "......OOOO......",   #  2
        ".......HBD......",   #  3  obelisk top
        ".......HBDK.....",   #  4
        "......HBBDK.....",   #  5  marker
        "......HWWDK.....",   #  6  inlay window
        "......HBBDK.....",   #  7
        "......HBBDK.....",   #  8
        "......HBBDK.....",   #  9
        "......HBBDK.....",   # 10
        ".....HBBBDK.....",   # 11  widening
        "....HBBBBDKK....",   # 12
        "...HBBBBBBBDK...",   # 13  plinth
        "..HBBBBBBBBBBDK.",   # 14
        "..CCCCCCCCCCCC..",   # 15  stone plinth
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Fountain (plaza center decoration) ────────────────────────────────
    "fountain": [
        "................",   #  0
        "......QXXQ......",   #  1  water spray top
        ".....QXXXXQ.....",   #  2  spray
        ".....XUUUUX.....",   #  3  basin rim
        "....XUUUUUUX....",   #  4  water surface
        "....XUUUBUUX....",   #  5  center pillar
        "....XUUUBUUX....",   #  6
        "....XUUUUUUX....",   #  7
        ".....XUUUUX.....",   #  8  basin edge
        "....CCCCCCCC....",   #  9  stone rim
        "...CCCCCCCCCC...",   # 10
        "...CAAAAAAAAC...",   # 11  stone basin face
        "...CAAAAAAAAC...",   # 12
        "...CAAAAAAAAC...",   # 13
        "...CCCCCCCCCC...",   # 14  base
        "..CCCCCCCCCCCC..",   # 15
        "GGGGGGGGGGGGGGGG",   # 16
        "................",   # 17
        "................",   # 18
        "................",   # 19
    ],

    # ── Streetlight (plaza / road decoration) ─────────────────────────────
    "streetlight": [
        "................",   #  0
        ".......OO.......",   #  1  lamp glow
        "......OOOOO.....",   #  2  lamp head
        "......XCCCX.....",   #  3  lamp housing
        ".......CCC......",   #  4  lamp neck
        ".......CC.......",   #  5  pole top
        ".......CC.......",   #  6
        ".......CC.......",   #  7
        ".......CC.......",   #  8  pole
        ".......CC.......",   #  9
        ".......CC.......",   # 10
        ".......CC.......",   # 11
        ".......CC.......",   # 12
        ".......CC.......",   # 13
        "......CCCC......",   # 14  pole base
        ".....CCCCCC.....",   # 15
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
PAD         = 8
LABEL_H     = 16
SHEET_W     = COLS * (THUMB_W + PAD) + PAD
SHEET_H     = ROWS * (THUMB_H + PAD + LABEL_H) + PAD + 32

sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (22, 22, 30, 255))
draw  = ImageDraw.Draw(sheet)

arch_names = list(GRIDS.keys())
axis_names = list(AXES.keys())

for row_i, axis_name in enumerate(axis_names):
    palette = make_palette(AXES[axis_name])
    y_off   = PAD + 32 + row_i * (THUMB_H + PAD + LABEL_H)
    draw.text((PAD, y_off - LABEL_H + 2), axis_name.upper(), fill=(200, 200, 200, 255))

    for col_i, arch_name in enumerate(arch_names):
        x_off = PAD + col_i * (THUMB_W + PAD)
        thumb = render(GRIDS[arch_name], palette)
        sheet.paste(thumb, (x_off, y_off), thumb)
        draw.text((x_off, y_off + THUMB_H + 2), arch_name[:8], fill=(130, 130, 140, 255))

# Column headers
for col_i, arch_name in enumerate(arch_names):
    x_off = PAD + col_i * (THUMB_W + PAD)
    draw.text((x_off, PAD), arch_name[:8], fill=(240, 240, 100, 255))

sheet_path = os.path.join(OUTPUT_DIR, "_PREVIEW_SHEET.png")
sheet.save(sheet_path)
print(f"✅ Preview sheet → {sheet_path}")
print(f"\n📂 Open: {OUTPUT_DIR}/")
print(f"   {count} building sprites + preview sheet generated")
print(f"   New archetypes: fountain, streetlight")
print(f"   Tip: drag all PNGs (except _PREVIEW_SHEET.png) into Xcode Assets.xcassets")
