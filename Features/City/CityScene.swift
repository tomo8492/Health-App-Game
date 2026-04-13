// CityScene.swift
// Features/City/
//
// メインゲームシーン（SpriteKit）
// - PixelArtRenderer によるアイソメトリックドット絵タイルマップ
// - 道路ネットワーク + 建物ブロック配置
// - 天気パーティクル・時刻ライティング
// - NPC スポーン・A* 経路探索（CLAUDE.md Key Rule 10）

import SpriteKit
import GameplayKit

final class CityScene: SKScene {

    // MARK: - Layer 構成（Z: tile < building < npc < weather < hud）

    private let mapLayer      = SKNode()
    private let buildingLayer = SKNode()
    private let npcLayer      = SKNode()
    private let weatherLayer  = SKNode()
    private let hudLayer      = SKNode()

    // MARK: - State

    weak var coordinator: CitySceneCoordinator?
    private var parsedMap: ParsedMap?
    private var npcs: [NPCNode] = []
    private var currentWeather: WeatherType = .sunny
    private var weatherEmitter: SKNode?    // SKEmitterNode or programmatic rain node
    private var buildings: [BuildingNode] = []

    // MARK: - カメラ

    private let cameraNode = SKCameraNode()

    // MARK: - ライフサイクル

    override func didMove(to view: SKView) {
        setupScene()
        setupMap()      // parsedMap を先にセットしてからカメラ初期位置を決定
        setupCamera()
        setupHUD()
        setupGestures(in: view)
        startTimeBasedUpdates()
    }

    // MARK: - シーン初期設定

    private func setupScene() {
        backgroundColor = SKColor(red: 0.45, green: 0.72, blue: 0.94, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        [mapLayer, buildingLayer, npcLayer, weatherLayer].forEach { addChild($0) }
        hudLayer.zPosition = 1000
        // hudLayer は setupHUD() 内で cameraNode に addChild するため、ここでは追加しない
    }

    private func setupCamera() {
        camera = cameraNode
        cameraNode.setScale(1.0)
        addChild(cameraNode)
        // マップ中心を起動時の初期表示位置に設定（setupMap() の後に呼ぶこと）
        if let map = parsedMap {
            cameraNode.position = TiledMapParser.isoToScreen(
                x: map.width  / 2,
                y: map.height / 2,
                tileWidth:  CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
        }
    }

    // MARK: - タイルマップ

    private func setupMap() {
        if let map = try? TiledMapParser.parse(named: "city_map") {
            parsedMap = map
            renderTiledMap(map)
        } else {
            let map = generateCityMap(size: 20)
            parsedMap = map
            renderCityMap(map)
        }
    }

    // ── 外部 JSON マップ ───────────────────────────────────────────

    private func renderTiledMap(_ map: ParsedMap) {
        for row in map.tiles {
            for tile in row {
                addTileSprite(tile: tile, tileW: CGFloat(map.tileWidth),
                              tileH: CGFloat(map.tileHeight))
            }
        }
    }

    // ── プロシージャル生成マップ ───────────────────────────────────

    private func renderCityMap(_ map: ParsedMap) {
        for row in map.tiles {
            for tile in row {
                addTileSprite(tile: tile, tileW: CGFloat(map.tileWidth),
                              tileH: CGFloat(map.tileHeight))
            }
        }
        placeDefaultCity(map: map)
    }

    private func addTileSprite(tile: MapTile, tileW: CGFloat, tileH: CGFloat) {
        let tex: SKTexture
        switch tile.gid {
        case 2:  tex = PixelArtRenderer.roadTile()
        case 3:  tex = PixelArtRenderer.sidewalkTile()
        case 4:  tex = PixelArtRenderer.waterTile()
        case 5:  tex = PixelArtRenderer.sandTile()
        default: tex = PixelArtRenderer.grassTile(variant: (tile.gridX + tile.gridY) % 2)
        }
        let node = SKSpriteNode(texture: tex, size: CGSize(width: tileW, height: tileH))
        node.position  = tile.screenPosition
        node.zPosition = CGFloat(tile.gridX + tile.gridY) * 0.1 - 100
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        mapLayer.addChild(node)
    }

    // MARK: - デフォルト都市レイアウト

    private func placeDefaultCity(map: ParsedMap) {
        let cx = map.width  / 2
        let cy = map.height / 2

        // ── 市庁舎（中央）── CLAUDE.md Key Rule 2
        placeBuilding(id: "B025", name: "市庁舎",     axis: .lifestyle, gridX: cx, gridY: cy,     map: map)

        // ── 運動軸エリア（右上ブロック）──
        placeBuilding(id: "B001", name: "ジム",       axis: .exercise, gridX: cx+3, gridY: cy-3, map: map)
        placeBuilding(id: "B003", name: "公園",       axis: .exercise, gridX: cx+5, gridY: cy-5, map: map)
        placeBuilding(id: "B004", name: "プール",     axis: .exercise, gridX: cx+4, gridY: cy-2, map: map)
        placeBuilding(id: "B002", name: "スタジアム", axis: .exercise, gridX: cx+6, gridY: cy-3, map: map)

        // ── 食事軸エリア（左上ブロック）──
        placeBuilding(id: "B007", name: "カフェ",     axis: .diet,  gridX: cx-3, gridY: cy-3, map: map)
        placeBuilding(id: "B008", name: "マーケット", axis: .diet,  gridX: cx-5, gridY: cy-4, map: map)
        placeBuilding(id: "B009", name: "レストラン", axis: .diet,  gridX: cx-4, gridY: cy-2, map: map)
        placeBuilding(id: "B012", name: "ジュース",   axis: .diet,  gridX: cx-2, gridY: cy-4, map: map)

        // ── 飲酒軸エリア（中央左）──
        placeBuilding(id: "B013", name: "瞑想センター", axis: .alcohol, gridX: cx-3, gridY: cy+1, map: map)
        placeBuilding(id: "B014", name: "ハーブティー", axis: .alcohol, gridX: cx-4, gridY: cy+3, map: map)

        // ── 睡眠軸エリア（左下ブロック）──
        placeBuilding(id: "B017", name: "睡眠クリニック", axis: .sleep, gridX: cx-3, gridY: cy+4, map: map)
        placeBuilding(id: "B018", name: "天文台",         axis: .sleep, gridX: cx-5, gridY: cy+5, map: map)
        placeBuilding(id: "B021", name: "月夜の公園",     axis: .sleep, gridX: cx-4, gridY: cy+6, map: map)

        // ── 生活習慣軸エリア（右下ブロック）──
        placeBuilding(id: "B023", name: "給水広場",    axis: .lifestyle, gridX: cx+2, gridY: cy+3, map: map)
        placeBuilding(id: "B026", name: "カレンダータワー", axis: .lifestyle, gridX: cx+4, gridY: cy+4, map: map)
        placeBuilding(id: "B028", name: "公民館",      axis: .lifestyle, gridX: cx+3, gridY: cy+5, map: map)

        // ── 木・装飾 ──────────────────────────────────────────────
        placeTreesAround(map: map, cx: cx, cy: cy)
    }

    private func placeTreesAround(map: ParsedMap, cx: Int, cy: Int) {
        let positions: [(Int, Int)] = [
            (cx+2, cy-2), (cx-2, cy+2), (cx+1, cy-5), (cx-1, cy+5),
            (cx+7, cy-1), (cx-7, cy+1), (cx+2, cy+7), (cx-2, cy-7),
            (cx+6, cy+2), (cx-6, cy-2), (cx+3, cy-7), (cx-3, cy+7),
            (cx+8, cy-4), (cx-8, cy+4)
        ]
        for (x, y) in positions {
            guard x >= 0 && x < map.width && y >= 0 && y < map.height else { continue }
            let variant = (x + y) % 2
            let tex = PixelArtRenderer.treeTexture(variant: variant)
            let node = SKSpriteNode(texture: tex, size: CGSize(width: 22, height: 34))
            node.position = TiledMapParser.isoToScreen(
                x: x, y: y,
                tileWidth: CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
            node.anchorPoint = CGPoint(x: 0.5, y: 0.1)
            node.zPosition = CGFloat(x + y) * 0.1 + 0.02
            buildingLayer.addChild(node)
        }
    }

    // MARK: - 建物配置

    func placeBuilding(id: String, name: String, axis: CPAxis,
                       gridX: Int, gridY: Int, map: ParsedMap) {
        guard gridX >= 0 && gridX < map.width &&
              gridY >= 0 && gridY < map.height else { return }

        let pos = TiledMapParser.isoToScreen(
            x: gridX, y: gridY,
            tileWidth:  CGFloat(map.tileWidth),
            tileHeight: CGFloat(map.tileHeight)
        )
        let node = BuildingNode(
            buildingId:   id,
            buildingName: name,
            axis:         axis,
            gridX:        gridX,
            gridY:        gridY
        )
        node.position = pos
        node.playIdleAnimation()
        buildingLayer.addChild(node)
        buildings.append(node)
    }

    // MARK: - 建物 XP 加算（addCP 経由で呼ばれる）

    /// CP 記録に応じて対応軸の建物に XP を付与する
    /// - 対応軸の建物: amount / 5 XP（100CP → 20 XP）
    /// - 市庁舎 (B025): 全軸から 1/5 の XP を受け取る（中央広場: CLAUDE.md Key Rule 2）
    func addXPToBuildings(axis: CPAxis, amount: Int) {
        let xp = max(1, amount / 5)
        buildings.filter { $0.axis == axis }.forEach { $0.addXP(xp) }
        // 市庁舎（lifestyle 軸）は全軸から補助 XP を受け取る
        if axis != .lifestyle {
            buildings
                .filter { $0.buildingId == "B025" }
                .forEach { $0.addXP(max(1, xp / 5)) }
        }
    }

    // MARK: - CP 加算エフェクト

    func onCPAdded(axis: CPAxis, amount: Int) {
        let label = SKLabelNode(text: "+\(amount)CP")
        label.fontName  = "Helvetica-Bold"
        label.fontSize  = 18
        label.fontColor = axis.skColor
        label.position  = CGPoint(x: CGFloat.random(in: -60...60), y: 20)
        label.zPosition = 600
        label.alpha     = 0
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: 55, duration: 0.9),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.fadeOut(withDuration: 0.4)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - 天気システム

    func updateWeather(_ weather: WeatherType) {
        currentWeather = weather
        weatherEmitter?.removeFromParent()
        weatherEmitter = nil

        let color = bgColor(for: weather)
        run(SKAction.colorize(with: color, colorBlendFactor: 1, duration: 2.0))

        // .sks ファイル非依存のプログラム生成パーティクルにフォールバック
        switch weather {
        case .rainy:
            let node = makeRainNode(isStorm: false)
            node.zPosition = 200
            weatherLayer.addChild(node)
            weatherEmitter = node
        case .stormy:
            let node = makeRainNode(isStorm: true)
            node.zPosition = 200
            weatherLayer.addChild(node)
            weatherEmitter = node
        default:
            break  // sunny / partlyCloudy / cloudy は背景色変化のみ
        }
    }

    /// .sks ファイル不要のプログラム生成雨エフェクト
    private func makeRainNode(isStorm: Bool) -> SKNode {
        let container  = SKNode()
        let sceneW     = size.width + 120
        let sceneH     = size.height
        let dropColor  = isStorm
            ? UIColor(white: 0.55, alpha: 0.80)
            : UIColor(white: 0.78, alpha: 0.55)
        let interval: TimeInterval = isStorm ? 0.018 : 0.038
        let speed: CGFloat         = isStorm ? 310    : 200
        let dropH: CGFloat         = isStorm ? 14     : 9
        let windX: CGFloat         = isStorm ? -45    : -12

        let spawn = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak container] in
                guard let container else { return }
                let drop = SKSpriteNode(
                    color: dropColor,
                    size: CGSize(width: 1.2, height: dropH)
                )
                drop.position = CGPoint(
                    x: CGFloat.random(in: -sceneW / 2 ... sceneW / 2),
                    y: sceneH / 2 + 20
                )
                container.addChild(drop)
                let duration = Double(sceneH + 40) / Double(speed)
                drop.run(SKAction.sequence([
                    SKAction.move(
                        to: CGPoint(x: drop.position.x + windX,
                                    y: -sceneH / 2 - 20),
                        duration: duration
                    ),
                    SKAction.removeFromParent()
                ]))
            },
            SKAction.wait(forDuration: interval)
        ]))
        container.run(spawn, withKey: "rain")
        return container
    }

    private func bgColor(for weather: WeatherType) -> SKColor {
        switch weather {
        case .sunny:        return SKColor(red: 0.45, green: 0.72, blue: 0.94, alpha: 1)
        case .partlyCloudy: return SKColor(red: 0.60, green: 0.78, blue: 0.90, alpha: 1)
        case .cloudy:       return SKColor(red: 0.62, green: 0.65, blue: 0.70, alpha: 1)
        case .rainy:        return SKColor(red: 0.40, green: 0.48, blue: 0.58, alpha: 1)
        case .stormy:       return SKColor(red: 0.22, green: 0.24, blue: 0.32, alpha: 1)
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
                if !npcs.isEmpty { npcs.removeLast() }
            }
        }
        // CP レベルに応じたムード更新
        let cp = coordinator?.totalCP ?? 0
        npcs.forEach { $0.setMood(cpLevel: cp) }
    }

    private func spawnNPC(map: ParsedMap) {
        for _ in 0..<10 {  // 10 回試行
            let x = Int.random(in: 0..<map.width)
            let y = Int.random(in: 0..<map.height)
            guard map.isWalkable(at: x, y: y) else { continue }

            // NPC タイプをランダムに選択（アドベンチャラーは 20% の確率）
            let type: NPCType = Int.random(in: 0..<5) == 0 ? .adventurer
                              : NPCType.allCases.randomElement() ?? .citizen1
            let npc = NPCNode(gridX: x, gridY: y, type: type)
            let pos = TiledMapParser.isoToScreen(
                x: x, y: y,
                tileWidth:  CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
            npc.position  = pos
            npc.zPosition = CGFloat(x + y) * 0.1 + 0.05
            npcLayer.addChild(npc)
            npc.startWandering(map: map)
            npcs.append(npc)
            return
        }
    }

    // MARK: - 時間帯ライティング

    func updateTimeOfDay(_ hour: Int) {
        let alpha = timeAlpha(hour: hour)
        guard alpha > 0 else { return }  // 昼間は不要なオーバーレイノードを生成しない
        let overlay = SKSpriteNode(color: timeColor(hour: hour),
                                   size: CGSize(width: size.width * 3, height: size.height * 3))
        overlay.alpha     = 0
        overlay.zPosition = 300
        addChild(overlay)
        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: alpha, duration: 2.0),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 2.5),
            SKAction.removeFromParent()
        ]))
    }

    private func timeColor(hour: Int) -> SKColor {
        switch hour {
        case 17...20: return SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1)
        case 21...23, 0...5: return SKColor(red: 0.05, green: 0.05, blue: 0.2, alpha: 1)
        case 6...8:  return SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1)
        default:     return .clear
        }
    }

    private func timeAlpha(hour: Int) -> CGFloat {
        switch hour {
        case 17...20: return 0.22
        case 21...23, 0...5: return 0.42
        case 6...8:  return 0.12
        default:     return 0
        }
    }

    // MARK: - カメラリセット

    func resetCameraToCenter() {
        guard let map = parsedMap else { return }
        let center = TiledMapParser.isoToScreen(
            x: map.width  / 2,
            y: map.height / 2,
            tileWidth:  CGFloat(map.tileWidth),
            tileHeight: CGFloat(map.tileHeight)
        )
        let move  = SKAction.move(to: center, duration: 0.45)
        let scale = SKAction.scale(to: 1.0,   duration: 0.45)
        move.timingMode  = .easeInEaseOut
        scale.timingMode = .easeInEaseOut
        cameraNode.run(SKAction.group([move, scale]))
    }

    // MARK: - マップ拡張

    func expandMap(to mapSize: MapSize) {
        mapLayer.removeAllChildren()
        buildingLayer.removeAllChildren()
        buildings.removeAll()
        let map = generateCityMap(size: mapSize.rawValue)
        parsedMap = map
        renderCityMap(map)
        // NPC を再スポーン
        npcLayer.removeAllChildren()
        npcs.removeAll()
        if let coordinator {
            updateNPCCount(coordinator.npcCount)
        }
        // 拡張後もマップ中心を表示
        resetCameraToCenter()
    }

    // MARK: - プレミアムテーマ

    func applyPremiumTheme() {
        // プレミアム向けの金色の光エフェクト
        let glow = SKSpriteNode(color: SKColor(red: 1, green: 0.84, blue: 0, alpha: 0.05),
                                size: CGSize(width: size.width * 3, height: size.height * 3))
        glow.zPosition = 299
        addChild(glow)
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.08, duration: 2.0),
            SKAction.fadeAlpha(to: 0.03, duration: 2.0)
        ])))
    }

    // MARK: - HUD（カメラ固定）

    private func setupHUD() {
        // CP ラベル（カメラ座標 = 常に画面左上付近）
        let cpLabel = SKLabelNode(text: "0 CP")
        cpLabel.fontName  = "Helvetica-Bold"
        cpLabel.fontSize  = 14
        cpLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
        cpLabel.name      = "cpLabel"
        cpLabel.horizontalAlignmentMode = .left
        cpLabel.position  = CGPoint(x: -size.width / 2 + 12, y: size.height / 2 - 36)
        cpLabel.zPosition = 1000
        cameraNode.addChild(hudLayer)
        hudLayer.addChild(cpLabel)
    }

    func updateHUDCP(_ cp: Int) {
        if let label = hudLayer.childNode(withName: "cpLabel") as? SKLabelNode {
            label.text = "\(cp) CP"
        }
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

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        switch g.state {
        case .began:    lastScale = cameraNode.xScale
        case .changed:  cameraNode.setScale((lastScale / g.scale).clamped(to: 0.4...2.5))
        default: break
        }
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard let view else { return }
        let t = g.translation(in: view)
        if g.state == .began { lastPanPoint = cameraNode.position }
        cameraNode.position = CGPoint(x: lastPanPoint.x - t.x,
                                      y: lastPanPoint.y + t.y)
    }

    // MARK: - 時間ベース更新（1時間ごと）

    private func startTimeBasedUpdates() {
        let timer = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 3600),
            SKAction.run { [weak self] in
                let h = Calendar.current.component(.hour, from: Date())
                self?.updateTimeOfDay(h)
            }
        ]))
        run(timer, withKey: "timeUpdate")
        updateTimeOfDay(Calendar.current.component(.hour, from: Date()))
    }

    // MARK: - プロシージャルマップ生成
    // GID: 1=草, 2=道路, 3=歩道, 4=水, 5=砂

    private func generateCityMap(size n: Int) -> ParsedMap {
        let tw = 64, th = 32
        let cx = n / 2, cy = n / 2

        let tiles: [[MapTile]] = (0..<n).map { row in
            (0..<n).map { col in
                let gid = tileGID(col: col, row: row, n: n, cx: cx, cy: cy)
                let pos = TiledMapParser.isoToScreen(
                    x: col, y: row,
                    tileWidth: CGFloat(tw), tileHeight: CGFloat(th)
                )
                return MapTile(gridX: col, gridY: row, gid: gid,
                               isWalkable: gid == 1 || gid == 3,
                               screenPosition: pos)
            }
        }
        return ParsedMap(width: n, height: n, tileWidth: tw, tileHeight: th, tiles: tiles)
    }

    private func tileGID(col: Int, row: Int, n: Int, cx: Int, cy: Int) -> Int {
        let isMainRoadX = col == cx
        let isMainRoadY = row == cy
        let isSideRoadX = col == cx - 3 || col == cx + 3
        let isSideRoadY = row == cy - 3 || row == cy + 3

        // 主要道路
        if isMainRoadX || isMainRoadY { return 2 }
        // 副道路
        if isSideRoadX || isSideRoadY { return 2 }
        // 歩道（道路隣接）
        let nearRoadX = abs(col - cx) == 1 || abs(col - cx + 3) == 1 || abs(col - cx - 3) == 1
        let nearRoadY = abs(row - cy) == 1 || abs(row - cy + 3) == 1 || abs(row - cy - 3) == 1
        if nearRoadX || nearRoadY { return 3 }
        // 縁: 水
        if col == 0 || row == 0 || col == n-1 || row == n-1 { return 4 }
        // 縁の内側: 砂浜
        if col == 1 || row == 1 || col == n-2 || row == n-2 { return 5 }
        // その他: 草
        return 1
    }
}

// MARK: - Comparable clamp

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
