// SleepLog.swift
// Domain/Models

import Foundation
import SwiftData

/// 睡眠記録エンティティ
@Model
final class SleepLog {

    var id: UUID = UUID()
    var date: Date
    var bedtime: Date?
    var wakeTime: Date?
    var durationMinutes: Int   // 睡眠時間（分）
    var sleepScore: Int        // 0〜100点（深睡眠・レム・覚醒比率から算出）
    var source: DataSource

    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }

    init(
        date:            Date,
        bedtime:         Date? = nil,
        wakeTime:        Date? = nil,
        durationMinutes: Int = 0,
        sleepScore:      Int = 0,
        source:          DataSource = .manual
    ) {
        self.date            = date
        self.bedtime         = bedtime
        self.wakeTime        = wakeTime
        self.durationMinutes = durationMinutes
        self.sleepScore      = sleepScore
        self.source          = source
    }
}
