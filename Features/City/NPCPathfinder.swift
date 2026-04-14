// NPCPathfinder.swift
// Features/City/
//
// CLAUDE.md Key Rule 10:
//   - A* ベースの簡易経路探索を Swift で自前実装（既製ライブラリ不使用）
//   - 建物タイルは isWalkable: Bool で通行不可判定

import Foundation

// MARK: - A* Node

private struct AStarNode: Hashable {
    let x: Int
    let y: Int
    var g: Int    // スタートからのコスト
    var h: Int    // ゴールまでの推定コスト（マンハッタン距離）
    var f: Int { g + h }
    // parent は再帰的 struct になるため別途 parentMap で管理

    func hash(into hasher: inout Hasher) {
        hasher.combine(x); hasher.combine(y)
    }
    static func == (lhs: AStarNode, rhs: AStarNode) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// MARK: - NPCPathfinder

enum NPCPathfinder {

    /// A* 経路探索
    /// - Parameters:
    ///   - start: 開始グリッド座標
    ///   - goal:  目標グリッド座標
    ///   - map:   通行可否マップ
    /// - Returns: 経路のグリッド座標配列（start → goal の順）。経路なしの場合は nil
    static func findPath(
        from start: (x: Int, y: Int),
        to goal:    (x: Int, y: Int),
        map:        ParsedMap
    ) -> [(x: Int, y: Int)]? {

        var openList:   [AStarNode] = []
        var closedSet:  Set<AStarNode> = []
        var parentMap:  [AStarNode: AStarNode] = [:]  // 再帰 struct を避けるため親を別管理

        let startNode = AStarNode(x: start.x, y: start.y,
                                  g: 0, h: manhattan(start, goal))
        openList.append(startNode)

        while !openList.isEmpty {
            // f 値最小のノードを選択
            let currentIdx  = openList.indices.min(by: { openList[$0].f < openList[$1].f })!
            let current     = openList.remove(at: currentIdx)

            if current.x == goal.x && current.y == goal.y {
                return reconstructPath(current, parentMap: parentMap)
            }

            closedSet.insert(current)

            for neighbor in neighbors(of: current, map: map) {
                guard !closedSet.contains(neighbor) else { continue }
                let tentativeG = current.g + 1
                if let existingIdx = openList.firstIndex(of: neighbor) {
                    if tentativeG < openList[existingIdx].g {
                        openList[existingIdx].g = tentativeG
                        parentMap[openList[existingIdx]] = current
                    }
                } else {
                    var newNode = neighbor
                    newNode.g = tentativeG
                    newNode.h = manhattan((neighbor.x, neighbor.y), goal)
                    parentMap[newNode] = current
                    openList.append(newNode)
                }
            }
        }
        return nil  // 経路なし
    }

    // MARK: - Helpers

    private static func neighbors(of node: AStarNode, map: ParsedMap) -> [AStarNode] {
        let dirs = [(0, 1), (0, -1), (1, 0), (-1, 0)]  // 上下左右
        return dirs.compactMap { (dx, dy) in
            let nx = node.x + dx
            let ny = node.y + dy
            guard map.isWalkable(at: nx, y: ny) else { return nil }
            return AStarNode(x: nx, y: ny, g: 0, h: 0)
        }
    }

    private static func manhattan(_ a: (x: Int, y: Int), _ b: (x: Int, y: Int)) -> Int {
        abs(a.x - b.x) + abs(a.y - b.y)
    }

    private static func reconstructPath(_ node: AStarNode, parentMap: [AStarNode: AStarNode]) -> [(x: Int, y: Int)] {
        var path: [(x: Int, y: Int)] = []
        var current: AStarNode? = node
        while let c = current {
            path.append((x: c.x, y: c.y))
            current = parentMap[c]
        }
        return path.reversed()
    }
}
