# VITA CITY - CLAUDE.md

> **この文書は設計書（Vol.1・Vol.2）間に矛盾がある場合の最終判断基準です。**
> 実装時は CLAUDE.md の記述を優先してください。

---

## Project Summary

**VITA CITY** — 健康習慣管理 × ドット絵シティビルダーゲームの iOS アプリ

- プラットフォーム：iOS 17.0+ / iPhone 専用 / 縦向き固定
- 開発スタック：Swift 5.9 / SwiftUI / SpriteKit / SwiftData / HealthKit / StoreKit2
- ターゲット層：20〜30代・健康意識高め・ゲーム好き
- 収益モデル：基本無料（バナー広告）+ 買い切りプレミアム課金

---

## Architecture

Clean Architecture + Repository Pattern の 4 層構造：

```
App/                    → エントリポイント・DI設定
Features/               → UI層（View + ViewModel）
  Health/               → 5軸記録画面（Exercise/Diet/Alcohol/Sleep/Lifestyle）
  City/                 → SpriteKit街ビュー・BuildingNode
  Statistics/           → Swift Chartsグラフ
  Store/                → 建設ショップ
Domain/                 → ビジネスロジック
  Models/               → SwiftData @Model エンティティ
  Repositories/         → Repository プロトコル + 実装
  UseCases/             → CPPointCalculator / StreakManager / AchievementEngine
Infrastructure/         → 外部サービス連携
  HealthKit/            → HealthKitService / HKQueryManager
  Notifications/        → NotificationService
  StoreKit/             → PurchaseService（StoreKit2のみ）
Core/                   → 共通ユーティリティ・デザインシステム
```

---

## Key Rules

### 1. CP 計算ロジック

- **CPPointCalculator.swift に全計算ロジックを集約**（テスト必須）
- 純粋関数として実装。副作用禁止
- 1日の最大 CP：**500CP/日**（5軸 × 最大 100CP）

| 軸 | 最大 CP | 主な計算条件 |
|---|---|---|
| 運動 | 100 | 歩数1万歩=60CP、ワークアウト30分=40CP |
| 食事 | 100 | 3食バランス良し=90CP、間食なし+10CP |
| 飲酒 | 100 | 飲まない=100CP、適量=60CP、過飲=-20CP（下限0） |
| 睡眠 | 100 | 7〜9時間=100CP、6時間=60CP、5時間以下=20CP |
| 生活習慣 | 100 | 水8杯=30CP、ストレス管理=40CP、習慣達成=30CP |

### 2. 飲酒軸のゲーム内扱い（設計書間の矛盾を解決）

**確定方針：飲酒軸 CP は中央広場（総合 CP プール）に加算する**

- 飲酒軸には**専用のポジティブゾーンを持たない**
- 飲酒 CP は `totalCP` に加算され、中央広場（市庁舎・時計台・噴水）の発展に寄与する
- スラム地区（B029居酒屋・B030廃墟ビル）はペナルティ表現のみ（過飲時に自動出現）
- **図書館（B019）は生活習慣軸**（Vol.2 の定義を優先）
- 水族館は将来の追加建物として保留（現バージョンには含めない）

### 3. 課金実装（StoreKit2 のみ使用）

**RevenueCat は使用しない。** StoreKit2 のオンデバイス検証のみ。

```swift
// 正しい実装
PurchaseService.swift → StoreKit2 のみ使用
CitySceneCoordinator.unlockPremium() → StoreKit2 のトランザクション検証後に呼び出す
```

- プロダクト ID：`com.vitacity.premium.lifetime`（非消耗型）
- レシート検証：`Transaction.currentEntitlement(for:)` でオンデバイス検証
- ファミリー共有：有効（StoreKit2 デフォルト）

### 4. 建物カタログの正しい種類数

- **建設可能建物：28 種**（B001〜B028）
- **自動生成建物：2 種**（B029 居酒屋・B030 廃墟ビル）
- 合計 30 種の総数は正しいが、プレイヤーが能動的に建設できるのは 28 種
- UI 表示では「建設可能 28 種」と表記すること

### 5. タイルマップ実装（SKTiled 不使用）

**SKTiled ライブラリを使用しない。**

- Tiled Map Editor の JSON 出力を自前でパースする軽量実装を採用
- 理由：サードパーティ依存を排除し、Swift バージョン対応リスクを軽減
- TiledMapParser.swift を Infrastructure/TileMap/ 以下に実装

### 6. マップ拡張コスト（確定値）

| マップサイズ | 必要総合 CP |
|---|---|
| 20×20（初期） | - |
| 30×30 | 5,000 CP |
| 40×40 | 15,000 CP |
| 50×50（最大） | 30,000 CP |

### 7. HealthKit データ取得タイミング

| データ種別 | 取得タイミング |
|---|---|
| 歩数・消費カロリー | バックグラウンド（HKObserverQuery）+ 起動時 |
| ワークアウト | 起動時 |
| 睡眠分析 | **朝の起動時のみ**（前夜分を取得）|
| 心拍数・体重 | 統計画面表示時 |

- バックグラウンド配信は**歩数・カロリーのみ**に限定（バッテリー節約）
- 睡眠データのバックグラウンド取得は行わない

### 8. データ保持ロジック（SwiftData）

`DailyRecord` モデルに `isArchived: Bool = false` フィールドを追加：

```swift
@Model class DailyRecord {
    var date: Date
    var totalCP: Int
    // ...その他フィールド
    var isArchived: Bool = false  // 無料版で90日超のデータをアーカイブ
}
```

- **無料版**：90日（3ヶ月）超の DailyRecord を `isArchived = true` に設定（削除はしない）
- **プレミアム版**：全データを `isArchived = false` のまま保持・参照可能
- アーカイブ処理は `StreakManager.archiveOldRecords()` で実行

### 9. SwiftUI ↔ SpriteKit 通信

```
SwiftUIの記録画面 → CitySceneCoordinator.addCP(axis:amount:) → CityScene
建物タップ → CitySceneCoordinator.selectedBuilding → SwiftUI詳細シート
```

- **CitySceneCoordinator（@Observable）経由のみ**で通信
- SpriteKit シーンへの直接アクセス禁止
- SwiftData エンティティへのアクセスは Repository プロトコル経由のみ（直接 @Query 禁止）

### 10. NPC 経路探索

- 建物タイルは通行不可フラグを持つ（`isWalkable: Bool`）
- **A\* ベースの簡易経路探索**を Swift で自前実装（既製ライブラリ不使用）
- NPC は建物タイルを通過しない
- NPCPathfinder.swift を Features/City/ 以下に実装

### 11. CloudKit 将来対応準備

現バージョンでは CloudKit 同期を実装しないが、将来の切り替えを容易にするため明示的に無効化：

```swift
let container = ModelContainer(
    for: schema,
    configurations: ModelConfiguration(cloudKitDatabase: .none)
)
```

### 12. 食事写真（Vision フレームワーク）

- **Phase 5 以降で実装**（StoreKit2 課金実装後）
- Phase 0〜4 では食事写真機能を一切実装しない
- UI には「将来実装予定」のプレースホルダーを置かない（機能追加時に実装）

---

## Testing

### 必須テスト対象

- `CPPointCalculator` → **Swift Testing でユニットテスト必須**（全計算パターンを網羅）
- `Repository` 実装 → モックを差し替えてテスト（DI コンテナ活用）
- `StreakManager` → 連続記録・アーカイブ処理のテスト

### テスト実行

```bash
xcodebuild test -scheme VitaCity -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Development Phases（ロードマップ）

| フェーズ | 期間目安 | 実装スコープ |
|---|---|---|
| **Phase 0** | 〜2週間 | プロジェクト初期設定・SwiftDataモデル・HealthKit認可フロー・CPPointCalculator |
| **Phase 1** | 2〜4週間 | 5軸記録画面（SCR-011〜015）・記録ダッシュボード（SCR-002）|
| **Phase 2** | 4〜8週間 | SpriteKit街ビュー基盤・ホーム画面（SCR-001）・CP→建物変換 |
| **Phase 3** | 8〜12週間 | 統計・レポート（SCR-003）・Swift Charts |
| **Phase 4** | 12〜16週間 | 実績・バッジ・通知・WidgetKit（小サイズ無料/中大サイズプレミアム）|
| **Phase 5** | 16〜20週間 | StoreKit2課金・プレミアム機能・食事写真（Vision）・Fastlane CI/CD |
| **Phase 6** | 20〜24週間 | App Store 審査・英語ローカライズ・パフォーマンス最適化・正式リリース |

---

## 設計書参照先

- 健康管理システム詳細 → `VITA CITY 健康管理設計書.docx`（Vol.1）
- ゲームエンジン詳細 → `VITA CITY ゲーム設計書.docx`（Vol.2）
- **矛盾がある場合は本 CLAUDE.md を最優先とする**
