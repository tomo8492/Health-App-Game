// DailyRecord.swift
// Domain/Models
//
// SwiftData エンティティ（CLAUDE.md Key Rule 8 準拠）
// - isArchived フィールド: 無料版で90日超のデータをアーカイブ
// - CloudKit 対応準備: ModelConfiguration(cloudKitDatabase: .none) で明示的に無効化

import Foundation
import SwiftData

@Model
final class DailyRecord {

    // MARK: - 識別子

    var id: UUID = UUID()
    var date: Date

    // MARK: - CP スコア（5軸 + 合計）

    var totalCP:     Int = 0
    var exerciseCP:  Int = 0
    var dietCP:      Int = 0
    var alcoholCP:   Int = 0
    var sleepCP:     Int = 0
    var lifestyleCP: Int = 0

    // MARK: - データ保持フラグ（CLAUDE.md Key Rule 8）

    /// 無料版で90日超のデータをアーカイブ済みとしてマーク
    /// - true: アーカイブ済み（無料版では表示・参照不可）
    /// - false: アクティブ（全ユーザーが参照可能）
    var isArchived: Bool = false

    // MARK: - リレーション

    @Relationship(deleteRule: .cascade)
    var exerciseLogs: [ExerciseLog] = []

    @Relationship(deleteRule: .cascade)
    var dietLogs: [DietLog] = []

    @Relationship(deleteRule: .cascade)
    var alcoholLogs: [AlcoholLog] = []

    @Relationship(deleteRule: .cascade)
    var sleepLogs: [SleepLog] = []

    @Relationship(deleteRule: .cascade)
    var lifestyleLogs: [LifestyleLog] = []

    // MARK: - Init

    init(date: Date) {
        self.date = date
    }

    // MARK: - Computed

    var isComplete: Bool {
        exerciseCP > 0 && dietCP > 0 && sleepCP > 0 && lifestyleCP > 0
    }
}
