// BuildingBonusCalculator.swift
// Domain/UseCases/
//
// 建設済み建物による CP ボーナスを計算する純粋関数
// CLAUDE.md Key Rule 1: 計算ロジックは集約・純粋関数
//
// 設計方針:
//   - 建設済み建物 ID の集合から、各軸の加算 CP ボーナスを返す
//   - ボーナスは CitySceneCoordinator.bonusCP(for:) 経由で取得
//   - 記録画面の previewCP に加算することで「建物の恩恵」を可視化
//   - SwiftData / SpriteKit に一切依存しない（テスト可能）

// MARK: - BuildingBonusCalculator

enum BuildingBonusCalculator {

    // MARK: - 軸別ボーナス（上限 20 CP）

    /// 運動軸のボーナス CP
    /// ジム / スタジアム / 公園 / プール / ヨガスタジオ / 自転車ST の建設数に比例
    static func exerciseBonus(builtIds: Set<String>) -> Int {
        var bonus = 0
        if builtIds.contains("B001") { bonus += 10 } // トレーニングジム
        if builtIds.contains("B002") { bonus +=  5 } // スポーツスタジアム
        if builtIds.contains("B003") { bonus +=  5 } // 公園・ランニングコース
        if builtIds.contains("B004") { bonus +=  5 } // プール
        if builtIds.contains("B005") { bonus +=  5 } // ヨガスタジオ（柔軟性 → 運動効率 UP）
        if builtIds.contains("B006") { bonus +=  5 } // 自転車ステーション
        return min(bonus, 20)
    }

    /// 食事軸のボーナス CP
    /// カフェ / マーケット / レストラン / 料理教室 / サラダバー / ジューススタンド
    static func dietBonus(builtIds: Set<String>) -> Int {
        var bonus = 0
        if builtIds.contains("B007") { bonus += 10 } // オーガニックカフェ
        if builtIds.contains("B008") { bonus += 10 } // ファーマーズマーケット
        if builtIds.contains("B009") { bonus +=  8 } // ヘルシーレストラン
        if builtIds.contains("B010") { bonus +=  8 } // 料理教室
        if builtIds.contains("B011") { bonus +=  5 } // サラダバー
        if builtIds.contains("B012") { bonus +=  5 } // ジューススタンド
        return min(bonus, 20)
    }

    /// 睡眠軸のボーナス CP
    /// 睡眠クリニック / 天文台 / アロマ / パーク / 寝具店、ヨガスタジオも睡眠に寄与
    static func sleepBonus(builtIds: Set<String>) -> Int {
        var bonus = 0
        if builtIds.contains("B017") { bonus += 12 } // 睡眠クリニック（専門施設）
        if builtIds.contains("B018") { bonus += 10 } // 天文台（夜空を楽しみ良眠を誘う）
        if builtIds.contains("B020") { bonus +=  5 } // アロマテラピーショップ
        if builtIds.contains("B021") { bonus +=  5 } // ムーンライトパーク
        if builtIds.contains("B022") { bonus +=  5 } // 布団・寝具専門店
        if builtIds.contains("B005") { bonus +=  3 } // ヨガスタジオ（リラクゼーション）
        return min(bonus, 20)
    }

    /// 生活習慣軸のボーナス CP
    /// 水広場 / クリニック / タワー / ショップ / 公民館 / 図書館 / 瞑想 / ハーブ
    static func lifestyleBonus(builtIds: Set<String>) -> Int {
        var bonus = 0
        if builtIds.contains("B023") { bonus += 12 } // ウォーターサーバー広場（水分補給支援）
        if builtIds.contains("B024") { bonus += 12 } // メンタルヘルスクリニック
        if builtIds.contains("B019") { bonus +=  8 } // 図書館（知識 → 習慣改善）
        if builtIds.contains("B026") { bonus +=  8 } // 習慣カレンダータワー（記録継続を促す）
        if builtIds.contains("B027") { bonus +=  5 } // ウェルネスショップ
        if builtIds.contains("B028") { bonus +=  5 } // 公民館
        if builtIds.contains("B013") { bonus +=  5 } // 瞑想センター（マインドフルネス）
        if builtIds.contains("B014") { bonus +=  3 } // ハーブティーショップ
        return min(bonus, 20)
    }

    // MARK: - 統合エントリポイント

    /// 軸と建設済み ID から加算ボーナス CP を返す
    /// - Returns: 0〜20 の整数（上限は maxAxisCP=100 側でクランプすること）
    static func bonus(for axis: CPAxis, builtIds: Set<String>) -> Int {
        switch axis {
        case .exercise:  return exerciseBonus(builtIds: builtIds)
        case .diet:      return dietBonus(builtIds: builtIds)
        case .sleep:     return sleepBonus(builtIds: builtIds)
        case .lifestyle: return lifestyleBonus(builtIds: builtIds)
        case .alcohol:   return 0  // 飲酒軸はペナルティ表現のみ（CLAUDE.md Key Rule 2）
        }
    }

    // MARK: - XP ブースト（建物レベルアップ速度向上）

    /// 建設済み建物によって XP 加算量を増幅するブースト倍率（1.0〜1.5）
    /// 建物が多いほど同軸の建物がより速くレベルアップする
    static func xpBoostMultiplier(for axis: CPAxis, builtIds: Set<String>) -> Double {
        let bonusCP = bonus(for: axis, builtIds: builtIds)
        // ボーナス 0→1.0, 5→1.1, 10→1.2, 15→1.35, 20→1.5
        return 1.0 + Double(bonusCP) / 40.0
    }
}
