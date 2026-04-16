# 00 — VITA CITY スタイルガイド（PixelLab.ai 共通設定）

全プロンプトで使い回す**スタイル固定用のテンプレート**。
各資産プロンプトは「STYLE_PREFIX + 個別説明 + STYLE_SUFFIX + NEGATIVE」
の順で貼り付けると作風が揃う。

---

## 1. アートディレクション

| 項目 | 決定 |
|------|------|
| 視点 | **アイソメトリック 2:1（30度俯瞰）** |
| 参考作品 | カイロソフト系（箱庭アイランド / 開拓サバイバル島） |
| タッチ | クリーンなドット、輪郭線は黒ではなく**暗色系の同系色** |
| 光源 | **左上 45° からの日光**、右下に柔らかい影 |
| 解像度感 | 1 建物 = 64px 幅 = 論理 32 ドット × 2x |
| アンチエイリアス | **使用禁止**（ハードピクセルエッジ） |
| 色数 | 1 建物あたり **16色以内**、全体パレット統一 |

## 2. 共通プロンプト断片（コピペ用）

### STYLE_PREFIX（毎回最初に貼る）

```
Isometric pixel art, 2:1 dimetric projection, 30-degree top-down view,
Kairosoft-style game sprite, clean hard-edge pixels, no anti-aliasing,
16-color limited palette, single light source from top-left,
soft diagonal shadow bottom-right,
```

### STYLE_SUFFIX（毎回最後に貼る）

```
, transparent background, centered on canvas, cute chibi proportions,
mobile game asset, crisp pixel edges, retro 16-bit era aesthetic
```

### NEGATIVE PROMPT（禁止ワード欄）

```
photorealistic, 3D render, blurry, anti-aliased, soft edges, gradient,
motion blur, watercolor, sketch, line art, realistic shadows, multiple
light sources, text, watermark, signature, frame, border
```

## 3. カラーパレット（軸別アクセント）

建物の外壁・看板・屋根装飾に差し色として使う。
背景壁はニュートラル（ベージュ/オフホワイト/木目）で統一。

| 軸 | HEX | 名前 | 用途 |
|----|-----|------|------|
| 運動 | `#34C759` | 緑 | スポーツ建物 |
| 食事 | `#FF9500` | 橙 | レストラン・カフェ |
| 飲酒 | `#AF52DE` | 紫 | 瞑想・スパ・ノンアル |
| 睡眠 | `#007AFF` | 青 | クリニック・天文台 |
| 生活習慣 | `#FF2D55` | ピンク | 図書館・市庁舎以外 |
| CP / 金 | `#FFD700` | 金 | 市庁舎・プレミアム |

### ニュートラル（共通）

| 用途 | HEX | 名前 |
|------|-----|------|
| 壁（明） | `#F4E6C8` | クリーム |
| 壁（暗） | `#C8B080` | カーキベージュ |
| 屋根瓦 | `#8C5A3C` | 煉瓦茶 |
| 屋根影 | `#5A3826` | ダーク茶 |
| 窓ガラス（昼）| `#7EC8F4` | 水色 |
| 窓枠 | `#3E2B18` | こげ茶 |
| 扉 | `#6B4423` | ウォルナット |

## 4. 生成の前提（PixelLab.ai の設定）

- **モデル**: Pixel Art Style（キャラ/建物どちらにも対応）
- **Canvas Size**: 生成は 128×128 を基本とし、後工程でリサイズ
  - 建物 Lv1–2: PixelLab で 128×128 → ダウンサンプル **64×52〜72**
  - 建物 Lv3–5: PixelLab で 128×192 / 128×256 → **64×92〜132**
  - タイル: PixelLab で 128×64 → **64×32**
  - NPC: PixelLab で 64×128 → **24×42**
- **Upscaling**: OFF（やりすぎるとドット感が消える）
- **Seed**: 同じシリーズ（例: 市庁舎 Lv1〜3）は同じシードで揃えると建物の
  「家系」が揃う

## 5. リサイズ手順（任意の画像エディタ）

PixelLab.ai の出力が 128×128 の場合:
1. 画像を開く
2. キャンバスサイズを目的サイズ（例: 64×52）に変更し、**中央寄せでクロップ**
3. もしくは **Image Resize → Nearest Neighbor** で 2:1 リサイズ
4. 透過 PNG 出力
5. Xcode の Asset Catalog に 1x スロットでドロップ

> `Pixelmator Pro` なら「画像→リサイズ→アルゴリズム: Nearest Neighbor」
> `Photoshop` なら「イメージ→画像解像度→ニアレストネイバー（ハードエッジ）」
