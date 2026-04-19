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
    private let skyOverlay    = SKSpriteNode()  // 朝焼け / 夕焼け / 夜の常時表示オーバーレイ
    private let nightLightLayer = SKNode()      // 夜の窓ライト（時間帯で alpha が変動）
    private let effectLayer   = SKNode()        // CP 加算・建設パーティクル等の上層演出
    private let hudLayer      = SKNode()

    // MARK: - State

    weak var coordinator: CitySceneCoordinator?
    private var parsedMap: ParsedMap?
    private var npcs: [NPCNode] = []
    private var currentWeather: WeatherType = .sunny
    private var weatherEmitter: SKNode?    // SKEmitterNode or programmatic rain node
    private var cloudLayer: SKNode?        // 曇り・部分曇りで流れる雲レイヤー
    private var buildings:     [BuildingNode] = []
    private var penaltyNodes: [BuildingNode] = []  // B029/B030 ペナルティ建物（過飲時に自動出現）
    private var currentHour: Int = 12

    // MARK: - カメラ

    private let cameraNode = SKCameraNode()

    /// 外部から FX（フラッシュ等）をカメラ固定で出すためのアクセサ
    var cameraNodeForFX: SKNode { cameraNode }

    // MARK: - ライフサイクル

    override func didMove(to view: SKView) {
        // coordinator の scene 参照を自身に設定（双方向通信に必要）
        coordinator?.scene = self
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
        [mapLayer, buildingLayer, nightLightLayer, npcLayer, weatherLayer, effectLayer]
            .forEach { addChild($0) }
        nightLightLayer.zPosition = 250  // 建物の上、天気より下
        nightLightLayer.alpha = 0
        effectLayer.zPosition = 600
        hudLayer.zPosition = 1000
        // hudLayer は setupHUD() 内で cameraNode に addChild するため、ここでは追加しない
    }

    private func setupCamera() {
        camera = cameraNode
        cameraNode.setScale(0.5)   // 俯瞰: スケール低いほどズームアウト
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
        let tileName: String
        switch tile.gid {
        case 2:  tex = PixelArtRenderer.roadTile();      tileName = "road"
        case 3:  tex = PixelArtRenderer.sidewalkTile();   tileName = "sidewalk"
        case 4:  tex = PixelArtRenderer.waterTile();      tileName = "water"
        case 5:  tex = PixelArtRenderer.sandTile();       tileName = "sand"
        default: tex = PixelArtRenderer.grassTile(variant: (tile.gridX + tile.gridY) % 2); tileName = "grass"
        }
        let node = SKSpriteNode(texture: tex, size: CGSize(width: tileW, height: tileH))
        node.position  = tile.screenPosition
        node.zPosition = CGFloat(tile.gridX + tile.gridY) * 0.1 - 100
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.name = tileName
        mapLayer.addChild(node)
    }

    // MARK: - デフォルト都市レイアウト

    private func placeDefaultCity(map: ParsedMap) {
        let cx = map.width  / 2
        let cy = map.height / 2

        // 初回起動時のみ市庁舎（B025）をシード
        BuildingPlacementStore.shared.seedIfNeeded(cx: cx, cy: cy)

        // BuildingPlacementStore の保存済み建物をすべて配置（永続化データから復元）
        for placed in BuildingPlacementStore.shared.placedBuildings {
            placeBuilding(id: placed.id, name: placed.name, axis: placed.axis,
                          gridX: placed.gridX, gridY: placed.gridY, map: map)
        }

        // 木・装飾
        placeTreesAround(map: map, cx: cx, cy: cy)
        // 街路灯・ベンチ
        placeStreetDecorations(map: map)
    }

    // MARK: - 街路灯・ベンチ配置（道路沿い・歩道沿い）

    private func placeStreetDecorations(map: ParsedMap) {
        let lampTex     = PixelArtRenderer.streetLampTexture()
        let benchTex    = PixelArtRenderer.benchTexture()
        let flowerTex   = PixelArtRenderer.flowerPotTexture()
        let signpostTex = PixelArtRenderer.signpostTexture()
        var lampCount = 0

        for row in 0..<map.height {
            for col in 0..<map.width {
                guard row < map.tiles.count, col < map.tiles[row].count else { continue }
                let tile = map.tiles[row][col]
                let pos = TiledMapParser.isoToScreen(
                    x: col, y: row,
                    tileWidth:  CGFloat(map.tileWidth),
                    tileHeight: CGFloat(map.tileHeight)
                )
                let z = CGFloat(col + row) * 0.1

                // 街路灯: 道路タイル (gid==2) で 4 マスごと、最大 24 本
                if tile.gid == 2 && (col + row) % 4 == 0 && lampCount < 24 {
                    let lamp = SKSpriteNode(texture: lampTex,
                                           size: CGSize(width: 16, height: 44))
                    lamp.position    = CGPoint(x: pos.x + 4, y: pos.y + 4)
                    lamp.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    lamp.zPosition   = z + 0.03
                    buildingLayer.addChild(lamp)
                    lampCount += 1
                }

                // ベンチ: 歩道タイル (gid==3) で 6 マスごと
                if tile.gid == 3 && (col + row) % 6 == 0 {
                    let bench = SKSpriteNode(texture: benchTex,
                                            size: CGSize(width: 32, height: 24))
                    bench.position    = CGPoint(x: pos.x, y: pos.y + 2)
                    bench.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    bench.zPosition   = z + 0.01
                    buildingLayer.addChild(bench)
                }

                // 花鉢: 歩道タイル (gid==3) で 8 マスごと（ベンチと被らない）
                if tile.gid == 3 && (col + row) % 8 == 3 {
                    let pot = SKSpriteNode(texture: flowerTex,
                                          size: CGSize(width: 20, height: 28))
                    pot.position    = CGPoint(x: pos.x - 3, y: pos.y + 2)
                    pot.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    pot.zPosition   = z + 0.02
                    buildingLayer.addChild(pot)
                }

                // 案内標識: 歩道タイル (gid==3) で 12 マスごと
                if tile.gid == 3 && (col + row) % 12 == 7 {
                    let sign = SKSpriteNode(texture: signpostTex,
                                           size: CGSize(width: 24, height: 40))
                    sign.position    = CGPoint(x: pos.x + 5, y: pos.y + 3)
                    sign.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    sign.zPosition   = z + 0.02
                    buildingLayer.addChild(sign)
                }
            }
        }
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
            let node = SKSpriteNode(texture: tex, size: CGSize(width: 44, height: 68))
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
        addNightLights(for: node)
    }

    // MARK: - 新規建設（CitySceneCoordinator.buildBuilding から呼ぶ）

    /// 建設済みの PlacedBuilding をシーンに追加する（ポップインアニメーション付き）
    func placeNewBuilding(_ placed: PlacedBuilding) {
        guard let map = parsedMap else { return }
        guard placed.gridX >= 0 && placed.gridX < map.width &&
              placed.gridY >= 0 && placed.gridY < map.height else { return }

        let pos = TiledMapParser.isoToScreen(
            x: placed.gridX, y: placed.gridY,
            tileWidth:  CGFloat(map.tileWidth),
            tileHeight: CGFloat(map.tileHeight)
        )
        let node = BuildingNode(
            buildingId:   placed.id,
            buildingName: placed.name,
            axis:         placed.axis,
            gridX:        placed.gridX,
            gridY:        placed.gridY
        )
        node.position = pos
        node.setScale(0.2)
        node.alpha = 0
        buildingLayer.addChild(node)
        buildings.append(node)

        // 1) 着地用の粉塵ダストリング（地面エフェクト）
        spawnConstructionDust(at: pos)

        // 2) 軸色のリングパルス（中心 → 外側に拡散）
        SpriteEffects.spawnRingPulse(
            at: pos, in: effectLayer,
            color: placed.axis.skColor,
            startSize: 28, endSize: 130, ringCount: 2,
            zPosition: 600, duration: 0.8
        )

        // 3) ポップインアニメーション: フェードイン → わずかにオーバーシュート → 定常サイズ
        node.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.22),
                SKAction.scale(to: 1.22, duration: 0.28)
            ]),
            SKAction.scale(to: 1.0, duration: 0.14),
            SKAction.run { [weak self] in
                node.playIdleAnimation()
                guard let self else { return }
                // 4) スパークルバースト（建設完了の達成感）
                SpriteEffects.spawnSparkleBurst(
                    at: pos, in: self.effectLayer,
                    color: UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                    count: 16, radius: 70, zPosition: 620
                )
                SpriteEffects.spawnSparkleBurst(
                    at: pos, in: self.effectLayer,
                    color: placed.axis.skColor,
                    count: 10, radius: 48, zPosition: 620
                )
                // 夜の窓ライトを追加する前に、親レイヤーの alpha を現在時刻に同期
                // これをしないと深夜に建設した建物のライトが一瞬見えず、updateTimeOfDay が
                // 次に呼ばれるまで待たされる（視覚フィードバック喪失）
                self.nightLightLayer.alpha = self.nightLightAlpha(hour: self.currentHour)
                self.addNightLights(for: node)
                HapticEngine.constructionLanding()
            }
        ]))
    }

    /// 建設時の地面ダストリング（軽量な薄い円が広がる）
    private func spawnConstructionDust(at position: CGPoint) {
        let tex = SpriteEffects.dustTexture()
        for i in 0..<6 {
            let angle = CGFloat(i) / 6 * .pi * 2
            let dust = SKSpriteNode(texture: tex)
            dust.size = CGSize(width: 12, height: 12)
            dust.position = position
            dust.zPosition = 580
            dust.alpha = 0.9
            effectLayer.addChild(dust)
            dust.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: cos(angle) * 26, dy: sin(angle) * 13),
                                  duration: 0.6),
                    SKAction.scale(to: 2.0, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    /// 軸ゾーンから最も近い空きウォーカブルタイルを返す（スパイラル探索）
    func findBestPosition(for axis: CPAxis) -> (Int, Int)? {
        guard let map = parsedMap else { return nil }
        let cx = map.width  / 2
        let cy = map.height / 2

        // 軸ゾーン中心オフセット（マップ中心からの相対グリッド座標）
        let (ox, oy): (Int, Int)
        switch axis {
        case .exercise:  (ox, oy) = ( 4, -4)
        case .diet:      (ox, oy) = (-4, -4)
        case .alcohol:   (ox, oy) = (-4,  2)
        case .sleep:     (ox, oy) = (-4,  5)
        case .lifestyle: (ox, oy) = ( 3,  4)
        }

        // 既存建物が占有するグリッドセット
        let occupied = Set(buildings.map { "\($0.gridX),\($0.gridY)" })

        // 半径 0 から 8 まで広げながら空きタイルを探す
        for radius in 0...8 {
            for dx in -radius...radius {
                for dy in -radius...radius {
                    guard abs(dx) == radius || abs(dy) == radius else { continue }
                    let gx = cx + ox + dx
                    let gy = cy + oy + dy
                    guard gx >= 0 && gx < map.width && gy >= 0 && gy < map.height else { continue }
                    guard map.isWalkable(at: gx, y: gy) else { continue }
                    guard !occupied.contains("\(gx),\(gy)") else { continue }
                    return (gx, gy)
                }
            }
        }
        return nil
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

    // MARK: - ペナルティ建物（B029居酒屋・B030廃墟ビル / CLAUDE.md Key Rule 2）

    /// 飲酒数に応じてペナルティ建物を表示 / 非表示にする（CitySceneCoordinator から呼ぶ）
    func updatePenaltyBuildings(drinkCount: Int) {
        if drinkCount >= 5 {
            spawnPenaltyBuildings()
        } else {
            removePenaltyBuildings()
        }
    }

    /// B029（居酒屋）+ B030（廃墟ビル）を飲酒ゾーン付近に出現させる
    private func spawnPenaltyBuildings() {
        guard penaltyNodes.isEmpty, let map = parsedMap else { return }
        let cx = map.width / 2, cy = map.height / 2

        // 警告フラッシュ + 警告音相当のハプティック
        SpriteEffects.flashScreen(
            in: cameraNode, size: size,
            color: UIColor(red: 0.78, green: 0.10, blue: 0.10, alpha: 1.0),
            peakAlpha: 0.40, duration: 0.55
        )
        HapticEngine.warning()

        // 飲酒ゾーン（findBestPosition の alcohol オフセット: -4, +2）付近
        let positions: [(id: String, name: String, dx: Int, dy: Int)] = [
            ("B029", "居酒屋",   -5, 2),
            ("B030", "廃墟ビル", -6, 3)
        ]
        for p in positions {
            let gx = max(0, min(cx + p.dx, map.width  - 1))
            let gy = max(0, min(cy + p.dy, map.height - 1))
            let pos = TiledMapParser.isoToScreen(
                x: gx, y: gy,
                tileWidth:  CGFloat(map.tileWidth),
                tileHeight: CGFloat(map.tileHeight)
            )
            let node = BuildingNode(
                buildingId:   p.id,
                buildingName: p.name,
                axis:         .alcohol,
                gridX:        gx,
                gridY:        gy
            )
            node.position  = pos
            node.zPosition = CGFloat(gx + gy) * 0.1 + 0.02
            node.alpha     = 0
            buildingLayer.addChild(node)
            penaltyNodes.append(node)

            // フェードイン + 揺れ演出（ペナルティ感）
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(penaltyNodes.count) * 0.4),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.6),
                    SKAction.sequence([
                        SKAction.rotate(byAngle: 0.06, duration: 0.1),
                        SKAction.rotate(byAngle: -0.12, duration: 0.2),
                        SKAction.rotate(byAngle: 0.06, duration: 0.1)
                    ])
                ]),
                SKAction.run { node.playIdleAnimation() }
            ]))
        }
    }

    /// ペナルティ建物をフェードアウトして除去する
    private func removePenaltyBuildings() {
        guard !penaltyNodes.isEmpty else { return }
        for node in penaltyNodes {
            node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.1, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        penaltyNodes.removeAll()
    }

    // MARK: - CP 加算エフェクト

    func onCPAdded(axis: CPAxis, amount: Int) {
        // カメラ中心（プレイヤーが今見ている位置）に加算演出を表示する
        let center = cameraNode.position

        // 1) リングパルス（軸色）— 視認性アップ
        SpriteEffects.spawnRingPulse(
            at: center, in: effectLayer,
            color: axis.skColor,
            startSize: 30, endSize: 140, ringCount: 2,
            zPosition: 660, duration: 0.7
        )

        // 2) スパークルバースト — 大量の粒で達成感を演出
        SpriteEffects.spawnSparkleBurst(
            at: center, in: effectLayer,
            color: axis.skColor,
            count: max(8, min(amount / 5, 18)),
            radius: 70, zPosition: 670
        )

        // 3) フローティングテキスト（影付き、軸アイコン＋金額）
        let container = SKNode()
        container.position = CGPoint(x: center.x + CGFloat.random(in: -40...40),
                                     y: center.y + 18)
        container.zPosition = 700
        container.alpha = 0
        container.setScale(0.5)
        effectLayer.addChild(container)

        // 影
        let shadow = SKLabelNode(text: "+\(amount) CP")
        shadow.fontName  = "AvenirNext-Heavy"
        shadow.fontSize  = 30
        shadow.fontColor = SKColor.black.withAlphaComponent(0.55)
        shadow.position  = CGPoint(x: 1, y: -1)
        shadow.horizontalAlignmentMode = .center
        container.addChild(shadow)

        // 本体
        let label = SKLabelNode(text: "+\(amount) CP")
        label.fontName  = "AvenirNext-Heavy"
        label.fontSize  = 30
        label.fontColor = axis.skColor
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        // 軸アイコンの代わりに金色の星マーク
        let star = SKLabelNode(text: "★")
        star.fontName  = "AvenirNext-Heavy"
        star.fontSize  = 16
        star.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        star.position  = CGPoint(x: -42, y: 7)
        star.horizontalAlignmentMode = .center
        container.addChild(star)

        container.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.12),
                SKAction.scale(to: 1.15, duration: 0.18)
            ]),
            SKAction.scale(to: 1.0, duration: 0.12),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 70, duration: 0.95),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.55),
                    SKAction.fadeOut(withDuration: 0.4)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - 天気システム

    func updateWeather(_ weather: WeatherType) {
        let previous = currentWeather
        currentWeather = weather
        weatherEmitter?.removeFromParent()
        weatherEmitter = nil
        cloudLayer?.removeFromParent()
        cloudLayer = nil

        let color = bgColor(for: weather)
        run(SKAction.colorize(with: color, colorBlendFactor: 1, duration: 2.0))

        // .sks ファイル非依存のプログラム生成パーティクルにフォールバック
        switch weather {
        case .rainy:
            let node = makeRainNode(isStorm: false)
            node.zPosition = 200
            weatherLayer.addChild(node)
            weatherEmitter = node
            cloudLayer = makeCloudLayer(density: 5, alpha: 0.55)
            if let c = cloudLayer {
                c.zPosition = 180
                weatherLayer.addChild(c)
            }
        case .stormy:
            let node = makeRainNode(isStorm: true)
            node.zPosition = 200
            weatherLayer.addChild(node)
            weatherEmitter = node
            cloudLayer = makeCloudLayer(density: 7, alpha: 0.75, dark: true)
            if let c = cloudLayer {
                c.zPosition = 180
                weatherLayer.addChild(c)
            }
            // 嵐に切り替わったときだけ雷フラッシュ + 警告ハプティック
            if previous != .stormy {
                triggerLightningFlash()
                HapticEngine.warning()
            }
        case .cloudy:
            cloudLayer = makeCloudLayer(density: 5, alpha: 0.65)
            if let c = cloudLayer {
                c.zPosition = 180
                weatherLayer.addChild(c)
            }
        case .partlyCloudy:
            cloudLayer = makeCloudLayer(density: 3, alpha: 0.55)
            if let c = cloudLayer {
                c.zPosition = 180
                weatherLayer.addChild(c)
            }
        case .sunny:
            break
        }
    }

    /// 雷光：白フラッシュを 2 回 + 短いディレイ（嵐時のみ）
    private func triggerLightningFlash() {
        SpriteEffects.flashScreen(
            in: cameraNode, size: size,
            color: .white, peakAlpha: 0.55, duration: 0.25
        )
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.18),
            SKAction.run { [weak self] in
                guard let self else { return }
                SpriteEffects.flashScreen(
                    in: self.cameraNode, size: self.size,
                    color: .white, peakAlpha: 0.4, duration: 0.18
                )
            }
        ]))
    }

    /// プログラム生成の流れる雲レイヤー
    private func makeCloudLayer(density: Int, alpha: CGFloat, dark: Bool = false) -> SKNode {
        let container = SKNode()
        container.alpha = alpha
        let sceneW = size.width
        let sceneH = size.height
        for i in 0..<density {
            let cloud = SKSpriteNode(texture: SpriteEffects.cloudTexture(variant: i % 2))
            cloud.size = CGSize(width: 96 + CGFloat.random(in: 0...40),
                                height: 36 + CGFloat.random(in: 0...10))
            if dark {
                cloud.color = UIColor(white: 0.28, alpha: 1)
                cloud.colorBlendFactor = 0.55
            }
            let startX = CGFloat.random(in: -sceneW/2 ... sceneW/2)
            let y = sceneH/2 - CGFloat.random(in: 30...160)
            cloud.position = CGPoint(x: startX, y: y)
            cloud.zPosition = CGFloat(i) * 0.05
            container.addChild(cloud)
            let speed: CGFloat = dark ? 24 : 14
            let totalDuration = TimeInterval((sceneW + 200) / speed)
            let move = SKAction.moveBy(x: sceneW + 200, y: 0, duration: totalDuration)
            let reset = SKAction.run { [weak cloud] in
                cloud?.position.x = -sceneW/2 - 100
            }
            cloud.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
        }
        return container
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
        for _ in 0..<10 {
            let x = Int.random(in: 0..<map.width)
            let y = Int.random(in: 0..<map.height)
            guard map.isWalkable(at: x, y: y) else { continue }

            let type = nextNPCType()
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

    private func nextNPCType() -> NPCType {
        let total = npcs.count
        // 旅人は最大 1 人（街レベル 3 以上）
        let hasAdventurer = npcs.contains { $0.npcType == .adventurer }
        if !hasAdventurer && total >= 5 && (coordinator?.cityLevel ?? 0) >= 3 {
            return .adventurer
        }
        // 5 種の住民を均等に分配
        let residents: [NPCType] = [.citizen1, .citizen2, .elder, .child, .citizen3]
        let counts = residents.map { t in npcs.filter { $0.npcType == t }.count }
        let minCount = counts.min() ?? 0
        let candidates = zip(residents, counts).filter { $0.1 == minCount }.map(\.0)
        return candidates.randomElement() ?? .citizen1
    }

    // MARK: - 時間帯ライティング（常時オーバーレイ + 夜の窓ライト）

    func updateTimeOfDay(_ hour: Int) {
        currentHour = hour
        let (topColor, bottomColor, overlayAlpha) = skyColors(hour: hour)

        // 1) 空のグラデーションオーバーレイ（常時表示・滑らかに遷移）
        let texture = SpriteEffects.skyGradientTexture(top: topColor, bottom: bottomColor)
        if skyOverlay.parent == nil {
            skyOverlay.size = CGSize(width: size.width * 3, height: size.height * 3)
            skyOverlay.zPosition = 300
            skyOverlay.alpha = 0
            cameraNode.addChild(skyOverlay)  // カメラ固定
        }
        let setTexture = SKAction.run { [weak self] in
            self?.skyOverlay.texture = texture
            self?.skyOverlay.size = CGSize(width: self?.size.width ?? 800,
                                           height: self?.size.height ?? 800)
            self?.skyOverlay.size = CGSize(width: (self?.size.width ?? 800) * 3,
                                           height: (self?.size.height ?? 800) * 3)
        }
        skyOverlay.run(SKAction.sequence([
            setTexture,
            SKAction.fadeAlpha(to: overlayAlpha, duration: 1.6)
        ]))

        // 2) 夜の窓ライト alpha を時間帯に合わせる
        let lightAlpha = nightLightAlpha(hour: hour)
        nightLightLayer.run(SKAction.fadeAlpha(to: lightAlpha, duration: 1.6))
    }

    /// 時刻に応じた空のグラデーションと不透明度を返す
    private func skyColors(hour: Int) -> (top: UIColor, bottom: UIColor, alpha: CGFloat) {
        switch hour {
        case 5...6:  // 夜明け前 → 朝焼け
            return (
                UIColor(red: 0.18, green: 0.16, blue: 0.36, alpha: 1.0),
                UIColor(red: 1.00, green: 0.55, blue: 0.40, alpha: 1.0),
                0.30
            )
        case 7...9:  // 朝の柔らかい光
            return (
                UIColor(red: 0.78, green: 0.92, blue: 1.00, alpha: 1.0),
                UIColor(red: 1.00, green: 0.92, blue: 0.78, alpha: 1.0),
                0.18
            )
        case 10...15:  // 昼間（オーバーレイをほぼ消す）
            return (.clear, .clear, 0.0)
        case 16...17:  // 黄昏前
            return (
                UIColor(red: 1.00, green: 0.78, blue: 0.45, alpha: 1.0),
                UIColor(red: 1.00, green: 0.55, blue: 0.30, alpha: 1.0),
                0.20
            )
        case 18...19:  // 夕焼け
            return (
                UIColor(red: 0.85, green: 0.30, blue: 0.45, alpha: 1.0),
                UIColor(red: 1.00, green: 0.45, blue: 0.20, alpha: 1.0),
                0.32
            )
        case 20...21:  // 夜の入り口（青紫）
            return (
                UIColor(red: 0.10, green: 0.08, blue: 0.30, alpha: 1.0),
                UIColor(red: 0.30, green: 0.18, blue: 0.45, alpha: 1.0),
                0.45
            )
        default:  // 深夜（22-4 時）— 群青色のしっかりした夜
            return (
                UIColor(red: 0.04, green: 0.04, blue: 0.18, alpha: 1.0),
                UIColor(red: 0.10, green: 0.10, blue: 0.30, alpha: 1.0),
                0.55
            )
        }
    }

    /// 窓ライトの不透明度（昼は 0、夜は 1.0）
    private func nightLightAlpha(hour: Int) -> CGFloat {
        switch hour {
        case 18:        return 0.6
        case 19:        return 0.85
        case 20...23, 0...4: return 1.0
        case 5:         return 0.6
        default:        return 0.0
        }
    }

    /// 建物に夜のウィンドウライトを追加（昼夜サイクルで点灯/消灯する）
    func addNightLights(for building: BuildingNode) {
        // 既存ライト除去（再構築用）
        nightLightLayer.children
            .compactMap { $0 as? SKSpriteNode }
            .filter { $0.name == "lights_\(building.gridX)_\(building.gridY)" }
            .forEach { $0.removeFromParent() }

        let tex = SpriteEffects.windowLightTexture()
        // ペナルティ建物は窓ライト無し（廃墟感を強調）
        if building.buildingId == "B030" { return }

        // 各建物に対して 2〜4 個の窓ライトを建物上面付近にランダム配置
        let count = Int.random(in: 2...4)
        for _ in 0..<count {
            let light = SKSpriteNode(texture: tex)
            light.size = CGSize(width: 5, height: 5)
            light.name = "lights_\(building.gridX)_\(building.gridY)"
            light.zPosition = building.zPosition + 0.5
            light.position = CGPoint(
                x: building.position.x + CGFloat.random(in: -16...16),
                y: building.position.y + CGFloat.random(in: 4...28)
            )
            light.alpha = 0  // nightLightLayer 自体の alpha は 0、点灯時に nightLightLayer.alpha が 1 になる
            // アクション: ランダムな間隔でちらつく（生活感）
            let flicker = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.85, duration: 0.4 + Double.random(in: 0...0.3)),
                SKAction.fadeAlpha(to: 1.0,  duration: 0.6 + Double.random(in: 0...0.4))
            ])
            light.run(SKAction.repeatForever(flicker))
            // 居酒屋（B029）はオレンジっぽい色
            if building.buildingId == "B029" {
                light.color = UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1)
                light.colorBlendFactor = 0.5
            }
            nightLightLayer.addChild(light)
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
        let scale = SKAction.scale(to: 0.5, duration: 0.45)  // 全体図に戻す
        move.timingMode  = .easeInEaseOut
        scale.timingMode = .easeInEaseOut
        cameraNode.run(SKAction.group([move, scale]))
    }

    // MARK: - マップ拡張

    func expandMap(to mapSize: MapSize) {
        mapLayer.removeAllChildren()
        buildingLayer.removeAllChildren()
        nightLightLayer.removeAllChildren()
        penaltyNodes.removeAll()
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
        // 時刻ライトを再適用（窓ライトが新規建物にも反映される）
        updateTimeOfDay(currentHour)
        // 拡張時の歓喜エフェクト：金色のスパークル + 軽いカメラズームアウト
        SpriteEffects.spawnSparkleBurst(
            at: cameraNode.position, in: effectLayer,
            color: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1),
            count: 24, radius: 160, zPosition: 700
        )
        SpriteEffects.flashScreen(
            in: cameraNode, size: size,
            color: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1),
            peakAlpha: 0.25, duration: 0.6
        )
        HapticEngine.success()
        // 拡張後もマップ中心を表示
        resetCameraToCenter()
    }

    // MARK: - プレミアムテーマ

    func applyPremiumTheme() {
        // 金色の光エフェクト（カメラ固定）
        let glow = SKSpriteNode(color: SKColor(red: 1, green: 0.84, blue: 0, alpha: 0.05),
                                size: CGSize(width: size.width * 3, height: size.height * 3))
        glow.zPosition = 299
        cameraNode.addChild(glow)
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.08, duration: 2.0),
            SKAction.fadeAlpha(to: 0.03, duration: 2.0)
        ])))

        // 道路タイルを石畳に差し替え
        upgradeToCobblestone()

        // 窓ライトを暖色に変更
        nightLightLayer.children.compactMap { $0 as? SKSpriteNode }.forEach { light in
            light.color = UIColor(red: 1.0, green: 0.93, blue: 0.55, alpha: 1)
            light.colorBlendFactor = 0.4
        }

        // 彩度 +10%（全体の色温度を少し暖かく）
        let warmOverlay = SKSpriteNode(color: SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.06),
                                       size: CGSize(width: size.width * 3, height: size.height * 3))
        warmOverlay.zPosition = 298
        warmOverlay.blendMode = .alpha
        cameraNode.addChild(warmOverlay)
    }

    private func upgradeToCobblestone() {
        let cobbleTex = PixelArtRenderer.cobblestoneTile()
        mapLayer.children.compactMap { $0 as? SKSpriteNode }.forEach { tile in
            if tile.name == "road" || tile.name == "sidewalk" {
                tile.texture = cobbleTex
            }
        }
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
        case .changed:  cameraNode.setScale((lastScale * g.scale).clamped(to: 0.2...2.0))
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
