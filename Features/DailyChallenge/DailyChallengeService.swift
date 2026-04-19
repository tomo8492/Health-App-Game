// DailyChallengeService.swift
// Features/DailyChallenge/
//
// 日替わりチャレンジ: 毎日 1 つのフォーカス軸を選び、その軸で 80CP 以上を達成すると
// ボーナス CP（+25）が付与される。
// - 軸の選択は曜日ベースで決定論的（ランダムだと再起動で変わってしまうため）
// - 達成判定は todayRecord の CP を監視

import Foundation
import Observation

// MARK: - DailyChallenge

struct DailyChallenge: Equatable {
    let axis:        CPAxis
    let targetCP:    Int      // この軸で必要な CP
    let bonusCP:     Int      // 達成時のボーナス CP
    let date:        Date
}

// MARK: - DailyChallengeService

@Observable
@MainActor
final class DailyChallengeService {

    // MARK: - State

    var todayChallenge: DailyChallenge
    var isCompleted: Bool = false

    // 達成通知（UI 表示用）
    var pendingCompletion: DailyChallenge? = nil

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.todayChallenge = Self.challengeFor(date: Date())
        self.isCompleted = Self.isCompletedToday(defaults: defaults)
    }

    // MARK: - チャレンジ生成（純粋関数・曜日ベース）

    static func challengeFor(date: Date) -> DailyChallenge {
        let weekday = Calendar.current.component(.weekday, from: date)
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1

        // 曜日 + 年通算日で軸を回転させる（同じ曜日でも毎週異なる軸が選ばれる）
        let axisIndex = (weekday + dayOfYear) % CPAxis.allCases.count
        let axis = CPAxis.allCases[axisIndex]

        return DailyChallenge(
            axis:     axis,
            targetCP: 80,
            bonusCP:  25,
            date:     Calendar.current.startOfDay(for: date)
        )
    }

    // MARK: - 達成チェック（記録更新時に呼ぶ）

    /// 今日のチャレンジが達成されたかチェックし、達成時は pendingCompletion を設定する
    /// - Returns: 達成時のボーナス CP（既に達成済み or 未達成なら 0）
    @discardableResult
    func checkCompletion(todayRecord: DailyRecord?) -> Int {
        guard !isCompleted, let record = todayRecord else { return 0 }

        let axisCP: Int
        switch todayChallenge.axis {
        case .exercise:  axisCP = record.exerciseCP
        case .diet:      axisCP = record.dietCP
        case .alcohol:   axisCP = record.alcoholCP
        case .sleep:     axisCP = record.sleepCP
        case .lifestyle: axisCP = record.lifestyleCP
        }

        if axisCP >= todayChallenge.targetCP {
            isCompleted = true
            markCompletedToday()
            pendingCompletion = todayChallenge
            return todayChallenge.bonusCP
        }
        return 0
    }

    // MARK: - 永続化

    private static let completedDateKey = "vitacity.dailyChallenge.completedDate"

    private func markCompletedToday() {
        defaults.set(Calendar.current.startOfDay(for: Date()),
                     forKey: Self.completedDateKey)
    }

    private static func isCompletedToday(defaults: UserDefaults) -> Bool {
        guard let d = defaults.object(forKey: completedDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(d)
    }
}
