// NPCNode.swift
// Features/City/
//
// NPC（住民）ノード
// - A* 経路探索 + SKAction でランダム経路移動（CLAUDE.md Key Rule 10）
// - CP 量でスポーン数を制御

import SpriteKit

final class NPCNode: SKSpriteNode {

    // MARK: - Properties

    var gridX: Int
    var gridY: Int
    private var isMoving = false
    private weak var map: ParsedMap?

    // MARK: - Init

    init(gridX: Int, gridY: Int) {
        self.gridX = gridX
        self.gridY = gridY
        // テクスチャは Phase 2 でドット絵アセット追加後に設定
        // 暫定: 丸いプレースホルダー
        super.init(texture: nil, color: UIColor(white: 0.9, alpha: 0.9),
                   size: CGSize(width: 16, height: 20))
        self.name = "npc_\(Int.random(in: 1000...9999))"
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - 移動（A* 経路探索）

    func startWandering(map: ParsedMap) {
        self.map = map
        scheduleNextMove()
    }

    private func scheduleNextMove() {
        let delay = Double.random(in: 1.0...3.0)
        run(SKAction.wait(forDuration: delay)) { [weak self] in
            self?.moveToRandomDestination()
        }
    }

    private func moveToRandomDestination() {
        guard let map, !isMoving else { return }

        // ランダムな目標地点を選択
        let goalX = Int.random(in: 0..<map.width)
        let goalY = Int.random(in: 0..<map.height)
        guard map.isWalkable(at: goalX, y: goalY) else {
            scheduleNextMove()
            return
        }

        // A* で経路を計算（CLAUDE.md Key Rule 10）
        guard let path = NPCPathfinder.findPath(
            from: (x: gridX, y: gridY),
            to:   (x: goalX, y: goalY),
            map:  map
        ), path.count > 1 else {
            scheduleNextMove()
            return
        }

        // SKAction で経路を移動
        isMoving = true
        let moveActions = path.dropFirst().map { point -> SKAction in
            let screenPos = TiledMapParser.isoToScreen(
                x: point.x, y: point.y,
                tileWidth:  CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
            return SKAction.sequence([
                SKAction.move(to: screenPos, duration: 0.3),
                SKAction.run { [weak self] in
                    self?.gridX = point.x
                    self?.gridY = point.y
                }
            ])
        }

        let sequence = SKAction.sequence(moveActions + [
            SKAction.run { [weak self] in
                self?.isMoving = false
                self?.scheduleNextMove()
            }
        ])
        run(sequence, withKey: "move")
    }

    // MARK: - 表情アニメーション（CP が高いと活発）

    func setMood(cpLevel: Int) {
        let alpha: CGFloat = cpLevel > 200 ? 1.0 : 0.6
        run(SKAction.fadeAlpha(to: alpha, duration: 0.5))
    }
}
