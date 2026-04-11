// ExerciseRecordViewModel.swift
// Features/Health/Exercise/

import Foundation
import Observation
import VitaCityCore

@Observable
final class ExerciseRecordViewModel {

    // MARK: - Input State

    var steps:          Int    = 0
    var workoutMinutes: Int    = 0
    var selectedType:   WorkoutType = .running
    var calories:       Int    = 0
    var isFromHealthKit: Bool  = false

    // MARK: - UI State

    var isSaving:   Bool   = false
    var saveError:  String? = nil
    var savedCP:    Int?   = nil  // 保存後のアニメーション用

    // MARK: - Dependencies

    private let streakManager: StreakManager

    init(streakManager: StreakManager) {
        self.streakManager = streakManager
    }

    // MARK: - Computed

    /// リアルタイム CP プレビュー
    var previewCP: Int {
        CPPointCalculator.exerciseCP(steps: steps, workoutMinutes: workoutMinutes)
    }

    var stepsProgress: Double { min(Double(steps) / 10_000, 1.0) }
    var workoutProgress: Double { min(Double(workoutMinutes) / 30, 1.0) }

    // MARK: - Actions

    @MainActor
    func save(to record: DailyRecord) async {
        isSaving = true
        defer { isSaving = false }

        let cp = previewCP
        do {
            // ExerciseLog を作成して DailyRecord に追加
            let log = ExerciseLog(
                date:            record.date,
                type:            selectedType,
                durationMinutes: workoutMinutes,
                calories:        calories,
                stepCount:       steps,
                source:          isFromHealthKit ? .healthKit : .manual
            )
            record.exerciseLogs.append(log)
            try await streakManager.updateCP(for: record, axis: .exercise, cp: cp)
            savedCP = cp
        } catch {
            saveError = error.localizedDescription
        }
    }

    /// HealthKit の歩数を反映
    func applyHealthKitSteps(_ steps: Int) {
        self.steps          = steps
        self.isFromHealthKit = true
    }
}
