// AchievementEvaluatorTests.swift
// VitaCityCoreTests
//
// AchievementEvaluator の全パターンをカバーするユニットテスト
// Swift Testing フレームワーク使用（@Suite / @Test / #expect）

import Testing
import Foundation
@testable import VitaCityCore

@Suite("AchievementEvaluator Tests")
struct AchievementEvaluatorTests {

    // MARK: - Helpers

    private static let cal = Calendar.current

    private static func daysAgo(_ n: Int) -> Date {
        cal.date(byAdding: .day, value: -n, to: Date())!
    }

    private static func record(
        daysAgo n: Int = 0,
        exercise: Int = 0, diet: Int = 0, alcohol: Int = 0,
        sleep: Int = 0, lifestyle: Int = 0
    ) -> RecordSnapshot {
        RecordSnapshot(
            date:        daysAgo(n),
            exerciseCP:  exercise,
            dietCP:      diet,
            alcoholCP:   alcohol,
            sleepCP:     sleep,
            lifestyleCP: lifestyle
        )
    }

    // MARK: - TotalCP

    @Test("totalCP が target 以上で解除")
    func totalCPReached() {
        let (unlocked, progress) = AchievementEvaluator.isTotalCPReached(totalCP: 1000, target: 1000)
        #expect(unlocked == true)
        #expect(progress == 1.0)
    }

    @Test("totalCP が target 未満では未解除")
    func totalCPNotReached() {
        let (unlocked, progress) = AchievementEvaluator.isTotalCPReached(totalCP: 999, target: 1000)
        #expect(unlocked == false)
        #expect(progress < 1.0)
    }

    @Test("progress は 1.0 を超えない（超過達成時）")
    func totalCPProgressCapped() {
        let (_, progress) = AchievementEvaluator.isTotalCPReached(totalCP: 5000, target: 1000)
        #expect(progress == 1.0)
    }

    @Test("progress の計算 — 500/1000 = 0.5")
    func totalCPProgressHalf() {
        let (_, progress) = AchievementEvaluator.isTotalCPReached(totalCP: 500, target: 1000)
        #expect(abs(progress - 0.5) < 0.001)
    }

    // MARK: - Streak

    @Test("連続3日で streakDays(3) 解除")
    func streakReached() {
        let (unlocked, _) = AchievementEvaluator.isStreakReached(streak: 3, target: 3)
        #expect(unlocked == true)
    }

    @Test("連続2日では streakDays(3) 未解除")
    func streakNotReached() {
        let (unlocked, progress) = AchievementEvaluator.isStreakReached(streak: 2, target: 3)
        #expect(unlocked == false)
        #expect(abs(progress - 2.0/3.0) < 0.001)
    }

    @Test("streak 0 のときは progress = 0")
    func streakZero() {
        let (unlocked, progress) = AchievementEvaluator.isStreakReached(streak: 0, target: 7)
        #expect(unlocked == false)
        #expect(progress == 0.0)
    }

    // MARK: - Single Day CP

    @Test("500CP 達成で perfectDay 相当の singleDayCP 解除")
    func singleDayCPReached() {
        let r = record(exercise: 100, diet: 100, alcohol: 100, sleep: 100, lifestyle: 100)
        let (unlocked, _) = AchievementEvaluator.isSingleDayCPReached(record: r, target: 500)
        #expect(unlocked == true)
    }

    @Test("record が nil のときは未解除")
    func singleDayCPNilRecord() {
        let (unlocked, progress) = AchievementEvaluator.isSingleDayCPReached(record: nil, target: 100)
        #expect(unlocked == false)
        #expect(progress == 0.0)
    }

    // MARK: - Perfect Day

    @Test("全軸 100CP で isPerfectDay 解除")
    func perfectDayUnlocked() {
        let r = record(exercise: 100, diet: 100, alcohol: 100, sleep: 100, lifestyle: 100)
        let (unlocked, progress) = AchievementEvaluator.isPerfectDay(record: r)
        #expect(unlocked == true)
        #expect(progress == 1.0)
    }

    @Test("1軸でも 100CP 未満なら未解除")
    func perfectDayNotUnlocked() {
        let r = record(exercise: 99, diet: 100, alcohol: 100, sleep: 100, lifestyle: 100)
        let (unlocked, _) = AchievementEvaluator.isPerfectDay(record: r)
        #expect(unlocked == false)
    }

    @Test("nil record では未解除")
    func perfectDayNilRecord() {
        let (unlocked, progress) = AchievementEvaluator.isPerfectDay(record: nil)
        #expect(unlocked == false)
        #expect(progress == 0.0)
    }

    @Test("progress は (全CP合計)/500 で計算")
    func perfectDayProgress() {
        // 250/500 = 0.5
        let r = record(exercise: 50, diet: 50, alcohol: 50, sleep: 50, lifestyle: 50)
        let (_, progress) = AchievementEvaluator.isPerfectDay(record: r)
        #expect(abs(progress - 0.5) < 0.001)
    }

    // MARK: - ExerciseCP100

    @Test("運動 100CP を 10 回達成で解除")
    func exerciseCP100Reached() {
        let records = (0..<10).map { record(daysAgo: $0, exercise: 100) }
        let (unlocked, _) = AchievementEvaluator.isExerciseCP100Reached(records: records, times: 10)
        #expect(unlocked == true)
    }

    @Test("運動 99CP は 100CP 達成としてカウントしない")
    func exerciseCP99NotCounted() {
        let records = (0..<10).map { record(daysAgo: $0, exercise: 99) }
        let (unlocked, _) = AchievementEvaluator.isExerciseCP100Reached(records: records, times: 10)
        #expect(unlocked == false)
    }

    @Test("9回では 10 回達成未解除（progress 0.9）")
    func exerciseCP100NineOfTen() {
        let records = (0..<9).map { record(daysAgo: $0, exercise: 100) }
        let (unlocked, progress) = AchievementEvaluator.isExerciseCP100Reached(records: records, times: 10)
        #expect(unlocked == false)
        #expect(abs(progress - 0.9) < 0.001)
    }

    // MARK: - AlcoholZeroDays

    @Test("飲酒ゼロ 7 日連続で解除")
    func alcoholZeroSevenDays() {
        let records = (0..<7).map { record(daysAgo: $0, alcohol: 100) }
        let (unlocked, _) = AchievementEvaluator.isAlcoholZeroDaysReached(records: records, target: 7)
        #expect(unlocked == true)
    }

    @Test("途中で飲酒ありでは連続カウントが切れる")
    func alcoholZeroInterrupted() {
        // 直近3日は飲酒ゼロだが4日前に飲酒
        let r0 = record(daysAgo: 0, alcohol: 100)
        let r1 = record(daysAgo: 1, alcohol: 100)
        let r2 = record(daysAgo: 2, alcohol: 100)
        let r3 = record(daysAgo: 3, alcohol: 40)   // 飲酒あり
        let r4 = record(daysAgo: 4, alcohol: 100)
        let (unlocked, progress) = AchievementEvaluator.isAlcoholZeroDaysReached(
            records: [r0, r1, r2, r3, r4], target: 7
        )
        #expect(unlocked == false)
        #expect(abs(progress - 3.0/7.0) < 0.001)
    }

    @Test("空の記録では 0 日連続")
    func alcoholZeroEmptyRecords() {
        let (unlocked, progress) = AchievementEvaluator.isAlcoholZeroDaysReached(records: [], target: 7)
        #expect(unlocked == false)
        #expect(progress == 0.0)
    }

    // MARK: - StepGoal (Proxy)

    @Test("exerciseCP >= 60 が requiredDays 日以上で解除")
    func stepGoalReached() {
        let records = (0..<7).map { record(daysAgo: $0, exercise: 60) }
        let (unlocked, _) = AchievementEvaluator.isStepGoalReached(records: records, requiredDays: 7)
        #expect(unlocked == true)
    }

    @Test("exerciseCP 59 はステップ達成とみなさない")
    func stepGoalNotReachedAt59CP() {
        let records = (0..<7).map { record(daysAgo: $0, exercise: 59) }
        let (unlocked, _) = AchievementEvaluator.isStepGoalReached(records: records, requiredDays: 7)
        #expect(unlocked == false)
    }

    // MARK: - NPCCount

    @Test("NPC 10 人以上で解除")
    func npcCountReached() {
        let (unlocked, progress) = AchievementEvaluator.isNPCCountReached(npcCount: 10, target: 10)
        #expect(unlocked == true)
        #expect(progress == 1.0)
    }

    @Test("NPC 9 人では未解除（progress 0.9）")
    func npcCountNotReached() {
        let (unlocked, progress) = AchievementEvaluator.isNPCCountReached(npcCount: 9, target: 10)
        #expect(unlocked == false)
        #expect(abs(progress - 0.9) < 0.001)
    }

    // MARK: - currentStreak (from RecordSnapshot)

    @Test("RecordSnapshot 配列から連続日数を計算")
    func currentStreakFromSnapshots() {
        let today     = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let r1 = RecordSnapshot(date: today)
        let r2 = RecordSnapshot(date: yesterday)
        #expect(AchievementEvaluator.currentStreak(from: [r1, r2]) == 2)
    }

    @Test("空のスナップショット配列 → streak 0")
    func currentStreakEmptySnapshots() {
        #expect(AchievementEvaluator.currentStreak(from: []) == 0)
    }

    // MARK: - longestStreak (from RecordSnapshot)

    @Test("最長連続ブロックを返す")
    func longestStreakFromSnapshots() {
        let cal = Calendar.current
        let today = Date()
        // 3日連続ブロック（5〜7日前）
        let block1 = [5, 6, 7].map { RecordSnapshot(date: cal.date(byAdding: .day, value: -$0, to: today)!) }
        // 2日連続ブロック（0〜1日前）
        let block2 = [0, 1].map { RecordSnapshot(date: cal.date(byAdding: .day, value: -$0, to: today)!) }
        #expect(AchievementEvaluator.longestStreak(from: block1 + block2) == 3)
    }

    // MARK: - RecordSnapshot

    @Test("totalCP は5軸の合計")
    func recordSnapshotTotalCP() {
        let r = RecordSnapshot(date: Date(), exerciseCP: 80, dietCP: 70, alcoholCP: 100, sleepCP: 90, lifestyleCP: 60)
        #expect(r.totalCP == 400)
    }

    @Test("isPerfectDay は全軸 100 のときのみ true")
    func recordSnapshotIsPerfectDay() {
        let perfect = RecordSnapshot(date: Date(), exerciseCP: 100, dietCP: 100, alcoholCP: 100, sleepCP: 100, lifestyleCP: 100)
        let imperfect = RecordSnapshot(date: Date(), exerciseCP: 100, dietCP: 100, alcoholCP: 100, sleepCP: 99, lifestyleCP: 100)
        #expect(perfect.isPerfectDay == true)
        #expect(imperfect.isPerfectDay == false)
    }
}
