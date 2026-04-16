# VITA CITY アセット命名規則 & PixelLab.ai 発注仕様

このドキュメントは PixelLab.ai 等で生成した画像を `Resources/Assets.xcassets` に
投入する際の規約です。命名が正しければ、`PixelArtRenderer` の
`assetTexture(_:)` ヘルパが自動的に画像版を優先表示し、プロシージャル生成を
バイパスします（画像が無い Lv はプロシージャル描画のまま）。

## 1. 共通ルール

- **全て透過 PNG**（周囲は完全透明）
- **カラーモード**: RGBA-8（`sRGB`）
- **画像フィルタ**: `SKTexture.filteringMode = .nearest` で近傍補間するため、
  アンチエイリアスやソフトエッジは避け、ハードピクセル境界を維持すること
- **Retina 不要**: `@1x` のみで OK（SpriteKit 側で拡大）
- **アイソメトリック**: タイルはすべて 2:1（上から見下ろし 30°）
- **光源**: 画面左上からの単一光源、右下に影
- **キャンバスサイズ = 画像の実サイズ**（パディングは入れない）

## 2. 命名規則

### 2.1 建物（28 建設可能 + 2 ペナルティ）

```
bld_B001_lv1.png   // トレーニングジム Lv1
bld_B001_lv2.png
bld_B001_lv3.png
...
bld_B025_lv1.png   // 市庁舎 Lv1
bld_B025_lv1_f0.png  // 市庁舎の旗アニメーション Frame 0
bld_B025_lv1_f1.png
bld_B025_lv1_f2.png
bld_B025_lv1_f3.png
...
bld_B029_lv1.png   // 居酒屋（ペナルティ）
bld_B030_lv1.png   // 廃墟ビル（ペナルティ）
```

#### 建物の高さ（ピクセルサイズ）

| Lv | 階数 | 画像サイズ (px) | コメント |
|----|------|---------------|---------|
| Lv1 | 1F  | **64 × 52**  | 32 (タイル) + 20×1 |
| Lv2 | 2F  | **64 × 72**  | 32 + 20×2 |
| Lv3 | 3F  | **64 × 92**  | 32 + 20×3 |
| Lv4 | 4F  | **64 × 112** | 32 + 20×4 |
| Lv5 | 5F  | **64 × 132** | 32 + 20×5 |

- **底面はタイル前方頂点（ダイアモンドの最下点）が画像下端から上に 16px**
- アンカーポイント Y は自動計算されるため、画像は上記サイズに正しく収めること

#### 建物 ID → 軸 対応（カラーテーマ）

| ID | 名前 | 軸 | 推奨アクセントカラー |
|----|------|---|-------------------|
| B001 | トレーニングジム | 運動 | `#34C759` 緑 |
| B002 | スポーツスタジアム | 運動 | `#34C759` |
| B003 | 公園・ランニングコース | 運動 | `#34C759` |
| B004 | プール | 運動 | `#34C759` |
| B005 | ヨガスタジオ | 運動 | `#34C759` |
| B006 | 自転車ステーション | 運動 | `#34C759` |
| B007 | オーガニックカフェ | 食事 | `#FF9500` 橙 |
| B008 | ファーマーズマーケット | 食事 | `#FF9500` |
| B009 | ヘルシーレストラン | 食事 | `#FF9500` |
| B010 | 料理教室 | 食事 | `#FF9500` |
| B011 | サラダバー | 食事 | `#FF9500` |
| B012 | ジューススタンド | 食事 | `#FF9500` |
| B013 | 瞑想センター | 飲酒 | `#AF52DE` 紫 |
| B014 | ハーブティーショップ | 飲酒 | `#AF52DE` |
| B015 | セルフケアスパ | 飲酒 | `#AF52DE` |
| B016 | コミュニティセンター | 飲酒 | `#AF52DE` |
| B017 | 睡眠クリニック | 睡眠 | `#007AFF` 青 |
| B018 | 天文台 | 睡眠 | `#007AFF` |
| B019 | 図書館 | 生活習慣 | `#FF2D55` ピンク |
| B020 | アロマテラピーショップ | 睡眠 | `#007AFF` |
| B021 | ムーンライトパーク | 睡眠 | `#007AFF` |
| B022 | 布団・寝具専門店 | 睡眠 | `#007AFF` |
| B023 | ウォーターサーバー広場 | 生活習慣 | `#FF2D55` |
| B024 | メンタルヘルスクリニック | 生活習慣 | `#FF2D55` |
| B025 | 市庁舎 | 生活習慣 | `#FFD700` 金（旗アニメ） |
| B026 | 習慣カレンダータワー | 生活習慣 | `#FF2D55` |
| B027 | ウェルネスショップ | 生活習慣 | `#FF2D55` |
| B028 | 公民館 | 生活習慣 | `#FF2D55` |
| B029 | 居酒屋 | （ペナルティ） | `#FF7043` 赤系・ネオン |
| B030 | 廃墟ビル | （ペナルティ） | `#616161` グレー・錆 |

### 2.2 地面タイル

すべて **64 × 32 px** のダイアモンド（2:1）、周囲透明

```
tile_grass_0.png    // 草タイル（バリエーション 0: 明るい）
tile_grass_1.png    // 草タイル（バリエーション 1: 少し暗い）
tile_road.png       // 道路タイル（中央に道路マーキング）
tile_sidewalk.png   // 歩道タイル
tile_water.png      // 水タイル（可能ならアニメ無しで OK）
tile_sand.png       // 砂タイル
```

### 2.3 NPC（5 種 × 4 フレーム = 20 枚）

**サイズ: 24 × 42 px**（8px × 14 論理ピクセル × 3px 拡大）

```
npc_0_f0.png   // 冒険者: idle
npc_0_f1.png   // 冒険者: walkLeft
npc_0_f2.png   // 冒険者: walkRight
npc_0_f3.png   // 冒険者: walkMid

npc_1_f0〜f3   // 市民1（青系）
npc_2_f0〜f3   // 市民2（赤系）
npc_3_f0〜f3   // 老人（白髪）
npc_4_f0〜f3   // 子ども
```

フレーム順: `idle → walkLeft → walkRight → walkMid` を繰り返して歩行ループ。

### 2.4 木・装飾

| ファイル名 | サイズ | 説明 |
|-----------|-------|------|
| `tree_0.png` | 24 × 40 | 広葉樹 |
| `tree_1.png` | 24 × 40 | 針葉樹 |
| `deco_streetlamp.png` | 8 × 22 | 街灯 |
| `deco_bench.png` | 16 × 12 | ベンチ |

## 3. PixelLab.ai への発注プロンプト例

### 建物プロンプト（Lv3 オーガニックカフェ）

```
Isometric pixel art building, 3-story organic cafe,
top-down 30-degree view, 64x92 pixels, transparent background,
orange accent color (#FF9500), green plants on facade,
wooden signage reading "CAFE" above entrance, warm lighting,
clean hard pixel edges, no anti-aliasing, 16-color palette,
pixel art style similar to Kairosoft games
```

### 地面タイルプロンプト

```
Isometric pixel art ground tile, 64x32 pixels diamond shape,
grass texture, bright green (#6BC845), transparent surrounding,
2:1 aspect ratio isometric, hard pixel edges, tileable seamless
```

### NPC プロンプト

```
Pixel art character sprite, 24x42 pixels, front-facing idle pose,
healthy city citizen in casual clothes, blue color palette,
transparent background, hard pixel edges, RPG JRPG style,
simple outline, 8-color palette
```

## 4. Asset Catalog へのインポート手順

1. PixelLab.ai で PNG を生成
2. Xcode で `Resources/Assets.xcassets` を開く
3. `PixelArt/Buildings` フォルダ（または該当カテゴリ）を右クリック →
   **New Image Set**
4. Image Set 名を命名規則に従って設定（例: `bld_B001_lv1`）
5. **1x スロットに PNG をドラッグ&ドロップ**（2x/3x は空のまま）
6. Image Set の Attribute Inspector で:
   - **Render As**: `Original Image`
   - **Preserves Vector Representation**: off
   - **Scale Factors**: `Single Scale` を選んでも可
7. アプリをビルド・実行すると当該建物のテクスチャが画像版に切り替わる

> 📝 `Resources/Assets.xcassets/PixelArt/_Template.imageset/` は複製用の
> 空テンプレートです。右クリック→Duplicate で新しい imageset を作れます。

## 5. 投入優先度（MVP 30 枚）

配信 MVP に最低必要な画像（これ以外は Phase A のプロシージャル生成のまま）:

### 最優先（5 枚）
- `bld_B025_lv1〜lv3`（市庁舎 3 Lv）
- `tile_grass_0`（初期マップの大部分）

### 高優先（10 枚）
- `bld_B001_lv1〜lv2`（ジム）
- `bld_B007_lv1〜lv2`（カフェ）
- `bld_B023_lv1〜lv2`（ウォーター広場）
- `bld_B012_lv1〜lv2`（ジューススタンド）
- `tile_road` / `tile_sidewalk`

### 中優先（10 枚）
- `bld_B029_lv1`（居酒屋 - ペナルティ演出に重要）
- `bld_B030_lv1`（廃墟ビル - ペナルティ演出に重要）
- 各軸から代表 1 軒ずつ Lv1 = 5 枚
- `tile_grass_1` / `tile_water` / `tile_sand`
- `tree_0`

### 低優先（配信後パッチで OK）
- 残り建物の Lv3〜Lv5
- 全 NPC 20 枚（プロシージャルは十分かわいい）
- `deco_streetlamp` / `deco_bench`

## 6. トラブルシュート

| 症状 | 原因と対策 |
|------|-----------|
| 画像をセットしたが反映されない | `PixelArtRenderer.invalidateCache()` を呼ぶか、アプリ再起動 |
| 画像がぼやけて見える | `filteringMode = .nearest` が効いているか確認（自動適用） |
| 画像の位置がずれる | 建物サイズ表の画像サイズと実画像サイズが一致しているか確認 |
| 旗が動かない | `bld_B025_lv1_f0` 〜 `f3` の 4 枚すべてが揃っているか確認（欠けていればプロシージャルにフォールバック） |
