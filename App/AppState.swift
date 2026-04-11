// AppState.swift
// App/
//
// nalexn/clean-architecture-swiftui パターン（⭐6,500）:
//   - アプリ全体の状態を単一の @Observable クラスで管理（Redux 風 Single Source of Truth）
//   - SwiftUI View は AppState を読み取るだけ（書き込みは Repository / UseCase 経由）
//
// isowords パターン（⭐3,000）:
//   - CitySceneCoordinator との協調（SpriteKit ↔ SwiftUI 橋渡し）

import Foundation
import SwiftUI

// MARK: - AppState

/// アプリ全体の状態（Single Source of Truth）
@Observable
final class AppState {

    // MARK: - HealthKit

    var isHealthKitAuthorized: Bool = false
    var todaySteps:            Int  = 0

    // MARK: - 今日の記録

    var todayRecord: DailyRecord?

    var todayTotalCP: Int {
        todayRecord?.totalCP ?? 0
    }

    var todayStreak: Int = 0

    // MARK: - プレミアム

    var isPremium: Bool = false

    /// プレミアム限定チェック（ウィジェット中/大サイズ、全期間統計など）
    var canViewFullStatistics: Bool { isPremium }
    var canUseWidgetMediumLarge: Bool { isPremium }

    // MARK: - エラー

    var error: AppError?

    // MARK: - Init

    init() {}

    // MARK: - 今日の記録をリフレッシュ（起動時・記録保存後に呼ぶ）

    @MainActor
    func refreshTodayRecord(using streakManager: StreakManager) async {
        do {
            let record = try await streakManager.todayRecord()
            let streak = try await streakManager.currentStreak()
            todayRecord  = record
            todayStreak  = streak
        } catch {
            self.error = .dataLoadFailed(error.localizedDescription)
        }
    }
}

// MARK: - AppError

enum AppError: LocalizedError {
    case healthKitDenied
    case dataLoadFailed(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .healthKitDenied:
            return "HealthKit へのアクセスが拒否されました。設定から許可してください。"
        case .dataLoadFailed(let msg):
            return "データの読み込みに失敗しました: \(msg)"
        case .saveFailed(let msg):
            return "保存に失敗しました: \(msg)"
        }
    }
}
