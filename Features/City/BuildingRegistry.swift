// BuildingRegistry.swift
// Features/City/
//
// 建物配置状態の管理
// - CP 閾値に基づいた建物の自動解放
// - グリッド上の配置位置管理（衝突回避）
// - 建物の XP・レベルアップ管理
// CLAUDE.md Key Rule 4: 建設可能 28 種 + 自動生成 2 種

import Foundation

// MARK: - PlacedBuilding

struct PlacedBuilding: Identifiable, Codable {
    let id:          String    // "B001" etc.
    let name:        String
    let axis:        String    // CPAxis.rawValue 相当
    let gridX:       Int
    let gridY:       Int
    var level:       Int
    var xp:          Int
    var isPlaced:    Bool      // false = 解放済みだが未配置
}

// MARK: - BuildingRegistry

final class BuildingRegistry {

    // MARK: - State

    private(set) var placed:    [PlacedBuilding] = []  // 配置済み
    private(set) var unlocked:  [String] = []          // 解放済み（未配置含む）
    private var occupiedCells:  Set<String> = []       // "x,y" 形式で占有グリッドを管理

    // MARK: - マップ設定

    var mapSize: Int = 20  // 現在のマップサイズ（20/30/40/50）

    // MARK: - 初期化

    init() {
        // 市庁舎は最初から配置済み（CP 不要: CLAUDE.md B025）
        placeBuilding(id: "B025", at: (x: 10, y: 10))
    }

    // MARK: - CP に応じた建物解放チェック

    /// 新しく増えた累計 CP で解放できる建物があるか確認
    /// - Returns: 新たに解放された建物エントリの配列（CityScene で配置に使う）
    @discardableResult
    func checkUnlocks(totalCP: Int) -> [BuildingCatalogEntry] {
        var newlyUnlocked: [BuildingCatalogEntry] = []

        for entry in BuildingCatalog.all {
            guard !unlocked.contains(entry.id) else { continue }
            guard totalCP >= entry.requiredCP else { continue }
            unlocked.append(entry.id)
            let pos = findPlacementPosition(for: entry)
            placeBuilding(id: entry.id, at: pos, entry: entry)
            newlyUnlocked.append(entry)
        }

        // 過飲ペナルティ: 総 CP に対して飲酒軸 CP が極端に低いと B029/B030 が出現
        // → CityScene 側で alcoholCP を監視して呼び出す（ここでは解放のみ）

        return newlyUnlocked
    }

    /// スラム建物を出現させる（過飲ペナルティ: CLAUDE.md Key Rule 2）
    func spawnSlamBuilding(id: String) {
        guard !placed.contains(where: { $0.id == id }) else { return }
        let pos = findEdgePlacementPosition()
        let axis: String
        switch id {
        case "B029": axis = "alcohol"
        default:     axis = "lifestyle"
        }
        let entry = PlacedBuilding(
            id: id, name: id == "B029" ? "居酒屋" : "廃墟ビル",
            axis: axis, gridX: pos.x, gridY: pos.y,
            level: 1, xp: 0, isPlaced: true
        )
        placed.append(entry)
        occupiedCells.insert("\(pos.x),\(pos.y)")
    }

    /// 建物に XP を加算してレベルアップ判定
    @discardableResult
    func addXP(to buildingId: String, amount: Int) -> Bool {
        guard let idx = placed.firstIndex(where: { $0.id == buildingId }) else { return false }
        placed[idx].xp += amount
        let thresholds = [0, 500, 1500, 3000, 6000]
        let newLevel = min((thresholds.lastIndex { $0 <= placed[idx].xp } ?? 0) + 1, 5)
        if newLevel > placed[idx].level {
            placed[idx].level = newLevel
            return true  // レベルアップ
        }
        return false
    }

    // MARK: - 配置位置計算

    private func placeBuilding(id: String, at pos: (x: Int, y: Int), entry: BuildingCatalogEntry? = nil) {
        let e = entry ?? BuildingCatalog.all.first { $0.id == id }
        let building = PlacedBuilding(
            id:      id,
            name:    e?.name ?? id,
            axis:    axisKey(e?.axis),
            gridX:   pos.x,
            gridY:   pos.y,
            level:   1,
            xp:      0,
            isPlaced: true
        )
        placed.append(building)
        occupiedCells.insert("\(pos.x),\(pos.y)")
    }

    /// 軸・CP に基づいた配置位置をゾーン分けして返す
    private func findPlacementPosition(for entry: BuildingCatalogEntry) -> (x: Int, y: Int) {
        let center = mapSize / 2

        // 軸別にゾーンを定義（中心から各方向）
        let baseOffset: (x: Int, y: Int)
        switch entry.axis {
        case .exercise:  baseOffset = (x: -4, y: -4)   // 北西
        case .diet:      baseOffset = (x:  4, y: -4)   // 北東
        case .alcohol:   baseOffset = (x:  0, y:  0)   // 中央（中央広場に寄与: CLAUDE.md）
        case .sleep:     baseOffset = (x: -4, y:  4)   // 南西
        case .lifestyle: baseOffset = (x:  4, y:  4)   // 南東
        }

        // 既存建物と衝突しない空きセルを探索
        for radius in 0..<6 {
            for dx in -radius...radius {
                for dy in -radius...radius {
                    let x = center + baseOffset.x + dx
                    let y = center + baseOffset.y + dy
                    guard x > 0 && x < mapSize - 1 else { continue }
                    guard y > 0 && y < mapSize - 1 else { continue }
                    guard !occupiedCells.contains("\(x),\(y)") else { continue }
                    return (x: x, y: y)
                }
            }
        }
        return (x: Int.random(in: 2..<mapSize-2), y: Int.random(in: 2..<mapSize-2))
    }

    /// スラム建物はマップ端寄りに配置
    private func findEdgePlacementPosition() -> (x: Int, y: Int) {
        let edgePositions: [(Int, Int)] = [
            (1, 1), (mapSize-2, 1), (1, mapSize-2), (mapSize-2, mapSize-2),
            (2, 2), (mapSize-3, 2)
        ]
        for (x, y) in edgePositions {
            if !occupiedCells.contains("\(x),\(y)") { return (x: x, y: y) }
        }
        return (x: 1, y: 1)
    }

    private func axisKey(_ axis: CPAxis?) -> String {
        switch axis {
        case .exercise:  return "exercise"
        case .diet:      return "diet"
        case .alcohol:   return "alcohol"
        case .sleep:     return "sleep"
        case .lifestyle, .none: return "lifestyle"
        }
    }

    // MARK: - 道路生成（中心から各建物へ）

    /// 市庁舎から各建物への経路を「道路グリッド」として返す
    func roadCells() -> Set<String> {
        var roads: Set<String> = []
        let center = mapSize / 2

        // 十字の基本道路
        for i in 0..<mapSize {
            roads.insert("\(center),\(i)")
            roads.insert("\(i),\(center)")
        }
        return roads
    }
}
