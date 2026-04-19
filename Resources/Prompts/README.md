# PixelLab.ai 発注台本

配信までに生成する全アセットのプロンプト集。上から順に実行すれば配信に
間に合うタイムラインで組まれている。

> **デザイン仕様の正**: `Resources/GameDesign/` 配下の設計書。
> 本プロンプト集はその仕様を PixelLab.ai 向けに変換したもの。

## 読む順序

| # | ファイル | 内容 | 生成枚数 |
|---|---------|------|---------|
| 00 | `00_StyleGuide.md` | 共通プロンプト・パレット・PixelLab 設定 | — |
| 01 | `01_MVP_TopPriority.md` | 市庁舎 3 Lv + 草タイル + 道路 | **5 枚** |
| 02 | `02_HighPriority.md` | 5 軸代表建物 + 残りタイル | **10 枚** |
| 03 | `03_Penalty_AppIcon.md` | B029 居酒屋 / B030 廃墟 / AppIcon | **3 枚** |
| 04 | `04_RemainingBuildings.md` | 残り 22 建物 Lv1 | 22 枚（配信後 OK） |
| 05 | `05_NPCs_Decor.md` | NPC 24 枚 + 装飾 7 種 + タイル 2 種 | 33 枚（配信後 OK） |
| 06 | `06_QA_Workflow.md` | 採用基準・投入手順・タイムライン | — |

## 来週配信ターゲット

**最小 18 枚**（ファイル 01+02+03）で配信可能。残りはプロシージャル描画の
ままでも違和感なく動作する。

## 命名規則（抜粋）

- 建物: `bld_B001_lv1` … `bld_B030_lv5`
- 旗アニメ: `bld_B025_lv1_f0` … `f3`
- タイル: `tile_grass_0`, `tile_road`, `tile_sidewalk`, `tile_water`, `tile_sand`, `tile_cobblestone`
- NPC: `npc_0_f0` … `npc_5_f3`（6 種族 × 4 フレーム = 24 枚）
- 装飾: `tree_0`, `tree_1`, `deco_streetlamp`, `deco_bench`, `deco_flowerpot`, `deco_signpost`, `deco_waterwell`
- 特殊: `npc_postman`（将来実装）

詳細は `../AssetNaming.md` を参照。

## 総アセット数

| カテゴリ | 枚数 |
|---------|------|
| 建物（MVP 18 枚 + 残り 22 枚） | 40 枚 |
| NPC（6 種族 × 4 フレーム） | 24 枚 |
| 装飾（木 2 + 街灯 + ベンチ + 花鉢 + 標識 + 井戸） | 7 枚 |
| タイル（草明/暗 + 道路 + 歩道 + 水 + 砂 + 石畳） | 7 枚 |
| AppIcon | 1 枚 |
| 特殊 NPC（郵便配達員） | 1 枚 |
| **合計** | **80 枚** |
