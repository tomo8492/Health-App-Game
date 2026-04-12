// CPAxisStyle.swift
// Core/DesignSystem/
//
// 5軸それぞれのスタイル定義（カラー・アイコン・名称）

import SwiftUI

// MARK: - CPAxis

enum CPAxis: CaseIterable {
    case exercise
    case diet
    case alcohol
    case sleep
    case lifestyle

    var name: String {
        switch self {
        case .exercise:  return "運動"
        case .diet:      return "食事"
        case .alcohol:   return "飲酒"
        case .sleep:     return "睡眠"
        case .lifestyle: return "生活習慣"
        }
    }

    var shortName: String {
        switch self {
        case .exercise:  return "運動"
        case .diet:      return "食事"
        case .alcohol:   return "飲酒"
        case .sleep:     return "睡眠"
        case .lifestyle: return "習慣"
        }
    }

    var icon: String {
        switch self {
        case .exercise:  return "figure.run"
        case .diet:      return "fork.knife"
        case .alcohol:   return "wineglass"
        case .sleep:     return "moon.zzz.fill"
        case .lifestyle: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .exercise:  return .vcExercise
        case .diet:      return .vcDiet
        case .alcohol:   return .vcAlcohol
        case .sleep:     return .vcSleep
        case .lifestyle: return .vcLifestyle
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .exercise:  return .vcExerciseGradient()
        case .diet:      return .vcDietGradient()
        case .alcohol:   return .vcAlcoholGradient()
        case .sleep:     return .vcSleepGradient()
        case .lifestyle: return .vcLifestyleGradient()
        }
    }

    /// DailyRecord から対応する軸の CP を取得
    func cp(from record: DailyRecord?) -> Int {
        guard let record else { return 0 }
        switch self {
        case .exercise:  return record.exerciseCP
        case .diet:      return record.dietCP
        case .alcohol:   return record.alcoholCP
        case .sleep:     return record.sleepCP
        case .lifestyle: return record.lifestyleCP
        }
    }

    /// CPAxis から記録済みかどうか判定
    func isRecorded(in record: DailyRecord?) -> Bool {
        cp(from: record) > 0
    }

    /// Assets.xcassets の PNG 名・Python スクリプトの軸名と一致させる
    var rawValue: String {
        switch self {
        case .exercise:  return "exercise"
        case .diet:      return "diet"
        case .alcohol:   return "alcohol"
        case .sleep:     return "sleep"
        case .lifestyle: return "lifestyle"
        }
    }
}
