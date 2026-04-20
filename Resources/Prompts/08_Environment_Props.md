# 08 — 環境装飾プロップ発注（PixelLab.ai）

**優先度**: 中（街に生活感を出す）

参考画像（カイロソフト風）に見られる牧場・風車・市場スタンド・花壇などの
小物装飾を発注。すでに `Core/PixelArtRenderer.swift` に**プロシージャル生成
フォールバック**が実装されており、コードは Asset 優先で読み込むため、画像が
揃い次第自動的に差し替わる。

共通スタイルは `00_StyleGuide.md` を参照。

---

## 1. 発注対象一覧

| 名前 | ファイル | キャンバス (幅×高) | フレーム | 備考 |
|------|----------|---------------------|----------|------|
| 牛（ホルスタイン） | `deco_cow_f0.png`, `deco_cow_f1.png` | 32 × 24 px | 2（idle / chew）| 白黒、正面 3/4 |
| 柵（横一枚） | `deco_fence_0.png` | 24 × 18 px | 1 | 横連結前提 |
| 柵（角パーツ） | `deco_fence_1.png` | 24 × 18 px | 1 | コーナー |
| 風車 | `deco_windmill_f0〜f3.png` | 36 × 64 px | 4（羽根回転）| 石造り本体 + 4 羽根 |
| 市場スタンド 野菜 | `deco_market_0.png` | 28 × 32 px | 1 | 赤白テント |
| 市場スタンド 魚 | `deco_market_1.png` | 28 × 32 px | 1 | 青白テント |
| 市場スタンド パン | `deco_market_2.png` | 28 × 32 px | 1 | 茶黄テント |
| 花壇（暖色） | `deco_flowerbed_0.png` | 28 × 16 px | 1 | 赤橙黄 |
| 花壇（寒色） | `deco_flowerbed_1.png` | 28 × 16 px | 1 | 紫桃 |
| 樽 | `deco_barrel.png` | 16 × 20 px | 1 | 鉄輪付き木樽 |
| 木箱 | `deco_crate.png` | 18 × 16 px | 1 | X 型補強材 |

## 2. 配色ガイド（既存の街との整合）

| プロップ | 主色 HEX | 影色 HEX | 補色 |
|----------|----------|----------|------|
| 牛 | `#FFFFFF` 白 | `#1A1A1A` 黒斑 | `#F5C09A` 鼻, `#FFB3B3` 乳 |
| 柵 | `#A8753A` 木 | `#6B4822` 影 | - |
| 風車 | `#D7CCC8` 石 / `#FAFAFA` 羽 | `#8D6E63` 屋根 | `#FFF176` 窓 |
| 市場 野菜 | `#E53935` 赤 / `#FAFAFA` 白 | `#A8753A` 木 | `#E57373` `#81C784` `#FFEE58` |
| 市場 魚 | `#1976D2` 青 / `#FAFAFA` 白 | `#A8753A` 木 | `#B0BEC5` 魚 |
| 市場 パン | `#A1887F` 茶 / `#FFE082` 黄 | `#8D6E63` | `#D7A36A` |
| 花壇 暖色 | `#8D6E63` 木 | `#4E342E` 土 | `#F44336` `#FF9800` `#FFEB3B` |
| 花壇 寒色 | `#8D6E63` 木 | `#4E342E` 土 | `#AB47BC` `#EC407A` `#7E57C2` |

## 3. 配置コード側の使い方（参考）

`Features/City/CityScene.swift` の `placeEnvironmentProps(map:)` が以下の条件で
自動配置する：

- **風車**: マップ中心から (±6, ±6) 付近の草地に 1 基（草タイル gid==1 検出）
- **牧場**: 草地の 3×2 連続ブロックを検出 → 周囲を柵で囲み、中央に牛 2 頭
- **市場スタンド**: 市庁舎（マップ中心）周辺の歩道 or 草地に 3 種
- **花壇 / 樽 / 木箱**: 歩道タイル（gid==3）の特定キーに散発的に配置（最大 12 個）

コード側は常に `PixelArtRenderer.{名前}Texture()` を呼ぶため、Asset Catalog に
`deco_{名前}` PNG を追加するだけで自動反映。

## 4. 発注プロンプト例

### 牛（frame 0 idle）

```
STYLE_PREFIX
Isometric pixel art Holstein cow from 3/4 top-down view,
standing calm idle pose, white body with large black patches,
pink snout, short horns, small pink udder visible between legs,
four black hooves, chibi farm animal proportion,
small mobile game asset, bottom center anchored
STYLE_SUFFIX
NEGATIVE_PROMPT
```

### 牛（frame 1 chew）

```
[同上] but with head slightly lowered as if grazing or chewing,
mouth slightly open, eyes half-closed in relaxed expression
```

### 風車 frame 0

```
STYLE_PREFIX
Isometric pixel art European windmill, cylindrical stone tower,
conical brown roof, small yellow window, wooden door at base,
four large white fabric sails arranged in a plus sign (+),
stationary frame (sails horizontal and vertical),
rustic countryside asset, centered on canvas
STYLE_SUFFIX
NEGATIVE_PROMPT
```

風車 f1/f2/f3 は羽根の回転角度を 22.5° / 45° / 67.5° ずらす（合計 90° で 1 周）。

### 市場スタンド 野菜

```
STYLE_PREFIX
Isometric pixel art small street market stall for vegetables,
red-and-white striped canvas tent roof, two wooden poles,
wooden counter displaying colorful vegetables (red tomato,
green cabbage, yellow corn), chibi-scale storefront,
outdoor daytime market vibe
STYLE_SUFFIX
NEGATIVE_PROMPT
```

### 風車・市場以外は 01〜04 の発注プロンプトの同系列を参考にしてください。

## 5. 品質チェックリスト

- [ ] 同じ軸の既存建物と並べて違和感がないか
- [ ] アンカー位置（底辺中央）を意識したレイアウトか
- [ ] 色数 8〜12 色程度に収まっているか（プロップは建物より少なめ）
- [ ] ペナルティ（B029/B030）と混同しない明るいトーンか
- [ ] 昼光の影の向き（左上光源 → 右下影）が揃っているか
