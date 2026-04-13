// NPCNode.swift
// Features/City/
//
// NPC（住民）ノード — 四肢アニメーション付きキャラクター
// - 頭/胴/左右腕/左右脚 の独立ノードで歩行を表現
// - 左右脚が半周期ずれて交互に動くリアルなウォーキング
// - 腕は脚と逆位相でスウィング（カイロソフト風）
// - バリアント6種の衣装（色分け + 固有アクセサリー）
// - A* 経路探索 + SKAction でランダム経路移動（CLAUDE.md Key Rule 10）
// - CP 量で表情・透明度・ジャンプを制御

import SpriteKit

// MARK: - NPCVariant

enum NPCVariant: CaseIterable {
    case walker     // 一般市民（グレー）
    case runner     // ランナー（緑: 運動高 CP）
    case chef       // 料理人（オレンジ: 食事高 CP）
    case nurse      // 医療従事者（青: 睡眠高 CP）
    case activist   // 環境活動家（ピンク: 生活習慣高 CP）
    case drunk      // 飲み過ぎ（紫: ペナルティ）

    // 上半身（シャツ・制服）の色
    var bodyColor: UIColor {
        switch self {
        case .walker:   return UIColor(red: 0.80, green: 0.80, blue: 0.82, alpha: 1)
        case .runner:   return UIColor(red: 0.18, green: 0.76, blue: 0.34, alpha: 1)
        case .chef:     return UIColor(red: 1.00, green: 0.96, blue: 0.90, alpha: 1)
        case .nurse:    return UIColor(red: 0.72, green: 0.88, blue: 1.00, alpha: 1)
        case .activist: return UIColor(red: 1.00, green: 0.20, blue: 0.38, alpha: 1)
        case .drunk:    return UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1)
        }
    }

    // 下半身（パンツ・スカート）の色
    var legColor: UIColor {
        switch self {
        case .walker:   return UIColor(red: 0.22, green: 0.34, blue: 0.56, alpha: 1)  // ジーンズ
        case .runner:   return UIColor(red: 0.06, green: 0.26, blue: 0.80, alpha: 1)  // ランパン
        case .chef:     return UIColor(red: 0.88, green: 0.88, blue: 0.86, alpha: 1)  // 白パンツ
        case .nurse:    return UIColor(red: 0.88, green: 0.92, blue: 0.98, alpha: 1)  // 白ズボン
        case .activist: return UIColor(red: 0.22, green: 0.52, blue: 0.26, alpha: 1)  // カーキ
        case .drunk:    return UIColor(red: 0.48, green: 0.20, blue: 0.60, alpha: 1)  // 紫パン
        }
    }

    // 肌色（全バリアント共通）
    var skinColor: UIColor {
        UIColor(red: 0.96, green: 0.82, blue: 0.68, alpha: 1)
    }

    // 移動速度（秒/タイル）
    var moveSpeed: CGFloat {
        switch self {
        case .runner: return 0.18
        case .drunk:  return 0.50
        default:      return 0.28
        }
    }

    // 歩行アニメーションの半周期（秒）: moveSpeed の半分が自然
    var halfCycle: CGFloat { moveSpeed * 0.50 }
}

// MARK: - NPCNode

final class NPCNode: SKNode {

    // MARK: - State

    var gridX: Int
    var gridY: Int
    private var isMoving  = false
    private var parsedMap: ParsedMap?
    private let variant:  NPCVariant

    // MARK: - キャラクターパーツ（ストアドプロパティで事前初期化 → super.init() 前に使用可）

    private let shadowNode = SKShapeNode(ellipseOf: CGSize(width: 18, height: 6))
    private let leftLeg    = SKShapeNode(rectOf: CGSize(width: 4, height: 8),  cornerRadius: 1.5)
    private let rightLeg   = SKShapeNode(rectOf: CGSize(width: 4, height: 8),  cornerRadius: 1.5)
    private let bodyNode   = SKShapeNode(rectOf: CGSize(width: 11, height: 12), cornerRadius: 2.5)
    private let leftArm    = SKShapeNode(rectOf: CGSize(width: 3, height: 8),  cornerRadius: 1.0)
    private let rightArm   = SKShapeNode(rectOf: CGSize(width: 3, height: 8),  cornerRadius: 1.0)
    private let headNode   = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 4.0)

    // MARK: - Init

    init(gridX: Int, gridY: Int, variant: NPCVariant = .walker) {
        self.gridX   = gridX
        self.gridY   = gridY
        self.variant = variant
        super.init()
        setupCharacter()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - キャラクター構築

    private func setupCharacter() {
        setupShadow()
        setupLegs()
        setupBody()
        setupArms()
        setupHead()
        addVariantAccessory()
        startWalkAnimation()
    }

    // ── 影 ─────────────────────────────────────────────────────────────────

    private func setupShadow() {
        shadowNode.fillColor   = UIColor.black.withAlphaComponent(0.18)
        shadowNode.strokeColor = .clear
        shadowNode.position    = CGPoint(x: 0, y: -17)
        shadowNode.zPosition   = -1
        addChild(shadowNode)
    }

    // ── 脚（アニメーション対象）────────────────────────────────────────────

    private func setupLegs() {
        let color  = variant.legColor
        let stroke = UIColor.black.withAlphaComponent(0.18)

        leftLeg.fillColor   = color
        leftLeg.strokeColor = stroke
        leftLeg.lineWidth   = 0.5
        leftLeg.position    = CGPoint(x: -3, y: -12)  // 胴の下・左
        leftLeg.zPosition   = 0
        addChild(leftLeg)

        rightLeg.fillColor   = color
        rightLeg.strokeColor = stroke
        rightLeg.lineWidth   = 0.5
        rightLeg.position    = CGPoint(x: 3, y: -12)   // 胴の下・右
        rightLeg.zPosition   = 0
        addChild(rightLeg)
    }

    // ── 胴体 ───────────────────────────────────────────────────────────────

    private func setupBody() {
        bodyNode.fillColor   = variant.bodyColor
        bodyNode.strokeColor = UIColor.black.withAlphaComponent(0.15)
        bodyNode.lineWidth   = 0.5
        bodyNode.position    = CGPoint(x: 0, y: -2)
        bodyNode.zPosition   = 1
        addChild(bodyNode)
    }

    // ── 腕（アニメーション対象）────────────────────────────────────────────

    private func setupArms() {
        let color  = variant.bodyColor.darkened(0.08)
        let stroke = UIColor.black.withAlphaComponent(0.15)

        leftArm.fillColor   = color
        leftArm.strokeColor = stroke
        leftArm.lineWidth   = 0.5
        leftArm.position    = CGPoint(x: -8, y: -2)   // 胴の左側
        leftArm.zPosition   = 0.5
        addChild(leftArm)

        rightArm.fillColor   = color
        rightArm.strokeColor = stroke
        rightArm.lineWidth   = 0.5
        rightArm.position    = CGPoint(x: 8, y: -2)   // 胴の右側
        rightArm.zPosition   = 0.5
        addChild(rightArm)
    }

    // ── 頭 ─────────────────────────────────────────────────────────────────

    private func setupHead() {
        headNode.fillColor   = variant.skinColor
        headNode.strokeColor = UIColor(red: 0.78, green: 0.60, blue: 0.46, alpha: 0.8)
        headNode.lineWidth   = 0.5
        headNode.position    = CGPoint(x: 0, y: 9)
        headNode.zPosition   = 2
        addChild(headNode)
    }

    // MARK: - バリアント固有アクセサリー

    private func addVariantAccessory() {
        switch variant {

        case .runner:
            // 赤いヘッドバンド（頭上部）
            let band = SKShapeNode(rectOf: CGSize(width: 12, height: 3))
            band.fillColor   = UIColor(red: 0.95, green: 0.20, blue: 0.20, alpha: 1)
            band.strokeColor = .clear
            band.position    = CGPoint(x: 0, y: 14)
            band.zPosition   = 3
            addChild(band)

        case .chef:
            // コック帽（白い縦長の帽子）
            let brim = SKShapeNode(rectOf: CGSize(width: 13, height: 3))
            brim.fillColor   = .white
            brim.strokeColor = UIColor(white: 0.7, alpha: 0.5)
            brim.lineWidth   = 0.5
            brim.position    = CGPoint(x: 0, y: 14)
            brim.zPosition   = 3
            addChild(brim)

            let crown = SKShapeNode(rectOf: CGSize(width: 9, height: 8), cornerRadius: 1)
            crown.fillColor   = UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1)
            crown.strokeColor = UIColor(white: 0.7, alpha: 0.4)
            crown.lineWidth   = 0.5
            crown.position    = CGPoint(x: 0, y: 20)
            crown.zPosition   = 3
            addChild(crown)

            // 胸の赤ネクタイ
            let tie = SKShapeNode(rectOf: CGSize(width: 2, height: 6))
            tie.fillColor   = UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)
            tie.strokeColor = .clear
            tie.position    = CGPoint(x: 0, y: -1)
            tie.zPosition   = 2
            addChild(tie)

        case .nurse:
            // 胸の赤い十字マーク（縦棒 + 横棒）
            let vbar = SKShapeNode(rectOf: CGSize(width: 3, height: 7))
            vbar.fillColor   = UIColor(red: 0.90, green: 0.10, blue: 0.10, alpha: 1)
            vbar.strokeColor = .clear
            vbar.position    = CGPoint(x: 0, y: -2)
            vbar.zPosition   = 2
            addChild(vbar)

            let hbar = SKShapeNode(rectOf: CGSize(width: 7, height: 3))
            hbar.fillColor   = UIColor(red: 0.90, green: 0.10, blue: 0.10, alpha: 1)
            hbar.strokeColor = .clear
            hbar.position    = CGPoint(x: 0, y: -2)
            hbar.zPosition   = 2
            addChild(hbar)

            // ナースキャップ
            let cap = SKShapeNode(rectOf: CGSize(width: 11, height: 4), cornerRadius: 1)
            cap.fillColor   = UIColor.white
            cap.strokeColor = UIColor(white: 0.7, alpha: 0.4)
            cap.lineWidth   = 0.5
            cap.position    = CGPoint(x: 0, y: 14)
            cap.zPosition   = 3
            addChild(cap)

        case .activist:
            // 緑の旗（楕円）
            let flag = SKShapeNode(ellipseOf: CGSize(width: 7, height: 5))
            flag.fillColor   = UIColor(red: 0.20, green: 0.72, blue: 0.28, alpha: 1)
            flag.strokeColor = .clear
            flag.position    = CGPoint(x: 9, y: 6)
            flag.zPosition   = 2
            addChild(flag)

            // 旗竿
            let pole = SKShapeNode(rectOf: CGSize(width: 1, height: 14))
            pole.fillColor   = UIColor(red: 0.60, green: 0.40, blue: 0.20, alpha: 1)
            pole.strokeColor = .clear
            pole.position    = CGPoint(x: 9, y: 0)
            pole.zPosition   = 1.5
            addChild(pole)

        case .drunk:
            // 「？」吹き出し
            let bubble = SKLabelNode(text: "？")
            bubble.fontName  = "Helvetica-Bold"
            bubble.fontSize  = 9
            bubble.fontColor = UIColor(red: 0.7, green: 0.2, blue: 0.9, alpha: 1)
            bubble.position  = CGPoint(x: 9, y: 17)
            bubble.zPosition = 3
            addChild(bubble)

            // 酩酊状態: 顔を少し赤みがかりに
            headNode.fillColor = UIColor(red: 1.00, green: 0.76, blue: 0.68, alpha: 1)

        case .walker:
            break
        }
    }

    // MARK: - 歩行アニメーション

    private func startWalkAnimation() {
        let half = variant.halfCycle

        // ── 脚: 左右交互に前後ステップ ──────────────────────────────────────
        // 1サイクル = 前へ (+3pt) → 戻る (-3pt) → 後ろへ (-3pt) → 戻る (+3pt)
        // 右脚は左脚から半サイクル(2 * half)遅れてスタート

        let leftLegCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y:  3, duration: half),   // 前へ
            SKAction.moveBy(x: 0, y: -3, duration: half),   // 中立
            SKAction.moveBy(x: 0, y: -3, duration: half),   // 後ろへ
            SKAction.moveBy(x: 0, y:  3, duration: half),   // 中立
        ]))
        leftLeg.run(leftLegCycle, withKey: "walk")

        // 右脚: 2 half 遅延で位相をずらす
        let rightLegStart = SKAction.sequence([
            SKAction.wait(forDuration: half * 2),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y:  3, duration: half),
                SKAction.moveBy(x: 0, y: -3, duration: half),
                SKAction.moveBy(x: 0, y: -3, duration: half),
                SKAction.moveBy(x: 0, y:  3, duration: half),
            ])),
        ])
        rightLeg.run(rightLegStart, withKey: "walk")

        // ── 腕: 脚と逆位相でスウィング ──────────────────────────────────────
        // 腕は脚と逆（左腕が前なら左脚は後ろ） → 2 half 遅延で腕を開始

        let leftArmCycle = SKAction.sequence([
            SKAction.wait(forDuration: half * 2),   // 脚と逆位相
            SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y:  2, duration: half * 2),
                SKAction.moveBy(x: 0, y: -2, duration: half * 2),
            ])),
        ])
        leftArm.run(leftArmCycle, withKey: "swing")

        let rightArmCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y:  2, duration: half * 2),
            SKAction.moveBy(x: 0, y: -2, duration: half * 2),
        ]))
        rightArm.run(rightArmCycle, withKey: "swing")

        // ── 胴体: 微細な左右揺れ（歩行感） ───────────────────────────────────
        if variant == .drunk {
            // 酔っ払い: 大きく揺れる
            let stagger = SKAction.repeatForever(SKAction.sequence([
                SKAction.rotate(byAngle:  0.18, duration: 0.28),
                SKAction.rotate(byAngle: -0.18, duration: 0.28),
            ]))
            bodyNode.run(stagger, withKey: "stagger")
            run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 2, y: 0, duration: 0.32),
                SKAction.moveBy(x: -2, y: 0, duration: 0.32),
            ])), withKey: "sway")
        } else {
            let rock = SKAction.repeatForever(SKAction.sequence([
                SKAction.rotate(byAngle:  0.04, duration: half * 2),
                SKAction.rotate(byAngle: -0.04, duration: half * 2),
            ]))
            bodyNode.run(rock, withKey: "rock")
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
        let stepDuration = Double(variant.moveSpeed)

        let moveActions: [SKAction] = path.dropFirst().map { point in
            let screenPos = TiledMapParser.isoToScreen(
                x: point.x, y: point.y,
                tileWidth:  CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
            let flip = SKAction.run { [weak self] in
                guard let self else { return }
                let dx = point.x - self.gridX
                if dx > 0 { self.xScale =  1 }
                if dx < 0 { self.xScale = -1 }
                self.gridX    = point.x
                self.gridY    = point.y
                self.zPosition = CGFloat(point.x + point.y) + 5
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
        let targetAlpha: CGFloat = cpLevel > 200 ? 1.0 : (cpLevel > 100 ? 0.82 : 0.55)
        run(SKAction.fadeAlpha(to: targetAlpha, duration: 0.5))

        if cpLevel >= 400 {
            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 0.18),
                SKAction.moveBy(x: 0, y: -8, duration: 0.18),
            ])
            run(bounce)
        }
    }
}

// MARK: - NPCFactory

enum NPCFactory {

    static func variant(for totalCP: Int, index: Int) -> NPCVariant {
        if totalCP < 50  { return index % 3 == 0 ? .drunk : .walker }
        if totalCP < 200 { return [.walker, .walker, .chef][index % 3] }
        if totalCP < 400 { return [.walker, .runner, .chef, .nurse][index % 4] }
        return NPCVariant.allCases[index % NPCVariant.allCases.count]
    }
}

// MARK: - UIColor ヘルパー（NPCNode 専用）

private extension UIColor {
    func darkened(_ amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(0, b - amount), alpha: a)
    }
}
