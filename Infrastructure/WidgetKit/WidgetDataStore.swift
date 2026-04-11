// WidgetDataStore.swift
// Infrastructure/WidgetKit/
//
// App Group 経由でウィジェットにデータを渡す
// CLAUDE.md Phase 4: 小サイズ（無料）/ 中・大サイズ（プレミアム）

import Foundation
import WidgetKit

enum WidgetDataStore {

    private static let suiteName = "group.com.vitacity.app"

    /// 今日の記録をウィジェット用 UserDefaults に書き込む
    static func save(
        totalCP:     Int,
        exerciseCP:  Int,
        dietCP:      Int,
        alcoholCP:   Int,
        sleepCP:     Int,
        lifestyleCP: Int,
        streak:      Int,
        isPremium:   Bool
    ) {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.set(totalCP,     forKey: "todayTotalCP")
        defaults.set(exerciseCP,  forKey: "todayExerciseCP")
        defaults.set(dietCP,      forKey: "todayDietCP")
        defaults.set(alcoholCP,   forKey: "todayAlcoholCP")
        defaults.set(sleepCP,     forKey: "todaySleepCP")
        defaults.set(lifestyleCP, forKey: "todayLifestyleCP")
        defaults.set(streak,      forKey: "currentStreak")
        defaults.set(isPremium,   forKey: "isPremium")
        // ウィジェットのタイムラインをリロード
        WidgetCenter.shared.reloadAllTimelines()
    }
}
