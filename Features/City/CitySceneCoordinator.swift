// CitySceneCoordinator.swift
// Features/City/
//
// CLAUDE.md Key Rule 9: SwiftUI ↔ SpriteKit の通信は CitySceneCoordinator（@Observable）経由のみ
// - SpriteKit シーンへの直接アクセス禁止
// - SwiftData エンティティへのアクセスは Repository プロトコル経由のみ
//
// CP の2種類の管理:
//   totalCP  — 全期間累計 CP（マップ拡張・NPC 数・年数表示に使用）
//   todayCP  — 今日の CP（0〜500, 天気表示に使用）

import Foundation
import Observation
import SpriteKit

// MARK: - CitySceneCoordinator

@Observable
@MainActor
final class CitySceneCoordinator {

    // MARK: - ゲーム状態（SwiftUI が読み取る）

    var totalCP:        Int    = 0       // 全期間累計 CP（永続値）
    var todayCP:        Int    = 0       // 今日の CP（0〜500, 天気・HUD 用）

    // 朝の天気ベースライン（ストリーク＋前日キャリーオーバーによる底上げ値）
    // todayCP がこの値を超えたら実績 CP が天気に反映される
    // totalCP の累積計算には一切影響しない
    private var morningBaselineCP: Int = 0

    var mapSize:        MapSize = .small
    var currentWeather: WeatherType = .sunny
    var selectedBuilding: BuildingInfo? = nil
    var npcCount:       Int    = 0
    var isPremium:      Bool   = false
    var cityLevel:      Int    = 1

    // MARK: - SpriteKit シーン参照（弱参照）

    weak var scene: CityScene?

    // MARK: - 建物建設（CLAUDE.md Key Rule 9）

    /// 建設済み建物 ID（@Observable → UI が自動更新）
    var builtBuildingIds: Set<String> = []

    /// BuildingPlacementStore から建設済み ID を読み込む（起動時・建設後に呼ぶ）
    func syncBuiltBuildings() {
        builtBuildingIds = BuildingPlacementStore.shared.builtIds
    }

    /// 建設可能かチェック（CP 不足 or 建設済みの場合 false）
    func canBuild(_ entry: BuildingCatalogEntry) -> Bool {
        !builtBuildingIds.contains(entry.id) && totalCP >= entry.requiredCP
    }

    /// 建物を建設する
    /// - Returns: 配置成功なら true、CP 不足 / 建設済み / 配置不可なら false
    @discardableResult
    func buildBuilding(_ entry: BuildingCatalogEntry) -> Bool {
        guard canBuild(entry) else {
            HapticEngine.error()
            return false
        }
        guard let (gx, gy) = scene?.findBestPosition(for: entry.axis) else {
            HapticEngine.error()
            return false
        }
        let placed = PlacedBuilding(
            id:      entry.id,
            name:    entry.name,
            axisKey: entry.axis.key,
            gridX:   gx,
            gridY:   gy
        )
        BuildingPlacementStore.shared.place(placed)
        builtBuildingIds.insert(entry.id)   // @Observable → UI 即時更新
        scene?.placeNewBuilding(placed)
        // 建設の触覚は scene?.placeNewBuilding 内で着地時に行われる
        return true
    }

    // MARK: - 累計 CP 初期化（起動時に DB から一度だけ呼ぶ）

    /// - Parameters:
    ///   - cumulative:    全期間の累計 CP（DailyRecordRepository.cumulativeCPTotal()）
    ///   - today:         今日の CP（AppState.todayTotalCP）
    ///   - streak:        連続記録日数（朝のベースライン計算に使用）
    ///   - previousDayCP: 前日の合計 CP（朝のキャリーオーバーに使用）
    func initCumulativeCP(cumulative: Int, today: Int,
                          streak: Int = 0, previousDayCP: Int = 0) {
        totalCP = min(cumulative, 999_999)
        todayCP = min(today, 500)
        // 朝の天気ベースライン: ストリーク 10CP/日 + 前日の 30%（上限 150）
        // 例: 7日継続 + 前日400CP → 70 + 120 = 190 → 上限 150 → 「晴れ時々曇り」確定
        morningBaselineCP = min(streak * 10 + previousDayCP * 30 / 100, 150)
        syncBuiltBuildings()   // 建設済みを復元
        updateWeather()
        updateNPCCount()
        checkMapExpansion()
    }

    // MARK: - 今日の CP 同期（AppState.todayTotalCP の onChange から呼ぶ）

    /// 今日の記録が更新されたとき差分を totalCP に加算し、todayCP を更新する
    func syncTodayCP(_ cp: Int) {
        let delta = max(0, cp - todayCP)
        todayCP = min(cp, 500)
        if delta > 0 {
            let prevLevel = cityLevelFor(cp: totalCP)
            totalCP = min(totalCP + delta, 999_999)
            scene?.onCPAdded(axis: .lifestyle, amount: delta)
            updateNPCCount()
            let newLevel = cityLevel
            if newLevel > prevLevel, let scene {
                SpriteEffects.flashScreen(
                    in: scene.cameraNodeForFX, size: scene.size,
                    color: UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                    peakAlpha: 0.30, duration: 0.55
                )
                HapticEngine.success()
            }
            checkMapExpansion()
        }
        updateWeather()
    }

    // MARK: - SwiftUI → SpriteKit イベント（CLAUDE.md Key Rule 9）

    /// 健康記録後に CP を加算しゲームを更新する
    /// - Parameters:
    ///   - axis:   更新する軸
    ///   - amount: 追加 CP 量
    func addCP(axis: CPAxis, amount: Int) {
        let prevTotal = totalCP
        totalCP = min(totalCP + amount, 999_999)
        todayCP = min(todayCP + amount, 500)
        scene?.onCPAdded(axis: axis, amount: amount)
        // 建物ボーナスを XP ブーストとして適用（建設済み建物が多いほど建物が速くレベルアップ）
        let boost = BuildingBonusCalculator.xpBoostMultiplier(for: axis, builtIds: builtBuildingIds)
        let boostedXP = Int(Double(amount) * boost)
        scene?.addXPToBuildings(axis: axis, amount: boostedXP)
        updateWeather()
        updateNPCCount()
        // 街レベルが上がった瞬間は強めの触覚 + 全画面祝福フラッシュ
        let prevCityLevel = cityLevelFor(cp: prevTotal)
        let newCityLevel  = cityLevel
        if newCityLevel > prevCityLevel, let scene {
            SpriteEffects.flashScreen(
                in: scene.cameraNodeForFX, size: scene.size,
                color: UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                peakAlpha: 0.32, duration: 0.55
            )
            HapticEngine.success()
        } else {
            HapticEngine.tapLight()
        }
        checkMapExpansion()
    }

    /// CP 値から街レベルを返す（cityLevel と同じスイッチ）
    private func cityLevelFor(cp: Int) -> Int {
        switch cp {
        case 50_000...: return 10
        case 30_000...: return  9
        case 20_000...: return  8
        case 15_000...: return  7
        case 10_000...: return  6
        case 7_000...:  return  5
        case 5_000...:  return  4
        case 3_000...:  return  3
        case 1_000...:  return  2
        default:        return  1
        }
    }

    /// 歩数更新（HealthKit バックグラウンド）
    func updateStepCount(_ steps: Int) {
        scene?.updateNPCCount(Int(Double(steps) / 10_000.0 * 10) + 1)
        npcCount = min(steps / 1000, 20)
    }

    /// 時刻変化（毎時）
    func updateTimeOfDay(_ hour: Int) {
        scene?.updateTimeOfDay(hour)
    }

    /// プレミアム解放（StoreKit2 検証後: CLAUDE.md Key Rule 3）
    func unlockPremium() {
        isPremium = true
        scene?.applyPremiumTheme()
    }

    /// カメラをマップ中心・等倍にリセット（全体図ボタンから呼ぶ: CLAUDE.md Key Rule 9）
    func resetCamera() {
        scene?.resetCameraToCenter()
    }

    // MARK: - 建物ボーナス（BuildingBonusCalculator 委譲）

    /// 建設済み建物による軸別ボーナス CP（0〜20）
    /// 記録画面の previewCP に加算して「建物の恩恵」を可視化する
    func bonusCP(for axis: CPAxis) -> Int {
        BuildingBonusCalculator.bonus(for: axis, builtIds: builtBuildingIds)
    }

    // MARK: - 飲酒ペナルティ建物（CLAUDE.md Key Rule 2）

    /// 飲酒数に応じて B029/B030 ペナルティ建物を表示 / 非表示にする
    /// drinkCount >= 5（過飲）→ 居酒屋・廃墟ビルを自動出現
    /// drinkCount < 5（記録あり）→ ペナルティ建物を除去
    /// drinkCount == -1（未記録）→ 何もしない
    func syncAlcohol(drinkCount: Int) {
        guard drinkCount >= 0 else { return }   // -1（未記録）は無視
        scene?.updatePenaltyBuildings(drinkCount: drinkCount)
    }

    // MARK: - 天気更新（todayCP 0〜500 から天気を決定）

    private func updateWeather() {
        // morningBaselineCP を下限として使用:
        //   todayCP が超えれば実績 CP が天気を決定する
        //   todayCP が下回っている間はベースラインが天気を底上げする
        let cp = max(0, min(max(todayCP, morningBaselineCP), 500))
        currentWeather = weatherForCP(cp)
        scene?.updateWeather(currentWeather)
    }

    private func weatherForCP(_ cp: Int) -> WeatherType {
        switch cp {
        case 400...: return .sunny
        case 300..<400: return .partlyCloudy
        case 200..<300: return .cloudy
        case 100..<200: return .rainy
        default:        return .stormy
        }
    }

    // MARK: - NPC 更新（totalCP 累計から計算）

    private func updateNPCCount() {
        npcCount = min(totalCP / 100 + 1, 20)
        scene?.updateNPCCount(npcCount)
        updateCityLevel()
    }

    // MARK: - 街レベル更新（累計 CP → Lv1〜10）
    // 閾値は cityLevelFor(cp:) に一元化し、ここは単純な委譲のみ
    // （閾値変更時に片方だけ更新されて整合が崩れるのを防ぐ）

    private func updateCityLevel() {
        cityLevel = cityLevelFor(cp: totalCP)
    }

    // MARK: - マップ拡張チェック（CLAUDE.md Key Rule 6: 累計 CP 基準）

    private func checkMapExpansion() {
        let newSize: MapSize
        switch totalCP {
        case 30_000...: newSize = .extraLarge  // 50×50
        case 15_000...: newSize = .large       // 40×40
        case 5_000...:  newSize = .medium      // 30×30
        default:        newSize = .small       // 20×20
        }
        if newSize != mapSize {
            mapSize = newSize
            scene?.expandMap(to: newSize)
        }
    }
}

// MARK: - Supporting Types

enum WeatherType: String, Sendable {
    case sunny        = "sunny"
    case partlyCloudy = "partlyCloudy"
    case cloudy       = "cloudy"
    case rainy        = "rainy"
    case stormy       = "stormy"

    var particleFileName: String? {
        switch self {
        case .rainy:   return "rain.sks"
        case .stormy:  return "storm.sks"
        default:       return nil
        }
    }

    var backgroundBrightness: Double {
        switch self {
        case .sunny:        return 1.0
        case .partlyCloudy: return 0.9
        case .cloudy:       return 0.75
        case .rainy:        return 0.6
        case .stormy:       return 0.45
        }
    }
}

enum MapSize: Int, Comparable, Sendable {
    case small      = 20   // 20×20
    case medium     = 30   // 30×30
    case large      = 40   // 40×40
    case extraLarge = 50   // 50×50

    static func < (lhs: MapSize, rhs: MapSize) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct BuildingInfo: Identifiable, Sendable {
    let id:          String
    let name:        String
    let axis:        CPAxis
    let level:       Int
    let description: String
    let gridX:       Int
    let gridY:       Int
}
