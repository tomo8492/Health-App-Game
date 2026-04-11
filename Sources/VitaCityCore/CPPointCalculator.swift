// CPPointCalculator.swift
// VitaCityCore
//
// 設計原則（CLAUDE.md Key Rule 1）:
//   - 全計算ロジックをここに集約
//   - 純粋関数として実装（副作用禁止・外部依存ゼロ）
//   - 1日の最大 CP = 500（5軸 × 最大 100CP）
//
// 参考: nalexn/clean-architecture-swiftui パターン
//   - ビジネスロジックはフレームワーク依存なしの純粋 Swift

// MARK: - Public Types

/// 食事クオリティの3段階評価
public enum MealQuality: Sendable, Equatable {
    case allGood    // 3食バランス良し
    case normal     // 普通
    case bad        // 悪い
}

/// ゲーム内天気（総合 CP に連動）
public enum WeatherCondition: String, Sendable, Equatable, CaseIterable {
    case sunny        = "sunny"         // 快晴: CP 400〜500
    case partlyCloudy = "partlyCloudy"  // 晴れ時々曇り: CP 300〜399
    case cloudy       = "cloudy"        // 曇り: CP 200〜299
    case rainy        = "rainy"         // 雨: CP 100〜199
    case stormy       = "stormy"        // 嵐: CP 0〜99
}

// MARK: - CPPointCalculator

/// 市民ポイント（CP）計算エンジン
///
/// すべてのメソッドは静的純粋関数です。
/// 同じ入力には必ず同じ出力を返し、副作用を持ちません。
public enum CPPointCalculator {

    // MARK: - Constants

    public static let maxDailyCP: Int = 500
    public static let maxAxisCP:  Int = 100

    // MARK: - 運動 CP

    /// 運動軸の CP を計算する
    ///
    /// - Parameters:
    ///   - steps: その日の歩数（HealthKit から取得）
    ///   - workoutMinutes: ワークアウト累計時間（分）
    /// - Returns: 0〜100 の CP 値
    ///
    /// 計算式:
    ///   歩数 10,000 歩 = 60 CP（線形スケール）
    ///   ワークアウト 30 分以上 = 40 CP（閾値判定）
    ///   合計上限 100 CP
    public static func exerciseCP(steps: Int, workoutMinutes: Int) -> Int {
        let stepsCP    = min(60, Int(Double(max(steps, 0)) / 10_000.0 * 60))
        let workoutCP  = workoutMinutes >= 30 ? 40 : 0
        return min(stepsCP + workoutCP, maxAxisCP)
    }

    // MARK: - 食事 CP

    /// 食事軸の CP を計算する
    ///
    /// - Parameters:
    ///   - mealQuality: 3食の総合評価
    ///   - hasSnack: 間食ありか否か
    /// - Returns: 0〜100 の CP 値
    ///
    /// 計算式:
    ///   3食バランス良し = 90 CP / 普通 = 50 CP / 悪い = 20 CP
    ///   間食なし = +10 CP
    ///   合計上限 100 CP
    public static func dietCP(mealQuality: MealQuality, hasSnack: Bool) -> Int {
        var cp: Int
        switch mealQuality {
        case .allGood: cp = 90
        case .normal:  cp = 50
        case .bad:     cp = 20
        }
        if !hasSnack { cp += 10 }
        return min(cp, maxAxisCP)
    }

    // MARK: - 飲酒 CP

    /// 飲酒軸の CP を計算する
    ///
    /// - Parameter drinkCount: 飲酒量（ドリンク数）
    ///   1 ドリンク = ビール 350ml / ワイン 125ml / 日本酒 1合 / ウイスキー 30ml
    /// - Returns: 0〜100 の CP 値
    ///
    /// 計算式:
    ///   0 ドリンク = 100 CP
    ///   1〜2 ドリンク（適量） = 60 CP
    ///   3〜4 ドリンク = 20 CP
    ///   5 ドリンク以上（過飲）= -20 CP → 下限 0 CP
    ///
    /// 設計注記（CLAUDE.md Key Rule 2）:
    ///   飲酒 CP は totalCP に加算され、中央広場の発展に寄与する。
    ///   飲酒軸専用のポジティブゾーンは存在しない。
    public static func alcoholCP(drinkCount: Int) -> Int {
        switch drinkCount {
        case 0:     return 100
        case 1...2: return 60
        case 3...4: return 20
        default:    return 0  // 5+ 杯 = -20 だが下限 0
        }
    }

    // MARK: - 睡眠 CP

    /// 睡眠軸の CP を計算する
    ///
    /// - Parameter hours: 睡眠時間（時間単位）
    /// - Returns: 0〜100 の CP 値
    ///
    /// 計算式:
    ///   7〜9 時間 = 100 CP（理想）
    ///   9 時間超  = 80 CP（寝すぎ）
    ///   6 時間台  = 60 CP
    ///   5 時間以下 = 20 CP
    public static func sleepCP(hours: Double) -> Int {
        switch hours {
        case 7.0..<9.0: return 100
        case 9.0...:    return 80
        case 6.0..<7.0: return 60
        case 5.0..<6.0: return 20
        default:        return 20  // 5 時間以下
        }
    }

    // MARK: - 生活習慣 CP

    /// 生活習慣軸の CP を計算する
    ///
    /// - Parameters:
    ///   - waterCups: 水分摂取量（コップ数）目標 8 杯 = 2L
    ///   - stressLevel: ストレスレベル（1〜5、1 が最も低い）
    ///   - habitsCompleted: 習慣チェックリストの達成有無
    /// - Returns: 0〜100 の CP 値
    ///
    /// 計算式:
    ///   水 8 杯以上 = 30 CP / 4〜7 杯 = 15 CP
    ///   ストレス 1〜2 = 40 CP / ストレス 3 = 20 CP
    ///   習慣達成 = 30 CP
    ///   合計上限 100 CP
    public static func lifestyleCP(
        waterCups:        Int,
        stressLevel:      Int,
        habitsCompleted:  Bool
    ) -> Int {
        var cp = 0
        if waterCups >= 8       { cp += 30 }
        else if waterCups >= 4  { cp += 15 }
        if stressLevel <= 2     { cp += 40 }
        else if stressLevel == 3 { cp += 20 }
        if habitsCompleted      { cp += 30 }
        return min(cp, maxAxisCP)
    }

    // MARK: - 合計 CP

    /// 5 軸の CP を合算して 1 日の総合 CP を返す
    ///
    /// - Returns: 0〜500 の CP 値（上限 500 CP/日）
    public static func totalCP(
        exercise:  Int,
        diet:      Int,
        alcohol:   Int,
        sleep:     Int,
        lifestyle: Int
    ) -> Int {
        let sum = exercise + diet + alcohol + sleep + lifestyle
        return min(max(sum, 0), maxDailyCP)
    }

    // MARK: - ゲーム内天気

    /// 総合 CP からゲーム内天気を決定する
    ///
    /// - Parameter totalCP: その日の総合 CP（0〜500）
    /// - Returns: 天気の種類（WeatherCondition）
    public static func weatherCondition(totalCP: Int) -> WeatherCondition {
        switch totalCP {
        case 400...: return .sunny
        case 300..<400: return .partlyCloudy
        case 200..<300: return .cloudy
        case 100..<200: return .rainy
        default:        return .stormy
        }
    }
}
