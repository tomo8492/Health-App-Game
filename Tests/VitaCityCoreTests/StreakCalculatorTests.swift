// StreakCalculatorTests.swift
// VitaCityCoreTests
//
// StreakCalculator の全パターンをカバーするユニットテスト
// Swift Testing フレームワーク使用（@Suite / @Test / #expect）

import Testing
import Foundation
@testable import VitaCityCore

@Suite("StreakCalculator Tests")
struct StreakCalculatorTests {

    // MARK: - streak(from:) ─ 基本パターン

    @Test("空配列 → 0")
    func emptyDates() {
        #expect(StreakCalculator.streak(from: []) == 0)
    }

    @Test("今日だけ → 1")
    func onlyToday() {
        #expect(StreakCalculator.streak(from: [Date()]) == 1)
    }

    @Test("昨日だけ（今日の記録なし） → 0")
    func onlyYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(StreakCalculator.streak(from: [yesterday]) == 0)
    }

    @Test("今日 + 昨日 → 2")
    func todayAndYesterday() {
        let cal = Calendar.current
        let today     = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        #expect(StreakCalculator.streak(from: [today, yesterday]) == 2)
    }

    @Test("7日連続 → 7")
    func sevenConsecutiveDays() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<7).map { cal.date(byAdding: .day, value: -$0, to: today)! }
        #expect(StreakCalculator.streak(from: dates) == 7)
    }

    @Test("30日連続 → 30")
    func thirtyConsecutiveDays() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<30).map { cal.date(byAdding: .day, value: -$0, to: today)! }
        #expect(StreakCalculator.streak(from: dates) == 30)
    }

    // MARK: - streak(from:) ─ ギャップ・重複

    @Test("今日 + 一昨日（昨日ギャップ） → 1")
    func gapBetweenTodayAndDayBeforeYesterday() {
        let cal        = Calendar.current
        let today      = Date()
        let dayBefore  = cal.date(byAdding: .day, value: -2, to: today)!
        #expect(StreakCalculator.streak(from: [today, dayBefore]) == 1)
    }

    @Test("重複した日付があっても連続としてカウント")
    func duplicateDates() {
        let cal   = Calendar.current
        let today = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        // 今日を3回、昨日を2回 → 連続 2
        let dates = [today, today, today, yesterday, yesterday]
        #expect(StreakCalculator.streak(from: dates) == 2)
    }

    @Test("順不同の配列でも正しく計算")
    func unsortedDates() {
        let cal   = Calendar.current
        let today = Date()
        let d1 = cal.date(byAdding: .day, value: -2, to: today)!
        let d2 = cal.date(byAdding: .day, value: -1, to: today)!
        #expect(StreakCalculator.streak(from: [d1, today, d2]) == 3)
    }

    @Test("将来日付は無視されて今日から連続カウント")
    func futureDateIgnored() {
        let cal      = Calendar.current
        let today    = Date()
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        // 明日と今日と昨日 → streak は今日起点なので 2（明日はスキップ）
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        #expect(StreakCalculator.streak(from: [tomorrow, today, yesterday]) == 2)
    }

    // MARK: - isConsecutive(dates:)

    @Test("空配列 → false")
    func isConsecutiveEmpty() {
        #expect(StreakCalculator.isConsecutive(dates: []) == false)
    }

    @Test("1要素 → true")
    func isConsecutiveSingle() {
        #expect(StreakCalculator.isConsecutive(dates: [Date()]) == true)
    }

    @Test("連続2日 → true")
    func isConsecutiveTwoDays() {
        let cal       = Calendar.current
        let today     = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        #expect(StreakCalculator.isConsecutive(dates: [yesterday, today]) == true)
    }

    @Test("非連続2日 → false")
    func isConsecutiveNonConsecutive() {
        let cal   = Calendar.current
        let today = Date()
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today)!
        #expect(StreakCalculator.isConsecutive(dates: [twoDaysAgo, today]) == false)
    }

    @Test("3日連続 → true")
    func isConsecutiveThreeDays() {
        let cal   = Calendar.current
        let today = Date()
        let d1 = cal.date(byAdding: .day, value: -2, to: today)!
        let d2 = cal.date(byAdding: .day, value: -1, to: today)!
        #expect(StreakCalculator.isConsecutive(dates: [d1, d2, today]) == true)
    }

    // MARK: - longestStreak(from:)

    @Test("空配列 → 0")
    func longestStreakEmpty() {
        #expect(StreakCalculator.longestStreak(from: []) == 0)
    }

    @Test("1要素 → 1")
    func longestStreakSingle() {
        #expect(StreakCalculator.longestStreak(from: [Date()]) == 1)
    }

    @Test("5日連続 → 5")
    func longestStreakFiveDays() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<5).map { cal.date(byAdding: .day, value: -$0, to: today)! }
        #expect(StreakCalculator.longestStreak(from: dates) == 5)
    }

    @Test("ギャップありで最長ブロックを返す")
    func longestStreakWithGap() {
        // 3日連続、2日ギャップ、4日連続 → 最長 4
        let cal   = Calendar.current
        let ref   = Date()
        // ブロック1: -9, -8, -7 （3日連続）
        // ブロック2: -4, -3, -2, -1 （4日連続）
        let block1 = (-9...(-7)).map { cal.date(byAdding: .day, value: $0, to: ref)! }
        let block2 = (-4...(-1)).map { cal.date(byAdding: .day, value: $0, to: ref)! }
        #expect(StreakCalculator.longestStreak(from: block1 + block2) == 4)
    }

    @Test("重複日付があっても最長ブロックを正確にカウント")
    func longestStreakWithDuplicates() {
        let cal   = Calendar.current
        let today = Date()
        let dates = [
            today,
            today,   // 重複
            cal.date(byAdding: .day, value: -1, to: today)!,
            cal.date(byAdding: .day, value: -2, to: today)!,
        ]
        #expect(StreakCalculator.longestStreak(from: dates) == 3)
    }
}
