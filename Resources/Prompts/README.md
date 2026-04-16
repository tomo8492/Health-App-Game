# PixelLab.ai 発注台本

配信までに生成する全アセットのプロンプト集。上から順に実行すれば配信に
間に合うタイムラインで組まれている。

## 読む順序

| # | ファイル | 内容 | 生成枚数 |
|---|---------|------|---------|
| 00 | `00_StyleGuide.md` | 共通プロンプト・パレット・PixelLab 設定 | — |
| 01 | `01_MVP_TopPriority.md` | 市庁舎 3 Lv + 草タイル + 道路 | **5 枚** |
| 02 | `02_HighPriority.md` | 5 軸代表建物 + 残りタイル | **10 枚** |
| 03 | `03_Penalty_AppIcon.md` | B029 居酒屋 / B030 廃墟 / AppIcon | **3 枚** |
| 04 | `04_RemainingBuildings.md` | 残り 22 建物 Lv1 | 22 枚（配信後 OK） |
| 05 | `05_NPCs_Decor.md` | NPC 20 枚 + 木・街灯・ベンチ | 25 枚（配信後 OK） |
| 06 | `06_QA_Workflow.md` | 採用基準・投入手順・タイムライン | — |

## 来週配信ターゲット

**最小 18 枚**（ファイル 01+02+03）で配信可能。残りはプロシージャル描画の
ままでも違和感なく動作する。

## 命名規則（抜粋）

- 建物: `bld_B001_lv1` … `bld_B030_lv5`
- 旗アニメ: `bld_B025_lv1_f0` … `f3`
- タイル: `tile_grass_0`, `tile_road`, `tile_sidewalk`, `tile_water`, `tile_sand`
- NPC: `npc_0_f0` … `npc_4_f3`
- 装飾: `tree_0`, `tree_1`, `deco_streetlamp`, `deco_bench`

詳細は `../AssetNaming.md` を参照。
