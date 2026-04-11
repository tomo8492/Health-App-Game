// CityScene.swift
// Features/City/
//
// メインゲームシーン（SpriteKit）
// - プログラム生成アイソメトリックタイルマップ
// - 天気パーティクル（WeatherParticleFactory 使用: .sks 不要）
// - 建物自動配置（BuildingRegistry 経由）
// - NPC スポーン・A* 移動（NPCNode + NPCPathfinder）
// - 時間帯ライティング

import SpriteKit

final class CityScene: SKScene {

    // MARK: - Layer 構成

    private let groundLayer   = SKNode()   // タイルマップ（最奥）
    private let roadLayer     = SKNode()   // 道路
    private let buildingLayer = SKNode()   // 建物
    private let npcLayer      = SKNode()   // NPC
    private let effectLayer   = SKNode()   // CP フロート・エフェクト
    private let weatherLayer  = SKNode()   // 天気パーティクル
    private let lightingLayer = SKNode()   // 時間帯オーバーレイ

    // MARK: - State

    weak var coordinator: CitySceneCoordinator?
    private var parsedMap: ParsedMap?
    private var npcs: [NPCNode] = []
    private var buildingNodes: [String: BuildingNode] = [:]   // id → node
    private var currentWeather: WeatherType = .sunny
    private var weatherEmitter: SKEmitterNode?

    // MARK: - カメラ

    private let cameraNode    = SKCameraNode()
    private var lastPanPoint: CGPoint = .zero
    private var lastScale:    CGFloat = 1.0

    // MARK: - ライフサイクル

    override func didMove(to view: SKView) {
        coordinator?.scene = self   // コーディネーターにシーン参照を登録（CLAUDE.md Key Rule 9）
        setupLayers()
        setupCamera()
        setupMap()
        setupHUD()
        setupGestures(in: view)
        startTimeBasedUpdates()
        startCloudCycle()
    }

    // MARK: - レイヤー初期設定

    private func setupLayers() {
        backgroundColor = bgColor(for: .sunny)
        anchorPoint     = CGPoint(x: 0.5, y: 0.4)

        let layers: [(SKNode, CGFloat)] = [
            (groundLayer,   0),
            (roadLayer,     1),
            (buildingLayer, 2),
            (npcLayer,      3),
            (effectLayer,   10),
            (weatherLayer,  20),
            (lightingLayer, 30),
        ]
        layers.forEach { node, z in
            node.zPosition = z
            addChild(node)
        }
    }

    // MARK: - カメラ

    private func setupCamera() {
        camera = cameraNode
        cameraNode.setScale(0.9)
        addChild(cameraNode)
    }

    // MARK: - マップ生成

    private func setupMap() {
        // Tiled JSON があればパース、なければプロシージャル生成
        if let map = try? TiledMapParser.parse(named: "city_map") {
            parsedMap = map
        } else {
            parsedMap = generateDefaultMap(size: 20)
        }
        renderMap()
        renderRoads()
        placeInitialBuildings()
    }

    /// アイソメトリックタイルをプログラムで描画
    private func renderMap() {
        guard let map = parsedMap else { return }
        groundLayer.removeAllChildren()

        for row in 0..<map.height {
            for col in 0..<map.width {
                let tile    = map.tiles[row][col]
                let tileNode = makeTileNode(
                    gid:      tile.gid,
                    pos:      tile.screenPosition,
                    tileW:    CGFloat(map.tileWidth),
                    tileH:    CGFloat(map.tileHeight),
                    row:      row, col: col
                )
                tileNode.zPosition = CGFloat(col + row) * 0.01
                groundLayer.addChild(tileNode)
            }
        }
    }

    private func makeTileNode(gid: Int, pos: CGPoint, tileW: CGFloat, tileH: CGFloat,
                               row: Int, col: Int) -> SKNode {
        let node = SKShapeNode()

        // アイソメトリックひし形パス
        let path = CGMutablePath()
        path.move(to:    CGPoint(x: 0,        y: tileH / 2))
        path.addLine(to: CGPoint(x: tileW / 2, y: 0))
        path.addLine(to: CGPoint(x: 0,        y: -tileH / 2))
        path.addLine(to: CGPoint(x: -tileW / 2, y: 0))
        path.closeSubpath()
        node.path = path

        // タイルの種類で色を決定
        node.fillColor   = tileColor(row: row, col: col, mapSize: parsedMap?.width ?? 20)
        node.strokeColor = UIColor.black.withAlphaComponent(0.08)
        node.lineWidth   = 0.5
        node.position    = pos

        return node
    }

    private func tileColor(row: Int, col: Int, mapSize: Int) -> UIColor {
        let center = mapSize / 2
        let distFromCenter = abs(row - center) + abs(col - center)

        // 中央は明るい芝生・外側は暗い草地
        if distFromCenter <= 2 {
            return UIColor(red: 0.52, green: 0.78, blue: 0.38, alpha: 1)   // 明るい緑（中央広場）
        } else if distFromCenter <= 5 {
            return UIColor(red: 0.45, green: 0.72, blue: 0.32, alpha: 1)   // 中間
        } else {
            return UIColor(red: 0.38, green: 0.62, blue: 0.28, alpha: 1)   // 暗い草地
        }
    }

    /// 道路レンダリング（市庁舎から十字）
    private func renderRoads() {
        guard let map = parsedMap else { return }
        roadLayer.removeAllChildren()

        let roads = coordinator?.registry.roadCells()
            ?? BuildingRegistry().roadCells()

        for cell in roads {
            let parts = cell.split(separator: ",").compactMap { Int($0) }
            guard parts.count == 2 else { continue }
            let col = parts[0], row = parts[1]
            guard row >= 0 && row < map.height && col >= 0 && col < map.width else { continue }

            let pos  = TiledMapParser.isoToScreen(
                x: col, y: row,
                tileWidth: CGFloat(map.tileWidth), tileHeight: CGFloat(map.tileHeight)
            )
            let road = makeRoadTile(pos: pos, tileW: CGFloat(map.tileWidth), tileH: CGFloat(map.tileHeight))
            road.zPosition = 0.5
            roadLayer.addChild(road)
        }
    }

    private func makeRoadTile(pos: CGPoint, tileW: CGFloat, tileH: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to:    CGPoint(x: 0,         y: tileH / 2))
        path.addLine(to: CGPoint(x: tileW / 2,  y: 0))
        path.addLine(to: CGPoint(x: 0,         y: -tileH / 2))
        path.addLine(to: CGPoint(x: -tileW / 2, y: 0))
        path.closeSubpath()

        let node = SKShapeNode(path: path)
        node.fillColor   = UIColor(red: 0.7, green: 0.65, blue: 0.55, alpha: 1)  // 砂利道
        node.strokeColor = UIColor(red: 0.6, green: 0.55, blue: 0.45, alpha: 0.5)
        node.lineWidth   = 0.5
        node.position    = pos
        return node
    }

    // MARK: - 初期建物配置（市庁舎 B025）

    private func placeInitialBuildings() {
        let reg = coordinator?.registry ?? BuildingRegistry()
        for b in reg.placed {
            addBuildingNode(id: b.id, name: b.name,
                            axis: axisFromKey(b.axis),
                            gridX: b.gridX, gridY: b.gridY, level: b.level)
        }
    }

    // MARK: - 建物ノード追加（Coordinator から呼ばれる）

    func addBuilding(id: String, name: String, axis: CPAxis,
                     gridX: Int, gridY: Int, level: Int) {
        guard buildingNodes[id] == nil else { return }
        addBuildingNode(id: id, name: name, axis: axis, gridX: gridX, gridY: gridY, level: level)
        // 出現アニメーション
        buildingNodes[id]?.alpha     = 0
        buildingNodes[id]?.setScale(0.3)
        buildingNodes[id]?.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4),
        ]))
    }

    private func addBuildingNode(id: String, name: String, axis: CPAxis,
                                  gridX: Int, gridY: Int, level: Int) {
        guard let map = parsedMap else { return }
        let pos  = TiledMapParser.isoToScreen(
            x: gridX, y: gridY,
            tileWidth: CGFloat(map.tileWidth), tileHeight: CGFloat(map.tileHeight)
        )
        let node = BuildingNode(
            buildingId: id, buildingName: name,
            axis: axis, gridX: gridX, gridY: gridY, level: level
        )
        node.position  = pos
        node.zPosition = CGFloat(gridX + gridY) + 5
        buildingLayer.addChild(node)
        buildingNodes[id] = node
    }

    // MARK: - 建物レベルアップ通知

    func onBuildingLevelUp(buildingId: String, newLevel: Int) {
        buildingNodes[buildingId]?.addXP(50 * newLevel)
    }

    // MARK: - CP フローターエフェクト

    func onCPAdded(axis: CPAxis, amount: Int) {
        let label = SKLabelNode(text: "+\(amount)CP")
        label.fontName      = "Helvetica-Bold"
        label.fontSize      = 18
        label.fontColor     = axis.uiColor  // SKColor = UIColor
        label.position      = CGPoint(x: CGFloat.random(in: -40...40), y: 20)
        label.zPosition     = 50
        label.alpha         = 0

        effectLayer.addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.15),
                SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 50, duration: 0.9),
            ]),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - 天気システム

    func updateWeather(_ weather: WeatherType) {
        guard weather != currentWeather else { return }
        currentWeather = weather

        // 背景色アニメーション
        let targetColor = bgColor(for: weather)
        run(SKAction.colorize(with: targetColor, colorBlendFactor: 1, duration: 2.5))

        // 旧パーティクル除去
        weatherEmitter?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent(),
        ]))
        weatherEmitter = nil

        // 新パーティクル生成（WeatherParticleFactory）
        if let emitter = WeatherParticleFactory.emitter(for: weather, sceneSize: size) {
            weatherLayer.addChild(emitter)
            weatherEmitter = emitter
        }

        // 嵐: 稲妻フラッシュ
        if weather == .stormy {
            let lightning = SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 3.0...8.0)),
                SKAction.run { [weak self] in
                    guard let self else { return }
                    WeatherParticleFactory.addLightningFlash(to: self)
                },
            ]))
            run(lightning, withKey: "lightning")
        } else {
            removeAction(forKey: "lightning")
        }
    }

    private func bgColor(for weather: WeatherType) -> SKColor {
        switch weather {
        case .sunny:        return SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1)
        case .partlyCloudy: return SKColor(red: 0.68, green: 0.84, blue: 0.95, alpha: 1)
        case .cloudy:       return SKColor(red: 0.65, green: 0.68, blue: 0.72, alpha: 1)
        case .rainy:        return SKColor(red: 0.44, green: 0.50, blue: 0.58, alpha: 1)
        case .stormy:       return SKColor(red: 0.26, green: 0.26, blue: 0.34, alpha: 1)
        }
    }

    // MARK: - 雲サイクル（晴れ以外で流れる雲）

    private func startCloudCycle() {
        let spawnCloud = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 8.0),
            SKAction.run { [weak self] in
                guard let self, let cloud = CloudFactory.makeCloud(
                    for: self.currentWeather, sceneWidth: self.size.width
                ) else { return }
                cloud.zPosition = 15
                self.weatherLayer.addChild(cloud)
            },
        ]))
        run(spawnCloud, withKey: "clouds")
    }

    // MARK: - NPC 管理

    func updateNPCCount(_ count: Int, totalCP: Int) {
        let diff = count - npcs.count

        if diff > 0, let map = parsedMap {
            for i in 0..<diff {
                let variant = NPCFactory.variant(for: totalCP, index: npcs.count + i)
                spawnNPC(map: map, variant: variant)
            }
        } else if diff < 0 {
            let toRemove = abs(diff)
            for i in 0..<toRemove where !npcs.isEmpty {
                npcs.last?.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent(),
                ]))
                npcs.removeLast()
            }
        }

        // CP 変化で NPC の気分を更新
        npcs.forEach { $0.setMood(cpLevel: totalCP) }
    }

    private func spawnNPC(map: ParsedMap, variant: NPCVariant) {
        let x = Int.random(in: 1..<map.width - 1)
        let y = Int.random(in: 1..<map.height - 1)
        guard map.isWalkable(at: x, y: y) else { return }

        let npc = NPCNode(gridX: x, gridY: y, variant: variant)
        let pos = TiledMapParser.isoToScreen(
            x: x, y: y,
            tileWidth: CGFloat(map.tileWidth), tileHeight: CGFloat(map.tileHeight)
        )
        npc.position  = pos
        npc.zPosition = CGFloat(x + y) + 5
        npc.alpha     = 0
        npcLayer.addChild(npc)
        npc.run(SKAction.fadeIn(withDuration: 0.3))
        npc.startWandering(map: map)
        npcs.append(npc)
    }

    // MARK: - 時間帯ライティング

    func updateTimeOfDay(_ hour: Int) {
        let overlayColor = timeOverlayColor(hour: hour)
        let overlayAlpha = timeOverlayAlpha(hour: hour)
        guard overlayAlpha > 0 else { return }

        let overlay = SKSpriteNode(color: overlayColor, size: size)
        overlay.alpha     = 0
        overlay.zPosition = 0
        lightingLayer.addChild(overlay)
        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: overlayAlpha, duration: 2.5),
            SKAction.wait(forDuration: 60.0),
            SKAction.fadeOut(withDuration: 2.5),
            SKAction.removeFromParent(),
        ]))
    }

    private func timeOverlayColor(hour: Int) -> SKColor {
        switch hour {
        case 17...20: return SKColor(red: 1.0, green: 0.50, blue: 0.10, alpha: 1)  // 夕焼け
        case 21...23, 0...4: return SKColor(red: 0.06, green: 0.06, blue: 0.25, alpha: 1)  // 深夜
        case 5...7:   return SKColor(red: 0.85, green: 0.85, blue: 1.00, alpha: 1)  // 夜明け
        default:      return .clear
        }
    }

    private func timeOverlayAlpha(hour: Int) -> CGFloat {
        switch hour {
        case 17...20: return 0.22
        case 21...23, 0...4: return 0.42
        case 5...7:   return 0.12
        default:      return 0
        }
    }

    // MARK: - マップ拡張

    func expandMap(to mapSize: MapSize) {
        let newParsed = generateDefaultMap(size: mapSize.rawValue)
        parsedMap = newParsed

        groundLayer.removeAllChildren()
        roadLayer.removeAllChildren()
        renderMap()
        renderRoads()

        // 既存の NPC を一掃してから再スポーン
        npcs.forEach { $0.removeFromParent() }
        npcs.removeAll()
    }

    // MARK: - プレミアムテーマ

    func applyPremiumTheme() {
        // ゴールドの光エフェクト
        let glow = SKSpriteNode(color: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.08),
                                size: size)
        glow.zPosition = 25
        lightingLayer.addChild(glow)
        glow.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 1.0),
            SKAction.fadeAlpha(to: 0.05, duration: 1.5),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.08, duration: 2.0),
                SKAction.fadeAlpha(to: 0.04, duration: 2.0),
            ])),
        ]))
    }

    // MARK: - ジェスチャー（ピンチ・パン）

    private func setupGestures(in view: SKView) {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let pan   = UIPanGestureRecognizer(target: self,   action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:   lastScale = cameraNode.xScale
        case .changed:
            let s = (lastScale / gesture.scale).clamped(to: 0.4...2.5)
            cameraNode.setScale(s)
        default: break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view else { return }
        let t = gesture.translation(in: view)
        if gesture.state == .began { lastPanPoint = cameraNode.position }
        cameraNode.position = CGPoint(
            x: lastPanPoint.x - t.x,
            y: lastPanPoint.y + t.y
        )
    }

    // MARK: - HUD

    private func setupHUD() {
        guard let cam = camera else { return }
        let cpLabel = SKLabelNode(text: "0 CP")
        cpLabel.fontName    = "Helvetica-Bold"
        cpLabel.fontSize    = 15
        cpLabel.fontColor   = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
        cpLabel.name        = "cpLabel"
        cpLabel.horizontalAlignmentMode = .left
        cpLabel.position    = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - 40)
        cpLabel.zPosition   = 100
        cam.addChild(cpLabel)
    }

    // MARK: - 時間ベース更新

    private func startTimeBasedUpdates() {
        run(
            SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: 3600),
                SKAction.run { [weak self] in
                    self?.updateTimeOfDay(Calendar.current.component(.hour, from: Date()))
                },
            ])),
            withKey: "timeUpdate"
        )
        updateTimeOfDay(Calendar.current.component(.hour, from: Date()))
    }

    // MARK: - デフォルトマップ生成

    private func generateDefaultMap(size n: Int) -> ParsedMap {
        let tiles = (0..<n).map { row in
            (0..<n).map { col in
                let screenPos = TiledMapParser.isoToScreen(
                    x: col, y: row,
                    tileWidth: 64, tileHeight: 32
                )
                return MapTile(gridX: col, gridY: row, gid: 1,
                               isWalkable: true, screenPosition: screenPos)
            }
        }
        return ParsedMap(width: n, height: n, tileWidth: 64, tileHeight: 32, tiles: tiles)
    }

    // MARK: - ユーティリティ

    private func axisFromKey(_ key: String) -> CPAxis {
        switch key {
        case "exercise":  return .exercise
        case "diet":      return .diet
        case "alcohol":   return .alcohol
        case "sleep":     return .sleep
        default:          return .lifestyle
        }
    }
}

// MARK: - Comparable clamp

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
