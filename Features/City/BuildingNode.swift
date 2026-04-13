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
        // テクスチャサイズ: 64 × (tileH + floors*floorH)
        let floorH: CGFloat = 20
        let cfg = BuildingVisualConfig.make(id: buildingId, level: level)
        let totalH = PixelArtRenderer.tileH + CGFloat(cfg.floors) * floorH
        let spriteSize = CGSize(width: PixelArtRenderer.tileW, height: totalH)

        super.init(texture: tex, color: .clear, size: spriteSize)

        // アンカーY: タイル前面底頂点がノード位置の tileH/2 下に来るよう調整
        // anchorY: タイル前面底頂点がノード位置の tileH/2 下に来るよう調整
        // buildingAnchorY() の内部呼び出しと重複しないよう cfg から直接計算
        self.anchorPoint = CGPoint(
            x: 0.5,
            y: (PixelArtRenderer.tileH / 2) / totalH
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
        // テクスチャ更新
        let newTex = PixelArtRenderer.buildingTexture(id: buildingId, level: level)
        let cfg = BuildingVisualConfig.make(id: buildingId, level: level)
        let totalH = PixelArtRenderer.tileH + CGFloat(cfg.floors) * PixelArtRenderer.floorH
        self.texture = newTex
        self.size = CGSize(width: PixelArtRenderer.tileW, height: totalH)
        self.anchorPoint = CGPoint(
            x: 0.5,
            y: PixelArtRenderer.buildingAnchorY(id: buildingId, level: level)
        )

        // レベルアップエフェクト
        let scaleUp   = SKAction.scale(to: 1.25, duration: 0.12)
        let scaleDown = SKAction.scale(to: 1.0,  duration: 0.1)
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.08),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.12)
        ])
        run(SKAction.group([SKAction.sequence([scaleUp, scaleDown]), flash]))

        // LvUP ラベル
        let lvLabel = SKLabelNode(text: "Lv UP!")
        lvLabel.fontName  = "Helvetica-Bold"
        lvLabel.fontSize  = 12
        lvLabel.fontColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        lvLabel.position  = CGPoint(x: 0, y: size.height * 0.5 + 6)
        lvLabel.zPosition = 500
        addChild(lvLabel)
        lvLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 20, duration: 0.8),
                SKAction.sequence([SKAction.wait(forDuration: 0.4),
                                   SKAction.fadeOut(withDuration: 0.4)])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - アイドルアニメーション

    func playIdleAnimation() {
        // 建物ごとの微細な揺れ（稼働感を演出）
        let bobUp   = SKAction.moveBy(x: 0, y: 1.5, duration: 1.4)
        let bobDown = SKAction.moveBy(x: 0, y: -1.5, duration: 1.4)
        bobUp.timingMode   = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "idle")
    }

    func highlightBuildingZone() {
        let hl = SKAction.sequence([
            SKAction.colorize(with: UIColor.white, colorBlendFactor: 0.4, duration: 0.15),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.25)
        ])
        run(hl)
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
