# 02 — 高優先生成リスト（10 枚）

5 軸すべての代表建物を 1 軒ずつ Lv1–Lv2 で揃える + 残りのタイル。
これで「全軸記録→全軸ゾーンが画像化」まで到達する。

プロンプトは `STYLE_PREFIX` + 本文 + `STYLE_SUFFIX` + `NEGATIVE` で使用。

> **重要**: 各軸のデザイン言語は `Resources/GameDesign/01_BuildingDesign.md` が正。
> プロンプトはその仕様を PixelLab.ai 用に落とし込んだもの。

---

## ⑥ `bld_B001_lv1` — トレーニングジム Lv1 (運動軸)

**サイズ**: 64 × 52 px
**アクセント**: 緑 `#34C759`
**軸デザイン言語**: ガラス+明るい木材、片流れ屋根、大きな横長窓、直線的・アクティブ

```
a small isometric gym building, 1-story, converted warehouse look,
bright wood and glass facade, large horizontal windows showing
exercise equipment silhouettes inside (openness = activity feel),
flat lean-to roof with green (#34C759) accent band, a small
dumbbell icon sign above the entrance, a tiny green pennant flag
on the roof edge, a towel draped on a railing near the door,
energetic and motivating feel, clean straight lines
```

**シード**: `101`

---

## ⑦ `bld_B001_lv2` — トレーニングジム Lv2

**サイズ**: 64 × 72 px

```
the same gym upgraded to 2 stories, wood-and-glass facade on both
floors with large horizontal windows, green (#34C759) accent bands
between floors, rooftop running track visible on the flat roof,
a green banner with dumbbell logo, small bench and potted shrub
added at the entrance (Lv2 decoration), bigger windows showing
more equipment inside, same straight-line active identity as Lv1
```

**シード**: `101`

---

## ⑧ `bld_B007_lv1` — オーガニックカフェ Lv1 (食事軸)

**サイズ**: 64 × 52 px
**アクセント**: 橙 `#FF9500`
**軸デザイン言語**: 煉瓦+暖色漆喰、三角屋根+煙突、格子窓+レースカーテン、曲線的・家庭的

```
a small isometric organic cafe, 1-story, warm brick (#C8B080) and
cream plaster (#F4E6C8) walls, orange (#FF9500) triangular pitched
roof with a small chimney, lattice windows with lace curtains
showing cozy warm interior, a chalkboard menu on the left wall,
green herb planters flanking the wooden door, a small orange awning
with gentle curves over the entrance, handmade warm atmosphere,
rounded and homey details
```

**シード**: `102`

---

## ⑨ `bld_B007_lv2` — オーガニックカフェ Lv2

**サイズ**: 64 × 72 px

```
the same organic cafe upgraded to 2 stories, brick and cream plaster
walls, orange triangular roof with chimney, 2nd floor terrace with
potted herbs and a small outdoor seating area, green vines climbing
the facade, lattice windows with warm lamp glow on both floors,
chalkboard menu on the ground floor, string lights along the awning,
same cozy brick-and-plaster identity as Lv1 but with rooftop herb
garden
```

**シード**: `102`

---

## ⑩ `bld_B013_lv1` — 瞑想センター Lv1 (飲酒軸)

**サイズ**: 64 × 52 px
**アクセント**: 紫 `#AF52DE`
**軸デザイン言語**: 石材+濃い木+障子風パネル、入母屋屋根、円窓・すりガラス、静的・シンメトリー

```
a small isometric meditation center, 1-story zen building,
dark wood (#5A3826) columns and stone (#B0BEC5) base walls,
shoji-style sliding panels with soft purple (#AF52DE) accent
frames, Japanese irimoya roof with curved eaves in dark tiles,
a small circular window (maru-mado) on the side wall, bonsai
tree to the left, stone lantern (ishidoro) to the right,
perfectly symmetrical composition, serene static atmosphere,
small karesansui gravel patch at the entrance
```

**シード**: `103`

---

## ⑪ `bld_B017_lv1` — 睡眠クリニック Lv1 (睡眠軸)

**サイズ**: 64 × 52 px
**アクセント**: 青 `#007AFF`
**軸デザイン言語**: ネイビー瓦+白壁、丸いドーム or 尖塔、星型窓・三日月看板、緩やかな曲線

```
a small isometric sleep clinic, 1-story, white walls with
navy blue (#007AFF) tile roof featuring a small rounded dome,
circular windows (porthole style) with soft warm light inside,
a crescent moon icon sign hanging above the entrance on a
bracket, a tiny star-shaped cutout window on the side wall,
soft blue awning with gentle curves, a warm bedside lamp glow
visible through the main window, tranquil and protective
atmosphere, gentle curved lines throughout
```

**シード**: `104`

---

## ⑫ `bld_B023_lv1` — ウォーターサーバー広場 Lv1 (生活習慣軸)

**サイズ**: 64 × 52 px
**アクセント**: ピンク `#FF2D55`
**軸デザイン言語**: クリーム漆喰+淡ピンク装飾タイル、寄棟屋根、縦長窓、折衷的・アカデミック

```
a small isometric public water fountain plaza, open structure
with cream plaster (#F4E6C8) low walls and pink (#FF2D55)
decorative tile trim, a central stone well with flowing blue
water, a hip roof canopy with pink tiles over the well,
tall sash-style windows on the back wall, two curved stone
benches around the fountain, a water droplet icon on the
canopy, a small flower bed next to the bench, welcoming
community gathering spot, warm public facility aesthetic
```

**シード**: `105`

---

## ⑬ `tile_grass_1` — 草タイル（暗）

**サイズ**: 64 × 32 px

```
isometric pixel art grass tile, diamond shape 2:1 aspect ratio,
slightly darker variation of grass (#59B035) with more dirt patches
showing through, a few small pebbles and clover leaves scattered,
tileable seamless pattern, companion variation to the bright grass
tile, top-down isometric view
```

---

## ⑭ `tile_sidewalk` — 歩道タイル

**サイズ**: 64 × 32 px

```
isometric pixel art sidewalk tile, diamond shape 2:1 aspect ratio,
pale beige stone pavement (#D8D0B8) with subtle grid lines showing
individual paving stones, slightly worn edges, tileable seamless,
top-down isometric view
```

---

## ⑮ `tile_water` — 水タイル

**サイズ**: 64 × 32 px

```
isometric pixel art water tile, diamond shape 2:1 aspect ratio,
bright ocean blue water (#5BB8FF) with tiny ripple patterns and
lighter highlights (#A8DFFF), a few white sparkle pixels for surface
reflection, tileable seamless, top-down isometric view
```

---

## チェックリスト（5 軸カラー識別）

- [ ] ⑥⑦（ジム）が**緑**だと一目でわかる
- [ ] ⑧⑨（カフェ）が**橙**だと一目でわかる
- [ ] ⑩（瞑想センター）が**紫**だと一目でわかる
- [ ] ⑪（睡眠クリニック）が**青**だと一目でわかる
- [ ] ⑫（ウォーター広場）が**ピンク**だと一目でわかる
- [ ] ⑬⑭⑮（3 タイル）が隣接しても継ぎ目が目立たない

## 生成を早める Tips

- **同じ建物の Lv1 と Lv2 は連続で生成**してシードを同じに保つ
- 気に入らない生成物は即リトライ（PixelLab のガチャ性）
- Lv2 は Lv1 を「image-to-image（参照画像入力）」で発注すると一貫性が高い
