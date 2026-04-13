// BuildingPlacementStore.swift
// Features/City/
//
// 建設済み建物リストを UserDefaults に永続化する
// - PlacedBuilding: 建物 ID・名前・軸・グリッド座標
// - seedIfNeeded: 初回起動時に市庁舎（B025）だけをシード
// - place: 建設完了後に追加

import Foundation

// MARK: - PlacedBuilding

struct PlacedBuilding: Codable, Equatable {
    let id:      String   // B001〜B028
    let name:    String
    let axisKey: String   // CPAxis.key
    let gridX:   Int
    let gridY:   Int

    var axis: CPAxis { CPAxis(key: axisKey) ?? .lifestyle }
}

// MARK: - CPAxis serialization

extension CPAxis {
    /// UserDefaults / JSON 保存用の文字列キー
    var key: String {
        switch self {
        case .exercise:  return "exercise"
        case .diet:      return "diet"
        case .alcohol:   return "alcohol"
        case .sleep:     return "sleep"
        case .lifestyle: return "lifestyle"
        }
    }

    init?(key: String) {
        switch key {
        case "exercise":  self = .exercise
        case "diet":      self = .diet
        case "alcohol":   self = .alcohol
        case "sleep":     self = .sleep
        case "lifestyle": self = .lifestyle
        default:          return nil
        }
    }
}

// MARK: - BuildingPlacementStore

/// 建設済み建物リストを UserDefaults に永続化するシングルトン
final class BuildingPlacementStore {

    static let shared = BuildingPlacementStore()
    private init() {}

    private let placedKey = "vita_placed_buildings_v1"
    private let seededKey = "vita_city_seeded_v1"

    // MARK: - Read / Write

    var placedBuildings: [PlacedBuilding] {
        get {
            guard let data = UserDefaults.standard.data(forKey: placedKey),
                  let list = try? JSONDecoder().decode([PlacedBuilding].self, from: data)
            else { return [] }
            return list
        }
        set {
            UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: placedKey)
        }
    }

    /// 建設済み ID のセット（O(1) ルックアップ）
    var builtIds: Set<String> { Set(placedBuildings.map(\.id)) }

    // MARK: - 初回シード（市庁舎のみ）

    /// 初回起動時のみ市庁舎（B025, requiredCP:0）をマップ中心に配置する
    func seedIfNeeded(cx: Int = 10, cy: Int = 10) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        placedBuildings = [
            PlacedBuilding(id: "B025", name: "市庁舎",
                           axisKey: CPAxis.lifestyle.key,
                           gridX: cx, gridY: cy)
        ]
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    // MARK: - 建設

    func place(_ building: PlacedBuilding) {
        var list = placedBuildings
        list.append(building)
        placedBuildings = list
    }
}
