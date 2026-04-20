# 07 — 建物 Lv2〜Lv5 追加発注（PixelLab.ai）

**優先度**: 中〜高（プレイ進行に伴って必要）

現状 `Resources/Assets.xcassets/PixelArt/Buildings/` には B001-B030 の **Lv1** が
一通り揃っているが、**Lv2-5 は B007/B025 を除いてほぼ未着手**。レベルアップ時に
`PixelArtRenderer` がプロシージャル生成にフォールバックして画質が劣化するため、
段階的に発注・差し替えを進める。

共通スタイルは `00_StyleGuide.md` を参照（STYLE_PREFIX / STYLE_SUFFIX / NEGATIVE）。

---

## 1. サイズ仕様（全建物共通）

| レベル | キャンバスサイズ (幅×高) | 論理ピクセル | 備考 |
|--------|--------------------------|--------------|------|
| Lv1    | 64 × 52 px               | 32 × 26 ドット | 基本形 |
| Lv2    | 64 × 72 px               | 32 × 36 ドット | +1 階 or 装飾追加 |
| Lv3    | 64 × 92 px               | 32 × 46 ドット | +1 階 + 看板発光 |
| Lv4    | 64 × 112 px              | 32 × 56 ドット | 屋上テラス・旗 |
| Lv5    | 64 × 132 px              | 32 × 66 ドット | ランドマーク級 |

- 画像底辺 = タイルの前面頂点（isometric の地面と揃える）
- 建物の**下端 16px は地面タイルに差し込まれる**前提でデザイン
- 背景は透明。中央配置。

## 2. レベル段階表現ガイド

| 要素 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 |
|------|-----|-----|-----|-----|-----|
| 階数 | 1〜2 | +1 階 | +1 階 | +1 階 + 屋上 | 最大階 + タワー装飾 |
| 窓   | 基本 | 意匠窓 | ステンドグラス等 | 発光窓 | 大型アーチ窓 |
| 屋根 | 素朴 | 瓦/銅板 | 装飾ライン | 小塔・煙突 | 大型旗・時計 |
| 看板 | なし | 小看板 | 発光看板 | LED/電飾 | ネオン |
| 周辺 | 簡素 | 植え込み | 花壇・街灯 | 噴水 / ベンチ | 階段・像 |

**重要**: 建物の「人格」を損ねないこと。ジム（B001）は一貫して緑系・筋肉アイコン、
市庁舎（B025）はベージュ系＋金の旗を維持する。カラーパレットは
`Resources/GameDesign/01_BuildingDesign.md` と
`Core/PixelArtRenderer.swift` の `BuildingVisualConfig.make` を参照。

## 3. 発注対象リスト

### 既納品（発注不要）
- `bld_B007_lv2` — オーガニックカフェ Lv2（済）
- `bld_B025_lv1 / lv2 / lv3` — 市庁舎（済）

### 今回発注（優先度順）

**Priority A: 中心建物の Lv2-3（プレイ序盤で到達）**

運動軸:
- `bld_B001_lv2` `bld_B001_lv3` — ジム
- `bld_B002_lv2` — パーク  
- `bld_B003_lv2` — ヨガスタジオ  

食事軸:
- `bld_B007_lv3` — オーガニックカフェ
- `bld_B008_lv2` `bld_B008_lv3` — ベジレストラン

睡眠軸:
- `bld_B017_lv2` `bld_B017_lv3` — スリープクリニック
- `bld_B018_lv2` — 天文台

生活習慣軸:
- `bld_B024_lv2` — 公民館
- `bld_B025_lv4` `bld_B025_lv5` — 市庁舎（ランドマーク拡張）
- `bld_B026_lv2` — 図書館系施設

**Priority B: 全建物の Lv4-5（プレイ中盤〜終盤）**

B001〜B028 の全レベル 4・5 を順次発注。

## 4. 発注プロンプト共通テンプレ

```
STYLE_PREFIX

[Lv1 プロンプト本文（01〜04 を参照）]

Upgrade to Level {N}:
- Add {N-1} additional floors with consistent architectural style
- Enhance signage: {看板デザインの変化}
- Add rooftop detail: {屋根装飾の変化}
- Maintain same axis color palette: {axis color from BuildingVisualConfig}
- {軸特有の装飾（ガラス張り / 木造 / 石造など）}

STYLE_SUFFIX

NEGATIVE PROMPT: STYLE_NEGATIVE
```

### 例: bld_B001_lv3（ジム Lv3）

```
STYLE_PREFIX
Isometric pixel art fitness gym building, 3 floors, green accent color
(#34C759), large front windows showing exercise equipment inside,
rooftop with small running track and yellow flag pole, muscle icon
signage with subtle glow, wooden frame doorway, potted plants at
entrance, clean modern gym aesthetic, bottom 16px merges into ground tile
STYLE_SUFFIX
NEGATIVE_PROMPT
```

## 5. 命名規則と投入方法

1. 生成 → `bld_{ID}_lv{N}.png` で保存
2. `generated_assets/final/` に配置
3. `Resources/Assets.xcassets/PixelArt/Buildings/bld_{ID}_lv{N}.imageset/` を作成
4. `Contents.json` は `_Template.imageset` を複製して filename だけ書き換え
5. シミュレータ起動 → `[PixelArt] ✅ Asset loaded: bld_{ID}_lv{N}` のログを確認

## 6. 品質チェック

- [ ] Lv1 と並べて比較：建物の「人格」が維持されているか
- [ ] 底辺が地面タイル（64×32 のひし形）と重なる位置にあるか
- [ ] 16色以内に収まっているか
- [ ] アンチエイリアスの滲みがないか（ピクセルエッジがシャープ）
- [ ] 左上 45° 光源の影方向と整合しているか
