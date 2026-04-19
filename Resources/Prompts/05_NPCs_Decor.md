# 05 — NPC・装飾・追加タイル

**優先度低**: プロシージャル生成のままで違和感は少ない。
配信後の品質アップデートで順次差し替え推奨。

> **重要**: NPC デザインは `Resources/GameDesign/02_CharacterDesign.md` が正。
> プロンプトはその仕様を PixelLab.ai 用に落とし込んだもの。

---

## NPC（6 種族 × 4 フレーム = 24 枚）

**サイズ**: 24 × 42 px（PixelLab では 64 × 128 で生成 → Nearest Neighbor で縮小）
**視点**: **正面向き**（isometric ではなくフロント 3/4 ビュー）
**スタイル**: 2.5 頭身の**チビキャラ**、RPG風
**シルエット原則**: 色だけでなく**形状で区別**できること（帽子・エプロン・ロングスカート等）

### 命名

`npc_{type}_f{frame}` — type: 0-5, frame: 0-3

| frame | ポーズ |
|-------|--------|
| f0 | idle（静止、両腕を体側に） |
| f1 | walkLeft（左足前、右腕前） |
| f2 | walkMid（両足揃え、腕中立） |
| f3 | walkRight（右足前、左腕前） |

### 6 種族プロンプト

#### `npc_0_*` — 旅人（プレイヤーの化身）

**人格**: 街を旅する冒険者。市庁舎付近に常駐。街Lv3以上で出現。
**識別特徴**: **金色のマント** + 大きなリュック

```
chibi pixel art character sprite, front-facing 3/4 view,
golden blonde hair, warm brown travel tunic, flowing golden cape
(#FFD700) draped over shoulders, large brown backpack, sturdy
brown leather boots, cheerful wise adventurer, 2.5-head
proportions, JRPG hero style, simple and readable at small size
```
シード: `300`

---

#### `npc_1_*` — ハルナ（運動軸 / citizen1）

**人格**: 明るく元気な朝ランナー。緑が目印。
**識別特徴**: **緑のトラックウェア** + ショートカット + ポニーテール + 白スニーカー

```
chibi pixel art character sprite, front-facing 3/4 view,
short dark brown hair with a small ponytail on the right side,
slim athletic build, bright green (#34C759) track jacket,
matching green track pants, white running sneakers, energetic
sporty young woman, lightly tanned skin, 2.5-head proportions,
JRPG style
```
シード: `301`

---

#### `npc_2_*` — ミツル（食事軸 / citizen2）

**人格**: 穏やかな職人気質の元料理人。オレンジのエプロンが目印。
**識別特徴**: **オレンジのエプロン** + バンダナ + がっしり体格

```
chibi pixel art character sprite, front-facing 3/4 view,
salt-and-pepper black hair with a white chef bandana on head,
sturdy broad-shouldered build, bright orange (#FF9500) apron
over cream shirt, beige chino pants, dark brown work shoes,
warm and kind-looking middle-aged chef, 2.5-head proportions,
JRPG style
```
シード: `302`

---

#### `npc_3_*` — ユキ（飲酒自制軸 / elder）

**人格**: 静かで芯が強い瞑想家。紫の和装が目印。
**識別特徴**: **紫の作務衣** + 黒髪を束ねたまとめ髪 + 草履

```
chibi pixel art character sprite, front-facing 3/4 view,
long black hair tied in a neat bun at the back, calm serene
expression, deep purple (#AF52DE) samue (Japanese work robe)
with a cream-beige obi sash at the waist, the robe extends
below the knees covering the legs, wooden geta sandals,
meditative peaceful person, 2.5-head proportions, JRPG style
```
シード: `303`

---

#### `npc_4_*` — リク（睡眠軸 / child）

**人格**: マイペースな睡眠研究者。青いベレー帽が目印。
**識別特徴**: **青のベレー帽** + 丸眼鏡 + 白衣風の上着

```
chibi pixel art character sprite, front-facing 3/4 view,
light brown messy hair under a distinctive blue (#007AFF)
beret hat, round glasses, white lab coat-style jacket over
a light blue shirt, dark blue pants, blue sneakers, curious
intellectual young researcher, 2.5-head proportions, JRPG
style
```
シード: `304`

---

#### `npc_5_*` — アオイ（生活習慣軸 / citizen3）★新規

**人格**: 優しい姉御肌の図書館司書。ピンクのカーディガンとロングスカートが目印。
**識別特徴**: **ピンクのカーディガン** + 三つ編み + ロングスカート + 本

```
chibi pixel art character sprite, front-facing 3/4 view,
chestnut brown hair in a long braid falling over the left
shoulder, round glasses, soft pink (#FF2D55 desaturated)
cardigan over a white blouse, dark purple long flowing skirt
reaching the ankles, brown low-heeled shoes, carrying 2-3
small books in one arm, gentle librarian, 2.5-head
proportions, JRPG style
```
シード: `305`

---

### アニメーション生成のコツ

**PixelLab.ai の "Character Animation" 機能**で 4 フレームを一括生成。
あるいは f0（idle）を作った後、image-to-image で「same character but
left foot forward」などの指示でフレーム追加。

- 各フレームで**キャラの顔・服装の色が絶対に変わらない**ようシード固定
- 歩行フレームは f1（left）と f3（right）が**ミラー反転**に近いとベスト
- **識別特徴（帽子・エプロン・マント等）はフレーム間で消えないこと**
- 失敗例: 頭身が変わる / 服の色が違う / 帽子が消える / 顔が別人

### シルエットテスト

6 種族の f0 画像を横に並べて、**モノクロ化しても誰か識別できる**ことを確認:

- 旅人: マント + リュックの横幅が広い
- ハルナ: スリム + ポニーテールが右に突出
- ミツル: 胴体が広い（エプロン）
- ユキ: 裾が長い（和服）+ 足元が狭い
- リク: 頭頂が尖る（ベレー帽）
- アオイ: スカートが裾広がり + 左に三つ編み

---

## 特殊キャラクター（将来実装 / Phase 7+）

### `npc_postman` — 郵便配達員ポッピー（ログインボーナス演出用）

**用途**: ログインボーナスオーバーレイの立ち絵（UI 表示のみ、街には不要）
**サイズ**: 48 × 84 px（通常 NPC の 2 倍サイズ）

```
chibi pixel art character sprite, front-facing 3/4 view,
cheerful mail carrier, pink (#FF2D55) postal uniform with
white collar, small red peaked cap, brown leather mail bag
slung diagonally across body, holding a golden envelope with
a star seal, bright smile, 2.5-head proportions, JRPG style,
larger and more detailed than normal NPC sprites
```
シード: `310`

---

## 装飾（7 枚）

### `tree_0` — 広葉樹
**サイズ**: 24 × 40 px

```
isometric pixel art tree, a round leafy broadleaf tree, bright
green foliage (#3AAA28) with darker green shadows (#2D8B1E),
three-layered canopy with highlight on top-left, brown trunk
(#6B4E2A), small and cute park tree, transparent background
```
シード: `400`

### `tree_1` — 針葉樹
**サイズ**: 24 × 40 px

```
isometric pixel art tree, a triangular pine/fir tree, dark green
conical foliage with layered branches, brown trunk, evergreen
forest tree, transparent background
```
シード: `401`

### `deco_streetlamp` — 街灯
**サイズ**: 8 × 22 px（極小 → **32×88 で生成して Nearest Neighbor 縮小**）

```
isometric pixel art street lamp, dark brown (#5D4037) pole with
L-shaped arm, glowing warm yellow lamp head (#FFF9C4) with soft
golden aura, traditional European city street lamp, very small
sprite, minimal detail
```
シード: `410`

### `deco_bench` — ベンチ
**サイズ**: 16 × 12 px

```
isometric pixel art park bench, wooden seat and backrest in brown
(#8D6E63) and dark brown (#5D4037), four small legs, facing front,
tiny public bench, very small sprite
```
シード: `411`

### `deco_flowerpot` — 花鉢 ★新規
**サイズ**: 10 × 14 px（極小 → **40×56 で生成して縮小**）

```
isometric pixel art flower pot, terracotta brown (#A1887F) pot
with two small flowers (one red #FF5252, one yellow #FFEB3B)
and green leaves, tiny garden decoration, transparent background,
very small sprite
```
シード: `412`

### `deco_signpost` — 案内標識 ★新規
**サイズ**: 12 × 20 px（→ **48×80 で生成して縮小**）

```
isometric pixel art wooden signpost, dark brown (#5D4037) pole,
cream-yellow (#FFF9C4) direction board with decorative lines
(no readable text), brown wooden base, small wayfinding sign,
transparent background
```
シード: `413`

### `deco_waterwell` — 井戸 ★新規
**サイズ**: 16 × 18 px（→ **64×72 で生成して縮小**）

```
isometric pixel art stone water well, circular gray stone (#B0BEC5)
base with blue water (#4FC3F7) visible inside, dark brown wooden
frame and crossbar on top, small bucket hanging, quaint village
well, transparent background
```
シード: `414`

---

## 追加タイル（2 枚）

### `tile_cobblestone` — 石畳タイル ★新規（プレミアム用）
**サイズ**: 64 × 32 px

```
isometric pixel art cobblestone tile, diamond shape 2:1 aspect
ratio, warm beige-gray stone (#C8B8A0) with individual cobble
stones visible in a brick-like pattern, darker grout lines
(#8A7A60) between stones, slightly weathered texture, tileable
seamless, elegant European town road, top-down isometric view
```

### `tile_sand` — 砂タイル
**サイズ**: 64 × 32 px

```
isometric pixel art sand tile, diamond shape 2:1 aspect ratio,
warm beige sand (#F0D890) with darker grains (#C0A850), a few
small pebbles scattered, tileable seamless, top-down isometric view
```

---

## 配信前に必要か？

| アセット | MVP 必須 | 配信後パッチで OK |
|---------|---------|---------------------|
| NPC 全 6 種 | ✘ | ✓ プロシージャル版が動く |
| 木 2 種 | ✘ | ✓ |
| 街灯・ベンチ・花鉢・標識・井戸 | ✘ | ✓ |
| 石畳タイル | ✘ | ✓（プレミアム専用） |
| 砂タイル | ✘ | ✓（マップ拡張 Lv4 以降） |

**結論**: 本ファイルの 33 枚はすべて**配信後アップデート対応**で問題なし。
