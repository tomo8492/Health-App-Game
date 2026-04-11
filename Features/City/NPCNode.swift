// NPCNode.swift
// Features/City/
//
// NPC（住民）ノード
// - プログラムで生成したドット絵スプライト（PNG アセット不要）
// - A* 経路探索 + SKAction でランダム経路移動（CLAUDE.md Key Rule 10）
// - CP 量で表情・色・スポーン数を制御

import SpriteKit

// MARK: - NPCVariant（NPC の種類）

enum NPCVariant: CaseIterable {
    case walker    // 一般市民（灰色）
    case runner    // ランナー（緑: 運動高 CP）
    case chef      // 料理人（オレンジ: 食事高 CP）
    case nurse     // 医療従事者（青: 睡眠高 CP）
    case activist  // 環境活動家（ピンク: 生活習慣高 CP）
    case drunk     // 飲み過ぎ市民（紫: ペナルティ）

    var bodyColor: UIColor {
        switch self {
        case .walker:   return UIColor(white: 0.85, alpha: 1)
        case .runner:   return UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        case .chef:     return UIColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1)
        case .nurse:    return UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
        case .activist: return UIColor(red: 1.00, green: 0.18, blue: 0.33, alpha: 1)
        case .drunk:    return UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1)
        }
    }

    var headColor: UIColor {
        UIColor(red: 0.95, green: 0.80, blue: 0.65, alpha: 1)  // 肌色
    }

    var moveSpeed: CGFloat {
        switch self {
        case .runner: return 0.18
        case .drunk:  return 0.55
        default:      return 0.30
        }
    }
}

// MARK: - NPCNode

final class NPCNode: SKNode {

    // MARK: - Properties

    var gridX: Int
    var gridY: Int
    private var isMoving = false
    private weak var parsedMap: ParsedMap?
    private let variant: NPCVariant

    // パーツノード
    private let headNode = SKShapeNode(circleOfRadius: 5)
    private let bodyNode = SKShapeNode(rectOf: CGSize(width: 8, height: 10))
    private let shadow   = SKShapeNode(ellipseOf: CGSize(width: 12, height: 4))

    // MARK: - Init

    init(gridX: Int, gridY: Int, variant: NPCVariant = .walker) {
        self.gridX   = gridX
        self.gridY   = gridY
        self.variant = variant
        super.init()
        setupSprite()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - スプライト構築

    private func setupSprite() {
        // 影
        shadow.fillColor   = UIColor.black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position    = CGPoint(x: 0, y: -6)
        shadow.zPosition   = -1
        addChild(shadow)

        // ボディ
        bodyNode.fillColor   = variant.bodyColor
        bodyNode.strokeColor = variant.bodyColor.withAlphaComponent(0.5)
        bodyNode.lineWidth   = 0.5
        bodyNode.position    = CGPoint(x: 0, y: 2)
        addChild(bodyNode)

        // 頭
        headNode.fillColor   = variant.headColor
        headNode.strokeColor = UIColor(red: 0.8, green: 0.65, blue: 0.5, alpha: 1)
        headNode.lineWidth   = 0.5
        headNode.position    = CGPoint(x: 0, y: 12)
        addChild(headNode)

        // バリアント固有の装飾
        addVariantDecoration()

        // 歩行アニメーション（左右の揺れ）
        startWalkAnimation()
    }

    private func addVariantDecoration() {
        switch variant {
        case .runner:
            // ヘッドバンド
            let band = SKShapeNode(rectOf: CGSize(width: 12, height: 3))
            band.fillColor   = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1)
            band.strokeColor = .clear
            band.position    = CGPoint(x: 0, y: 14)
            addChild(band)

        case .chef:
            // コック帽
            let hat = SKShapeNode(rectOf: CGSize(width: 10, height: 8))
            hat.fillColor   = .white
            hat.strokeColor = UIColor(white: 0.7, alpha: 1)
            hat.lineWidth   = 0.5
            hat.position    = CGPoint(x: 0, y: 20)
            addChild(hat)

        case .nurse:
            // 十字マーク
            let cross = SKSpriteNode(color: UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1),
                                     size: CGSize(width: 4, height: 8))
            cross.position = CGPoint(x: 0, y: 2)
            addChild(cross)

        case .activist:
            // 旗（葉）
            let flag = SKShapeNode(ellipseOf: CGSize(width: 8, height: 6))
            flag.fillColor   = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1)
            flag.strokeColor = .clear
            flag.position    = CGPoint(x: 7, y: 8)
            addChild(flag)

        case .drunk:
            // 揺れるエフェクト（上部に「?」吹き出し）
            let bubble = SKLabelNode(text: "？")
            bubble.fontSize = 8
            bubble.position = CGPoint(x: 8, y: 18)
            addChild(bubble)

        case .walker:
            break  // 装飾なし
        }
    }

    private func startWalkAnimation() {
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle:  0.08, duration: variant.moveSpeed),
            SKAction.rotate(byAngle: -0.08, duration: variant.moveSpeed),
        ])
        bodyNode.run(SKAction.repeatForever(sway), withKey: "walk")

        if variant == .drunk {
            // 酔っ払いは大きく揺れる
            let stagger = SKAction.sequence([
                SKAction.moveBy(x: 2, y: 0, duration: 0.3),
                SKAction.moveBy(x: -2, y: 0, duration: 0.3),
            ])
            run(SKAction.repeatForever(stagger), withKey: "stagger")
        }
    }

    // MARK: - 移動（A* 経路探索）

    func startWandering(map: ParsedMap) {
        self.parsedMap = map
        scheduleNextMove()
    }

    private func scheduleNextMove() {
        let delay = Double.random(in: 1.5...4.0)
        run(SKAction.wait(forDuration: delay)) { [weak self] in
            self?.moveToRandomDestination()
        }
    }

    private func moveToRandomDestination() {
        guard let map = parsedMap, !isMoving else { return }

        let goalX = Int.random(in: 0..<map.width)
        let goalY = Int.random(in: 0..<map.height)
        guard map.isWalkable(at: goalX, y: goalY) else {
            scheduleNextMove()
            return
        }

        guard let path = NPCPathfinder.findPath(
            from: (x: gridX, y: gridY),
            to:   (x: goalX, y: goalY),
            map:  map
        ), path.count > 1 else {
            scheduleNextMove()
            return
        }

        isMoving = true
        let stepDuration = variant == .runner ? 0.18 : 0.30

        let moveActions: [SKAction] = path.dropFirst().map { point in
            let screenPos = TiledMapParser.isoToScreen(
                x: point.x, y: point.y,
                tileWidth:  CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
            // 向きに応じてスプライトを反転
            let flip = SKAction.run { [weak self] in
                let dx = point.x - (self?.gridX ?? point.x)
                if dx > 0 { self?.xScale =  1 }
                if dx < 0 { self?.xScale = -1 }
                self?.gridX = point.x
                self?.gridY = point.y
                // Z ポジション更新（アイソメトリック奥行き）
                self?.zPosition = CGFloat(point.x + point.y) + 5
            }
            return SKAction.sequence([
                SKAction.move(to: screenPos, duration: stepDuration),
                flip,
            ])
        }

        run(
            SKAction.sequence(moveActions + [SKAction.run { [weak self] in
                self?.isMoving = false
                self?.scheduleNextMove()
            }]),
            withKey: "move"
        )
    }

    // MARK: - CP レベルに応じた外見変化

    func setMood(cpLevel: Int) {
        let targetAlpha: CGFloat = cpLevel > 200 ? 1.0 : (cpLevel > 100 ? 0.8 : 0.55)
        run(SKAction.fadeAlpha(to: targetAlpha, duration: 0.5))

        // 高 CP → 軽くジャンプ
        if cpLevel >= 400 {
            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 6, duration: 0.2),
                SKAction.moveBy(x: 0, y: -6, duration: 0.2),
            ])
            run(bounce)
        }
    }
}

// MARK: - NPCFactory

enum NPCFactory {

    /// 総 CP に応じた NPC バリアントを返す
    static func variant(for totalCP: Int, index: Int) -> NPCVariant {
        if totalCP < 50  { return index % 3 == 0 ? .drunk : .walker }
        if totalCP < 200 { return [.walker, .walker, .chef][index % 3] }
        if totalCP < 400 { return [.walker, .runner, .chef, .nurse][index % 4] }
        return NPCVariant.allCases[index % NPCVariant.allCases.count]
    }
}
