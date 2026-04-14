// StreakCalculator.swift
// VitaCityCore
//
// 連続記録日数の計算ロジック（純粋関数、Foundation のみ依存）
// テスト可能にするため VitaCityCore に配置（CLAUDE.md Key Rule 1 パターン）

import Foundation

// MARK: - StreakCalculator

/// 連続記録日数の計算ユーティリティ（純粋関数）
public enum StreakCalculator {

    /// 今日からさかのぼって連続している記録日数を返す
    ///
    /// - Parameter dates: 記録がある日付の配列（順不同・重複可）
    /// - Returns: 今日を起点とした連続日数。今日の記録がなければ 0。
    public static func streak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sorted = dates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
        var count = 0
        var expected = calendar.startOfDay(for: Date())
        for day in sorted {
            if day == expected {
                count += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else if day < expected {
                break   // 期待した日より古い → ギャップ確定
            }
            // day > expected は重複 → スキップ
        }
        return count
    }

    /// 日付のリストが 1 日ずつ連続しているかどうかを判定する
    ///
    /// - Parameter dates: 日付の配列
    /// - Returns: 全ての日付が連続していれば true、空なら false、1 要素なら true
    public static func isConsecutive(dates: [Date]) -> Bool {
        guard dates.count >= 2 else { return dates.count == 1 }
        let calendar = Calendar.current
        let sorted = dates
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff != 1 { return false }
        }
        return true
    }

    /// 最長連続日数を返す（記録の途中でのギャップを考慮）
    ///
    /// - Parameter dates: 記録がある日付の配列
    /// - Returns: 配列内で最も長い連続日数ブロック
    public static func longestStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sorted = Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted()
        var longest = 1
        var current = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }
}
