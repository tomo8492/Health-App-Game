// VCColors.swift
// Core/DesignSystem/
//
// VITA CITY カラーシステム
// 5軸それぞれに専用カラーを定義。ダークモード対応。

import SwiftUI

// MARK: - Axis Colors

extension Color {
    // 5軸テーマカラー（Activity Rings パターン）
    static let vcExercise  = Color(red: 0.20, green: 0.78, blue: 0.35)  // 緑 #34C759
    static let vcDiet      = Color(red: 1.00, green: 0.58, blue: 0.00)  // オレンジ #FF9500
    static let vcAlcohol   = Color(red: 0.69, green: 0.32, blue: 0.87)  // 紫 #AF52DE
    static let vcSleep     = Color(red: 0.00, green: 0.48, blue: 1.00)  // 青 #007AFF
    static let vcLifestyle = Color(red: 1.00, green: 0.18, blue: 0.33)  // ピンク #FF2D55

    // 背景・UI
    static let vcBackground    = Color(.systemBackground)
    static let vcSecondary     = Color(.secondarySystemBackground)
    static let vcGrouped       = Color(.systemGroupedBackground)
    static let vcLabel         = Color(.label)
    static let vcSecondaryLabel = Color(.secondaryLabel)
    static let vcSeparator     = Color(.separator)

    // CP・ゲーム
    static let vcCP        = Color(red: 1.00, green: 0.84, blue: 0.00)  // 金色 #FFD700
    static let vcCPGlow    = Color(red: 1.00, green: 0.70, blue: 0.00)  // 深みのある金
    static let vcPremium   = Color(red: 0.89, green: 0.62, blue: 0.00)  // プレミアム金
}

// MARK: - Gradient

extension LinearGradient {
    static func vcExerciseGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: [.vcExercise, Color(red: 0.18, green: 0.65, blue: 0.31)], startPoint: startPoint, endPoint: endPoint)
    }
    static func vcDietGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: [.vcDiet, Color(red: 0.90, green: 0.45, blue: 0.00)], startPoint: startPoint, endPoint: endPoint)
    }
    static func vcAlcoholGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: [.vcAlcohol, Color(red: 0.55, green: 0.22, blue: 0.73)], startPoint: startPoint, endPoint: endPoint)
    }
    static func vcSleepGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: [.vcSleep, Color(red: 0.00, green: 0.30, blue: 0.80)], startPoint: startPoint, endPoint: endPoint)
    }
    static func vcLifestyleGradient(startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: [.vcLifestyle, Color(red: 0.83, green: 0.12, blue: 0.27)], startPoint: startPoint, endPoint: endPoint)
    }
}
