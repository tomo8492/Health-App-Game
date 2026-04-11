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

    var totalCP:        Int    = 0
    var mapSize:        MapSize = .small   // 20×20
    var currentWeather: WeatherType = .sunny
    var selectedBuilding: BuildingInfo? = nil    // 建物タップで SwiftUI シートを表示
    var npcCount:       Int    = 0
    var isPremium:      Bool   = false
    var cityLevel:      Int    = 1         // 市庁舎レベル

    // MARK: - SpriteKit シーン参照（弱参照）

    weak var scene: CityScene?

    // MARK: - SwiftUI → SpriteKit イベント（CLAUDE.md Key Rule 9）

    /// 健康記録後に CP を加算しゲームを更新する
    /// - Parameters:
    ///   - axis:   更新する軸
    ///   - amount: 追加 CP 量
    func addCP(axis: CPAxis, amount: Int) {
        // 軸別 CP を totalCP に加算（飲酒も中央広場へ: CLAUDE.md Key Rule 2）
        totalCP = min(totalCP + amount, 999_999)
        scene?.onCPAdded(axis: axis, amount: amount)
        updateWeather()
        updateNPCCount()
        checkMapExpansion()
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

    /// AppState.todayTotalCP と絶対値で同期（RootView の onChange から呼ぶ）
    /// addCP は差分加算のため、AppState の絶対値と合わせるにはこちらを使う
    func syncTotalCP(_ cp: Int) {
        guard cp != totalCP else { return }
        let delta = cp - totalCP
        totalCP = min(cp, 999_999)
        if delta > 0 {
            scene?.onCPAdded(axis: .lifestyle, amount: delta)  // 全軸合算を中央広場に反映
        }
        updateWeather()
        updateNPCCount()
        checkMapExpansion()
    }

    // MARK: - 天気更新（CLAUDE.md Key Rule 2: CP→天気）

    private func updateWeather() {
        // 当日 CP（0〜500）から天気を決定
        let todayCP = min(totalCP % 500 == 0 ? 500 : totalCP % 500, 500)
        currentWeather = weatherForCP(todayCP)
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

    // MARK: - NPC 更新

    private func updateNPCCount() {
        npcCount = min(totalCP / 100 + 1, 20)
        scene?.updateNPCCount(npcCount)
    }

    // MARK: - マップ拡張チェック（CLAUDE.md Key Rule 6）

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
