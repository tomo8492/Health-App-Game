// CityScene.swift
// Features/City/
//
// メインゲームシーン（SpriteKit）
// - アイソメトリックタイルマップレンダリング
// - 天気パーティクルシステム（SKEmitterNode）
// - NPC スポーン・管理
// - 時間帯ライティング

import SpriteKit
import GameplayKit

final class CityScene: SKScene {

    // MARK: - Layer 構成

    private let mapLayer     = SKNode()    // タイルマップ
    private let buildingLayer = SKNode()   // 建物
    private let npcLayer     = SKNode()    // NPC
    private let weatherLayer = SKNode()    // 天気エフェクト
    private let hudLayer     = SKNode()    // 画面固定 HUD

    // MARK: - State

    weak var coordinator: CitySceneCoordinator?
    private var parsedMap: ParsedMap?
    private var npcs: [NPCNode] = []
    private var currentWeather: WeatherType = .sunny
    private var weatherEmitter: SKEmitterNode?

    // MARK: - カメラ

    private let cameraNode = SKCameraNode()

    // MARK: - ライフサイクル

    override func didMove(to view: SKView) {
        setupScene()
        setupCamera()
        setupMap()
        setupHUD()
        setupGestures(in: view)
        startTimeBasedUpdates()
    }

    // MARK: - シーン初期設定

    private func setupScene() {
        backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1)  // 晴れ空
        anchorPoint     = CGPoint(x: 0.5, y: 0.5)

        [mapLayer, buildingLayer, npcLayer, weatherLayer].forEach { addChild($0) }
        hudLayer.zPosition = 1000
        addChild(hudLayer)
    }

    private func setupCamera() {
        camera = cameraNode
        cameraNode.setScale(1.0)
        addChild(cameraNode)
    }

    // MARK: - タイルマップ

    private func setupMap() {
        // Tiled JSON がある場合はパースして表示
        // アセット未準備の場合はプロシージャル生成
        if let map = try? TiledMapParser.parse(named: "city_map") {
            parsedMap = map
            renderMap(map)
        } else {
            parsedMap = generateDefaultMap(size: 20)
            renderDefaultMap()
        }
    }

    private func renderMap(_ map: ParsedMap) {
        for row in map.tiles {
            for tile in row {
                let tileNode = SKSpriteNode(
                    color: groundColor(gid: tile.gid),
                    size:  CGSize(width: CGFloat(map.tileWidth), height: CGFloat(map.tileHeight))
                )
                tileNode.position  = tile.screenPosition
                tileNode.zPosition = CGFloat(tile.gridX + tile.gridY) - 100
                mapLayer.addChild(tileNode)
            }
        }
    }

    private func renderDefaultMap() {
        guard let map = parsedMap else { return }
        renderMap(map)
        // 市庁舎（デフォルト）を中央に配置
        placeDefaultBuildings()
    }

    private func placeDefaultBuildings() {
        guard let map = parsedMap else { return }
        let cx = map.width  / 2
        let cy = map.height / 2

        // 市庁舎 B025（中央広場: CLAUDE.md Key Rule 2）
        placeBuilding(
            id:    "B025",
            name:  "市庁舎",
            axis:  .exercise,   // 総合 CP = 全軸合算
            gridX: cx,
            gridY: cy,
            texture: "building_B025_lv1"
        )
    }

    // MARK: - 建物配置

    func placeBuilding(id: String, name: String, axis: CPAxis, gridX: Int, gridY: Int, texture: String) {
        guard let map = parsedMap else { return }
        let pos  = TiledMapParser.isoToScreen(
            x: gridX, y: gridY,
            tileWidth:  CGFloat(map.tileWidth),
            tileHeight: CGFloat(map.tileHeight)
        )
        let node = BuildingNode(
            buildingId:   id,
            buildingName: name,
            axis:         axis,
            gridX:        gridX,
            gridY:        gridY,
            textureName:  texture
        )
        node.position = pos
        node.playIdleAnimation()
        buildingLayer.addChild(node)

        // 建物タイルを通行不可に設定
        // map.tiles[gridY][gridX] の isWalkable = false（イミュータブルのため ParsedMap 拡張が必要）
    }

    // MARK: - CP 加算エフェクト

    func onCPAdded(axis: CPAxis, amount: Int) {
        let label = SKLabelNode(text: "+\(amount)CP")
        label.fontName       = "Helvetica-Bold"
        label.fontSize       = 20
        label.fontColor      = axis.skColor
        label.position       = CGPoint(x: 0, y: 40)
        label.zPosition      = 500
        label.alpha          = 0

        addChild(label)

        let appear = SKAction.fadeIn(withDuration: 0.2)
        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([appear, SKAction.group([moveUp, SKAction.sequence([SKAction.wait(forDuration: 0.6), fadeOut])]), remove]))
    }

    // MARK: - 天気システム

    func updateWeather(_ weather: WeatherType) {
        currentWeather = weather
        weatherEmitter?.removeFromParent()
        weatherEmitter = nil

        // 背景色を変更
        let targetColor = bgColor(for: weather)
        run(SKAction.colorize(with: targetColor, colorBlendFactor: 1, duration: 2.0))

        // パーティクルエフェクト
        if let particleFile = weather.particleFileName,
           let emitter = SKEmitterNode(fileNamed: particleFile) {
            emitter.position   = CGPoint(x: 0, y: size.height / 2)
            emitter.zPosition  = 200
            weatherLayer.addChild(emitter)
            weatherEmitter = emitter
        }
    }

    private func bgColor(for weather: WeatherType) -> SKColor {
        switch weather {
        case .sunny:        return SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1)
        case .partlyCloudy: return SKColor(red: 0.70, green: 0.85, blue: 0.95, alpha: 1)
        case .cloudy:       return SKColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1)
        case .rainy:        return SKColor(red: 0.47, green: 0.53, blue: 0.60, alpha: 1)
        case .stormy:       return SKColor(red: 0.28, green: 0.28, blue: 0.35, alpha: 1)
        }
    }

    // MARK: - NPC 管理

    func updateNPCCount(_ count: Int) {
        guard let map = parsedMap else { return }
        let diff = count - npcs.count

        if diff > 0 {
            for _ in 0..<diff { spawnNPC(map: map) }
        } else if diff < 0 {
            for _ in 0..<abs(diff) {
                npcs.last?.removeFromParent()
                npcs.removeLast()
            }
        }
    }

    private func spawnNPC(map: ParsedMap) {
        let x = Int.random(in: 0..<map.width)
        let y = Int.random(in: 0..<map.height)
        guard map.isWalkable(at: x, y: y) else { return }

        let npc = NPCNode(gridX: x, gridY: y)
        let pos = TiledMapParser.isoToScreen(
            x: x, y: y,
            tileWidth: CGFloat(map.tileWidth),
            tileHeight: CGFloat(map.tileHeight)
        )
        npc.position  = pos
        npc.zPosition = CGFloat(x + y) + 10
        npcLayer.addChild(npc)
        npc.startWandering(map: map)
        npcs.append(npc)
    }

    // MARK: - 時間帯ライティング

    func updateTimeOfDay(_ hour: Int) {
        let overlay = SKSpriteNode(color: timeOverlayColor(hour: hour), size: size)
        overlay.alpha     = 0
        overlay.zPosition = 300
        addChild(overlay)
        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: timeOverlayAlpha(hour: hour), duration: 2.0),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 2.0),
            SKAction.removeFromParent()
        ]))
    }

    private func timeOverlayColor(hour: Int) -> SKColor {
        switch hour {
        case 17...20: return SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1)  // 夕暮れ
        case 21...23, 0...5: return SKColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1)  // 夜
        case 6...8:  return SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1)  // 朝
        default:     return .clear
        }
    }

    private func timeOverlayAlpha(hour: Int) -> CGFloat {
        switch hour {
        case 17...20: return 0.25
        case 21...23, 0...5: return 0.45
        case 6...8:  return 0.15
        default:     return 0
        }
    }

    // MARK: - マップ拡張

    func expandMap(to size: MapSize) {
        parsedMap = generateDefaultMap(size: size.rawValue)
        mapLayer.removeAllChildren()
        renderDefaultMap()
    }

    // MARK: - プレミアムテーマ

    func applyPremiumTheme() {
        // Phase 5 で実装
    }

    // MARK: - ジェスチャー

    private func setupGestures(in view: SKView) {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let pan   = UIPanGestureRecognizer(target: self,   action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(pan)
    }

    private var lastScale:    CGFloat = 1.0
    private var lastPanPoint: CGPoint = .zero

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:  lastScale = cameraNode.xScale
        case .changed:
            let newScale = (lastScale / gesture.scale).clamped(to: 0.5...2.0)
            cameraNode.setScale(newScale)
        default: break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = view else { return }
        let translation = gesture.translation(in: view)
        if gesture.state == .began { lastPanPoint = cameraNode.position }
        cameraNode.position = CGPoint(
            x: lastPanPoint.x - translation.x,
            y: lastPanPoint.y + translation.y
        )
    }

    // MARK: - HUD

    private func setupHUD() {
        // Phase 2 簡易 HUD（今日の CP）
        let cpLabel = SKLabelNode(text: "0 CP")
        cpLabel.fontName    = "Helvetica-Bold"
        cpLabel.fontSize    = 16
        cpLabel.fontColor   = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
        cpLabel.name        = "cpLabel"
        cpLabel.position    = CGPoint(x: -size.width / 2 + 60, y: size.height / 2 - 40)
        cpLabel.zPosition   = 1000
        hudLayer.addChild(cpLabel)
        cameraNode.addChild(hudLayer)
    }

    // MARK: - 時間ベース更新

    private func startTimeBasedUpdates() {
        let timer = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 3600),  // 1時間ごと
                SKAction.run { [weak self] in
                    let hour = Calendar.current.component(.hour, from: Date())
                    self?.updateTimeOfDay(hour)
                }
            ])
        )
        run(timer, withKey: "timeUpdate")
        // 起動時に現在の時刻を適用
        updateTimeOfDay(Calendar.current.component(.hour, from: Date()))
    }

    // MARK: - デフォルトマップ生成（アセット未準備時）

    private func generateDefaultMap(size n: Int) -> ParsedMap {
        let tiles = (0..<n).map { row in
            (0..<n).map { col in
                let screenPos = TiledMapParser.isoToScreen(
                    x: col, y: row,
                    tileWidth: 64, tileHeight: 32
                )
                return MapTile(gridX: col, gridY: row, gid: 1, isWalkable: true, screenPosition: screenPos)
            }
        }
        return ParsedMap(width: n, height: n, tileWidth: 64, tileHeight: 32, tiles: tiles)
    }

    private func groundColor(gid: Int) -> SKColor {
        switch gid {
        case 0: return SKColor(red: 0.3, green: 0.55, blue: 0.25, alpha: 1)  // 草地
        case 1: return SKColor(red: 0.6, green: 0.78, blue: 0.45, alpha: 1)  // 明るい草地
        case 2: return SKColor(red: 0.7, green: 0.65, blue: 0.55, alpha: 1)  // 道
        default: return SKColor(red: 0.5, green: 0.7, blue: 0.4, alpha: 1)
        }
    }
}

// MARK: - Comparable clamp

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
