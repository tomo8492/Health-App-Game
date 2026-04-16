# リリースノート — VITA CITY 1.0.0

初回リリース向け「What's New in this Version」テキスト。
App Store Connect → App Store → Version or Platform → What's New in This
Version に貼り付ける（**4,000 文字以内**）。

---

## 日本語版（App Store Connect `What's New in This Version` 貼り付け用）

```
🌟 VITA CITY 初リリース！

「健康で街が育つ」全く新しいライフログ×シティビルダーゲームです。

▼ 5 つの軸で健康を楽しく記録
運動・食事・飲酒・睡眠・生活習慣を 1 日最大 500 CP で記録。
歩数や睡眠は Apple ヘルスケアから自動取得、タップだけで完了。

▼ 記録するほど街が育つ
28 種類の建物を好きな順に建設。トレーニングジム、オーガニックカフェ、
天文台、公園…あなたの健康習慣がそのままドット絵の街に反映されます。
マップは最大 50×50 まで段階的に拡張。

▼ 天気・時間帯・ペナルティで毎日が違う
CP 500 の日は晴れ、100 未満なら嵐。朝・昼・夕・夜で街の表情が変わり、
飲みすぎた日は居酒屋や廃墟ビルがそっと警告。
でもペナルティは翌日の健康的な記録で自然に消えます。

▼ プライバシー第一
すべてのデータは iPhone 内にのみ保存。外部送信・トラッキング一切なし。
アカウント登録不要、すぐに始められます。

▼ プレミアム（買い切り・¥610）
• マップ無制限拡張
• 全期間の統計グラフ（無料版は 90 日）
• ウィジェット全サイズ対応（無料版は小サイズのみ）
• 詳細な健康レポート
• プレミアム限定テーマ

1 度買えば永久。ファミリー共有対応。

毎日の小さな一歩が、あなただけの街になります。
```

文字数: 約 450 / 4,000

---

## 英語版（`What's New in This Version` — US store）

```
🌟 Welcome to VITA CITY — 1.0.0

A brand-new life-log × city-builder that turns your daily healthy
habits into a thriving pixel-art town.

▼ Log Your Health Across 5 Axes
Track Exercise, Diet, Alcohol, Sleep, and Lifestyle for up to 500 CP
per day. Steps and sleep are pulled automatically from Apple Health,
so most of your logging is a single tap.

▼ Your Habits Become a City
Build any of 28 unique buildings — gyms, organic cafes, observatories,
parks, and more. Each one reflects a real habit. The map expands up
to 50×50 as you level up.

▼ Weather, Time of Day, and Gentle Penalties
Hit 500 CP and the sun shines. Fall below 100 and storms roll in.
Morning, noon, dusk, and night bring a different look to your town.
Over-drink and an izakaya or ruined building appears as a visual
warning — but it fades as soon as you resume healthy logs.

▼ Privacy First
All data stays on your iPhone. No tracking. No accounts. Just open
the app and start building.

▼ Premium (one-time, $4.99)
• Unlimited map expansion
• Full statistics history (free tier: 90 days)
• All widget sizes (free tier: small only)
• Detailed health reports
• Exclusive pixel-art themes

One payment, lifetime access. Family Sharing enabled.

Every small step becomes a city block. Start yours today.
```

文字数: 約 1,100 / 4,000

---

## GitHub Release 用（バージョンタグに添付）

```markdown
# VITA CITY 1.0.0

Initial release.

## Highlights

### Core Gameplay
- 5-axis health logging with 500 CP/day cap (Exercise, Diet, Alcohol,
  Sleep, Lifestyle)
- Automatic HealthKit integration for steps, active energy, workouts,
  and sleep analysis
- 28 unique buildings unlockable via cumulative CP
- 2 penalty buildings (izakaya / ruined office) as over-drinking warnings
- Map expansion: 20×20 → 30×30 → 40×40 → 50×50
- City level system Lv1–10 with golden celebration flash
- Streak system with morning weather baseline

### Visual Polish
- Procedural pixel art renderer for all sprites (asset-override ready)
- Persistent day/night sky gradient
- Weather system: sunny / cloudy / partly-cloudy / rainy / stormy
- Cloud layer animation for overcast / storm
- Window light flicker during night hours
- Building level-up with 4-step elastic scale + gold sparkle burst
- CP-gain ring pulse + sparkle + floating `+N CP` text
- Construction landing: dust ring + axis-color ring + pop-in + sparkles
- Penalty warning: red flash + warning haptic
- Map expansion celebration: gold sparkle burst + success haptic
- Lightning double-flash when weather becomes stormy

### UX / Haptics
- Unified HapticEngine (tap / success / warning / error / levelUpBurst /
  constructionLanding)
- Home HUD: CP badge pulse + numericText transition
- Weather icon symbol bounce on change
- Minimap (bottom-right) with axis-colored building dots + city level badge
- Record dashboard: 3 concentric pulse rings on CP gain
- Confetti view on all-axis completion
- Quick record button: pressed-state ring + shadow

### Infrastructure
- SwiftUI + SpriteKit hybrid (CitySceneCoordinator @Observable bridge)
- SwiftData @Model for persistence (DailyRecord)
- Repository pattern for domain isolation
- CPPointCalculator as pure function (Swift Testing)
- StoreKit 2 in-app purchase (`com.vitacity.premium.lifetime`, ¥610)
- WidgetKit: small (free), medium/large (premium)
- HealthKit background delivery (steps + active energy only, per CLAUDE.md
  Key Rule 7)
- Privacy Manifest (`PrivacyInfo.xcprivacy`) for App Store compliance
- XcodeGen-based project generation with explicit .xcprivacy resource mapping

### Architecture
- Clean Architecture + Repository Pattern (App / Features / Domain /
  Infrastructure / Core)
- VitaCityCore Swift Package with StrictConcurrency enabled
- NSCache-backed texture caching for all pixel art sprites

## Known Limitations

- **Pixel art assets are programmatic in 1.0.0.** The asset-override
  pipeline (`PixelArtRenderer.assetTexture(_:)`) is ready; custom PixelLab.ai
  artwork will be added progressively via patch releases.
- Food photo recognition (Vision framework) is Phase 5+ and not included.
- CloudKit sync is explicitly disabled (Key Rule 11).

## Upgrade Path

This is the initial public release. No upgrade path applies.

## Contributors

- Designed and developed by [YOUR COMPANY / DEVELOPER NAME]
- Pixel art (incremental via PixelLab.ai) by [YOUR NAME]
- Additional thanks to the Claude Code assistant

## Links

- [Privacy Policy](https://tomo8492.github.io/Health-App-Game/privacy.html)
- [Support](https://tomo8492.github.io/Health-App-Game/support.html)
- [App Store](https://apps.apple.com/app/idXXXXXXXXX)
```

---

## 配信時 TODO チェック

- [ ] 日本語版を App Store Connect の「このバージョンの新機能」に貼り付け
- [ ] 英語版を同じ欄の US ロケールに貼り付け
- [ ] GitHub Releases にバージョンタグ `v1.0.0` で公開
- [ ] `[YOUR COMPANY / DEVELOPER NAME]` / `[YOUR NAME]` / `idXXXXXXXXX` を実値に置換
- [ ] SNS 告知用の短縮版（140 文字）も用意しておくと便利

### SNS 告知テンプレ（日本語・140 文字）

```
🌟 iOS アプリ『VITA CITY』リリース！

毎日の健康習慣が、あなただけのドット絵の街を育てます。
歩数・食事・睡眠を記録するだけで街がレベルアップ 🏙️
5 軸記録 × シティビルダー × ドット絵、新感覚のライフログゲーム。

App Store → [URL]
#VitaCity #ヘルスケア #ドット絵
```

### SNS 告知テンプレ（英語・280 文字）

```
🌟 VITA CITY is out on iOS!

A cozy life-log × pixel-art city-builder that turns your daily healthy
habits into a growing town. Log steps, meals, sleep — your town levels
up 🏙️

Privacy-first. No tracking. Free to download, optional one-time premium.

App Store → [URL]
#VitaCity #iOSDev #PixelArt
```
