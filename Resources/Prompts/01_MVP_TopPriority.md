# 01 — 最優先生成リスト（5 枚）

配信スクリーンショット撮影に最低限必要なアセット。
**この 5 枚が揃えばホーム画面が「デザイン完成」の見た目になる**。

プロンプトは `00_StyleGuide.md` の `STYLE_PREFIX` / `STYLE_SUFFIX` /
`NEGATIVE` を前後に必ず貼り付けて使用すること。

---

## ① `bld_B025_lv1` — 市庁舎 Lv1（最重要）

**サイズ**: 64 × 52 px（1F 建物）
**配置**: マップ中央、街のランドマーク
**カラー**: クリーム壁 + 金屋根 + 赤い旗

```
a small isometric city hall building, 1-story, cream-white walls
(#F4E6C8), red pitched roof with golden trim (#FFD700), front door
with arched top (#6B4423), two square windows with blue glass
(#7EC8F4), a small flagpole on top with a red flag, a round clock
above the entrance, ornamental stone base, civic fountain-like
pedestal feel, ground-level building on a diamond-shaped dirt base
```

**推奨シード**: `42`（Lv2/Lv3 でも同じシードを使う）

---

## ② `bld_B025_lv2` — 市庁舎 Lv2

**サイズ**: 64 × 72 px（2F 建物）

```
the same city hall upgraded to 2 stories, cream walls with decorative
gold banding between floors, red pitched roof with two small dormers,
large clock face on 2nd floor facade, red flag waving from rooftop
flagpole, arched entrance with double doors, ornate window frames on
both floors, civic architecture feel, same building identity as Lv1
but larger and more ornate
```

**推奨シード**: `42`（Lv1 と同じ）

---

## ③ `bld_B025_lv3` — 市庁舎 Lv3

**サイズ**: 64 × 92 px（3F 建物）

```
the same city hall upgraded to 3 stories with a grand clock tower on
top, cream and gold facade, red roof, large central clock, banner-
style red flag with gold trim, symmetrical balconies on 2nd and 3rd
floors, columns flanking the main entrance, ornate parapets,
monumental civic building, same identity as Lv1/Lv2 but imposing
```

**推奨シード**: `42`

---

## ④ `tile_grass_0` — 草タイル（明）

**サイズ**: 64 × 32 px（ダイアモンド形）
**重要**: ダイアモンドの外側は**完全透明**

```
isometric pixel art grass tile, diamond shape 2:1 aspect ratio, bright
fresh green grass (#6BC845) with subtle texture variation, a few tiny
grass tufts and dots for detail, edges show slight dirt at the
diamond perimeter, tileable seamless pattern, top-down isometric view
```

**注意**: 「seamless tileable」を必ず含める。隣接タイルとの境界が目立たないこと。

---

## ⑤ `tile_road` — 道路タイル

**サイズ**: 64 × 32 px（ダイアモンド形）

```
isometric pixel art road tile, diamond shape 2:1 aspect ratio, light
gray-beige asphalt (#B0A890) with subtle texture, a single white
dashed line running diagonally across the center (road marking),
slightly worn edges, tileable seamless, top-down isometric view
```

---

## 生成順序（推奨）

1. **`tile_grass_0`** を先に作る（街のベース）
2. **`bld_B025_lv1`** を作る → この時点でスクリーンショット 1 枚目が撮れる
3. **`tile_road`** を作る → 市庁舎への道が見える
4. **`bld_B025_lv2` / `lv3`** を作る → Lv アップ演出のスクリーンショットが撮れる

## チェックリスト

生成後、次を満たしているか確認:

- [ ] 背景が完全透明（白塗り・格子柄背景になっていない）
- [ ] ダイアモンドのエッジがギザついていない（ピクセルパーフェクト）
- [ ] 光源が左上、影が右下
- [ ] 建物が 2:1 アイソメ比率に沿っている（屋根が正面から見えすぎていない）
- [ ] Lv1〜Lv3 で同じ建物だと識別できる（色・旗・屋根の特徴が共通）
- [ ] アンチエイリアスのソフトエッジが無い（全ピクセル角張っている）
