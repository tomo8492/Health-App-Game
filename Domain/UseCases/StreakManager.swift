// StreakManager.swift
// Domain/UseCases/
//
// 連続記録管理・アーカイブ処理（CLAUDE.md Key Rule 8）
// テスト可能な純粋関数 + SwiftData 操作の分離

import Foundation
import SwiftData

// MARK: - StreakManager

@MainActor
final class StreakManager {

    private let repository: DailyRecordRepositoryProtocol

    init(repository: DailyRecordRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 連続記録日数

    func currentStreak() async throws -> Int {
        try await repository.currentStreak()
    }

    // MARK: - 旧データアーカイブ（CLAUDE.md Key Rule 8）

    /// 無料版で 90 日超の記録を isArchived = true に設定
    /// - 削除はしない（プレミアム版へのアップグレード時に復活できるよう保持）
    func archiveOldRecords(isPremium: Bool) async throws {
        guard !isPremium else { return }  // プレミアム版はアーカイブしない
        try await repository.archiveOldRecords(olderThan: 90)
    }

    // MARK: - 今日の記録を取得または作成

    func todayRecord() async throws -> DailyRecord {
        if let existing = try await repository.record(for: Date()) {
            return existing
        }
        let newRecord = DailyRecord(date: Date())
        try await repository.save(newRecord)
        return newRecord
    }

    // MARK: - CP 更新

    func updateCP(
        for record: DailyRecord,
        axis: CPAxis,
        cp: Int
    ) async throws {
        switch axis {
        case .exercise:  record.exerciseCP  = cp
        case .diet:      record.dietCP      = cp
        case .alcohol:   record.alcoholCP   = cp
        case .sleep:     record.sleepCP     = cp
        case .lifestyle: record.lifestyleCP = cp
        }
        record.totalCP = record.exerciseCP + record.dietCP + record.alcoholCP + record.sleepCP + record.lifestyleCP
        try await repository.save(record)
    }
}

// MARK: - Pure Logic Tests (静的ヘルパー)

extension StreakManager {

    /// 指定日数間隔で連続記録があるか判定（テスト可能な純粋関数）
    static func isConsecutive(dates: [Date]) -> Bool {
        guard dates.count >= 2 else { return dates.count == 1 }
        let sorted   = dates.map { Calendar.current.startOfDay(for: $0) }.sorted()
        for i in 1..<sorted.count {
            let diff = Calendar.current.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff != 1 { return false }
        }
        return true
    }
}
