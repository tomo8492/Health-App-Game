# VITA CITY — リリースまでの残タスク

> 最終更新: 2026-04-12  
> 開発ブランチ: `claude/review-github-plans-V8OzK`

---

## 優先度: 高（リリースブロッカー）

### 1. Google Mobile Ads SDK のインストール

Xcode でのみ実施可能。コードは実装済み。

```
Xcode → File → Add Package Dependencies
URL: https://github.com/googleads/swift-package-manager-google-mobile-ads
バージョン: 11.x 以上
```

完了後、`AdUnitID.swift` と `Info.plist` の以下をプロダクション ID に差し替える：

| 箇所 | 現在値（テスト） | 差し替え先 |
|---|---|---|
| `Infrastructure/Ads/AdService.swift` — `AdUnitID.banner` | `ca-app-pub-3940256099942544/2934735716` | AdMob コンソールで取得した実 ID |
| `Infrastructure/Ads/AdService.swift` — `AdUnitID.reward` | `ca-app-pub-3940256099942544/1712485313` | 同上 |
| `App/Info.plist` — `GADApplicationIdentifier` | `ca-app-pub-3940256099942544~1458002511` | AdMob アプリ ID（`~` 区切りの形式）|

---

### 2. App Store Connect 設定

- [ ] **App ID 作成**: `com.vitacity.app`（Developer Portal）
- [ ] **AdMob アカウント作成** → アプリを登録 → App ID / 広告ユニット ID 取得
- [ ] **In-App Purchase 設定**
  - プロダクト ID: `com.vitacity.premium.lifetime`
  - 種別: 非消耗型
  - 価格: ¥980（Tier 7 相当）
  - 表示名・説明文を日英両方で記入
- [ ] **TestFlight 内部テスター登録** → beta レーンで配信確認

---

### 3. プライバシーマニフェスト（必須）

iOS 17.4+ / 2024 年以降の審査で必須。AdMob SDK が収集するデータを申告する。

```
Xcode → New File → App Privacy (PrivacyInfo.xcprivacy)
```

記載が必要な項目:
- `NSPrivacyCollectedDataTypes`: `NSPrivacyCollectedDataTypeAdvertisingData`（AdMob）
- `NSPrivacyAccessedAPITypes`: 使用する API（UserDefaults など）
- `NSPrivacyTracking`: `false`（ATT 未使用の場合）

---

### 4. プライバシーポリシー URL

HealthKit + 広告を使うアプリは**必須**。

- [ ] プライバシーポリシーページを作成（GitHub Pages / Notion など）
- [ ] `Info.plist` に `NSPrivacyPolicyURL` を追加
- [ ] App Store Connect の「App プライバシー」栄養ラベルを記入

---

## 優先度: 中（QA・品質）

### 5. 実機 QA テスト

| テスト項目 | 確認内容 |
|---|---|
| 5 軸記録画面 | 全軸で記録保存 → HomeView の CP が更新される |
| 街ビュー | タブ切り替え後もクラッシュしない（`isSetupComplete` 修正確認）|
| バナー広告 | HomeView 最下部に表示される（テスト ID で確認）|
| リワード広告 | 街管理 → 広告視聴 → +50 CP アラートが出る |
| プレミアム購入 | Sandbox で購入 → 広告が非表示になる |
| 通知 | 初回起動時に通知許可ダイアログが出る・夜 20 時に届く |
| ウィジェット | ホーム画面に追加 → 今日の CP が反映される |
| ストリーク | 連日記録でストリーク数が増える |
| アーカイブ | 無料版: 90 日超の記録が閲覧不可になる |

### 6. パフォーマンス計測（Instruments）

- [ ] 街ビューで 60fps が維持されているか確認
- [ ] NPC 20 体スポーン時のメモリ使用量（目標: 200MB 以下）
- [ ] BuildingTextureGenerator のキャッシュ量
- [ ] バッテリー消費（HealthKit バックグラウンド）

---

## 優先度: 低（App Store 申請準備）

### 7. App Store スクリーンショット

最低限必要なサイズ: **iPhone 6.7"**（iPhone 15 Pro Max 相当）

撮影が必要な画面（5 枚以上推奨）:
1. ホーム画面（街ビュー）— 天気が快晴の状態
2. 記録ダッシュボード（5 軸リング）
3. 食事 or 運動の記録画面
4. 統計画面（Swift Charts グラフ）
5. プレミアムストア画面

### 8. App Store メタデータ

| 項目 | 状態 |
|---|---|
| アプリ名（日本語）| `VITA CITY` |
| アプリ名（英語）| `VITA CITY` |
| サブタイトル | 未作成 |
| 説明文（日本語 4,000 字以内） | 未作成 |
| 説明文（英語） | 未作成（`en.lproj` は実装済み）|
| キーワード（100 字以内） | 未作成 |
| サポート URL | 未設定 |
| App アイコン 1024×1024 PNG | `Core/DesignSystem/AppIconView.swift` を Xcode Preview で書き出し |

---

## 将来実装（Phase 6 以降）

- [ ] **食事写真（Vision フレームワーク）** — CLAUDE.md Key Rule 12 により延期済み
- [ ] **CloudKit 同期** — `cloudKitDatabase: .none` で準備済み・有効化のみ
- [ ] **Apple Watch 対応** — 歩数・心拍をウォッチから記録
- [ ] **iPad 最適化** — 現在は縦向き iPhone 専用

---

## チェックリスト: リリース直前

```
□ AdMob 本番 ID に差し替え済み
□ #if DEBUG ブロックがすべて正しく機能している
□ PrivacyInfo.xcprivacy 作成済み
□ プライバシーポリシー URL 設定済み
□ TestFlight で内部テスト完了
□ App Store Connect に全メタデータ入力済み
□ スクリーンショット 5 枚以上アップロード済み
□ アプリ内課金の審査提出設定済み
□ 年齢区分: 4+ で問題ないか確認
□ 輸出コンプライアンス: ITSAppUsesNonExemptEncryption = false（設定済み）
```
