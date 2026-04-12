// StreakCalculatorTests.swift
// VitaCityCoreTests
//
// Swift Testing フレームワーク使用（CLAUDE.md Testing セクション準拠）
// StreakCalculator.streak(from:) および StreakLogic.isConsecutive(dates:) の全パターンを網羅

import Testing
import Foundation
@testable import VitaCityCore

// MARK: - StreakCalculator Tests

@Suite("StreakCalculator.streak(from:)")
struct StreakCalculatorTests {

    // MARK: 空・単体

    @Test("空配列 → 0")
    func emptyArray() {
        #expect(StreakCalculator.streak(from: []) == 0)
    }

    @Test("今日1件 → 1")
    func singleToday() {
        #expect(StreakCalculator.streak(from: [Date()]) == 1)
    }

    @Test("昨日のみ（今日なし）→ 0")
    func singleYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(StreakCalculator.streak(from: [yesterday]) == 0)
    }

    // MARK: 連続記録

    @Test("今日〜2日前（3日連続）→ 3")
    func threeDayStreakEndingToday() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<3).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        #expect(StreakCalculator.streak(from: dates) == 3)
    }

    @Test("30日連続 → 30")
    func thirtyDayStreak() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<30).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        #expect(StreakCalculator.streak(from: dates) == 30)
    }

    // MARK: 途中ギャップ

    @Test("今日・昨日・3日前（一昨日抜け）→ 2")
    func gapAtDayTwo() {
        let cal       = Calendar.current
        let today     = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let threeDago = cal.date(byAdding: .day, value: -3, to: today)!
        #expect(StreakCalculator.streak(from: [today, yesterday, threeDago]) == 2)
    }

    @Test("今日のみ含む30日シーケンスで15日目抜け → 1（今日+昨日...14日目で止まる前に抜けがあるため）")
    func thirtyDaysWithGapAtDay15() {
        let cal   = Calendar.current
        let today = Date()
        // day0(今日)〜day14は連続、day15を抜かす、day16〜day29
        var dates: [Date] = []
        for i in 0..<30 where i != 15 {
            if let d = cal.date(byAdding: .day, value: -i, to: today) { dates.append(d) }
        }
        // 今日〜14日前まで連続(15日) → streak = 15
        #expect(StreakCalculator.streak(from: dates) == 15)
    }

    // MARK: 過去のみ（今日なし）

    @Test("3日前〜1日前（今日なし）→ 0")
    func allPastNoToday() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (1...3).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        #expect(StreakCalculator.streak(from: dates) == 0)
    }

    // MARK: 重複・時刻無視

    @Test("今日が重複して含まれる → 1（重複は無視）")
    func duplicatesToday() {
        let today = Date()
        // 同じ日の異なる時刻
        let t1 = Calendar.current.date(byAdding: .hour, value: 8, to: Calendar.current.startOfDay(for: today))!
        let t2 = Calendar.current.date(byAdding: .hour, value: 20, to: Calendar.current.startOfDay(for: today))!
        #expect(StreakCalculator.streak(from: [t1, t2]) == 1)
    }

    @Test("時刻が異なっても同じ日として扱う")
    func ignoresTimeComponent() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let todayLate  = cal.date(byAdding: .hour, value: 23, to: today)!
        let yesterday  = cal.date(byAdding: .day, value: -1, to: today)!
        let yesterEarly = cal.date(byAdding: .hour, value: 6, to: yesterday)!
        #expect(StreakCalculator.streak(from: [todayLate, yesterEarly]) == 2)
    }

    // MARK: 順序不定

    @Test("入力が逆順でも正しくカウントする")
    func unorderedInput() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<5).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }.reversed()
        #expect(StreakCalculator.streak(from: Array(dates)) == 5)
    }
}

// MARK: - StreakLogic.isConsecutive Tests

@Suite("StreakLogic.isConsecutive(dates:)")
struct StreakLogicTests {

    // MARK: 空・単体

    @Test("空配列 → true")
    func emptyArray() {
        #expect(StreakLogic.isConsecutive(dates: []) == true)
    }

    @Test("1要素 → true")
    func singleElement() {
        #expect(StreakLogic.isConsecutive(dates: [Date()]) == true)
    }

    // MARK: 2要素

    @Test("連続2日 → true")
    func twoConsecutive() {
        let cal       = Calendar.current
        let today     = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        #expect(StreakLogic.isConsecutive(dates: [today, yesterday]) == true)
    }

    @Test("2日空き → false")
    func twoWithGap() {
        let cal       = Calendar.current
        let today     = Date()
        let twoDago   = cal.date(byAdding: .day, value: -2, to: today)!
        #expect(StreakLogic.isConsecutive(dates: [today, twoDago]) == false)
    }

    @Test("同じ日2件（重複）→ false（diff=0）")
    func duplicates() {
        let today = Date()
        #expect(StreakLogic.isConsecutive(dates: [today, today]) == false)
    }

    // MARK: 3要素

    @Test("連続3日 → true")
    func threeConsecutive() {
        let cal     = Calendar.current
        let today   = Date()
        let dates   = (0..<3).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        #expect(StreakLogic.isConsecutive(dates: dates) == true)
    }

    @Test("中間1日抜け（今日・昨日・3日前）→ false")
    func gapInMiddle() {
        let cal       = Calendar.current
        let today     = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let threeDago = cal.date(byAdding: .day, value: -3, to: today)!
        #expect(StreakLogic.isConsecutive(dates: [today, yesterday, threeDago]) == false)
    }

    @Test("末尾にギャップ（今日・昨日・4日前）→ false")
    func gapAtEnd() {
        let cal       = Calendar.current
        let today     = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let fourDago  = cal.date(byAdding: .day, value: -4, to: today)!
        #expect(StreakLogic.isConsecutive(dates: [today, yesterday, fourDago]) == false)
    }

    // MARK: 順序・時刻

    @Test("入力が逆順でも正しく判定する")
    func unorderedInput() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<3).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }.reversed()
        #expect(StreakLogic.isConsecutive(dates: Array(dates)) == true)
    }

    @Test("時刻が異なっても同じ日として扱う")
    func ignoresTimeComponent() {
        let cal        = Calendar.current
        let today      = cal.startOfDay(for: Date())
        let todayLate  = cal.date(byAdding: .hour, value: 22, to: today)!
        let yesterday  = cal.date(byAdding: .day, value: -1, to: today)!
        let yesterMorn = cal.date(byAdding: .hour, value: 7, to: yesterday)!
        #expect(StreakLogic.isConsecutive(dates: [todayLate, yesterMorn]) == true)
    }

    // MARK: 長いシーケンス

    @Test("7日連続 → true")
    func sevenDays() {
        let cal   = Calendar.current
        let today = Date()
        let dates = (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        #expect(StreakLogic.isConsecutive(dates: dates) == true)
    }

    @Test("30日シーケンスに1日の抜け → false")
    func thirtyDaysWithOneGap() {
        let cal   = Calendar.current
        let today = Date()
        var dates = (0..<30).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        dates.remove(at: 10)  // 10日目を除外してギャップを作る
        #expect(StreakLogic.isConsecutive(dates: dates) == false)
    }
}
