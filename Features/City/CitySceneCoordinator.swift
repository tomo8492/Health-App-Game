// CitySceneCoordinator.swift
// Features/City/
//
// CLAUDE.md Key Rule 9: SwiftUI ↔ SpriteKit の通信は CitySceneCoordinator（@Observable）経由のみ
// - SpriteKit シーンへの直接アクセス禁止
// - SwiftData エンティティへのアクセスは Repository プロトコル経由のみ

import Foundation
import Observation
import SpriteKit

// MARK: - CitySceneCoordinator

@Observable
@MainActor
final class CitySceneCoordinator {

    // MARK: - ゲーム状態（SwiftUI が読み取る）

    var totalCP:           Int         = 0
    var mapSize:           MapSize     = .small
    var currentWeather:    WeatherType = .sunny
    var selectedBuilding:  BuildingInfo? = nil
    var npcCount:          Int         = 0
    var isPremium:         Bool        = false
    var cityLevel:         Int         = 1

    // MARK: - 建物レジストリ

    private(set) var registry = BuildingRegistry()

    // MARK: - SpriteKit シーン参照（弱参照）

    weak var scene: CityScene?

    // MARK: - 絶対値同期（起動時・記録保存後）

    /// AppState.todayTotalCP が変化したときに呼ぶ（デルタではなく絶対値）
    func syncTotalCP(_ newCP: Int) {
        guard newCP != totalCP else { return }
        let delta = newCP - totalCP
        totalCP   = min(newCP, 999_999)

        if delta > 0 {
            // 新しく解放された建物をシーンに追加
            let unlocked = registry.checkUnlocks(totalCP: totalCP)
            unlocked.forEach { entry in
                if let b = registry.placed.first(where: { $0.id == entry.id }) {
                    scene?.addBuilding(id: b.id, name: b.name, axis: entry.axis,
                                       gridX: b.gridX, gridY: b.gridY, level: b.level)
                    scene?.onCPAdded(axis: entry.axis, amount: delta)
                }
            }
            // 既存建物に XP を配布
            distributeXP(delta)
        }

        updateWeather()
        updateNPCCount()
        checkMapExpansion()
        updateCityLevel()
    }

    // MARK: - デルタ加算（記録ボタン押下時）

    func addCP(axis: CPAxis, amount: Int) {
        syncTotalCP(totalCP + amount)
    }

    // MARK: - XP 配布（同軸建物に）

    private func distributeXP(_ delta: Int) {
        for building in registry.placed {
            let leveledUp = registry.addXP(to: building.id, amount: delta / 10 + 1)
            if leveledUp {
                scene?.onBuildingLevelUp(buildingId: building.id,
                                          newLevel: registry.placed.first(where: { $0.id == building.id })?.level ?? 1)
            }
        }
    }

    // MARK: - 歩数更新（HealthKit バックグラウンド）

    func updateStepCount(_ steps: Int) {
        npcCount = min(steps / 1000, 20)
        scene?.updateNPCCount(npcCount, totalCP: totalCP)
    }

    // MARK: - 時刻変化

    func updateTimeOfDay(_ hour: Int) {
        scene?.updateTimeOfDay(hour)
    }

    // MARK: - プレミアム解放（StoreKit2 検証後: CLAUDE.md Key Rule 3）

    func unlockPremium() {
        isPremium = true
        scene?.applyPremiumTheme()
    }

    // MARK: - 天気更新（CP → 天気: CLAUDE.md Key Rule 2）

    private func updateWeather() {
        let todayCP   = min(totalCP, 500)
        let newWeather = weatherForCP(todayCP)
        guard newWeather != currentWeather else { return }
        currentWeather = newWeather
        scene?.updateWeather(currentWeather)

        // 嵐の場合: スラム建物を出現させる可能性
        if currentWeather == .stormy && totalCP > 0 {
            let penaltyRoll = Int.random(in: 0..<10)
            if penaltyRoll == 0 {
                registry.spawnSlamBuilding(id: "B030")
                if let b = registry.placed.first(where: { $0.id == "B030" }) {
                    scene?.addBuilding(id: "B030", name: "廃墟ビル", axis: .lifestyle,
                                       gridX: b.gridX, gridY: b.gridY, level: 1)
                }
            }
        }
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

    // MARK: - NPC 更新

    private func updateNPCCount() {
        npcCount = min(totalCP / 50 + 1, 20)
        scene?.updateNPCCount(npcCount, totalCP: totalCP)
    }

    // MARK: - マップ拡張チェック（CLAUDE.md Key Rule 6）

    private func checkMapExpansion() {
        let newSize: MapSize
        switch totalCP {
        case 30_000...: newSize = .extraLarge
        case 15_000...: newSize = .large
        case 5_000...:  newSize = .medium
        default:        newSize = .small
        }
        guard newSize != mapSize else { return }
        mapSize = newSize
        registry.mapSize = newSize.rawValue
        scene?.expandMap(to: newSize)
    }

    // MARK: - 市レベル計算

    private func updateCityLevel() {
        cityLevel = switch totalCP {
        case 50_000...: 10
        case 30_000...: 9
        case 20_000...: 8
        case 15_000...: 7
        case 10_000...: 6
        case 5_000...:  5
        case 3_000...:  4
        case 1_500...:  3
        case 500...:    2
        default:        1
        }
    }
}

// MARK: - Supporting Types

enum WeatherType: String, Sendable, Equatable {
    case sunny        = "sunny"
    case partlyCloudy = "partlyCloudy"
    case cloudy       = "cloudy"
    case rainy        = "rainy"
    case stormy       = "stormy"

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
    case small      = 20
    case medium     = 30
    case large      = 40
    case extraLarge = 50

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
