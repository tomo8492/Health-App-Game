// ExerciseLog.swift
// Domain/Models

import Foundation
import SwiftData

/// 運動記録エンティティ
@Model
final class ExerciseLog {

    var id: UUID = UUID()
    var date: Date
    var type: WorkoutType
    var durationMinutes: Int
    var calories: Int
    var stepCount: Int
    var source: DataSource

    init(
        date:            Date,
        type:            WorkoutType = .other,
        durationMinutes: Int = 0,
        calories:        Int = 0,
        stepCount:       Int = 0,
        source:          DataSource = .manual
    ) {
        self.date            = date
        self.type            = type
        self.durationMinutes = durationMinutes
        self.calories        = calories
        self.stepCount       = stepCount
        self.source          = source
    }
}

enum WorkoutType: String, Codable {
    case running   = "running"
    case strength  = "strength"
    case swimming  = "swimming"
    case yoga      = "yoga"
    case cycling   = "cycling"
    case walking   = "walking"
    case other     = "other"
}

enum DataSource: String, Codable {
    case healthKit = "healthKit"
    case manual    = "manual"
}
