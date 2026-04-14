// AchievementEvaluator.swift
// VitaCityCore
//
// 実績評価の純粋関数（Foundation のみ依存・テスト可能）
// SwiftData の DailyRecord に依存しないよう RecordSnapshot 値型を使用

import Foundation

// MARK: - RecordSnapshot

/// SwiftData @Model に依存しない、テスト可能な記録スナップショット
public struct RecordSnapshot: Sendable {
    public let date:        Date
    public let exerciseCP:  Int
    public let dietCP:      Int
    public let alcoholCP:   Int
    public let sleepCP:     Int
    public let lifestyleCP: Int

    public var totalCP: Int { exerciseCP + dietCP + alcoholCP + sleepCP + lifestyleCP }

    public var isPerfectDay: Bool {
        exerciseCP >= 100 && dietCP >= 100 &&
        alcoholCP  >= 100 && sleepCP >= 100 && lifestyleCP >= 100
    }

    public init(
        date:        Date,
        exerciseCP:  Int = 0,
        dietCP:      Int = 0,
        alcoholCP:   Int = 0,
        sleepCP:     Int = 0,
        lifestyleCP: Int = 0
    ) {
        self.date        = date
        self.exerciseCP  = exerciseCP
        self.dietCP      = dietCP
        self.alcoholCP   = alcoholCP
        self.sleepCP     = sleepCP
        self.lifestyleCP = lifestyleCP
    }
}

// MARK: - AchievementEvaluator

/// 実績条件を評価する純粋関数コレクション
public enum AchievementEvaluator {

    // MARK: - Milestone / CP

    /// 累計 CP が target 以上かどうか
    public static func isTotalCPReached(totalCP: Int, target: Int) -> (unlocked: Bool, progress: Double) {
        (totalCP >= target, min(Double(totalCP) / Double(target), 1.0))
    }

    // MARK: - Streak

    /// 連続記録日数が target 以上かどうか
    public static func isStreakReached(streak: Int, target: Int) -> (unlocked: Bool, progress: Double) {
        (streak >= target, min(Double(streak) / Double(target), 1.0))
    }

    // MARK: - Single Day

    /// 今日の totalCP が target 以上かどうか
    public static func isSingleDayCPReached(record: RecordSnapshot?, target: Int) -> (unlocked: Bool, progress: Double) {
        let cp = record?.totalCP ?? 0
        return (cp >= target, min(Double(cp) / Double(target), 1.0))
    }

    /// 完璧な一日（全軸 100CP）かどうか
    public static func isPerfectDay(record: RecordSnapshot?) -> (unlocked: Bool, progress: Double) {
        guard let r = record else { return (false, 0.0) }
        let avg = Double(r.exerciseCP + r.dietCP + r.alcoholCP + r.sleepCP + r.lifestyleCP) / 500.0
        return (r.isPerfectDay, min(avg, 1.0))
    }

    // MARK: - Exercise

    /// 運動 100CP を times 回以上達成しているか
    public static func isExerciseCP100Reached(
        records: [RecordSnapshot], times: Int
    ) -> (unlocked: Bool, progress: Double) {
        let count = records.filter { $0.exerciseCP >= 100 }.count
        return (count >= times, min(Double(count) / Double(times), 1.0))
    }

    // MARK: - Alcohol

    /// 飲酒ゼロを直近 target 日連続で達成しているか
    /// （alcoholCP >= 100 = その日は飲酒なし）
    public static func isAlcoholZeroDaysReached(
        records: [RecordSnapshot], target: Int
    ) -> (unlocked: Bool, progress: Double) {
        let sorted = records.sorted { $0.date > $1.date }
        var consecutive = 0
        for r in sorted {
            if r.alcoholCP >= 100 { consecutive += 1 } else { break }
        }
        return (consecutive >= target, min(Double(consecutive) / Double(target), 1.0))
    }

    // MARK: - Step Goal (Exercise Proxy)

    /// 歩数 N 歩を D 日達成しているか
    /// HealthKit 外のコンテキストでは exerciseCP >= 60 を歩数達成の代理指標とする
    public static func isStepGoalReached(
        records: [RecordSnapshot], requiredDays: Int
    ) -> (unlocked: Bool, progress: Double) {
        let count = records.filter { $0.exerciseCP >= 60 }.count
        return (count >= requiredDays, min(Double(count) / Double(requiredDays), 1.0))
    }

    // MARK: - NPC Count

    /// 街の住民数が target 人以上か
    public static func isNPCCountReached(npcCount: Int, target: Int) -> (unlocked: Bool, progress: Double) {
        (npcCount >= target, min(Double(npcCount) / Double(target), 1.0))
    }

    // MARK: - Streak (from raw dates)

    /// 記録日付の配列から今日の連続日数を返す
    /// （StreakCalculator への薄いラッパー）
    public static func currentStreak(recordDates: [Date]) -> Int {
        StreakCalculator.streak(from: recordDates)
    }

    /// 記録スナップショットの配列から記録日付を抽出し連続日数を返す
    public static func currentStreak(from records: [RecordSnapshot]) -> Int {
        StreakCalculator.streak(from: records.map(\.date))
    }

    /// 最長連続記録日数
    public static func longestStreak(from records: [RecordSnapshot]) -> Int {
        StreakCalculator.longestStreak(from: records.map(\.date))
    }
}
