# 05 — NPC と街の装飾

**優先度低**: プロシージャル生成のままで違和感は少ない。
配信後の品質アップデートで順次差し替え推奨。

---

## NPC（5 種族 × 4 フレーム = 20 枚）

**サイズ**: 24 × 42 px（PixelLab では 64 × 128 で生成 → 縮小）
**視点**: **正面向き**（isometric ではなくフロント 3/4 ビュー）
**スタイル**: 2.5 頭身の**チビキャラ**、RPG風

### 命名

`npc_{type}_f{frame}` — type: 0-4, frame: 0-3

| frame | ポーズ |
|-------|--------|
| f0 | idle（静止、両腕を体側に） |
| f1 | walkLeft（左足前） |
| f2 | walkRight（右足前） |
| f3 | walkMid（両足揃える、中立） |

### 5 種族プロンプト

#### `npc_0_*` — 冒険者（メイン主人公風）
```
chibi pixel art character sprite, front-facing, blonde hair with
orange cape, teal tunic, brown boots, cheerful adventurer, 2.5-head
proportions, JRPG style, simple and readable at small size
```
シード: `300`

#### `npc_1_*` — 市民 A（青系）
```
chibi pixel art character sprite, front-facing, dark hair with blue
shirt and gray pants, glasses, friendly urban citizen, 2.5-head
proportions, JRPG style
```
シード: `301`

#### `npc_2_*` — 市民 B（赤系）
```
chibi pixel art character sprite, front-facing, brown hair with red
hoodie and dark jeans, casual youth, 2.5-head proportions, JRPG
style
```
シード: `302`

#### `npc_3_*` — 老人
```
chibi pixel art character sprite, front-facing, white hair and
beard, dark green cardigan, brown pants, kind elderly person with
a small cane, 2.5-head proportions, JRPG style
```
シード: `303`

#### `npc_4_*` — 子ども
```
chibi pixel art character sprite, front-facing, small child with
orange hair in pigtails, yellow t-shirt with a star, red skirt,
sneakers, cheerful kid, 2.3-head proportions (smaller), JRPG style
```
シード: `304`

### アニメーション生成のコツ

**PixelLab.ai の "Character Animation" 機能を使う**と 4 フレームを一括生成。
あるいは f0（idle）を作った後、image-to-image で「same character but
left foot forward」などの指示でフレーム追加。

- 各フレームで**キャラの顔・服装の色が絶対に変わらない**ようシード固定
- 歩行フレームは f1（left）と f2（right）が**ミラー反転**に近いとベスト
- 失敗例: 頭身が変わる／服の色が違う／顔が別人

---

## 装飾（3 枚）

### `tree_0` — 広葉樹
**サイズ**: 24 × 40 px

```
isometric pixel art tree, a round leafy broadleaf tree, bright
green foliage with darker green shadows, brown trunk, small and
cute park tree, transparent background
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
**サイズ**: 8 × 22 px（非常に小さい！）

```
isometric pixel art street lamp, dark brown pole, small L-shaped
arm at top, glowing yellow lamp head with soft golden aura,
traditional city street lamp, very small sprite
```
シード: `410`
**注意**: 8×22px は極小なので**キャンバスを 32×88 に拡大して生成→縮小**。
読みやすさ重視でディテールは最小限に。

### `deco_bench` — ベンチ
**サイズ**: 16 × 12 px

```
isometric pixel art park bench, wooden seat and backrest in brown
and dark brown, four small legs, facing front, tiny public bench,
very small sprite
```
シード: `411`

---

## 残り地面タイル

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
| NPC 全 5 種 | ✘ | ✓ プロシージャル版が動く |
| 木 2 種 | ✘ | ✓ |
| 街灯・ベンチ | ✘ | ✓ |
| 砂タイル | ✘ | ✓（マップ拡張 LV4 以降でしか使わない） |

**結論**: 本ファイルの 25 枚はすべて**配信後アップデート対応**で問題なし。
来週配信は `01_MVP_TopPriority.md`（5枚）+ `02_HighPriority.md`（10枚）+
`03_Penalty_AppIcon.md`（3枚）= **18 枚**を目標に。
