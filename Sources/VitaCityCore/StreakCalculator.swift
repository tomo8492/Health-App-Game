// StreakCalculator.swift
// VitaCityCore
//
// 連続記録計算（純粋関数 — 副作用なし・外部依存ゼロ）
// テスト必須（CLAUDE.md Key Rule Testing セクション）
//
// 使い方:
//   let streak = StreakCalculator.streak(from: dates)
//   let ok     = StreakLogic.isConsecutive(dates: dates)
//
// NOTE: App ターゲットの DailyRecordRepository も同じロジックを持つ。
//       Xcode で VitaCityCore を App ターゲットに追加した後、
//       DailyRecordRepository の StreakCalculator 定義を削除してこちらに統一すること。

import Foundation

// MARK: - StreakCalculator

/// 今日から遡る連続記録日数を計算する
public enum StreakCalculator {

    /// 指定された日付の配列から、今日を起点とする連続記録日数を返す
    ///
    /// - Parameter dates: 記録日の配列（順不同・重複可）
    /// - Returns: 今日を含む連続記録日数。今日の記録がなければ 0。
    ///
    /// 例:
    ///   今日・昨日・一昨日 → 3
    ///   今日・一昨日（昨日抜け）→ 1
    ///   昨日のみ → 0
    public static func streak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sorted   = dates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)

        var streak   = 0
        var expected = calendar.startOfDay(for: Date())

        for day in sorted {
            if day == expected {
                streak  += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: expected) else { break }
                expected = prev
            } else if day < expected {
                // expected より古い日付が来たら連続が切れている
                break
            }
            // day > expected は未来日（重複 startOfDay で起きないはずだが念のためスキップ）
        }
        return streak
    }
}

// MARK: - StreakLogic

/// 日付リストが連続した日々かどうかを判定する
public enum StreakLogic {

    /// 日付の配列がすべて連続した日々（前後1日差）であるかを返す
    ///
    /// - Parameter dates: 日付の配列（順不同・重複不可を前提）
    /// - Returns:
    ///   - 空配列 / 1要素 → true
    ///   - 全要素が連続 → true
    ///   - 1日でもギャップ / 重複があれば → false
    ///
    /// 使用例（StreakManager.isConsecutive のバックエンド）:
    ///   StreakLogic.isConsecutive(dates: recordDates)
    public static func isConsecutive(dates: [Date]) -> Bool {
        guard dates.count >= 2 else { return true }
        let calendar = Calendar.current
        let sorted   = dates
            .map { calendar.startOfDay(for: $0) }
            .sorted()

        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff != 1 { return false }
        }
        return true
    }
}
