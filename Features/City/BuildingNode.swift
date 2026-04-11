// BuildingNode.swift
// Features/City/
//
// 建物ノード（SpriteKit）
// - レベルに応じたテクスチャ切り替え（Lv1〜Lv5）
// - タップ検出 → CitySceneCoordinator.selectedBuilding へ通知
// - アイソメトリック表示（奥行き Zポジション 管理）

import SpriteKit

// MARK: - BuildingNode

final class BuildingNode: SKSpriteNode {

    // MARK: - Properties

    let buildingId:  String
    let buildingName: String
    let axis:        CPAxis
    private(set) var level: Int = 1
    private(set) var xp:    Int = 0
    let gridX:       Int
    let gridY:       Int

    // XP 要件（CLAUDE.md 3.1 参照）
    static let xpThresholds = [0, 500, 1500, 3000, 6000]

    // MARK: - Init

    init(
        buildingId:   String,
        buildingName: String,
        axis:         CPAxis,
        gridX:        Int,
        gridY:        Int,
        textureName:  String
    ) {
        self.buildingId   = buildingId
        self.buildingName = buildingName
        self.axis         = axis
        self.gridX        = gridX
        self.gridY        = gridY
        let texture = SKTexture(imageNamed: textureName)
        super.init(texture: texture, color: axis.skColor, size: CGSize(width: 64, height: 64))
        self.isUserInteractionEnabled = true
        updateZPosition()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Level Up

    func addXP(_ amount: Int) {
        xp += amount
        let nextLevel = BuildingNode.xpThresholds.lastIndex { $0 <= xp } ?? 0
        if nextLevel > level - 1 {
            level = nextLevel + 1
            onLevelUp()
        }
    }

    private func onLevelUp() {
        // レベルアップエフェクト
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        run(SKAction.group([SKAction.sequence([scaleUp, scaleDown]), flash]))
        // テクスチャを Lv に応じて変更（アセット準備後に実装）
        // texture = SKTexture(imageNamed: "\(buildingId)_lv\(level)")
    }

    // MARK: - アニメーション

    func playIdleAnimation() {
        // 建物ごとの待機アニメーション（煙・光など）
        let bobUp   = SKAction.moveBy(x: 0, y: 2, duration: 1.2)
        let bobDown = SKAction.moveBy(x: 0, y: -2, duration: 1.2)
        bobUp.timingMode  = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "idle")
    }

    func highlightBuildingZone() {
        let highlight = SKAction.sequence([
            SKAction.colorize(with: axis.skColor, colorBlendFactor: 0.5, duration: 0.2),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
        ])
        run(highlight)
    }

    // MARK: - タップ検出

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let scene = scene as? CityScene else { return }
        scene.coordinator?.selectedBuilding = BuildingInfo(
            id:          buildingId,
            name:        buildingName,
            axis:        axis,
            level:       level,
            description: "\(buildingName) Lv.\(level)",
            gridX:       gridX,
            gridY:       gridY
        )
        highlightBuildingZone()
    }

    // MARK: - Z ポジション（アイソメトリック奥行き）

    private func updateZPosition() {
        // グリッド座標の合計が大きいほど手前（大きい Z）
        zPosition = CGFloat(gridX + gridY)
    }
}

// MARK: - CPAxis → SKColor

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
