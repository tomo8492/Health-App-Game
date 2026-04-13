// NPCNode.swift
// Features/City/
//
// NPC（住民）ノード
// - PixelArtRenderer によるドット絵スプライト（参考画像2 のアドベンチャラー含む）
// - A* 経路探索 + SKAction でランダム経路移動（CLAUDE.md Key Rule 10）
// - CP 量でスポーン数・活発度を制御
// - 歩行フレームアニメーション（4フレームサイクル）

import SpriteKit

final class NPCNode: SKSpriteNode {

    // MARK: - Properties

    var gridX: Int
    var gridY: Int
    let npcType: NPCType

    private var isMoving = false
    private var walkFrame = 0
    private var currentMap: ParsedMap?

    // ドット絵サイズ（8col×14row × 3px）
    private static let spriteSize = CGSize(width: 24, height: 42)

    // MARK: - Init

    init(gridX: Int, gridY: Int, type: NPCType? = nil) {
        self.gridX   = gridX
        self.gridY   = gridY
        self.npcType = type ?? NPCType.allCases.randomElement() ?? .adventurer

        let tex = PixelArtRenderer.npcTexture(type: self.npcType, walkFrame: 0)
        super.init(texture: tex, color: .clear, size: NPCNode.spriteSize)

        // 足元を基準にアンカー設定
        self.anchorPoint = CGPoint(x: 0.5, y: 0.1)
        self.name = "npc_\(Int.random(in: 1000...9999))"
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - 移動開始

    func startWandering(map: ParsedMap) {
        self.currentMap = map
        startIdleAnimation()
        scheduleNextMove()
    }

    // MARK: - アイドルアニメーション（上下ゆらぎ）

    private func startIdleAnimation() {
        let up   = SKAction.moveBy(x: 0, y: 1.5, duration: 0.9)
        let down = SKAction.moveBy(x: 0, y: -1.5, duration: 0.9)
        up.timingMode   = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "idle")
    }

    // MARK: - 移動スケジュール

    private func scheduleNextMove() {
        let delay = Double.random(in: 1.5...4.0)
        run(SKAction.wait(forDuration: delay)) { [weak self] in
            self?.moveToRandomDestination()
        }
    }

    private func moveToRandomDestination() {
        guard let map = currentMap, !isMoving else { return }

        let goalX = Int.random(in: 0..<map.width)
        let goalY = Int.random(in: 0..<map.height)
        guard map.isWalkable(at: goalX, y: goalY) else { scheduleNextMove(); return }

        guard let path = NPCPathfinder.findPath(
            from: (x: gridX, y: gridY),
            to:   (x: goalX, y: goalY),
            map:  map
        ), path.count > 1 else { scheduleNextMove(); return }

        isMoving = true
        removeAction(forKey: "idle")

        // フレームアニメーション付き移動
        let moveActions: [SKAction] = path.dropFirst().map { point -> SKAction in
            let screenPos = TiledMapParser.isoToScreen(
                x: point.x, y: point.y,
                tileWidth:  CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
            return SKAction.sequence([
                SKAction.run { [weak self] in self?.advanceWalkFrame() },
                SKAction.move(to: screenPos, duration: 0.28),
                SKAction.run { [weak self] in
                    self?.gridX = point.x
                    self?.gridY = point.y
                    // Z ソート更新
                    self?.zPosition = CGFloat(point.x + point.y) * 0.1 + 0.05
                }
            ])
        }

        let seq = SKAction.sequence(moveActions + [
            SKAction.run { [weak self] in
                self?.isMoving = false
                self?.walkFrame = 0
                self?.updateTexture(frame: 0)
                self?.startIdleAnimation()
                self?.scheduleNextMove()
            }
        ])
        run(seq, withKey: "move")
    }

    // MARK: - ウォークフレーム更新

    private func advanceWalkFrame() {
        walkFrame = (walkFrame + 1) % 4
        updateTexture(frame: walkFrame)
    }

    private func updateTexture(frame: Int) {
        texture = PixelArtRenderer.npcTexture(type: npcType, walkFrame: frame)
    }

    // MARK: - CP レベルで表情変化

    func setMood(cpLevel: Int) {
        let targetAlpha: CGFloat = cpLevel > 200 ? 1.0 : cpLevel > 100 ? 0.8 : 0.6
        run(SKAction.fadeAlpha(to: targetAlpha, duration: 0.5))
        // 活発度: 高 CP で歩行速度 UP + エモート表示
        if cpLevel > 300 {
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])
            run(SKAction.repeatForever(pulse), withKey: "pulse")
            // 8% の確率でエモートを表示
            if Int.random(in: 0..<12) == 0 {
                let emotes = ["♪", "★", "♡", "!"]
                showEmote(emotes.randomElement() ?? "♪")
            }
        } else {
            removeAction(forKey: "pulse")
            run(SKAction.scale(to: 1.0, duration: 0.2))
        }
    }

    // MARK: - エモート吹き出し

    /// NPC の頭上に小さなエモートバブルを表示する（1.5s 後にフェードアウト）
    func showEmote(_ symbol: String) {
        // 二重表示防止
        guard childNode(withName: "emote") == nil else { return }

        // 背景円
        let bg = SKShapeNode(circleOfRadius: 9)
        bg.fillColor   = .white
        bg.strokeColor = UIColor(white: 0.65, alpha: 0.9)
        bg.lineWidth   = 0.6
        bg.position    = CGPoint(x: 0, y: 38)   // NPC 頭上
        bg.zPosition   = 200
        bg.name        = "emote"
        bg.alpha       = 0
        addChild(bg)

        // シンボルラベル
        let label = SKLabelNode(text: symbol)
        label.fontSize                  = 11
        label.fontName                  = "Helvetica-Bold"
        label.verticalAlignmentMode     = .center
        label.horizontalAlignmentMode   = .center
        bg.addChild(label)

        // アニメーション: フェードイン → ホールド → 上昇しながらフェードアウト
        bg.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.wait(forDuration: 1.2),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 8, duration: 0.45),
                SKAction.fadeOut(withDuration: 0.45)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
