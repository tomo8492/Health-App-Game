# 03 — ペナルティ建物 & アプリアイコン

ペナルティ建物（B029/B030）は**過飲記録時に自動出現**するためゲーム体験を
左右する重要要素。アプリアイコンは App Store 審査に必須。

---

## ⑯ `bld_B029_lv1` — 古びた居酒屋（ペナルティ）

**サイズ**: 64 × 52 px
**雰囲気**: 質素で寂しげ、でも不潔ではない。罪悪感を軽く示唆する程度。

> **設計方針**: 醜くしない。「暖かい窓明かり」で完全否定にならないようバランスを取る。
> 詳細は `Resources/GameDesign/01_BuildingDesign.md` §3 特殊建物を参照。

```
a small isometric old izakaya Japanese pub, 1-story weathered
wooden facade, faded dark brown wood panels, two faded red paper
lanterns (not bright — washed-out red) hanging from the eaves,
a slightly tilted noren curtain covering the entrance, roof tiles
with 2 tiles visibly missing on the right side, BUT warm golden
window light glowing softly from inside (not fully negative),
a single empty bottle near the doorstep (subtle hint, not many),
quiet and melancholy atmosphere, subdued muted color palette,
NOT ugly NOT dirty — just old and lonely
```

**シード**: `200`（ペナルティ建物は別シリーズなので独立シード）
**注意**: 「**暖かい窓明かり**」を必ず入れる。完全に暗く汚くしない。色あせ＋寂しさが正解。

---

## ⑰ `bld_B030_lv1` — 廃墟ビル（ペナルティ）

**サイズ**: 64 × 72 px
**雰囲気**: ツタが這う切ない建物。ホラーではなく「夕焼けが似合う」。

> **設計方針**: 虫・血・暗闇は NG。物寂しさを表現。雑草は小さく、ツタは植物の生命力。

```
a small isometric abandoned office building, 2-stories, gray
concrete walls (#9E9E9E, not too dark) with hairline cracks,
a cracked wooden sign hanging slightly crooked, boarded-up
windows with wooden planks on the ground floor, 2nd floor
windows still intact but dusty, green ivy vines climbing up
the left wall (life reclaiming the building — not horror),
small weeds at the base (tiny, not overgrown jungle), a
faded faint sunset glow reflecting on the walls (melancholy
golden hour feel), no lights inside, muted desaturated
palette, atmosphere of quiet sadness NOT horror NOT scary,
the kind of building that makes you feel a little wistful
```

**シード**: `201`
**注意**: 全体の**彩度を明確に落とす**がホラーにしない。ツタは「植物の生命力」として表現。

---

## ⑱ `AppIcon` — アプリアイコン（1024×1024）

**サイズ**: **1024 × 1024 px**（正方形、角丸なし。iOS が自動で丸める）
**背景**: 透明**禁止**（App Store 要件で不透明必須）

### メインコンセプト
街のシルエットの上に輝く CP の星。「健康＝街が育つ」が一目で伝わる。

```
a vibrant pixel art mobile app icon for a health and city-building
game, 1024x1024, square canvas, fully opaque background with a soft
gradient sky (sunrise colors from orange #FF9500 at top to light blue
#7EC8F4 at bottom), centered composition featuring: a small
isometric city skyline silhouette at the bottom third (1-2 buildings
including a clock tower) in cream and red colors, a large shining
golden star (#FFD700) centered in the upper two-thirds emitting soft
light rays, the star represents CP (city points / wellness points),
tiny floating healthy icons around the star (green leaf, blue water
drop, orange sun) as small accents, warm uplifting atmosphere,
professional mobile game icon quality, clean pixel art style but
readable at small sizes
```

**推奨シード**: 任意（複数試して最もアイコニックなものを採用）

### バリエーション案（気に入らなければ試す）

- **A案: 街シルエット + 輝く CP 星**（上記）
- **B案: 市庁舎だけを正面から堂々と + 金の後光**
- **C案: 5 軸の色が花弁のように広がる抽象的ロゴ + 中央に街**

### アイコン固有の注意

- **角丸不要**（iOS が自動で `SuperEllipse` に丸める）
- **透過 NG**（不透明背景必須）
- **テキスト禁止**（小サイズで読めない・App Store レビューで減点リスク）
- **小さく見えても識別できるか**を必ず 40×40 にリサイズしてチェック
- **他の健康アプリと色で区別**: FitBit系は緑、Apple ヘルスケアはピンク、
  VITA CITY は「**金+暖色**」で差別化

### App Store Connect 用の追加サイズ

AppIcon を 1024×1024 で 1 枚だけ用意すれば、
Xcode の asset catalog が自動的に他サイズを派生する。
ただし念のため以下も生成しておくと手動調整が楽:

- 180×180（iPhone）
- 120×120（iPhone 古い機種）
- 40×40（Spotlight 検索・通知）

基本は 1024 だけで OK。

---

## チェックリスト

### ペナルティ建物
- [ ] B029 は「飲み過ぎ」を連想させるが**差別的/ネガティブすぎない**
- [ ] B030 はホラーではなく**物寂しい**雰囲気
- [ ] 他のポジティブな建物と比較して明確に**色が沈んでいる**
- [ ] 背景透明

### アプリアイコン
- [ ] 40×40 に縮小しても識別できる
- [ ] 背景が完全不透明（透過 0%）
- [ ] テキストなし
- [ ] 1024×1024 の JPG/PNG（透過 PNG でも OK、Xcode が変換）
- [ ] Apple Human Interface Guidelines の「Icon Design」準拠

## 生成後の投入フロー

1. PixelLab.ai で生成した PNG をダウンロード
2. **ペナルティ建物** (⑯⑰):
   - Xcode → `Resources/Assets.xcassets/PixelArt/Buildings/`
   - `_Template.imageset` を Duplicate → `bld_B029_lv1` にリネーム
   - 1x スロットに PNG をドラッグ
3. **AppIcon** (⑱):
   - Xcode → `Resources/Assets.xcassets/AppIcon.appiconset`
   - 1024×1024 スロットにドラッグ
   - Xcode が自動的に他サイズを派生
