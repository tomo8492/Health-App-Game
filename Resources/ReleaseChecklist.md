# VITA CITY リリースチェックリスト

配信までに完了させる全タスク。左端チェックボックスを順に埋めていけば
App Store 提出まで到達できる構成。

---

## 0. 前提（リポジトリ内で完結）

- [x] Phase A: アセット差し込みパイプライン（`PixelArtRenderer`）
- [x] Phase B: PixelLab.ai 発注台本（`Resources/Prompts/`）
- [x] Phase C: 配信準備ファイル（本ドキュメント含む）
- [ ] Phase D: PixelLab.ai で MVP 18 枚生成（01〜03）
- [ ] Phase E: Xcode で画像投入 → 実機確認
- [ ] Phase F: スクリーンショット撮影・App Store Connect 登録

---

## 1. Apple Developer Program

- [ ] Apple Developer Program に加入済み（年間 USD 99）
- [ ] App ID 作成: `com.vitacity.app`
  - HealthKit Capability: **ON**
  - App Groups: `group.com.vitacity.app`
  - Push Notifications: ON（将来用）
- [ ] Provisioning Profile 作成（Development / Distribution 両方）
- [ ] App Store Connect で App レコード作成
- [ ] Bundle ID を `com.vitacity.app` に設定

## 2. Xcode プロジェクト設定

- [ ] `project.yml` の `sources` に `Resources/Assets.xcassets` が含まれている
- [ ] XcodeGen 実行: `xcodegen generate`
- [ ] Signing & Capabilities:
  - [ ] Team を選択
  - [ ] HealthKit Capability 追加
  - [ ] App Groups に `group.com.vitacity.app` 追加
  - [ ] In-App Purchase Capability 追加
- [ ] Info.plist に `NSHealthShareUsageDescription` 等が含まれている（済）
- [ ] `App/PrivacyInfo.xcprivacy` が Copy Bundle Resources に含まれる
- [ ] `Resources/Assets.xcassets/AppIcon.appiconset` に 1024×1024 画像を配置

## 3. StoreKit2 設定

- [ ] `VitaCity.storekit` の `com.vitacity.premium.lifetime` が存在（済）
- [ ] App Store Connect で同じ Product ID の IAP を作成
  - [ ] タイプ: Non-Consumable
  - [ ] Reference Name: `VITA CITY Premium Lifetime`
  - [ ] Pricing: Tier 6（610 円 / 4.99 USD）
  - [ ] Family Sharing: **Enabled**
  - [ ] ja / en の Display Name と Description を登録（`VitaCity.storekit` 参照）
  - [ ] レビュー用スクリーンショット（プレミアム購入画面）を添付
  - [ ] Cleared for Sale: ON

## 4. HealthKit

- [ ] シミュレータで HealthKit 権限ダイアログが出る
- [ ] 実機（iPhone 実機必須）で `HealthKitService` が歩数を取得できる
- [ ] バックグラウンド配信（HKObserverQuery）が動く
- [ ] 睡眠データが朝の起動時に取得される
- [ ] 権限拒否時のフォールバック UI が表示される

## 5. プライバシー関連

- [ ] プライバシーポリシー Web ページ公開
  - [ ] `https://tomo8492.github.io/Health-App-Game/privacy.html` (ja)
  - [ ] `https://tomo8492.github.io/Health-App-Game/privacy_en.html` (en)
  - [ ] `[YOUR EMAIL]` と `[YOUR COMPANY]` を実名に置換
- [ ] サポートページ公開（プライバシーと同じドメインで OK）
- [ ] App Store Connect → App プライバシー:
  - [ ] データタイプ: Health & Fitness を宣言
  - [ ] データ使用目的: App Functionality
  - [ ] リンク: No（データは端末内のみ）
  - [ ] トラッキング: No

## 6. デザインアセット（Phase B 参照）

### MVP 18 枚（必須）

- [ ] `bld_B025_lv1` 市庁舎 Lv1
- [ ] `bld_B025_lv2` 市庁舎 Lv2
- [ ] `bld_B025_lv3` 市庁舎 Lv3
- [ ] `tile_grass_0` 草タイル（明）
- [ ] `tile_road` 道路タイル
- [ ] `bld_B001_lv1` ジム Lv1
- [ ] `bld_B001_lv2` ジム Lv2
- [ ] `bld_B007_lv1` カフェ Lv1
- [ ] `bld_B007_lv2` カフェ Lv2
- [ ] `bld_B013_lv1` 瞑想センター Lv1
- [ ] `bld_B017_lv1` 睡眠クリニック Lv1
- [ ] `bld_B023_lv1` ウォーター広場 Lv1
- [ ] `tile_grass_1` 草タイル（暗）
- [ ] `tile_sidewalk` 歩道
- [ ] `tile_water` 水
- [ ] `bld_B029_lv1` 居酒屋（ペナルティ）
- [ ] `bld_B030_lv1` 廃墟ビル（ペナルティ）
- [ ] `AppIcon` 1024×1024

### 残りは配信後パッチで OK（Phase B の 04〜05 参照）

## 7. スクリーンショット（実機 or シミュレータで撮影）

必須サイズ（5 枚ずつ）:

- [ ] 6.7" (1290×2796) — iPhone 15/16 Pro Max
- [ ] 6.5" (1242×2688) — iPhone XS Max / 11 Pro Max

推奨サイズ:

- [ ] 5.5" (1242×2208) — iPhone 8 Plus

各デバイスで次のシーンを撮影:

1. [ ] ホーム画面（街全景 + HUD）
2. [ ] 記録ダッシュボード（5 軸リング + 紙吹雪）
3. [ ] 建物詳細（市庁舎 Lv3 + 説明パネル）
4. [ ] 建設ショップ（カタログ画面）
5. [ ] 統計グラフ（週別 CP 推移）

## 8. App Store Connect メタデータ

- [ ] `AppStoreMetadata_ja.md` を貼り付け
- [ ] `AppStoreMetadata_en.md` を貼り付け
- [ ] サポート URL 設定
- [ ] マーケティング URL 設定（任意）
- [ ] プライバシーポリシー URL 設定
- [ ] 年齢制限設定（4+ or 12+ を決断）
- [ ] カテゴリ設定（Primary: Health & Fitness, Secondary: Games > Simulation）
- [ ] 価格設定（無料 + IAP）
- [ ] App Review Information:
  - [ ] 連絡先情報
  - [ ] レビュー用ノート（`AppStoreMetadata_en.md` の末尾参照）
  - [ ] デモアカウント（不要と明記）

## 9. TestFlight 内部テスト

- [ ] Archive ビルド作成（Xcode → Product → Archive）
- [ ] App Store Connect にアップロード
- [ ] TestFlight 内部テスター招待（自分 + 身内）
- [ ] 実機で以下を確認:
  - [ ] 初回起動 → HealthKit 権限ダイアログが日本語で表示
  - [ ] 権限許可後、歩数が取得できる
  - [ ] 記録が保存され街が育つ
  - [ ] プレミアム購入フローが動く（Sandbox 環境）
  - [ ] 購入復元ボタンが動く
  - [ ] ウィジェットが表示される
  - [ ] 通知が届く
  - [ ] アンインストール→再インストールで初期化される

## 10. 審査提出

- [ ] Version 1.0.0 / Build 1 で提出
- [ ] Pre-release 情報すべて埋まっている
- [ ] 「審査に提出」→ 24〜48 時間で結果
- [ ] リジェクトされた場合:
  - HealthKit 説明不足 → `Info.plist` の文言をさらに具体化
  - アルコール関連の懸念 → Review Notes に販売・促進ではない旨を明記
  - プライバシーポリシー不足 → URL が正しくアクセス可能か再確認

## 11. リリース後

- [ ] 初日のインストール数・クラッシュ率を確認
- [ ] AppStoreReviewRequestService でレビュー依頼が動作するか検証
- [ ] 週次で建物画像を追加パッチ（Phase B の 04〜05 を順次消化）

---

## 緊急連絡先・参考リンク

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [HealthKit Guidelines](https://developer.apple.com/documentation/healthkit)
- [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [StoreKit 2](https://developer.apple.com/storekit/)
