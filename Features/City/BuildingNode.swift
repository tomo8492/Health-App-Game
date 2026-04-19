// BuildingNode.swift
// Features/City/
//
// アイソメトリック建物ノード（SpriteKit）
// - PixelArtRenderer による 3D ドット絵テクスチャ（参考画像1 のカイロソフト風）
// - レベルに応じたテクスチャ切り替え（Lv1〜Lv5）
// - タップ検出 → CitySceneCoordinator.selectedBuilding へ通知
// - 奥行き Z ポジション管理（isometric depth sort）

import SpriteKit

// MARK: - BuildingNode

final class BuildingNode: SKSpriteNode {

    // MARK: - Properties

    let buildingId:   String
    let buildingName: String
    let axis:         CPAxis
    private(set) var level: Int = 1
    private(set) var xp:    Int = 0
    let gridX: Int
    let gridY: Int

    // XP 閾値（Lv1→2: 500, 2→3: 1500, 3→4: 3000, 4→5: 6000）
    static let xpThresholds = [0, 500, 1500, 3000, 6000]

    // MARK: - Init

    init(
        buildingId:   String,
        buildingName: String,
        axis:         CPAxis,
        gridX:        Int,
        gridY:        Int,
        level:        Int = 1
    ) {
        self.buildingId   = buildingId
        self.buildingName = buildingName
        self.axis         = axis
        self.gridX        = gridX
        self.gridY        = gridY
        self.level        = level

        let tex = PixelArtRenderer.buildingTexture(id: buildingId, level: level)
        let spriteSize = PixelArtRenderer.buildingSpriteSize(id: buildingId, level: level)

        super.init(texture: tex, color: .clear, size: spriteSize)

        self.anchorPoint = CGPoint(
            x: 0.5,
            y: PixelArtRenderer.buildingAnchorY(id: buildingId, level: level)
        )

        self.isUserInteractionEnabled = true
        updateZPosition()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Level Up

    func addXP(_ amount: Int) {
        xp += amount
        let nextLevel = (BuildingNode.xpThresholds.lastIndex { $0 <= xp } ?? 0) + 1
        if nextLevel > level {
            level = min(nextLevel, 5)
            onLevelUp()
        }
    }

    private func onLevelUp() {
        let newTex = PixelArtRenderer.buildingTexture(id: buildingId, level: level)
        self.texture = newTex
        self.size = PixelArtRenderer.buildingSpriteSize(id: buildingId, level: level)
        self.anchorPoint = CGPoint(
            x: 0.5,
            y: PixelArtRenderer.buildingAnchorY(id: buildingId, level: level)
        )

        // レベルアップエフェクト（より大きく・長く）
        let scaleUp1   = SKAction.scale(to: 1.35, duration: 0.18)
        let scaleDown1 = SKAction.scale(to: 0.95, duration: 0.10)
        let scaleUp2   = SKAction.scale(to: 1.10, duration: 0.10)
        let scaleDown2 = SKAction.scale(to: 1.0,  duration: 0.10)
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.10),
            SKAction.colorize(with: axis.skColor, colorBlendFactor: 0.4, duration: 0.18),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.20)
        ])
        run(SKAction.group([
            SKAction.sequence([scaleUp1, scaleDown1, scaleUp2, scaleDown2]),
            flash
        ]))

        // 金色スパークルバースト＋軸色のリングパルス（建物足元から放射）
        if let scene = scene {
            SpriteEffects.spawnRingPulse(
                at: position, in: scene,
                color: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1),
                startSize: 28, endSize: 110, ringCount: 2,
                zPosition: zPosition + 0.4, duration: 0.7
            )
            SpriteEffects.spawnSparkleBurst(
                at: CGPoint(x: position.x, y: position.y + size.height * 0.4),
                in: scene,
                color: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1),
                count: 14, radius: 60,
                zPosition: zPosition + 0.5
            )
            SpriteEffects.spawnSparkleBurst(
                at: CGPoint(x: position.x, y: position.y + size.height * 0.4),
                in: scene,
                color: axis.skColor,
                count: 8, radius: 36,
                zPosition: zPosition + 0.5
            )
        }
        HapticEngine.levelUpBurst()

        // LvUP ラベル（影付き・大きく）
        let lvLabel = SKLabelNode(text: "Lv.\(level)  UP!")
        lvLabel.fontName  = "AvenirNext-Heavy"
        lvLabel.fontSize  = 16
        lvLabel.fontColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        lvLabel.position  = CGPoint(x: 0, y: size.height * 0.5 + 8)
        lvLabel.zPosition = 500
        lvLabel.alpha = 0
        lvLabel.setScale(0.5)
        addChild(lvLabel)
        let shadow = SKLabelNode(text: "Lv.\(level)  UP!")
        shadow.fontName  = "AvenirNext-Heavy"
        shadow.fontSize  = 16
        shadow.fontColor = UIColor.black.withAlphaComponent(0.55)
        shadow.position  = CGPoint(x: 1, y: -1)
        lvLabel.insertChild(shadow, at: 0)

        lvLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.12),
                SKAction.scale(to: 1.0, duration: 0.18)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 28, duration: 0.95),
                SKAction.sequence([SKAction.wait(forDuration: 0.55),
                                   SKAction.fadeOut(withDuration: 0.4)])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - アイドルアニメーション

    func playIdleAnimation() {
        // B025（市庁舎）は旗揺れアニメーション、それ以外は上下ゆらぎ
        if let frames = PixelArtRenderer.buildingAnimationTextures(id: buildingId, level: level) {
            let anim = SKAction.animate(with: frames, timePerFrame: 0.35, resize: false, restore: false)
            run(SKAction.repeatForever(anim), withKey: "idle")
        } else {
            let bobUp   = SKAction.moveBy(x: 0, y: 1.5, duration: 1.4)
            let bobDown = SKAction.moveBy(x: 0, y: -1.5, duration: 1.4)
            bobUp.timingMode   = .easeInEaseOut
            bobDown.timingMode = .easeInEaseOut
            run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "idle")
        }
    }

    func highlightBuildingZone() {
        // より長く・派手に：白フラッシュ + 軸色チント + スケールパンチ
        let flash = SKAction.sequence([
            SKAction.colorize(with: UIColor.white, colorBlendFactor: 0.6, duration: 0.10),
            SKAction.colorize(with: axis.skColor, colorBlendFactor: 0.45, duration: 0.18),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.28)
        ])
        let punch = SKAction.sequence([
            SKAction.scale(to: 1.10, duration: 0.10),
            SKAction.scale(to: 1.0,  duration: 0.16)
        ])
        run(SKAction.group([flash, punch]))
        // 軸色のリングパルスを建物足元に表示
        if let scene = scene {
            SpriteEffects.spawnRingPulse(
                at: position, in: scene,
                color: axis.skColor,
                startSize: 24, endSize: 90, ringCount: 1,
                zPosition: zPosition + 0.3, duration: 0.45
            )
        }
    }

    // MARK: - タップ検出

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let scene = scene as? CityScene else { return }
        scene.coordinator?.selectedBuilding = BuildingInfo(
            id:          buildingId,
            name:        buildingName,
            axis:        axis,
            level:       level,
            description: buildingDescription,
            gridX:       gridX,
            gridY:       gridY
        )
        highlightBuildingZone()
        // SKNode.touchesBegan は main queue で呼ばれるが SKNode 自体は @MainActor ではないため、
        // 将来 Swift 6 で strict concurrency を有効化した際の安全策として
        // @MainActor Task でディスパッチして HapticEngine を呼ぶ
        Task { @MainActor in HapticEngine.tapMedium() }
    }

    // MARK: - 説明文

    private var buildingDescription: String {
        BuildingCatalog.all.first { $0.id == buildingId }?.description
            ?? "\(buildingName) Lv.\(level)"
    }

    // MARK: - Z ポジション（アイソメトリック奥行きソート）
    // 数式: (gridX + gridY) * 0.1 → 同列は同 Z, 手前の行ほど大きい Z

    private func updateZPosition() {
        zPosition = CGFloat(gridX + gridY) * 0.1
    }
}

// MARK: - CPAxis → SKColor (for legacy compat)

extension CPAxis {
    var skColor: UIColor {
        switch self {
        case .exercise:  return UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        case .diet:      return UIColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1)
        case .alcohol:   return UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1)
        case .sleep:     return UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
        case .lifestyle: return UIColor(red: 1.00, green: 0.18, blue: 0.33, alpha: 1)
        }
    }
}
