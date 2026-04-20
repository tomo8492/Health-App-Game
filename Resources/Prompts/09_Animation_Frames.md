# 09 — アニメーションフレーム発注（PixelLab.ai）

**優先度**: 中（街に動きを与える）

`CityScene.update(_:)` および各ノードの `SKAction.animate(with:)` で使用する
**フレームアニメ用の複数枚スプライト**をまとめて発注する。コード側は
フォールバックを実装済みのため、フレームが一部欠けても動作はするが、
全フレーム揃えると参考画像レベルの躍動感が出る。

共通スタイルは `00_StyleGuide.md` を参照。

---

## 1. 発注対象一覧

| 種別 | ファイル | キャンバス | フレーム数 | 時間／フレーム | 備考 |
|------|----------|------------|------------|----------------|------|
| NPC 歩行（各 type） | `npc_{type}_f0〜f7.png` | 48 × 84 px | 8 | 0.12s | 既存 0-3 のみ → 4-7 追加 |
| ジム屋上の旗（B001） | `bld_B001_lv{1-5}_f0〜f3.png` | 64 × (建物高) | 4 | 0.35s | 旗のはためき |
| 市庁舎旗（B025） | `bld_B025_lv{1-5}_f0〜f3.png` | 64 × (建物高) | 4 | 0.35s | 既存（再確認のみ） |
| 水タイル | `tile_water_f0〜f2.png` | 64 × 32 px | 3 | 0.6s | 波のテクスチャシフト |
| 風車（B 付近） | `deco_windmill_f0〜f3.png` | 36 × 64 px | 4 | 0.2s | 羽根回転（`08` 参照） |
| 牛（アイドル） | `deco_cow_f0, f1.png` | 32 × 24 px | 2 | 2.0s | idle / chew（`08` 参照） |
| 煙パフ（任意） | `fx_smoke_puff.png` | 8 × 8 px | 1 | — | 単体テクスチャ、コードでフェード |

> ※ NPC type は `adventurer / citizen / child / elder / jogger / chef / business / tourist` など
> （`NPCType.allCases` の rawValue に準拠）

---

## 2. NPC 歩行 8 フレーム仕様

### フレーム割当

| f# | 足運び | 腕振り | 上下オフセット |
|----|--------|--------|----------------|
| 0 | 右足前・左足後（着地） | 左腕前・右腕後 | 0 |
| 1 | 右足前進中・左足支持 | 腕中間 | -1 px（沈む）|
| 2 | 両足交差（浮遊） | 腕左右対称 | +1 px（浮く）|
| 3 | 左足前進中・右足支持 | 腕逆方向に遷移 | -1 px |
| 4 | 左足前・右足後（着地） | 右腕前・左腕後 | 0 |
| 5 | 左足前進中・右足支持 | 腕中間 | -1 px |
| 6 | 両足交差（浮遊） | 腕左右対称 | +1 px |
| 7 | 右足前進中・左足支持 | 腕逆方向に遷移 | -1 px |

**ポイント**：
- 0-3 が「右→左ステップ」、4-7 が「左→右ステップ」で計 1 歩幅
- 既存 4 フレーム資産がある場合、f4-f7 を新規に発注
- コード側は Asset 不在時 `f % 4` にフォールバックするので、4-7 のみ発注してもクラッシュしない

### 発注プロンプト雛形（adventurer の f5 例）

```
STYLE_PREFIX
Isometric pixel art chibi adventurer NPC character,
3/4 side walking pose frame 5 of 8 (left leg forward mid-stride,
right leg support, arms swinging mid-position), small backpack,
leather boots, green tunic, brown pants, simple sword at hip,
bouncing 1 pixel down from baseline, facing slight right,
small mobile game character sprite, bottom center anchored
STYLE_SUFFIX
NEGATIVE_PROMPT
```

---

## 3. ジム屋上旗アニメ（B001）4 フレーム

現状 B025（市庁舎）のみ旗アニメが稼働。B001 も同仕組みに対応済み。
Lv1-5 すべてのレベルで `bld_B001_lv{N}_f0〜f3.png` を発注する。

| f# | 旗の形状 |
|----|----------|
| 0 | ほぼ水平、右になびく |
| 1 | 中央が少し膨らむ（風受け） |
| 2 | 逆方向に少し揺れる（戻り） |
| 3 | 再び右方向に戻り始める |

### 発注プロンプト雛形（B001 Lv3 f1）

```
STYLE_PREFIX
Isometric pixel art fitness gym building, 3 floors, green accent (#34C759),
rooftop flag pole with yellow flag BULGING in the middle (frame 1 of 4 in flag
flutter animation), muscle icon signage, wooden doorway, clean gym aesthetic,
bottom 16px merges into ground tile
STYLE_SUFFIX
NEGATIVE_PROMPT
```

---

## 4. 水タイル 3 フレーム仕様

`Core/PixelArtRenderer.swift` の `waterTile(frame:)` が Asset 優先で
`tile_water_f0〜f2` を参照する。アセット不在時はプロシージャル生成。

| f# | 波の状態 |
|----|----------|
| 0 | 波頂が画面左寄り、白きらめき左上 |
| 1 | 波頂が中央、きらめき中央 |
| 2 | 波頂が右寄り、きらめき右下 |

- タイルサイズ：**64 × 32 px（isometric ひし形の外接矩形）**
- 色：主色 `#3B8FD4`（深青）/ 波頂 `#7FC3EC` / ハイライト `#FFFFFF` 2-3 ドット
- 背景は透明だが、ひし形の外側は完全透明（ドット絵タイルの定石）

### 発注プロンプト雛形（f1 例）

```
STYLE_PREFIX
Isometric pixel art water tile, 2:1 diamond shape (64x32 bounding rect),
shallow ocean water with sine wave pattern at CENTER (frame 1 of 3),
deep blue base color #3B8FD4, wave crest highlight #7FC3EC,
2-3 bright white sparkle pixels near center, transparent outside the diamond,
seamless tileable, Kairosoft-style water
STYLE_SUFFIX
NEGATIVE_PROMPT
```

---

## 5. 煙スプライト（`fx_smoke_puff`）

`SpriteEffects.attachSmoke(to:offset:tint:)` が参照。
**1 枚の単体テクスチャ**で、コード側で以下の動きを付ける：

- 初期 scale 0.4 → 最終 scale 1.6（2.4 秒で拡大）
- alpha 0.7 → 0（フェードアウト）
- Y 方向に +24 px 上昇
- tint は建物により変更（B029 居酒屋はオレンジ系）

| パラメータ | 値 |
|------------|----|
| キャンバス | 8 × 8 px |
| 主色 | `#BDBDBD`（灰）|
| 形状 | 丸い雲状パフ、1-2 ドットのハイライト `#FFFFFF` |
| 背景 | 透明 |

### 発注プロンプト

```
STYLE_PREFIX
Small pixel art puff of smoke, 8x8 canvas, round cloud shape,
gray color #BDBDBD with 1-2 white highlight pixels at top-left,
semi-transparent cloud edges (but still hard-edge pixels, no alpha gradient),
single frame particle asset
STYLE_SUFFIX
NEGATIVE_PROMPT
```

> ※ 複数フレーム版（`fx_smoke_f0〜f3`）を将来検討する場合は、
> 拡散→消滅の 4 フレームで発注すれば `SpriteEffects` 側を
> `SKAction.animate(with:)` に切り替え可能。

---

## 6. 命名・投入フロー

1. PixelLab で生成 → `generated_assets/final/` に保存
2. `Resources/Assets.xcassets/PixelArt/{カテゴリ}/{ファイル名}.imageset/` を
   `_Template.imageset` 複製で作成
3. `Contents.json` の `filename` を書き換え
4. シミュレータ起動時のログを確認：
   - `[PixelArt] ✅ Asset loaded: tile_water_f1`
   - `[PixelArt] ✅ Asset loaded: npc_adventurer_f5`
5. 街を歩き回り、実際のアニメーションが滑らかに見えるか目視

---

## 7. 品質チェック

- [ ] NPC 8 フレームで腕・脚の左右対称性が破綻していないか
- [ ] 旗アニメは 4 フレームでループ違和感なし（最終フレーム → 0 に戻る）
- [ ] 水タイルは隣接タイル間で継ぎ目が見えないか（シームレス）
- [ ] 煙パフは建物のチムニーオフセット位置で違和感なく上昇するか
- [ ] 全アニメーションが 60fps で滑らかに描画される（Instruments で検証）
- [ ] `CityScene.update(_:)` のループで 1 フレームあたり 1ms 以内に収まるか
