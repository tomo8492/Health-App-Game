# PixelLab.ai 生成ワークフロー（実作業手順）

---

## Step 0: PixelLab 初期設定（最初の1回だけ）

1. PixelLab.ai にログイン
2. **Model**: Pixel Art Style を選択
3. **Canvas Size**: `128 × 128`（建物 Lv1-2 のデフォルト）
4. **Upscaling**: OFF

---

## Step 1: プロンプト組み立て（毎回）

3つの断片を連結してプロンプト欄に貼る:

```
[STYLE_PREFIX] + [個別プロンプト] + [STYLE_SUFFIX]
```

### STYLE_PREFIX（毎回最初に貼る）
```
Isometric pixel art, 2:1 dimetric projection, 30-degree top-down view,
Kairosoft-style game sprite, clean hard-edge pixels, no anti-aliasing,
16-color limited palette, single light source from top-left,
soft diagonal shadow bottom-right,
```

### 個別プロンプト
→ `01_MVP_TopPriority.md` 〜 `05_NPCs_Decor.md` から該当部分をコピー

### STYLE_SUFFIX（毎回最後に貼る）
```
, transparent background, centered on canvas, cute chibi proportions,
mobile game asset, crisp pixel edges, retro 16-bit era aesthetic
```

### NEGATIVE PROMPT（禁止ワード欄に貼る）
```
photorealistic, 3D render, blurry, anti-aliased, soft edges, gradient,
motion blur, watercolor, sketch, line art, realistic shadows, multiple
light sources, text, watermark, signature, frame, border
```

---

## Step 2: 生成 → 採用判定

### Canvas サイズ早見表

| アセット種別 | PixelLab Canvas | 最終サイズ | リサイズ方法 |
|---|---|---|---|
| 建物 Lv1-2 | 128 × 128 | 64 × 52〜72 | Nearest Neighbor 縮小 |
| 建物 Lv3-5 | 128 × 192 or 256 | 64 × 92〜132 | Nearest Neighbor 縮小 |
| タイル | 128 × 64 | 64 × 32 | Nearest Neighbor 縮小 |
| NPC | 64 × 128 | 24 × 42 | Nearest Neighbor 縮小 |
| AppIcon | 1024 × 1024 | 1024 × 1024 | そのまま |

### シード設定

各プロンプトファイルに記載のシード値を入力。**同じ建物の Lv 違いは同じシード**。

### 即座に確認する 5 項目（NG なら即リトライ）

1. 背景が透明か（白塗りになっていないか）
2. アンチエイリアスのぼやけがないか
3. 光源が左上 → 影が右下か
4. 軸色が一目でわかるか
5. 判読可能なテキストが入っていないか

---

## Step 3: リサイズ（Aseprite / Pixelmator / Photoshop）

1. 生成 PNG をダウンロード
2. 画像エディタで開く
3. **リサイズ → アルゴリズム: Nearest Neighbor**（ぼかし禁止）
4. 目的サイズにクロップ（中央寄せ）
5. **透過 PNG で書き出し**

---

## Step 4: Xcode に投入

1. `Resources/Assets.xcassets/PixelArt/Buildings/_Template.imageset` を **Duplicate**
2. `bld_B025_lv1` 等にリネーム
3. **1x スロットに PNG をドラッグ**
4. 属性インスペクタ:
   - Render As: **Original Image**
   - Preserves Vector: **OFF**
5. ビルドして確認（プロシージャル描画が画像に置き換わる）

差し替わらない場合:
- `PixelArtRenderer.invalidateCache()` を起動直後に 1 回呼ぶ
- Product → Clean Build Folder → 再ビルド

---

## Step 5: QA チェック（全アセット完了後）

### 建物チェック
- [ ] 同軸の建物を横に並べて色調が揃っている
- [ ] 軸デザイン言語に準拠（運動=ガラス+片流れ、食事=煉瓦+煙突、飲酒=石+障子、睡眠=ドーム+丸窓、生活習慣=マンサード+縦長窓）
- [ ] Lv1 と Lv2 が「同じ家族」に見える
- [ ] 黒の輪郭線を使っていない（同系暗色のみ）
- [ ] 32×32 に縮小しても識別可能

### NPC チェック
- [ ] 6 種族を横に並べてモノクロ化 → 形だけで全員区別できる
- [ ] 4 フレーム間で顔・服装・色が変わっていない
- [ ] 帽子・エプロン・マント等の識別特徴がフレーム間で消えていない

### ペナルティ建物チェック
- [ ] B029: 暖かい窓明かりがある（完全に暗くない）
- [ ] B030: ホラーではなく切ない雰囲気
- [ ] 他のポジティブ建物より明確に彩度が低い

---

## 生成スケジュール（推奨順序）

### Day 1: MVP 5 枚（`01_MVP_TopPriority.md`）
| # | アセット | シード |
|---|---------|-------|
| ① | tile_grass_0 | — |
| ② | bld_B025_lv1（市庁舎） | 42 |
| ③ | tile_road | — |
| ④ | bld_B025_lv2 | 42 |
| ⑤ | bld_B025_lv3 | 42 |

→ この時点でスクリーンショット撮影可能

### Day 2: 高優先 10 枚（`02_HighPriority.md`）
| # | アセット | シード |
|---|---------|-------|
| ⑥⑦ | B001 ジム Lv1/Lv2 | 101 |
| ⑧⑨ | B007 カフェ Lv1/Lv2 | 102 |
| ⑩ | B013 瞑想センター | 103 |
| ⑪ | B017 睡眠クリニック | 104 |
| ⑫ | B023 ウォーター広場 | 105 |
| ⑬⑭⑮ | タイル 3 種 | — |

**Tips**: 同じ建物の Lv1→Lv2 は連続生成。Lv1 を Style Reference にすると統一感 UP。

### Day 3: ペナルティ + AppIcon（`03_Penalty_AppIcon.md`）
| # | アセット | シード |
|---|---------|-------|
| ⑯ | B029 居酒屋 | 200 |
| ⑰ | B030 廃墟ビル | 201 |
| ⑱ | AppIcon | 任意 |

→ **ここまでの 18 枚で配信可能**

### Day 4+: 残り建物（`04_RemainingBuildings.md`）— 配信後パッチ
- 軸ごとにまとめて生成すると色調が揃いやすい
- 1 枚 3〜5 分 × 22 枚 ≒ 2〜4 時間

### Day 5+: NPC + 装飾（`05_NPCs_Decor.md`）— 配信後パッチ
- NPC は Character Animation 機能で 4 フレーム一括生成
- 装飾は極小なので大きめ Canvas → Nearest Neighbor 縮小

---

## トラブルシューティング

| 問題 | 対処 |
|------|------|
| 背景が白塗り | NEGATIVE に `white background` を追加 |
| ぼやけたエッジ | `no anti-aliasing, hard pixel edges` を強調 |
| 色がバラバラ | Style Reference 機能で既存の採用画像を参照 |
| テキストが入る | NEGATIVE に `text, letters, words` を追加 |
| 建物が正面向き | `isometric 2:1, top-down 30-degree` を強調 |
| NPC の顔が毎回違う | シードを固定 + image-to-image で f0 を参照 |
