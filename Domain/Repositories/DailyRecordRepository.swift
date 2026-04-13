// DailyRecordRepository.swift
// Domain/Repositories
//
// nalexn/clean-architecture-swiftui パターン:
//   - Protocol でインターフェースを定義（DI / テスト用モック差し替えを可能に）
//   - 具象実装は Infrastructure 層に置く
//   - SwiftUI View から直接 @Query を使用しない（CLAUDE.md Key Rule 9）

import Foundation

// MARK: - Repository Protocol

protocol DailyRecordRepositoryProtocol {

    /// 指定日の記録を取得（なければ nil）
    func record(for date: Date) async throws -> DailyRecord?

    /// 直近 N 日間の記録を取得
    func recentRecords(limit: Int) async throws -> [DailyRecord]

    /// 記録を保存（新規 or 更新）
    func save(_ record: DailyRecord) async throws

    /// 90日超の記録をアーカイブ（無料版向け）
    func archiveOldRecords(olderThan days: Int) async throws

    /// 連続記録日数を取得
    func currentStreak() async throws -> Int

    /// 全期間の累計 CP 合計を取得（ゲーム進行・マップ拡張の基準値）
    func cumulativeCPTotal() async throws -> Int
}

// MARK: - SwiftData 実装

import SwiftData

@MainActor
final class DailyRecordRepository: DailyRecordRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func record(for date: Date) async throws -> DailyRecord? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay   = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate  = #Predicate<DailyRecord> { r in
            r.date >= startOfDay && r.date < endOfDay && !r.isArchived
        }
        let descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func recentRecords(limit: Int) async throws -> [DailyRecord] {
        var descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { !$0.isArchived },
            sortBy:    [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func save(_ record: DailyRecord) async throws {
        modelContext.insert(record)
        try modelContext.save()
    }

    func archiveOldRecords(olderThan days: Int) async throws {
        let cutoff    = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = #Predicate<DailyRecord> { r in
            r.date < cutoff && !r.isArchived
        }
        let descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)
        let old        = try modelContext.fetch(descriptor)
        old.forEach { $0.isArchived = true }
        try modelContext.save()
    }

    func currentStreak() async throws -> Int {
        var descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { !$0.isArchived },
            sortBy:    [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 365
        let records = try modelContext.fetch(descriptor)
        return StreakCalculator.streak(from: records.map(\.date))
    }

    func cumulativeCPTotal() async throws -> Int {
        // アーカイブ含む全記録の totalCP を合計（起動時の cumulative CP 初期化に使用）
        let records = try modelContext.fetch(FetchDescriptor<DailyRecord>())
        return records.reduce(0) { $0 + $1.totalCP }
    }
}

// MARK: - StreakCalculator（連続日数計算）

enum StreakCalculator {
    static func streak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        let calendar  = Calendar.current
        let sorted    = dates.map { calendar.startOfDay(for: $0) }
                             .sorted(by: >)
        var streak    = 0
        var expected  = calendar.startOfDay(for: Date())

        for day in sorted {
            if day == expected {
                streak  += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else {
                break
            }
        }
        return streak
    }
}
