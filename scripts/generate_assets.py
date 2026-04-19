#!/usr/bin/env python3
"""VITA CITY — PixelLab API batch asset generator (MVP 18 assets)"""

import os
import json
import time
import pixellab
from PIL import Image

SECRET = "d4b69cfd-0d79-43c3-bf73-149ec6c79e8b"
BASE_DIR = "/home/user/Health-App-Game"
XCASSETS = f"{BASE_DIR}/Resources/Assets.xcassets/PixelArt"
RAW_DIR = f"{BASE_DIR}/generated_assets/raw"
FINAL_DIR = f"{BASE_DIR}/generated_assets/final"

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(FINAL_DIR, exist_ok=True)

STYLE_PREFIX = (
    "Isometric pixel art, 2:1 dimetric projection, 30-degree top-down view, "
    "Kairosoft-style game sprite, clean hard-edge pixels, no anti-aliasing, "
    "16-color limited palette, single light source from top-left, "
    "soft diagonal shadow bottom-right, "
)

STYLE_SUFFIX = (
    ", transparent background, centered on canvas, cute chibi proportions, "
    "mobile game asset, crisp pixel edges, retro 16-bit era aesthetic"
)

NEGATIVE = (
    "photorealistic, 3D render, blurry, anti-aliased, soft edges, gradient, "
    "motion blur, watercolor, sketch, line art, realistic shadows, multiple "
    "light sources, text, watermark, signature, frame, border"
)

# (name, gen_w, gen_h, final_w, final_h, seed, description, xcasset_subdir)
ASSETS = [
    # === Day 1: MVP 5 ===
    ("tile_grass_0", 128, 64, 64, 32, 0,
     "isometric pixel art grass tile, diamond shape 2:1 aspect ratio, bright "
     "fresh green grass (#6BC845) with subtle texture variation, a few tiny "
     "grass tufts and dots for detail, edges show slight dirt at the diamond "
     "perimeter, tileable seamless pattern, top-down isometric view",
     "Tiles"),

    ("bld_B025_lv1", 128, 128, 64, 52, 42,
     "a small isometric city hall building, 1-story, cream-white walls "
     "(#F4E6C8), red pitched roof with golden trim (#FFD700), front door "
     "with arched top (#6B4423), two square windows with blue glass "
     "(#7EC8F4), a small flagpole on top with a red flag, a round clock "
     "above the entrance, ornamental stone base, civic fountain-like "
     "pedestal feel, ground-level building on a diamond-shaped dirt base",
     "Buildings"),

    ("tile_road", 128, 64, 64, 32, 0,
     "isometric pixel art road tile, diamond shape 2:1 aspect ratio, light "
     "gray-beige asphalt (#B0A890) with subtle texture, a single white "
     "dashed line running diagonally across the center (road marking), "
     "slightly worn edges, tileable seamless, top-down isometric view",
     "Tiles"),

    ("bld_B025_lv2", 128, 128, 64, 72, 42,
     "the same city hall upgraded to 2 stories, cream walls with decorative "
     "gold banding between floors, red pitched roof with two small dormers, "
     "large clock face on 2nd floor facade, red flag waving from rooftop "
     "flagpole, arched entrance with double doors, ornate window frames on "
     "both floors, civic architecture feel, same building identity as Lv1 "
     "but larger and more ornate",
     "Buildings"),

    ("bld_B025_lv3", 192, 256, 64, 92, 42,
     "the same city hall upgraded to 3 stories with a grand clock tower on "
     "top, cream and gold facade, red roof, large central clock, banner-"
     "style red flag with gold trim, symmetrical balconies on 2nd and 3rd "
     "floors, columns flanking the main entrance, ornate parapets, "
     "monumental civic building, same identity as Lv1/Lv2 but imposing",
     "Buildings"),

    # === Day 2: High Priority 10 ===
    ("bld_B001_lv1", 128, 128, 64, 52, 101,
     "a small isometric gym building, 1-story, converted warehouse look, "
     "bright wood and glass facade, large horizontal windows showing "
     "exercise equipment silhouettes inside (openness = activity feel), "
     "flat lean-to roof with green (#34C759) accent band, a small "
     "dumbbell icon sign above the entrance, a tiny green pennant flag "
     "on the roof edge, energetic and motivating feel, clean straight lines",
     "Buildings"),

    ("bld_B001_lv2", 128, 128, 64, 72, 101,
     "the same gym upgraded to 2 stories, wood-and-glass facade on both "
     "floors with large horizontal windows, green (#34C759) accent bands "
     "between floors, rooftop running track visible on the flat roof, "
     "a green banner with dumbbell logo, small bench and potted shrub "
     "added at the entrance, bigger windows showing more equipment inside, "
     "same straight-line active identity as Lv1",
     "Buildings"),

    ("bld_B007_lv1", 128, 128, 64, 52, 102,
     "a small isometric organic cafe, 1-story, warm brick (#C8B080) and "
     "cream plaster (#F4E6C8) walls, orange (#FF9500) triangular pitched "
     "roof with a small chimney, lattice windows with lace curtains "
     "showing cozy warm interior, a chalkboard menu on the left wall, "
     "green herb planters flanking the wooden door, a small orange awning "
     "with gentle curves over the entrance, handmade warm atmosphere",
     "Buildings"),

    ("bld_B007_lv2", 128, 128, 64, 72, 102,
     "the same organic cafe upgraded to 2 stories, brick and cream plaster "
     "walls, orange triangular roof with chimney, 2nd floor terrace with "
     "potted herbs and a small outdoor seating area, green vines climbing "
     "the facade, lattice windows with warm lamp glow on both floors, "
     "chalkboard menu on the ground floor, string lights along the awning, "
     "same cozy brick-and-plaster identity as Lv1 but with rooftop herb garden",
     "Buildings"),

    ("bld_B013_lv1", 128, 128, 64, 52, 103,
     "a small isometric meditation center, 1-story zen building, "
     "dark wood (#5A3826) columns and stone (#B0BEC5) base walls, "
     "shoji-style sliding panels with soft purple (#AF52DE) accent "
     "frames, Japanese irimoya roof with curved eaves in dark tiles, "
     "a small circular window on the side wall, bonsai tree to the left, "
     "stone lantern to the right, perfectly symmetrical composition, "
     "serene static atmosphere",
     "Buildings"),

    ("bld_B017_lv1", 128, 128, 64, 52, 104,
     "a small isometric sleep clinic, 1-story, white walls with "
     "navy blue (#007AFF) tile roof featuring a small rounded dome, "
     "circular windows with soft warm light inside, "
     "a crescent moon icon sign hanging above the entrance, "
     "a tiny star-shaped cutout window on the side wall, "
     "soft blue awning with gentle curves, warm bedside lamp glow "
     "visible through the main window, tranquil and protective atmosphere",
     "Buildings"),

    ("bld_B023_lv1", 128, 128, 64, 52, 105,
     "a small isometric public water fountain plaza, open structure "
     "with cream plaster (#F4E6C8) low walls and pink (#FF2D55) "
     "decorative tile trim, a central stone well with flowing blue "
     "water, a hip roof canopy with pink tiles over the well, "
     "two curved stone benches around the fountain, a water droplet "
     "icon on the canopy, welcoming community gathering spot",
     "Buildings"),

    ("tile_grass_1", 128, 64, 64, 32, 0,
     "isometric pixel art grass tile, diamond shape 2:1 aspect ratio, "
     "slightly darker variation of grass (#59B035) with more dirt patches "
     "showing through, a few small pebbles and clover leaves scattered, "
     "tileable seamless pattern, companion variation to the bright grass "
     "tile, top-down isometric view",
     "Tiles"),

    ("tile_sidewalk", 128, 64, 64, 32, 0,
     "isometric pixel art sidewalk tile, diamond shape 2:1 aspect ratio, "
     "pale beige stone pavement (#D8D0B8) with subtle grid lines showing "
     "individual paving stones, slightly worn edges, tileable seamless, "
     "top-down isometric view",
     "Tiles"),

    ("tile_water", 128, 64, 64, 32, 0,
     "isometric pixel art water tile, diamond shape 2:1 aspect ratio, "
     "bright ocean blue water (#5BB8FF) with tiny ripple patterns and "
     "lighter highlights (#A8DFFF), a few white sparkle pixels for surface "
     "reflection, tileable seamless, top-down isometric view",
     "Tiles"),

    # === Day 3: Penalty 2 ===
    ("bld_B029_lv1", 128, 128, 64, 52, 200,
     "a small isometric old izakaya Japanese pub, 1-story weathered "
     "wooden facade, faded dark brown wood panels, two faded red paper "
     "lanterns hanging from the eaves, a slightly tilted noren curtain "
     "covering the entrance, roof tiles with 2 tiles visibly missing, "
     "warm golden window light glowing softly from inside, "
     "a single empty bottle near the doorstep, quiet melancholy atmosphere, "
     "subdued muted color palette, NOT ugly NOT dirty just old and lonely",
     "Buildings"),

    ("bld_B030_lv1", 128, 192, 64, 72, 201,
     "a small isometric abandoned office building, 2-stories, gray "
     "concrete walls (#9E9E9E) with hairline cracks, a cracked wooden "
     "sign hanging slightly crooked, boarded-up windows with wooden "
     "planks on the ground floor, 2nd floor windows still intact but "
     "dusty, green ivy vines climbing up the left wall, small weeds at "
     "the base, faded sunset glow reflecting on the walls, no lights "
     "inside, muted desaturated palette, quiet sadness NOT horror",
     "Buildings"),
]


def generate_one(client, asset):
    name, gen_w, gen_h, final_w, final_h, seed, desc, subdir = asset
    raw_path = f"{RAW_DIR}/{name}_raw.png"
    final_path = f"{FINAL_DIR}/{name}.png"

    if os.path.exists(final_path):
        print(f"  SKIP (already exists): {name}")
        return True

    full_desc = STYLE_PREFIX + desc + STYLE_SUFFIX
    print(f"  Generating {name} ({gen_w}x{gen_h})...", end=" ", flush=True)

    try:
        response = client.generate_image_pixflux(
            description=full_desc,
            image_size={"width": gen_w, "height": gen_h},
            negative_description=NEGATIVE,
            isometric=True,
            no_background=True,
            seed=seed,
        )
        pil_image = response.image.pil_image()
        pil_image.save(raw_path)

        resized = pil_image.resize((final_w, final_h), Image.NEAREST)
        resized.save(final_path)
        print(f"OK → {final_w}x{final_h}")
        return True

    except Exception as e:
        print(f"FAIL: {e}")
        return False


def install_to_xcassets(name, subdir):
    """Copy final PNG into Xcode asset catalog."""
    final_path = f"{FINAL_DIR}/{name}.png"
    if not os.path.exists(final_path):
        return False

    imageset_dir = f"{XCASSETS}/{subdir}/{name}.imageset"
    os.makedirs(imageset_dir, exist_ok=True)

    contents = {
        "images": [
            {"filename": f"{name}.png", "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"}
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": False}
    }

    with open(f"{imageset_dir}/Contents.json", "w") as f:
        json.dump(contents, f, indent=2)

    import shutil
    shutil.copy2(final_path, f"{imageset_dir}/{name}.png")
    return True


def main():
    client = pixellab.Client(secret=SECRET)
    balance = client.get_balance()
    print(f"=== VITA CITY Asset Generator ===")
    print(f"Balance: ${balance.usd:.2f}")
    print(f"Assets to generate: {len(ASSETS)}")
    print()

    success = 0
    fail = 0

    for i, asset in enumerate(ASSETS):
        name = asset[0]
        subdir = asset[7]
        print(f"[{i+1}/{len(ASSETS)}] {name}")

        if generate_one(client, asset):
            if install_to_xcassets(name, subdir):
                print(f"  → Installed to Assets.xcassets/{subdir}/{name}.imageset/")
            success += 1
        else:
            fail += 1

        time.sleep(1)

    print()
    remaining = client.get_balance()
    print(f"=== Done ===")
    print(f"Success: {success}, Failed: {fail}")
    print(f"Remaining balance: ${remaining.usd:.2f}")


if __name__ == "__main__":
    main()
