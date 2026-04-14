#!/usr/bin/env python3
"""
VITA CITY - PixelLab.ai Asset Generation Script
================================================
使い方:
    export PIXELLAB_SECRET=<your_api_key>
    python3 scripts/generate_assets.py --phase 1

フェーズ:
    --phase 1  : MVP 45枚（無料トライアル範囲）
    --phase 2  : 推薦 73枚
    --phase 3  : 全量 185枚
    --dry-run  : 生成リストのみ表示（API呼び出しなし）
    --id B001  : 特定建物のみ生成
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Optional

import pixellab

# ── 出力ディレクトリ ──────────────────────────────────────────────
SCRIPT_DIR  = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
OUT = {
    "buildings":    PROJECT_DIR / "Resources/PixelArt/buildings",
    "tiles":        PROJECT_DIR / "Resources/PixelArt/tiles",
    "npcs":         PROJECT_DIR / "Resources/PixelArt/npcs",
    "decorations":  PROJECT_DIR / "Resources/PixelArt/decorations",
}

# ── スタイル定数（全アセット共通）────────────────────────────────
BASE_STYLE = (
    "isometric pixel art, late Showa to early Heisei era Japan (1985-1995), "
    "warm retro colors, clean pixel edges, game asset, "
    "transparent background, 2:1 isometric perspective"
)
NEGATIVE = (
    "3D render, photorealistic, blurry, watermark, text, "
    "western style, medieval, fantasy, sci-fi, noise"
)

# ── 建物カタログ ─────────────────────────────────────────────────
# id: (name_ja, axis, floors_per_level, phase, description_en)
BUILDINGS = {
    "B001": ("フィットネスジム",    "exercise",  [1,2,3,4], 1,
             "fitness gym, exercise equipment visible through glass windows, sporty signboard"),
    "B002": ("スタジアム",          "exercise",  [2,3],     2,
             "small sports stadium, running track, bleachers, Olympic rings decoration"),
    "B003": ("マラソンコース",      "exercise",  [1],       2,
             "marathon course park entrance building, timing arch, running path"),
    "B004": ("プール",              "exercise",  [1,2],     1,
             "public swimming pool building, blue water shimmer, lane markers, diving board"),
    "B005": ("サイクリングロード",  "exercise",  [1],       3,
             "cycling road station, bike rack, route map board, cheerful yellow"),
    "B006": ("自転車ステーション",  "exercise",  [1,2],     2,
             "bicycle rental station, row of bikes, bright orange and yellow colors"),
    "B007": ("カフェ",              "diet",      [1,2],     1,
             "cozy Japanese cafe, coffee cup sign, warm wooden exterior, potted plant at entrance"),
    "B008": ("有機野菜市場",        "diet",      [1],       1,
             "organic vegetable market stall, fresh produce display, green and earthy tones"),
    "B009": ("ヘルシーレストラン",  "diet",      [1,2],     1,
             "healthy Japanese restaurant, menu board outside, noren curtain, bento symbol"),
    "B010": ("ジューサーバー",      "diet",      [1],       2,
             "juice bar kiosk, colorful fruit illustrations, smoothie cups display"),
    "B011": ("ファーマーズマーケット","diet",     [1,2],     2,
             "farmers market building, seasonal produce signs, natural wood stall"),
    "B012": ("料理教室",            "diet",      [1,2],     3,
             "cooking school, chef hat signboard, kitchen chimney, window showing cooking class"),
    "B013": ("スパ",                "sleep",     [2,3],     2,
             "Japanese spa building, noren curtain, bamboo decoration, calming blue-green tones"),
    "B014": ("睡眠クリニック",      "sleep",     [2,3],     1,
             "sleep clinic medical building, moon and stars logo, calming night-blue colors"),
    "B015": ("ヨガスタジオ",        "lifestyle", [1,2],     1,
             "yoga studio, large glass windows, lotus flower sign, purple and white theme"),
    "B016": ("瞑想センター",        "lifestyle", [1,2],     2,
             "meditation center, zen garden at entrance, simple minimalist design, stone lantern"),
    "B017": ("温泉旅館",            "sleep",     [2,3],     2,
             "traditional Japanese hot spring inn, tiled roof, steam wisps, red lanterns"),
    "B018": ("公園",                "lifestyle", [1],       1,
             "city park entrance gate, green trees, park bench, cherry blossom tree"),
    "B019": ("図書館",              "lifestyle", [2,3],     1,
             "public library, book logo on facade, tall windows, quiet scholarly atmosphere"),
    "B020": ("コミュニティセンター","lifestyle",  [2,3],     2,
             "community center, noticeboard outside, welcoming entrance, bulletin board"),
    "B021": ("ムーンライトパーク",  "lifestyle", [1,2],     3,
             "moonlight park pavilion, crescent moon decoration, night garden lanterns, dark blue"),
    "B022": ("ウェルネスタワー",    "lifestyle", [3,4],     2,
             "wellness tower skyscraper, heart logo on glass facade, modern office building"),
    "B023": ("健康診断センター",    "lifestyle", [2,3],     2,
             "health check center, medical cross sign, clean white and blue clinical design"),
    "B024": ("薬局",                "lifestyle", [1,2],     1,
             "Japanese pharmacy, green cross sign, medicine shelves visible, Showa retro style"),
    "B025": ("市庁舎",              "lifestyle", [2,3,4],   1,
             "city hall, Japanese government building, flag pole with tricolor flag, clock tower"),
    "B026": ("カレンダータワー",    "lifestyle", [3,4],     1,
             "calendar tower, large wall clock, Showa architecture, brick facade, clock hands"),
    "B027": ("スポーツセンター",    "exercise",  [2,3],     2,
             "sports center complex, multiple sport icons on signboard, gymnasium entrance"),
    "B028": ("公民館",              "lifestyle", [2,3],     2,
             "community hall, traditional Japanese hall, bulletin board, warm brown tones"),
    # ペナルティ建物
    "B029": ("居酒屋",              "penalty",   [1,2],     3,
             "Japanese izakaya bar, red lanterns, sake barrel outside, slightly grungy look"),
    "B030": ("廃墟ビル",            "penalty",   [2,3],     3,
             "abandoned building, broken windows, weeds growing, faded paint, crumbling walls"),
}

# ── タイル カタログ ───────────────────────────────────────────────
TILES = {
    "grass":     ("grass ground tile, isometric, fresh green, small flowers",        1),
    "grass2":    ("grass ground tile variant, darker green, slightly worn path",     2),
    "road":      ("paved road tile isometric, asphalt gray, center white dashed line", 1),
    "sidewalk":  ("sidewalk tile isometric, concrete gray, slight texture",          1),
    "water":     ("water tile isometric, gentle ripple, deep blue",                  2),
    "sand":      ("sand ground tile isometric, warm beige, fine texture",            3),
}

# ── NPC カタログ ─────────────────────────────────────────────────
NPCS = {
    "worker":   ("Japanese office worker salaryman, suit, briefcase, isometric pixel art", 1),
    "student":  ("Japanese high school student, uniform, backpack, isometric pixel art",   1),
    "elder":    ("Japanese elderly woman, apron, shopping bag, isometric pixel art",       1),
    "athlete":  ("Japanese athlete in tracksuit, running pose, isometric pixel art",       2),
    "child":    ("Japanese child, school uniform, waving, isometric pixel art",            2),
}

# ── デコレーション カタログ ──────────────────────────────────────
DECORATIONS = {
    "tree_sakura":  ("cherry blossom tree, isometric pixel art, pink flowers, spring", 1),
    "tree_pine":    ("pine tree, isometric pixel art, deep green, traditional Japanese", 1),
    "lamp_showa":   ("Showa-era street lamp post, warm yellow glow, brown metal post", 1),
    "bench_park":   ("park bench, isometric pixel art, wooden slats, iron legs",       1),
    "fountain":     ("small city fountain, isometric pixel art, water spray, stone base", 2),
    "vending":      ("Japanese vending machine, isometric pixel art, colorful drinks",  2),
    "mailbox":      ("red Japanese mailbox post, isometric pixel art, classic shape",   3),
    "bus_stop":     ("Japanese bus stop shelter, isometric pixel art, route sign",      3),
}


def get_building_levels(bid: str) -> list[int]:
    """建物の生成対象レベルリストを返す"""
    if bid not in BUILDINGS:
        return []
    _, _, level_floors, _, _ = BUILDINGS[bid]
    return list(range(1, len(level_floors) + 1))


def make_building_prompt(bid: str, level: int) -> str:
    name_ja, axis, level_floors, _, desc_en = BUILDINGS[bid]
    floors = level_floors[min(level - 1, len(level_floors) - 1)]
    floor_word = "single" if floors == 1 else f"{floors}-story"
    return (
        f"{floor_word} {desc_en}, {BASE_STYLE}, "
        f"level {level} building, building ID {bid}"
    )


def get_output_path(category: str, name: str) -> Path:
    return OUT[category] / f"{name}.png"


def generate_one(
    client,
    description: str,
    out_path: Path,
    size: dict,
    dry_run: bool = False,
) -> float:
    """1枚生成して保存。dry_run=True なら保存せずに 0 を返す。"""
    if out_path.exists():
        print(f"  ✓ スキップ（既存）: {out_path.name}")
        return 0.0

    if dry_run:
        print(f"  [DRY] {out_path.name}")
        print(f"        {description[:80]}...")
        return 0.0

    print(f"  生成中: {out_path.name} ...", end="", flush=True)
    try:
        resp = client.generate_image_pixflux(
            description=description,
            image_size=size,
            negative_description=NEGATIVE,
            text_guidance_scale=9.0,
            outline="single color black outline",
            shading="basic shading",
            detail="medium detail",
            isometric=True,
            no_background=True,
            seed=0,
        )
        img = resp.image.to_pil_image()
        img.save(out_path, "PNG")
        cost = resp.usage.usd
        print(f" ${cost:.4f}")
        return cost
    except Exception as e:
        print(f" エラー: {e}")
        return 0.0


def build_queue(phase: int, target_id: Optional[str] = None) -> list[tuple]:
    """(category, filename, description, size_dict) のキューを作成"""
    queue = []

    # 建物
    for bid, (name_ja, axis, level_floors, b_phase, _) in BUILDINGS.items():
        if target_id and bid != target_id:
            continue
        if not target_id and b_phase > phase:
            continue
        for lv in range(1, len(level_floors) + 1):
            fname = f"building_{bid}_lv{lv}"
            desc = make_building_prompt(bid, lv)
            queue.append(("buildings", fname, desc, {"width": 96, "height": 128}))

    # タイル
    for tile_key, (desc, t_phase) in TILES.items():
        if target_id:
            continue
        if t_phase > phase:
            continue
        full_desc = f"{desc}, {BASE_STYLE}"
        queue.append(("tiles", f"tile_{tile_key}", full_desc, {"width": 64, "height": 48}))

    # NPC
    for npc_key, (desc, n_phase) in NPCS.items():
        if target_id:
            continue
        if n_phase > phase:
            continue
        queue.append(("npcs", f"npc_{npc_key}", desc, {"width": 32, "height": 48}))

    # デコレーション
    for deco_key, (desc, d_phase) in DECORATIONS.items():
        if target_id:
            continue
        if d_phase > phase:
            continue
        full_desc = f"{desc}, {BASE_STYLE}"
        queue.append(("decorations", f"deco_{deco_key}", full_desc, {"width": 48, "height": 64}))

    return queue


def main():
    parser = argparse.ArgumentParser(description="VITA CITY pixel art asset generator")
    parser.add_argument("--phase", type=int, default=1, choices=[1, 2, 3],
                        help="生成フェーズ (1=MVP/2=推薦/3=全量)")
    parser.add_argument("--dry-run", action="store_true",
                        help="APIを呼ばず生成リストのみ表示")
    parser.add_argument("--id", type=str, default=None,
                        help="特定の建物IDのみ生成 (例: --id B025)")
    args = parser.parse_args()

    # ── API クライアント初期化 ────────────────────────────────────
    secret = os.environ.get("PIXELLAB_SECRET")
    if not secret and not args.dry_run:
        print("エラー: 環境変数 PIXELLAB_SECRET を設定してください")
        print("  export PIXELLAB_SECRET=<your_api_key>")
        sys.exit(1)

    client = None
    if not args.dry_run:
        client = pixellab.Client(secret=secret)
        # 残高確認
        try:
            balance = client.get_balance()
            print(f"残高: ${balance.usd:.2f}\n")
        except Exception as e:
            print(f"警告: 残高確認できません ({e})\n")

    # ── 生成キュー ───────────────────────────────────────────────
    queue = build_queue(phase=args.phase, target_id=args.id)
    already_done = sum(1 for _, fname, _, _ in queue
                       if (OUT[_cat := "buildings"] / f"{fname}.png").exists()
                       or any((OUT[cat] / f"{fname}.png").exists() for cat in OUT))

    print(f"=== VITA CITY Asset Generator ===")
    print(f"フェーズ: {args.phase}  |  合計: {len(queue)}枚  |  生成済み: {already_done}枚")
    print(f"残り: {len(queue) - already_done}枚\n")

    # ── 生成ループ ────────────────────────────────────────────────
    total_cost = 0.0
    for i, (category, fname, desc, size) in enumerate(queue, 1):
        out_path = OUT[category] / f"{fname}.png"
        print(f"[{i}/{len(queue)}] {fname}")
        cost = generate_one(client, desc, out_path, size, dry_run=args.dry_run)
        total_cost += cost
        if not args.dry_run and cost > 0:
            time.sleep(0.5)   # レート制限対策

    print(f"\n=== 完了 ===")
    print(f"合計コスト: ${total_cost:.4f}")

    if not args.dry_run:
        print(f"\n次のステップ:")
        print(f"  1. Resources/PixelArt/ 内のPNGを確認")
        print(f"  2. python3 scripts/generate_assets.py --phase 2  で追加生成")
        print(f"  3. xcodegen generate  でXcodeプロジェクト再生成")


if __name__ == "__main__":
    main()
