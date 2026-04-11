// LifestyleLog.swift
// Domain/Models

import Foundation
import SwiftData

/// 生活習慣記録エンティティ
@Model
final class LifestyleLog {

    var id: UUID = UUID()
    var date: Date
    var waterCups: Int        // 水分摂取量（コップ数）目標: 8杯
    var stressLevel: Int      // ストレスレベル（1〜5）
    var meditationDone: Bool
    var readingDone: Bool
    var detoxDone: Bool       // デジタルデトックス達成

    var habitsCompleted: Bool {
        meditationDone || readingDone || detoxDone
    }

    init(
        date:           Date,
        waterCups:      Int = 0,
        stressLevel:    Int = 3,
        meditationDone: Bool = false,
        readingDone:    Bool = false,
        detoxDone:      Bool = false
    ) {
        self.date           = date
        self.waterCups      = waterCups
        self.stressLevel    = stressLevel
        self.meditationDone = meditationDone
        self.readingDone    = readingDone
        self.detoxDone      = detoxDone
    }
}
