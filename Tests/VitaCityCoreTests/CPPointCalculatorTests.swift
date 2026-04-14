// CPPointCalculatorTests.swift
// VitaCityCoreTests
//
// Swift Testing フレームワーク使用（isowords パターン）
// 全計算パターンを網羅（CLAUDE.md Key Rule 1 必須要件）

import Testing
@testable import VitaCityCore

// MARK: - 運動 CP テスト

@Suite("運動 CP")
struct ExerciseCPTests {

    @Test("歩数 0・ワークアウト 0 → 0 CP")
    func noActivity() {
        #expect(CPPointCalculator.exerciseCP(steps: 0, workoutMinutes: 0) == 0)
    }

    @Test("歩数 5,000 → 30 CP（線形スケール 50%）")
    func halfStepGoal() {
        #expect(CPPointCalculator.exerciseCP(steps: 5_000, workoutMinutes: 0) == 30)
    }

    @Test("歩数 10,000 → 60 CP")
    func fullStepGoal() {
        #expect(CPPointCalculator.exerciseCP(steps: 10_000, workoutMinutes: 0) == 60)
    }

    @Test("歩数 10,000 超過 → 上限 60 CP（歩数分）")
    func stepsOverGoal() {
        #expect(CPPointCalculator.exerciseCP(steps: 20_000, workoutMinutes: 0) == 60)
    }

    @Test("ワークアウト 30 分 → 40 CP")
    func workoutThreshold() {
        #expect(CPPointCalculator.exerciseCP(steps: 0, workoutMinutes: 30) == 40)
    }

    @Test("ワークアウト 29 分 → 0 CP（閾値未満）")
    func workoutBelowThreshold() {
        #expect(CPPointCalculator.exerciseCP(steps: 0, workoutMinutes: 29) == 0)
    }

    @Test("歩数 10,000 + ワークアウト 30 分 → 最大 100 CP")
    func maxExerciseCP() {
        #expect(CPPointCalculator.exerciseCP(steps: 10_000, workoutMinutes: 30) == 100)
    }

    @Test("100 CP を超えない（上限チェック）")
    func cappedAt100() {
        #expect(CPPointCalculator.exerciseCP(steps: 50_000, workoutMinutes: 120) == 100)
    }

    @Test("負の歩数 → 0 CP（境界値チェック）")
    func negativeSteps() {
        #expect(CPPointCalculator.exerciseCP(steps: -1000, workoutMinutes: 0) == 0)
    }
}

// MARK: - 飲酒 CP テスト

@Suite("飲酒 CP")
struct AlcoholCPTests {

    @Test("0 ドリンク（禁酒） → 100 CP")
    func noDrinks() {
        #expect(CPPointCalculator.alcoholCP(drinkCount: 0) == 100)
    }

    @Test("1 ドリンク（適量） → 60 CP")
    func oneDrink() {
        #expect(CPPointCalculator.alcoholCP(drinkCount: 1) == 60)
    }

    @Test("2 ドリンク（適量上限） → 60 CP")
    func twoDrinks() {
        #expect(CPPointCalculator.alcoholCP(drinkCount: 2) == 60)
    }

    @Test("3 ドリンク → 20 CP")
    func threeDrinks() {
        #expect(CPPointCalculator.alcoholCP(drinkCount: 3) == 20)
    }

    @Test("4 ドリンク → 20 CP")
    func fourDrinks() {
        #expect(CPPointCalculator.alcoholCP(drinkCount: 4) == 20)
    }

    @Test("5 ドリンク（過飲） → 0 CP（下限：-20 は 0 に切り上げ）")
    func heavyDrinking() {
        #expect(CPPointCalculator.alcoholCP(drinkCount: 5) == 0)
    }

    @Test("10 ドリンク → 0 CP（下限チェック）")
    func extremeDrinking() {
        #expect(CPPointCalculator.alcoholCP(drinkCount: 10) == 0)
    }
}

// MARK: - 睡眠 CP テスト

@Suite("睡眠 CP")
struct SleepCPTests {

    @Test("7 時間 → 100 CP（理想下限）")
    func sevenHours() {
        #expect(CPPointCalculator.sleepCP(hours: 7.0) == 100)
    }

    @Test("8 時間 → 100 CP（理想中心）")
    func eightHours() {
        #expect(CPPointCalculator.sleepCP(hours: 8.0) == 100)
    }

    @Test("8.5 時間 → 100 CP（理想範囲内）")
    func eighPointFiveHours() {
        #expect(CPPointCalculator.sleepCP(hours: 8.5) == 100)
    }

    @Test("9 時間ちょうど → 100 CP（理想範囲の上限、「超」ではない）")
    func exactlyNineHours() {
        #expect(CPPointCalculator.sleepCP(hours: 9.0) == 100)
    }

    @Test("9 時間超 → 80 CP（寝すぎ）")
    func oversleep() {
        #expect(CPPointCalculator.sleepCP(hours: 9.5) == 80)
        #expect(CPPointCalculator.sleepCP(hours: 10.0) == 80)
    }

    @Test("9.0 超えの最小値 → 80 CP（境界値チェック）")
    func justAboveNineHours() {
        // 9.0 はちょうど理想範囲内、それを超えた値は寝すぎ
        #expect(CPPointCalculator.sleepCP(hours: 9.01) == 80)
    }

    @Test("6 時間台 → 60 CP")
    func sixHours() {
        #expect(CPPointCalculator.sleepCP(hours: 6.0) == 60)
        #expect(CPPointCalculator.sleepCP(hours: 6.5) == 60)
    }

    @Test("5 時間台 → 20 CP")
    func fiveHours() {
        #expect(CPPointCalculator.sleepCP(hours: 5.0) == 20)
        #expect(CPPointCalculator.sleepCP(hours: 5.9) == 20)
    }

    @Test("4 時間以下 → 20 CP（最低値）")
    func veryShortSleep() {
        #expect(CPPointCalculator.sleepCP(hours: 4.0) == 20)
        #expect(CPPointCalculator.sleepCP(hours: 0.0) == 20)
    }
}

// MARK: - 食事 CP テスト

@Suite("食事 CP")
struct DietCPTests {

    @Test("3食良い + 間食なし → 100 CP（最大）")
    func perfectDiet() {
        #expect(CPPointCalculator.dietCP(mealQuality: .allGood, hasSnack: false) == 100)
    }

    @Test("3食良い + 間食あり → 90 CP")
    func goodWithSnack() {
        #expect(CPPointCalculator.dietCP(mealQuality: .allGood, hasSnack: true) == 90)
    }

    @Test("普通 + 間食なし → 60 CP")
    func normalNoSnack() {
        #expect(CPPointCalculator.dietCP(mealQuality: .normal, hasSnack: false) == 60)
    }

    @Test("普通 + 間食あり → 50 CP")
    func normalWithSnack() {
        #expect(CPPointCalculator.dietCP(mealQuality: .normal, hasSnack: true) == 50)
    }

    @Test("悪い + 間食あり → 20 CP（最低）")
    func badWithSnack() {
        #expect(CPPointCalculator.dietCP(mealQuality: .bad, hasSnack: true) == 20)
    }

    @Test("悪い + 間食なし → 30 CP")
    func badNoSnack() {
        #expect(CPPointCalculator.dietCP(mealQuality: .bad, hasSnack: false) == 30)
    }
}

// MARK: - 生活習慣 CP テスト

@Suite("生活習慣 CP")
struct LifestyleCPTests {

    @Test("全条件達成 → 100 CP（水8杯 + ストレス1 + 習慣完了）")
    func maxLifestyleCP() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 8, stressLevel: 1, habitsCompleted: true) == 100)
    }

    @Test("全条件未達成 → 0 CP")
    func minLifestyleCP() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 0, stressLevel: 5, habitsCompleted: false) == 0)
    }

    @Test("水 8 杯以上 → +30 CP")
    func waterGoalAchieved() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 8, stressLevel: 5, habitsCompleted: false) == 30)
        #expect(CPPointCalculator.lifestyleCP(waterCups: 10, stressLevel: 5, habitsCompleted: false) == 30)
    }

    @Test("水 4〜7 杯 → +15 CP")
    func partialWaterGoal() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 4, stressLevel: 5, habitsCompleted: false) == 15)
        #expect(CPPointCalculator.lifestyleCP(waterCups: 7, stressLevel: 5, habitsCompleted: false) == 15)
    }

    @Test("ストレスレベル 2 → +40 CP")
    func lowStress() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 0, stressLevel: 2, habitsCompleted: false) == 40)
    }

    @Test("ストレスレベル 3 → +20 CP")
    func midStress() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 0, stressLevel: 3, habitsCompleted: false) == 20)
    }

    @Test("ストレスレベル 4 以上 → +0 CP")
    func highStress() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 0, stressLevel: 4, habitsCompleted: false) == 0)
    }

    @Test("習慣達成のみ → +30 CP")
    func habitsOnly() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 0, stressLevel: 5, habitsCompleted: true) == 30)
    }

    @Test("100 CP を超えない（上限チェック）")
    func cappedAt100() {
        #expect(CPPointCalculator.lifestyleCP(waterCups: 100, stressLevel: 1, habitsCompleted: true) == 100)
    }
}

// MARK: - 合計 CP テスト

@Suite("合計 CP")
struct TotalCPTests {

    @Test("5軸 × 100 → 500 CP（最大値）")
    func maxTotal() {
        #expect(CPPointCalculator.totalCP(exercise: 100, diet: 100, alcohol: 100, sleep: 100, lifestyle: 100) == 500)
    }

    @Test("500 CP を超えない（上限チェック）")
    func cappedAt500() {
        #expect(CPPointCalculator.totalCP(exercise: 200, diet: 200, alcohol: 200, sleep: 200, lifestyle: 200) == 500)
    }

    @Test("全 0 → 0 CP")
    func allZero() {
        #expect(CPPointCalculator.totalCP(exercise: 0, diet: 0, alcohol: 0, sleep: 0, lifestyle: 0) == 0)
    }

    @Test("典型的な1日：歩数達成 + 普通食 + 禁酒 + 良い睡眠 + 習慣完了")
    func typicalGoodDay() {
        let exercise  = CPPointCalculator.exerciseCP(steps: 10_000, workoutMinutes: 0)   // 60
        let diet      = CPPointCalculator.dietCP(mealQuality: .allGood, hasSnack: false)  // 100
        let alcohol   = CPPointCalculator.alcoholCP(drinkCount: 0)                        // 100
        let sleep     = CPPointCalculator.sleepCP(hours: 7.5)                             // 100
        let lifestyle = CPPointCalculator.lifestyleCP(waterCups: 8, stressLevel: 1, habitsCompleted: true) // 100
        let total     = CPPointCalculator.totalCP(exercise: exercise, diet: diet, alcohol: alcohol, sleep: sleep, lifestyle: lifestyle)
        #expect(total == 460)
    }

    @Test("最悪な1日：運動ゼロ + 悪い食事 + 過飲 + 睡眠不足 + 習慣未達成")
    func typicalBadDay() {
        let exercise  = CPPointCalculator.exerciseCP(steps: 0, workoutMinutes: 0)        // 0
        let diet      = CPPointCalculator.dietCP(mealQuality: .bad, hasSnack: true)       // 20
        let alcohol   = CPPointCalculator.alcoholCP(drinkCount: 8)                         // 0
        let sleep     = CPPointCalculator.sleepCP(hours: 4.0)                              // 20
        let lifestyle = CPPointCalculator.lifestyleCP(waterCups: 1, stressLevel: 5, habitsCompleted: false) // 0
        let total     = CPPointCalculator.totalCP(exercise: exercise, diet: diet, alcohol: alcohol, sleep: sleep, lifestyle: lifestyle)
        #expect(total == 40)
    }
}

// MARK: - ゲーム内天気テスト

@Suite("ゲーム内天気")
struct WeatherConditionTests {

    @Test("CP 500 → 快晴")
    func maxCP() {
        #expect(CPPointCalculator.weatherCondition(totalCP: 500) == .sunny)
    }

    @Test("CP 400 → 快晴（下限）")
    func sunnyCPLowerBound() {
        #expect(CPPointCalculator.weatherCondition(totalCP: 400) == .sunny)
    }

    @Test("CP 399 → 晴れ時々曇り")
    func partlyCloudyUpperBound() {
        #expect(CPPointCalculator.weatherCondition(totalCP: 399) == .partlyCloudy)
    }

    @Test("CP 300 → 晴れ時々曇り（下限）")
    func partlyCloudyLowerBound() {
        #expect(CPPointCalculator.weatherCondition(totalCP: 300) == .partlyCloudy)
    }

    @Test("CP 200〜299 → 曇り")
    func cloudyRange() {
        #expect(CPPointCalculator.weatherCondition(totalCP: 299) == .cloudy)
        #expect(CPPointCalculator.weatherCondition(totalCP: 200) == .cloudy)
    }

    @Test("CP 100〜199 → 雨")
    func rainyRange() {
        #expect(CPPointCalculator.weatherCondition(totalCP: 199) == .rainy)
        #expect(CPPointCalculator.weatherCondition(totalCP: 100) == .rainy)
    }

    @Test("CP 0〜99 → 嵐")
    func stormyRange() {
        #expect(CPPointCalculator.weatherCondition(totalCP: 99) == .stormy)
        #expect(CPPointCalculator.weatherCondition(totalCP: 0) == .stormy)
    }
}
