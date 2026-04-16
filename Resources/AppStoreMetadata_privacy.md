# プライバシーポリシー文案（ja + en）

GitHub Pages 等で公開してプライバシーポリシー URL として App Store Connect に
登録するための文面。**`[YOUR COMPANY / DEVELOPER NAME]` と `[YOUR EMAIL]` を
自分の情報に置換してから公開すること**。

---

## 日本語版 — `privacy.html` 用

```markdown
# VITA CITY プライバシーポリシー

最終更新日: 2026 年 4 月 16 日

[YOUR COMPANY / DEVELOPER NAME]（以下「当方」）は、iOS アプリ「VITA CITY」
（以下「本アプリ」）におけるユーザーのプライバシーを尊重し、以下の方針で
個人情報・健康情報を取り扱います。

## 1. 収集するデータ

本アプリは以下のデータをユーザーの iPhone 内でのみ取り扱います。

- **HealthKit 経由で取得するデータ**
  - 歩数
  - 消費アクティブエネルギー
  - ワークアウト
  - 睡眠分析
- **ユーザーが本アプリに入力するデータ**
  - 食事・飲酒・生活習慣の記録（自由入力・選択式）
  - 連続記録日数（ストリーク）
  - プレミアム購入状態

## 2. データの保存場所

- **すべてのデータはお使いの iPhone 内にのみ保存されます**
- 当方のサーバーや第三者のクラウドサービスへの送信は **一切行いません**
- Apple の iCloud バックアップを有効にしている場合、iOS のシステム機能により
  端末バックアップの一部として暗号化されて Apple のサーバーに保存される
  ことがあります（Apple のプライバシーポリシーに従います）

## 3. データの利用目的

収集したデータは以下の目的でのみ利用されます。

- 健康ポイント（CP）の計算と街の発展演出
- 連続記録日数の表示
- 統計画面のグラフ表示
- ウィジェットでの今日の CP 表示

## 4. データの第三者提供

当方は本アプリで取り扱うデータを **第三者に提供・販売することは一切ありません**。

## 5. 広告・トラッキング

本アプリは以下を行いません:
- 第三者広告 SDK の組み込み
- ユーザー行動のトラッキング
- IDFA（広告識別子）の取得

## 6. 課金情報

アプリ内課金は Apple の StoreKit 2 を通じて処理され、クレジットカード情報
などの決済情報を当方が取得することは一切ありません。購入情報は Apple ID に
紐づいて Apple のサーバーで管理されます。

## 7. データの削除

iOS の設定アプリから VITA CITY をアンインストールすることで、本アプリが
端末内に保存したすべてのデータは削除されます。HealthKit の元データは Apple
ヘルスケアアプリ側で管理されているため、別途削除が必要です。

## 8. 子どものプライバシー

本アプリはすべての年齢の方にお使いいただけますが、13 歳未満のお子様が利用
する場合は保護者の同意のもとでご利用ください。

## 9. ポリシーの変更

本ポリシーは必要に応じて改定されることがあります。重要な変更がある場合は
アプリ内通知でお知らせします。

## 10. お問い合わせ

本ポリシーに関するお問い合わせは下記までお寄せください。

- メール: [YOUR EMAIL]
- 開発者: [YOUR COMPANY / DEVELOPER NAME]
```

---

## 英語版 — `privacy_en.html` 用

```markdown
# VITA CITY Privacy Policy

Last updated: April 16, 2026

[YOUR COMPANY / DEVELOPER NAME] ("we", "our", "us") respects the privacy of
users of the iOS app "VITA CITY" ("the App") and handles personal and health
information as described below.

## 1. Data We Handle

The App handles the following data locally on the user's iPhone only:

- **Data obtained via HealthKit**
  - Step count
  - Active energy burned
  - Workouts
  - Sleep analysis
- **Data entered by the user**
  - Diet, alcohol, and lifestyle logs (free-form or selectable)
  - Streak count
  - Premium purchase state

## 2. Data Storage

- **All data is stored only on your iPhone.**
- We do **NOT** transmit any data to our servers or any third-party service.
- If you have Apple iCloud Backup enabled, your data may be included in the
  encrypted device backup stored by Apple, subject to Apple's privacy policy.

## 3. How We Use the Data

Data is used exclusively for:

- Calculating City Points (CP) and city growth visuals
- Displaying streak counts
- Rendering statistics charts
- Showing today's CP on widgets

## 4. Third-Party Sharing

We do **NOT** provide or sell the data handled by the App to any third party.

## 5. Advertising & Tracking

The App does **NOT**:
- Integrate any third-party advertising SDKs
- Track user behavior
- Access IDFA (advertising identifier)

## 6. In-App Purchases

In-app purchases are processed through Apple's StoreKit 2. We never receive
your credit card or payment information. Purchase state is managed by Apple
servers linked to your Apple ID.

## 7. Data Deletion

Uninstalling VITA CITY from your device via iOS Settings deletes all data
stored by the App. HealthKit source data is managed by Apple Health and must
be deleted separately there if desired.

## 8. Children's Privacy

The App is available to users of all ages. Users under 13 should use the App
with parental consent.

## 9. Changes to This Policy

We may update this policy as needed. Significant changes will be announced
via in-app notification.

## 10. Contact

For questions about this policy:

- Email: [YOUR EMAIL]
- Developer: [YOUR COMPANY / DEVELOPER NAME]
```

---

## 公開手順（GitHub Pages 最速ルート）

1. GitHub で本リポジトリの Settings → Pages を開く
2. Source を `Deploy from a branch` → `main` → `/docs` に設定
3. リポジトリに `docs/privacy.html` と `docs/privacy_en.html` を追加
4. 上記 Markdown を HTML に変換して貼り付け（または MD のまま公開して Jekyll 処理）
5. URL: `https://tomo8492.github.io/Health-App-Game/privacy.html`
6. App Store Connect のプライバシーポリシー URL 欄にこの URL を入力

**所要時間の目安: 30 分**
