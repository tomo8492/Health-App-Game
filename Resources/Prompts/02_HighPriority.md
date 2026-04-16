# 02 — 高優先生成リスト（10 枚）

5 軸すべての代表建物を 1 軒ずつ Lv1–Lv2 で揃える + 残りのタイル。
これで「全軸記録→全軸ゾーンが画像化」まで到達する。

プロンプトは `STYLE_PREFIX` + 本文 + `STYLE_SUFFIX` + `NEGATIVE` で使用。

---

## ⑥ `bld_B001_lv1` — トレーニングジム Lv1 (運動軸)

**サイズ**: 64 × 52 px
**アクセント**: 緑 `#34C759`

```
a small isometric gym building, 1-story, gray concrete walls with
bright green accent stripes (#34C759), large glass front windows
showing exercise equipment silhouettes, a dumbbell icon sign above
the entrance, flat modern roof with a green banner, sports/fitness
facility, energetic and motivating feel
```

**シード**: `101`

---

## ⑦ `bld_B001_lv2` — トレーニングジム Lv2

**サイズ**: 64 × 72 px

```
the same gym upgraded to 2 stories, gray concrete with green accent
bands between floors, large glass facade on both levels showing gym
equipment silhouettes, rooftop running track visible, green banner
with a dumbbell logo, modern sports facility with bigger windows and
more equipment visible inside
```

**シード**: `101`

---

## ⑧ `bld_B007_lv1` — オーガニックカフェ Lv1 (食事軸)

**サイズ**: 64 × 52 px
**アクセント**: 橙 `#FF9500`

```
a small isometric organic cafe building, 1-story, warm cream walls
(#F4E6C8) with orange accents (#FF9500), wooden slatted awning over
the entrance, a chalkboard menu on the left wall, green potted plants
flanking the door, a small orange banner reading "CAFE" above the
door, large glass window showing cozy interior with warm yellow
lighting, cute organic cafe aesthetic
```

**シード**: `102`

---

## ⑨ `bld_B007_lv2` — オーガニックカフェ Lv2

**サイズ**: 64 × 72 px

```
the same organic cafe upgraded to 2 stories, cream walls with orange
trim, wooden awning with string lights, 2nd floor terrace with potted
herbs and a small outdoor seating area, green vines climbing the
facade, warm lamp glow from windows, chalkboard menu on the ground
floor, same cozy identity as Lv1 but with rooftop garden
```

**シード**: `102`

---

## ⑩ `bld_B013_lv1` — 瞑想センター Lv1 (飲酒軸)

**サイズ**: 64 × 52 px
**アクセント**: 紫 `#AF52DE`

```
a small isometric meditation center, 1-story zen-inspired building,
white and light wood walls with soft purple accents (#AF52DE),
traditional Japanese pagoda-style pitched roof with curved eaves,
bonsai tree next to the entrance, sliding shoji door, small stone
lantern on the left side, serene and calming atmosphere, minimalist
and peaceful
```

**シード**: `103`

---

## ⑪ `bld_B017_lv1` — 睡眠クリニック Lv1 (睡眠軸)

**サイズ**: 64 × 52 px
**アクセント**: 青 `#007AFF`

```
a small isometric sleep clinic, 1-story medical-style building, white
walls with calming blue accents (#007AFF), large curved window with
blue tinted glass, a crescent moon icon sign above the entrance,
sleek modern clinic architecture, soft blue rooftop, a small "Z"
decoration on the sign, tranquil medical facility aesthetic
```

**シード**: `104`

---

## ⑫ `bld_B023_lv1` — ウォーターサーバー広場 Lv1 (生活習慣軸)

**サイズ**: 64 × 52 px
**アクセント**: ピンク `#FF2D55`

```
a small isometric public water fountain plaza, 1-story open
structure, a central stone fountain with flowing blue water, pink
accent tiles (#FF2D55) on the circular base, two curved stone benches
around the fountain, small water droplet icons as decoration, bright
and refreshing public space, community gathering spot
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
