// DietRecordViewModel.swift
// Features/Health/Diet/

import Foundation
import VitaCityCore

@Observable
final class DietRecordViewModel {

    // MARK: - 3食の評価
    var breakfastQuality: MealQuality = .normal
    var lunchQuality:     MealQuality = .normal
    var dinnerQuality:    MealQuality = .normal
    var hasSnack:         Bool        = false

    // ─ オプション詳細 ─
    var hasProtein:    Bool = false
    var hasVegetable:  Bool = false

    // UI State
    var isSaving:  Bool    = false
    var saveError: String? = nil
    var savedCP:   Int?    = nil

    private let streakManager: StreakManager
    init(streakManager: StreakManager) { self.streakManager = streakManager }

    // MARK: - Computed

    var overallQuality: MealQuality {
        let scores: [MealQuality] = [breakfastQuality, lunchQuality, dinnerQuality]
        let good   = scores.filter { $0 == .allGood }.count
        let bad    = scores.filter { $0 == .bad }.count
        if good >= 2 { return .allGood }
        if bad  >= 2 { return .bad }
        return .normal
    }

    var previewCP: Int {
        CPPointCalculator.dietCP(mealQuality: overallQuality, hasSnack: hasSnack)
    }

    // MARK: - Save

    @MainActor
    func save(to record: DailyRecord) async {
        isSaving = true
        defer { isSaving = false }
        let cp = previewCP
        do {
            for (type, quality) in [(MealType.breakfast, breakfastQuality),
                                     (.lunch, lunchQuality),
                                     (.dinner, dinnerQuality)] {
                let log = DietLog(
                    date:         record.date,
                    mealType:     type,
                    qualityRaw:   quality.rawStringValue,
                    hasProtein:   hasProtein,
                    hasVegetable: hasVegetable,
                    hasSnack:     hasSnack
                )
                record.dietLogs.append(log)
            }
            try await streakManager.updateCP(for: record, axis: .diet, cp: cp)
            savedCP = cp
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - MealQuality helpers

extension MealQuality {
    var rawStringValue: String {
        switch self { case .allGood: "allGood"; case .normal: "normal"; case .bad: "bad" }
    }
    var label: String {
        switch self { case .allGood: "良い"; case .normal: "普通"; case .bad: "悪い" }
    }
    var icon: String {
        switch self { case .allGood: "face.smiling"; case .normal: "face.smiling.inverse"; case .bad: "xmark.circle" }
    }
    var color: Color {
        switch self { case .allGood: .vcExercise; case .normal: .vcDiet; case .bad: .vcLifestyle }
    }
}

import SwiftUI
