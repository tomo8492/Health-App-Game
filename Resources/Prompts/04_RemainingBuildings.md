# 04 — 残り建物カタログ（22 建物 × Lv1 = 22 枚）

配信後パッチで順次追加する建物群。**MVP は Lv1 のみで十分**。
Lv2〜Lv5 の画像が無い場合、renderer は**プロシージャル生成**にフォールバックする
（低 Lv 画像へのカスケードは行わない: BuildingNode のスプライトサイズは Lv ごとに
異なるため、低 Lv 画像を流用すると縦に引き延ばされて表示が崩れる）。
プロシージャル表示と画像表示は同じ Lv 固有サイズで整合する。

プロンプトは `STYLE_PREFIX` + 本文 + `STYLE_SUFFIX` + `NEGATIVE` で使用。
すべて **64 × 52 px**（Lv1）、**16色パレット**、**背景透明**。

---

## 運動軸（緑 #34C759）

### `bld_B002_lv1` — スポーツスタジアム
```
an isometric sports stadium, oval shape with bright green pitch
visible inside, curved white concrete walls, green banners, stadium
lights on tall poles, entrance archway with scoreboard, large
landmark sports venue
```
シード: `110`

### `bld_B003_lv1` — 公園・ランニングコース
```
an isometric small park with a running track, green lawn surface,
winding red-brown running path, a few benches, young trees around
the perimeter, a stretching spot marker, cheerful outdoor recreation
area
```
シード: `111`

### `bld_B004_lv1` — プール
```
an isometric swimming pool facility, rectangular blue pool with
lane dividers, white tile deck, green umbrellas, glass-walled
swim building adjacent, aquatic sports feel
```
シード: `112`

### `bld_B005_lv1` — ヨガスタジオ
```
an isometric yoga studio, soft pastel green walls, large glass
window showing a yoga mat silhouette, a lotus icon above the door,
small zen garden with stones outside, peaceful wellness studio
```
シード: `113`

### `bld_B006_lv1` — 自転車ステーション
```
an isometric bike share station, green canopy roof, 4 bicycles
parked in a row at docking stations, a small payment kiosk, urban
mobility hub, clean modern infrastructure
```
シード: `114`

---

## 食事軸（橙 #FF9500）

### `bld_B008_lv1` — ファーマーズマーケット
```
an isometric outdoor farmers market, open wooden stalls under
striped orange canvas awnings, baskets of colorful vegetables and
fruits, a chalkboard menu, rustic fresh produce market
```
シード: `120`

### `bld_B009_lv1` — ヘルシーレストラン
```
an isometric healthy restaurant, warm cream walls with orange trim,
large glass window showing dining area, a leaf icon sign, wooden
patio seating outside, farm-to-table aesthetic
```
シード: `121`

### `bld_B010_lv1` — 料理教室
```
an isometric cooking school, cream walls with orange chef-hat sign,
large window showing countertops with ingredients, a red-brick
chimney, warm inviting culinary school
```
シード: `122`

### `bld_B011_lv1` — サラダバー
```
an isometric salad bar, bright fresh green and white exterior,
glass counter showing colorful salad bowls, a simple geometric
leaf logo, small and modern eatery
```
シード: `123`

### `bld_B012_lv1` — ジューススタンド
```
an isometric juice stand, small kiosk with bright yellow-orange
awning, fruit crates on display (oranges, apples, berries), a
chalkboard menu of juices, cheerful small street vendor
```
シード: `124`

---

## 飲酒軸（紫 #AF52DE、ポジティブ側）

### `bld_B014_lv1` — ハーブティーショップ
```
an isometric herbal tea shop, soft lavender walls, dried herbs
hanging in the window, a steaming teacup icon sign, cozy apothecary
feel, wooden door with stained glass, aromatic herbal store
```
シード: `130`

### `bld_B015_lv1` — セルフケアスパ
```
an isometric self-care spa, elegant purple and white walls, a
relaxation icon (crescent moon + steam) sign, stone walkway, small
bamboo accent, serene wellness retreat
```
シード: `131`

### `bld_B016_lv1` — コミュニティセンター
```
an isometric community center, warm cream and purple walls, group
gathering silhouette through the window, a handshake icon sign,
welcoming public building, garden bench outside
```
シード: `132`

---

## 睡眠軸（青 #007AFF）

### `bld_B018_lv1` — 天文台
```
an isometric observatory, cylindrical white tower with a domed
silver roof that slides open, a telescope peeking out, star icons
on the base, deep blue night sky mural on the walls, scientific
stargazing building
```
シード: `140`

### `bld_B019_lv1` — 図書館（生活習慣軸）
```
an isometric library, classic cream walls with pink accent trim
(#FF2D55), tall arched windows showing bookshelves, a book icon
sign above the entrance, stone columns flanking the door, scholarly
quiet atmosphere
```
シード: `141`
**注意**: 軸は **生活習慣** なのでアクセントは**ピンク**

### `bld_B020_lv1` — アロマテラピーショップ
```
an isometric aromatherapy shop, soft pale blue walls, glass bottles
of essential oils in the window, a leaf-and-droplet icon sign,
dried lavender bunches hanging outside, calming sensory store
```
シード: `142`

### `bld_B021_lv1` — ムーンライトパーク
```
an isometric moonlight park, night-themed park with a stone arch
entrance, a crescent moon sculpture, dark blue path with tiny
sparkles (stars), silver benches, serene nighttime outdoor space
```
シード: `143`

### `bld_B022_lv1` — 布団・寝具専門店
```
an isometric bedding store, cream walls with blue awning, large
window showing pillows and folded futons on display, a "Z" sleep
icon sign, warm inviting sleep-goods shop
```
シード: `144`

---

## 生活習慣軸（ピンク #FF2D55）

### `bld_B024_lv1` — メンタルヘルスクリニック
```
an isometric mental health clinic, white and soft pink walls, a
heart+brain icon sign, large welcoming windows with curtains,
approachable medical building, healing atmosphere
```
シード: `150`

### `bld_B026_lv1` — 習慣カレンダータワー
```
an isometric habit calendar tower, tall slender monument-like
structure, pink and cream vertical stripes, large calendar face
with dates, a streak flame icon at the top, motivational civic
monument
```
シード: `151`

### `bld_B027_lv1` — ウェルネスショップ
```
an isometric wellness shop, cream walls with pink accents, display
window with vitamin bottles and yoga mats, a heart icon sign,
boutique health store
```
シード: `152`

### `bld_B028_lv1` — 公民館
```
an isometric community hall, traditional Japanese-meets-Western
cream building with pink tile roof accents, large entrance with
double doors, banner reading "公民館" styled as a sign (kanji
rendered as decorative shapes, not readable text), local gathering
hall
```
シード: `153`
**注意**: 「kanji rendered as shapes」で**判読不能な装飾文字**にすること
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
