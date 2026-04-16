# StoreKit2 レビュー用スクリーンショット取得ガイド

App Store Connect の IAP 登録時に**レビュアー向けスクリーンショット**が必須。
StoreKit2 Sandbox と iOS シミュレータを組み合わせて取得する手順。

---

## 必要なスクリーンショット

IAP `com.vitacity.premium.lifetime` の審査に添付するのは **1 枚**:

1. **プレミアム購入画面**（課金ボタン + 価格 + 機能一覧が見える画面）

ただし審査官がプレミアムの価値を判断できる補足として、以下もあると安心:

2. プレミアム購入後にロック解除される機能を示す画面（例: 全サイズウィジェット）
3. 「購入を復元」ボタンが見える画面

---

## 取得方法 A: iOS シミュレータ + `.storekit` ファイル（最速）

本リポジトリには `VitaCity.storekit` が既に用意されているため、
シミュレータでそのまま購入フローが動く。

### 1. Xcode で StoreKit Configuration を有効化

`project.yml` の schemes → run → storeKitConfiguration に設定済み:
```yaml
run:
  config: Debug
  storeKitConfiguration: VitaCity.storekit   # Sandbox 購入テスト
```

### 2. シミュレータ起動 + 購入画面遷移
- シミュレータで iPhone 16 Pro を選ぶ（6.7" スクショサイズ）
- アプリ起動 → 設定タブ → 「プレミアム購入」→ 購入画面

### 3. スクリーンショット撮影
- **Command + S** でシミュレータスクショを撮影（デスクトップに保存）
- または File → Save Screen

### 4. 購入を実行してロック解除画面も撮る
- 「プレミアムを購入」ボタンをタップ
- Apple ID ダイアログ → 「購入」
- StoreKit Configuration が Sandbox として動作するのでお金はかからない
- 購入完了後のロック解除画面も同様に撮影

### 5. 購入状態をリセットしたい場合
- Xcode → Debug → StoreKit → Manage Transactions → 該当取引を削除
- または `.storekit` エディタで「Delete All Transactions」

---

## 取得方法 B: 実機 + Sandbox アカウント（本番に近い）

実機での挙動確認を兼ねて行う場合の手順。

### 1. Sandbox テスター作成
- App Store Connect → ユーザーとアクセス → Sandbox テスター
- 新規テスターを作成（Apple ID に使っていないメールアドレス）

### 2. 実機で Sandbox サインイン
- iPhone → 設定 → Developer → Sandbox Apple Account
- 作成した Sandbox ユーザーでサインイン

### 3. TestFlight または Development ビルドで購入
- 購入フローを一度経験 → 無料で Sandbox 購入される
- レシートは `Transaction.currentEntitlement(for:)` で検証される

### 4. スクショ取得
- **電源ボタン + 音量上** で iPhone スクショ
- 写真アプリからエクスポート → Mac に転送

---

## App Store Connect への添付手順

1. App Store Connect → 自分のアプリ → 機能 → App 内課金
2. `com.vitacity.premium.lifetime` を選択
3. 「App レビュー情報」セクション → 「スクリーンショット」欄
4. 撮影した 6.7" の PNG をアップロード
5. **最低 1 枚、推奨 3 枚**
6. 「レビューメモ」に次を記載:

```
Premium Purchase Flow:
1. Tap "設定" tab
2. Tap "プレミアムを購入"
3. The premium purchase screen shows price (¥610), feature list,
   and a "Purchase" button
4. Tap "Purchase" to initiate StoreKit2 flow
5. Use Sandbox account to complete purchase (Test account info provided
   in main App Review Notes)

Features unlocked after purchase:
- Unlimited map expansion (beyond 50x50)
- Full statistics history (free tier limited to 90 days)
- All widget sizes (free tier: small only)
- Detailed health reports
- Exclusive pixel-art themes

The "Restore Purchases" button is available at the bottom of the Premium
screen and recovers the purchase via Transaction.currentEntitlement(for:).
```

---

## 推奨スクリーンショット構成

実際のスクショは次の 3 枚を用意しておくと理想的:

### スクショ① — 購入訴求画面
見えていると良い要素:
- アプリのロゴ/タイトル
- 「VITA CITY プレミアム」タイトル
- **価格: ¥610**（`.storekit` と一致）
- **「買い切り」**の表記
- 機能一覧（5 項目以上）
- 「購入する」大きなボタン
- 「購入を復元」小さなリンク
- 「ファミリー共有対応」の小さな表記

### スクショ② — 購入完了 & 機能解放
- 購入成功後の「ありがとうございます」画面
- プレミアム限定機能がアクセス可能になったことが分かる UI

### スクショ③ — 具体機能デモ
- 中サイズウィジェット
- 大サイズウィジェット
- 統計画面の全期間スクロール

---

## 1024×1024 以上の縦長スクリーンショットも必要？

通常の App Store Connect は 6.7" (1290×2796) 等の標準サイズを要求するが、
**IAP のレビュースクリーンショットは縦長のアプリスクショそのままで OK**。
別途 1024×1024 は不要（こちらは App Icon のみ）。

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| シミュレータで `.storekit` が無視される | Scheme → Run → Options → StoreKit Configuration を再選択 |
| 購入成功後にプレミアム解除されない | `PurchaseService` の `Transaction.updates` リスナーが動いているか確認 |
| 「購入を復元」が動かない | `Transaction.currentEntitlement(for:)` の呼び出しを確認 |
| Sandbox 購入で Apple ID 認証が何度も出る | 設定 → Developer → Sandbox Apple Account で再サインイン |
| スクショの日本語が文字化け | シミュレータ設定 → Language を日本語に変更して再起動 |
