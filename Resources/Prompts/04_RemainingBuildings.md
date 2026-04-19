# 04 — 残り建物カタログ（22 建物 × Lv1 = 22 枚）

配信後パッチで順次追加する建物群。**MVP は Lv1 のみで十分**。
Lv2〜Lv5 の画像が無い場合、renderer は**プロシージャル生成**にフォールバックする
（低 Lv 画像へのカスケードは行わない: BuildingNode のスプライトサイズは Lv ごとに
異なるため、低 Lv 画像を流用すると縦に引き延ばされて表示が崩れる）。
プロシージャル表示と画像表示は同じ Lv 固有サイズで整合する。

プロンプトは `STYLE_PREFIX` + 本文 + `STYLE_SUFFIX` + `NEGATIVE` で使用。
すべて **64 × 52 px**（Lv1）、**16色パレット**、**背景透明**。

> **重要**: 各軸のデザイン言語は `Resources/GameDesign/01_BuildingDesign.md` が正。
> プロンプトはその仕様を PixelLab.ai 用に落とし込んだもの。

---

## 運動軸（緑 #34C759）

**軸デザイン言語**: ガラス+明るい木材、片流れ/大庇、大きな横長窓、直線的・アクティブ

### `bld_B002_lv1` — スポーツスタジアム
```
an isometric sports stadium, oval shape with bright green (#34C759)
pitch visible inside, wood-and-glass curved walls with lean-to
canopy, green banners on tall poles, wide horizontal entrance
archway, a small scoreboard icon, straight clean lines, energetic
sports venue, active and open feel
```
シード: `110`

### `bld_B003_lv1` — 公園・ランニングコース
```
an isometric small park with a running track, bright green lawn,
winding red-brown running path, a wooden bench, young trees with
bright wood trunks around the perimeter, a small wayfinding
signboard, wide open space, cheerful active recreation area,
straight clean pathways
```
シード: `111`

### `bld_B004_lv1` — プール
```
an isometric swimming pool facility, rectangular blue pool with
lane dividers visible, bright wood deck surround, glass-walled
swim building with flat lean-to roof, green (#34C759) accent
stripe on the building, a green parasol, horizontal windows
showing pool interior, aquatic active sports feel
```
シード: `112`

### `bld_B005_lv1` — ヨガスタジオ
```
an isometric yoga studio, bright wood frame walls with large
glass panels, flat roof with green (#34C759) accent edge, a
lotus icon sign above the door, a small wooden terrace with a
yoga mat visible, tiny zen stones at the entrance, peaceful
but active wellness studio, clean straight lines
```
シード: `113`

### `bld_B006_lv1` — 自転車ステーション
```
an isometric bike share station, bright wood structure with
glass panel sides, flat green (#34C759) canopy roof, 4 bicycles
parked in a row at docking stations, a small payment kiosk,
horizontal clean design, a tiny air pump and toolbox near
the rack, urban active mobility hub
```
シード: `114`

---

## 食事軸（橙 #FF9500）

**軸デザイン言語**: 煉瓦+暖色漆喰、三角屋根+煙突、格子窓+レースカーテン、曲線的・家庭的

### `bld_B008_lv1` — ファーマーズマーケット
```
an isometric outdoor farmers market, open wooden stalls under
orange (#FF9500) striped canvas awnings with curved edges, brick
base, wicker baskets of colorful vegetables and fruits, a
chalkboard menu with rounded frame, burlap sacks of produce,
rustic warm handmade market feel, gentle curves
```
シード: `120`

### `bld_B009_lv1` — ヘルシーレストラン
```
an isometric healthy restaurant, warm cream plaster (#F4E6C8)
and brick walls, orange (#FF9500) triangular pitched roof with
a small chimney, lattice windows with lace curtains showing
dining area, a leaf icon sign, wooden patio seating with a small
planter outside, farm-to-table homey aesthetic, rounded details
```
シード: `121`

### `bld_B010_lv1` — 料理教室
```
an isometric cooking school, cream plaster and brick walls, orange
(#FF9500) triangular roof with a red-brick chimney, a chef-hat
icon sign, lattice window showing countertops with ingredients,
a wooden cutting board propped by the door, warm inviting
culinary school, gentle curved lines, homey feel
```
シード: `122`

### `bld_B011_lv1` — サラダバー
```
an isometric salad bar, small circular kiosk shape with cream
plaster walls and brick base, orange (#FF9500) conical awning
with gentle curves, glass counter showing colorful salad bowls,
a simple leaf logo, fresh green herbs visible, bright and
friendly small eatery, rounded organic shape
```
シード: `123`

### `bld_B012_lv1` — ジューススタンド
```
an isometric juice stand, small kiosk with brick base and cream
walls, bright orange (#FF9500) awning with curved edges, fruit
crates on display (oranges, apples, berries stacked), a
chalkboard menu of juices with rounded frame, a small straw
dispenser, cheerful street vendor, warm handmade feel
```
シード: `124`

---

## 飲酒軸（紫 #AF52DE、自制・代替）

**軸デザイン言語**: 石材+濃い木+障子風パネル、入母屋屋根、円窓・すりガラス、静的・シンメトリー

### `bld_B014_lv1` — ハーブティーショップ
```
an isometric herbal tea shop, dark wood (#5A3826) frame with
stone base, soft purple (#AF52DE) noren curtain at the entrance,
frosted glass window showing dried herbs inside, Japanese irimoya
style sloped roof with dark tiles, a steaming teacup icon sign,
wooden box display of herb jars outside, symmetrical facade,
cozy apothecary feel, quiet static atmosphere
```
シード: `130`

### `bld_B015_lv1` — セルフケアスパ
```
an isometric self-care spa, stone (#B0BEC5) walls with dark wood
accents, shoji-style frosted panels on the facade, purple
(#AF52DE) accent on the door frame, flat traditional roof with
curved eaves, a stone pathway to the entrance, a small bamboo
water feature (tsukubai) to the side, symmetrical composition,
serene static wellness retreat, quiet meditative atmosphere
```
シード: `131`

### `bld_B016_lv1` — コミュニティセンター
```
an isometric community center, Japanese-Western hybrid building,
stone and dark wood walls, cream plaster upper section, purple
(#AF52DE) accent lantern (chochin) by the entrance, circular
window (maru-mado) on the side, irimoya-style roof, a garden
bench on one side, symmetrical welcoming public building,
calm and static composition
```
シード: `132`

---

## 睡眠軸（青 #007AFF）

**軸デザイン言語**: ネイビー瓦+白壁、丸いドーム or 尖塔、星型窓・三日月看板、緩やかな曲線

### `bld_B018_lv1` — 天文台
```
an isometric observatory, cylindrical white tower with a navy
blue (#007AFF) domed roof that slides open, a telescope peeking
out, star-shaped cutout windows on the tower wall, small
constellation panel decoration at the base, gentle curved
architecture, scientific stargazing building, tranquil
nighttime atmosphere
```
シード: `140`

### `bld_B019_lv1` — 図書館（⚠️ 生活習慣軸）
```
an isometric library, classic cream plaster (#F4E6C8) walls with
pink (#FF2D55) decorative tile trim, mansard roof with pink tile
accents, tall sash windows showing bookshelves inside, a book
icon sign above the entrance, stone columns flanking the door,
a small flower bed at the base, scholarly quiet atmosphere,
academic and welcoming public facility
```
シード: `141`
**注意**: 軸は **生活習慣** なのでアクセントは**ピンク**、デザイン言語も生活習慣軸に従う

### `bld_B020_lv1` — アロマテラピーショップ
```
an isometric aromatherapy shop, white walls with navy blue
(#007AFF) tile roof featuring a small spire, round porthole
windows showing glass bottles of essential oils inside, a
leaf-and-droplet icon sign on a bracket, dried lavender bunches
hanging from the eaves, gentle curved roofline, warm lamp glow
from inside, calming sensory store, soft curved lines
```
シード: `142`

### `bld_B021_lv1` — ムーンライトパーク
```
an isometric moonlight park, night-themed park with a stone arch
entrance, navy blue (#007AFF) path with tiny sparkle dots (stars),
a crescent moon sculpture centerpiece, silver benches with gentle
curved backs, star-shaped lamp posts, dark blue-gray ground,
serene nighttime outdoor space, gentle rounded forms throughout
```
シード: `143`

### `bld_B022_lv1` — 布団・寝具専門店
```
an isometric bedding store, white walls with navy blue (#007AFF)
awning featuring gentle curves, domed shop roof accent, round
porthole window showing pillows and folded futons on display, a
crescent moon "Z" sleep icon sign hanging on a bracket, warm
golden lamp glow from inside, inviting sleep-goods shop, soft
rounded architecture
```
シード: `144`

---

## 生活習慣軸（ピンク #FF2D55）

**軸デザイン言語**: クリーム漆喰+淡ピンク装飾タイル、寄棟/マンサード屋根、縦長上げ下げ窓、折衷的・アカデミック

### `bld_B024_lv1` — メンタルヘルスクリニック
```
an isometric mental health clinic, cream plaster (#F4E6C8) walls
with soft pink (#FF2D55) decorative tile accents, mansard roof
with pink tile edges, tall sash windows with warm curtains, a
heart+brain icon sign above the entrance, a potted plant and a
small bench by the door, approachable academic medical building,
warm welcoming healing atmosphere
```
シード: `150`

### `bld_B026_lv1` — 習慣カレンダータワー
```
an isometric habit calendar tower, tall slender monument-like
structure, cream plaster and pink (#FF2D55) decorative tile
vertical stripes, hip roof cap with pink tiles, a large
calendar face with date marks (no readable text), a streak
flame icon at the top, a small flower bed at the base,
motivational civic monument, academic and warm
```
シード: `151`

### `bld_B027_lv1` — ウェルネスショップ
```
an isometric wellness shop, cream plaster (#F4E6C8) walls with
pink (#FF2D55) tile trim accents, mansard roof with pink edges,
tall sash display window with vitamin bottles and wellness goods,
a heart icon sign, a small book-shaped object by the door,
boutique health store, warm academic public facility aesthetic
```
シード: `152`

### `bld_B028_lv1` — 公民館
```
an isometric community hall, Japanese-meets-Western cream plaster
building with pink (#FF2D55) hip roof tile accents, large
entrance with double doors, tall sash windows, a decorative
emblem above the entrance (abstract shapes, NOT readable text),
a small bulletin board and flower bed outside, warm local
gathering hall, academic public building feel
```
シード: `153`
**注意**: 看板は**判読不能な装飾文字**にすること
（実際の文字を入れると App Store 審査で NG の可能性）

---

## 量が多い場合の省略判断

Lv1 だけで 22 枚。1 枚あたり 3〜5 分の生成+調整時間として **2〜4 時間**。

**配信前に必須**: 市庁舎 B025（3 Lv）+ ⑥〜⑫ の 7 建物 = **10 枚**
**配信後パッチで OK**: 本リストの残り 22 枚
**完全パリティ**: 上記 + NPC + 装飾 = 60 枚規模（Phase B 以降）

## バッチ生成 Tips

- **軸ごとに連続生成**すると色調が揃いやすい
- PixelLab.ai の「Style Reference」機能で Lv1 画像を参照にすると
  他の建物もスタイル統一しやすい
- 同時期に生成した 5〜6 枚を並べて比較し、浮いているものだけリトライ
