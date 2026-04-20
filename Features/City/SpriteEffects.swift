// SpriteEffects.swift
// Features/City/
//
// CityScene 内で使い回す SpriteKit エフェクト集（パーティクル風 / フラッシュ / グラデーション空）。
// .sks ファイル不要のプログラム生成エフェクトに統一して、ビルド設定への依存を排除する。

import SpriteKit
import UIKit

enum SpriteEffects {

    // MARK: - 星型・粒子テクスチャ（キャッシュ）

    // 内訳: 空グラデーション 7 パターン + スパークル 色別 ~6 + グローリング 色別 ~6 +
    //      ウィンドウライト 1 + 純白 1 + ダスト 1 + 雲 2 + 余裕 = 128 で十分
    private static let textureCache: NSCache<NSString, SKTexture> = {
        let c = NSCache<NSString, SKTexture>()
        c.countLimit = 128
        return c
    }()

    private static func cached(_ key: String, _ make: () -> SKTexture) -> SKTexture {
        let nsKey = key as NSString
        if let t = textureCache.object(forKey: nsKey) { return t }
        let t = make()
        textureCache.setObject(t, forKey: nsKey)
        return t
    }

    /// 4方向に光る小さなドット粒子（5x5）
    static func sparkleTexture(color: UIColor) -> SKTexture {
        let key = "sparkle_\(color.description)"
        return cached(key) {
            let size = CGSize(width: 8, height: 8)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(color.cgColor)
                // 十字＋中央
                cg.fill(CGRect(x: 3, y: 0, width: 2, height: 8))
                cg.fill(CGRect(x: 0, y: 3, width: 8, height: 2))
                cg.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
                cg.fill(CGRect(x: 3, y: 3, width: 2, height: 2))
            }
            let t = SKTexture(image: img); t.filteringMode = .nearest; return t
        }
    }

    /// 半透明の柔らかい光球（CP リング用）
    static func glowRingTexture(color: UIColor) -> SKTexture {
        let key = "glow_\(color.description)"
        return cached(key) {
            let size = CGSize(width: 64, height: 64)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                cg.setStrokeColor(color.withAlphaComponent(0.85).cgColor)
                cg.setLineWidth(3.0)
                cg.strokeEllipse(in: CGRect(x: 4, y: 4, width: 56, height: 56))
                cg.setStrokeColor(color.withAlphaComponent(0.45).cgColor)
                cg.setLineWidth(1.5)
                cg.strokeEllipse(in: CGRect(x: 1, y: 1, width: 62, height: 62))
            }
            let t = SKTexture(image: img); t.filteringMode = .linear; return t
        }
    }

    /// 点光源（夜の窓ライト用）
    static func windowLightTexture() -> SKTexture {
        cached("window_light") {
            let size = CGSize(width: 6, height: 6)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(UIColor(red: 1.0, green: 0.93, blue: 0.55, alpha: 1.0).cgColor)
                cg.fill(CGRect(x: 1, y: 1, width: 4, height: 4))
                cg.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
                cg.fill(CGRect(x: 2, y: 2, width: 2, height: 2))
            }
            let t = SKTexture(image: img); t.filteringMode = .nearest; return t
        }
    }

    /// 1×1 白テクスチャ（雲・空グラデーション用）
    static func solidWhiteTexture() -> SKTexture {
        cached("solid_white") {
            let img = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { _ in
                UIColor.white.setFill()
                UIBezierPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2)).fill()
            }
            let t = SKTexture(image: img); t.filteringMode = .linear; return t
        }
    }

    /// アイソメ用の粉塵タイル（建設時の地面エフェクト）
    static func dustTexture() -> SKTexture {
        cached("dust") {
            let size = CGSize(width: 16, height: 16)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(UIColor(white: 0.95, alpha: 0.85).cgColor)
                cg.fillEllipse(in: CGRect(x: 0, y: 0, width: 16, height: 16))
                cg.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
                cg.fillEllipse(in: CGRect(x: 2, y: 2, width: 8, height: 8))
            }
            let t = SKTexture(image: img); t.filteringMode = .linear; return t
        }
    }

    // MARK: - スパークルバースト（建物建設・LvUP・CP 加算）

    /// 中心点から放射状に飛び散るスパークルを生成する（自動破棄）
    static func spawnSparkleBurst(
        at position: CGPoint,
        in parent: SKNode,
        color: UIColor,
        count: Int = 12,
        radius: CGFloat = 60,
        zPosition: CGFloat = 600
    ) {
        let tex = sparkleTexture(color: color)
        for i in 0..<count {
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2 + CGFloat.random(in: -0.2...0.2)
            let dist = radius * CGFloat.random(in: 0.7...1.2)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            let p = SKSpriteNode(texture: tex)
            p.size = CGSize(width: 8, height: 8)
            p.position = position
            p.zPosition = zPosition
            p.alpha = 0.0
            p.setScale(0.3)
            parent.addChild(p)
            let dur = TimeInterval.random(in: 0.55...0.85)
            p.run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: 1.0, duration: 0.08),
                    SKAction.scale(to: CGFloat.random(in: 1.0...1.6), duration: 0.18)
                ]),
                SKAction.group([
                    SKAction.move(by: CGVector(dx: dx, dy: dy), duration: dur),
                    SKAction.sequence([
                        SKAction.wait(forDuration: dur * 0.4),
                        SKAction.fadeOut(withDuration: dur * 0.6)
                    ]),
                    SKAction.rotate(byAngle: CGFloat.random(in: -.pi...(.pi)), duration: dur)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - 拡張リング（パルス）

    /// 中心点から広がる円のパルスを 1〜2 回生成（CP 加算 / 建物選択）
    static func spawnRingPulse(
        at position: CGPoint,
        in parent: SKNode,
        color: UIColor,
        startSize: CGFloat = 24,
        endSize: CGFloat = 110,
        ringCount: Int = 2,
        zPosition: CGFloat = 580,
        duration: TimeInterval = 0.7
    ) {
        let tex = glowRingTexture(color: color)
        for i in 0..<ringCount {
            let ring = SKSpriteNode(texture: tex)
            ring.size = CGSize(width: startSize, height: startSize)
            ring.position = position
            ring.zPosition = zPosition
            ring.alpha = 0.85
            parent.addChild(ring)
            let scale = endSize / startSize
            let delay = Double(i) * 0.18
            ring.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: scale, duration: duration),
                    SKAction.fadeOut(withDuration: duration)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - 画面フラッシュ（カメラ固定 / ペナルティ・嵐）

    /// カメラ固定の全画面フラッシュ。color と alpha で警告色も表現可能。
    static func flashScreen(
        in cameraNode: SKNode,
        size: CGSize,
        color: UIColor,
        peakAlpha: CGFloat = 0.45,
        duration: TimeInterval = 0.45
    ) {
        let flash = SKSpriteNode(color: color, size: CGSize(width: size.width * 3, height: size.height * 3))
        flash.alpha = 0
        flash.zPosition = 950
        cameraNode.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: peakAlpha, duration: duration * 0.25),
            SKAction.fadeOut(withDuration: duration * 0.75),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - 空グラデーションオーバーレイ（朝焼け・夕焼け・夜）

    /// 朝焼け / 夕焼け / 夜の縦グラデーション（top→bottom）
    static func skyGradientTexture(top: UIColor, bottom: UIColor) -> SKTexture {
        let key = "sky_\(top.description)_\(bottom.description)"
        return cached(key) {
            let size = CGSize(width: 8, height: 256)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                let cs = CGColorSpaceCreateDeviceRGB()
                let colors = [top.cgColor, bottom.cgColor] as CFArray
                let locations: [CGFloat] = [0.0, 1.0]
                if let grad = CGGradient(colorsSpace: cs, colors: colors, locations: locations) {
                    cg.drawLinearGradient(
                        grad,
                        start: CGPoint(x: 0, y: 0),
                        end: CGPoint(x: 0, y: 256),
                        options: []
                    )
                }
            }
            let t = SKTexture(image: img); t.filteringMode = .linear; return t
        }
    }

    // MARK: - 雲スプライト（曇りの日に流す）

    // MARK: - 煙突の煙エフェクト（建物に継続的に attach）

    /// 建物ノードに煙突エミッターを取り付ける（毎秒 1.5 個の煙粒子を生成）
    /// - Parameters:
    ///   - building: 煙を出す親ノード（BuildingNode を想定）
    ///   - offset: building の anchor 基準の相対位置（煙突位置）
    ///   - tint: 煙の色味（nil でデフォルトのグレー）
    /// 既に "smoke" key のアクションが動いていれば二重に追加しない。
    static func attachSmoke(
        to building: SKNode,
        offset: CGPoint,
        tint: UIColor? = nil
    ) {
        // 既存の煙エミッターがあればスキップ（二重 attach 防止）
        if building.action(forKey: "smokeEmitter") != nil { return }

        let emitter = SKNode()
        emitter.position = offset
        emitter.zPosition = 0.5  // 建物よりわずかに手前
        emitter.name = "smokeEmitter"
        building.addChild(emitter)

        let tex = PixelArtRenderer.smokePuffTexture()
        let spawn = SKAction.run { [weak emitter] in
            guard let emitter else { return }
            let puff = SKSpriteNode(texture: tex)
            puff.size = CGSize(width: 6, height: 6)
            if let tint {
                puff.color = tint
                puff.colorBlendFactor = 0.5
            }
            puff.position = CGPoint(
                x: CGFloat.random(in: -1.5...1.5),
                y: 0
            )
            puff.alpha = 0.75
            puff.zPosition = 0.5
            emitter.addChild(puff)
            let duration: TimeInterval = 2.4
            puff.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(
                        dx: CGFloat.random(in: -6...6),
                        dy: 28 + CGFloat.random(in: 0...8)
                    ), duration: duration),
                    SKAction.scale(to: 2.6, duration: duration),
                    SKAction.sequence([
                        SKAction.wait(forDuration: duration * 0.35),
                        SKAction.fadeOut(withDuration: duration * 0.65)
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }
        let wait = SKAction.wait(forDuration: 0.65, withRange: 0.3)
        building.run(SKAction.repeatForever(SKAction.sequence([spawn, wait])),
                     withKey: "smokeEmitter")
    }

    /// 建物の煙を停止する
    static func detachSmoke(from building: SKNode) {
        building.removeAction(forKey: "smokeEmitter")
        building.childNode(withName: "smokeEmitter")?.removeFromParent()
    }

    // MARK: - 鳥の群れ（空を横切る）

    /// V 字・直線の鳥シルエットテクスチャ（2 フレーム：上羽・下羽）
    /// frame: 0 = 羽を上げた ^ 形, 1 = 羽を下げた ∨ 形
    static func birdTexture(frame: Int) -> SKTexture {
        cached("bird_f\(frame % 2)") {
            let size = CGSize(width: 10, height: 6)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(UIColor(white: 0.18, alpha: 1.0).cgColor)
                if frame % 2 == 0 {
                    // 羽を上げた形 ^（両翼が少し上がっている）
                    cg.fill(CGRect(x: 0, y: 2, width: 2, height: 1))
                    cg.fill(CGRect(x: 2, y: 1, width: 2, height: 1))
                    cg.fill(CGRect(x: 4, y: 2, width: 2, height: 1))
                    cg.fill(CGRect(x: 6, y: 1, width: 2, height: 1))
                    cg.fill(CGRect(x: 8, y: 2, width: 2, height: 1))
                } else {
                    // 羽を下げた形 ∨
                    cg.fill(CGRect(x: 0, y: 3, width: 2, height: 1))
                    cg.fill(CGRect(x: 2, y: 4, width: 2, height: 1))
                    cg.fill(CGRect(x: 4, y: 3, width: 2, height: 1))
                    cg.fill(CGRect(x: 6, y: 4, width: 2, height: 1))
                    cg.fill(CGRect(x: 8, y: 3, width: 2, height: 1))
                }
            }
            let t = SKTexture(image: img); t.filteringMode = .nearest; return t
        }
    }

    /// parent レイヤーに 3-5 羽の鳥群れを出現させ、sceneSize の横幅分を斜めに横切らせる
    /// zPosition は雲（180-200）より少し上、天気 emitter より下を想定（= 210）
    static func spawnBirdFlock(
        in parent: SKNode,
        sceneSize: CGSize,
        zPosition: CGFloat = 210
    ) {
        let count = Int.random(in: 3...5)
        let goingRight = Bool.random()
        let startX = goingRight ? -sceneSize.width * 0.6 : sceneSize.width * 0.6
        let endX   = -startX
        let startY = CGFloat.random(in: sceneSize.height * 0.1...sceneSize.height * 0.35)
        let endY   = startY - CGFloat.random(in: 20...60)
        let duration = TimeInterval.random(in: 6.0...9.0)
        let tex0 = birdTexture(frame: 0)
        let tex1 = birdTexture(frame: 1)
        let flap = SKAction.animate(with: [tex0, tex1], timePerFrame: 0.18, resize: false, restore: false)
        let flapForever = SKAction.repeatForever(flap)

        for i in 0..<count {
            let bird = SKSpriteNode(texture: tex0)
            bird.size = CGSize(width: 12, height: 8)
            // V 字編隊: 中央が先頭、両翼が少し後ろ下がり
            let offsetFromLead = CGFloat(i) * 8
            let sideShift = CGFloat(i % 2 == 0 ? -1 : 1) * CGFloat((i + 1) / 2) * 6
            bird.position = CGPoint(
                x: startX + (goingRight ? -offsetFromLead : offsetFromLead),
                y: startY + sideShift
            )
            bird.zPosition = zPosition
            bird.alpha = 0
            if !goingRight { bird.xScale = -1 }
            parent.addChild(bird)
            bird.run(flapForever, withKey: "flap")

            let target = CGPoint(
                x: endX + (goingRight ? -offsetFromLead : offsetFromLead),
                y: endY + sideShift
            )
            bird.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.9, duration: 0.4),
                SKAction.move(to: target, duration: duration),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - 蝶（花壇に付随してふわふわ飛ぶ）

    /// 2 フレーム（羽を開いた / 閉じた）の小さな蝶テクスチャ
    static func butterflyTexture(color: UIColor, frame: Int) -> SKTexture {
        let key = "butterfly_\(color.description)_f\(frame % 2)"
        return cached(key) {
            let size = CGSize(width: 8, height: 6)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                // 胴体
                cg.setFillColor(UIColor(white: 0.12, alpha: 1.0).cgColor)
                cg.fill(CGRect(x: 3, y: 2, width: 2, height: 2))
                // 羽
                cg.setFillColor(color.cgColor)
                if frame % 2 == 0 {
                    // 羽を開いた
                    cg.fill(CGRect(x: 0, y: 1, width: 3, height: 3))
                    cg.fill(CGRect(x: 5, y: 1, width: 3, height: 3))
                    cg.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
                    cg.fill(CGRect(x: 1, y: 2, width: 1, height: 1))
                    cg.fill(CGRect(x: 6, y: 2, width: 1, height: 1))
                } else {
                    // 羽を閉じた（縦長）
                    cg.fill(CGRect(x: 2, y: 0, width: 1, height: 5))
                    cg.fill(CGRect(x: 5, y: 0, width: 1, height: 5))
                }
            }
            let t = SKTexture(image: img); t.filteringMode = .nearest; return t
        }
    }

    /// 花壇などに蝶を付与する（楕円軌道でふわふわ飛び、羽ばたきも同期）
    static func attachButterfly(to parent: SKNode, color: UIColor) {
        // 二重 attach 防止: 子に名前 "butterfly" のノードがあればスキップ
        if parent.childNode(withName: "butterfly") != nil { return }

        let butterfly = SKSpriteNode(texture: butterflyTexture(color: color, frame: 0))
        butterfly.size = CGSize(width: 10, height: 8)
        butterfly.position = CGPoint(x: 0, y: 10)
        butterfly.zPosition = 1.0
        butterfly.name = "butterfly"
        parent.addChild(butterfly)

        // 羽ばたき（連続）
        let flap = SKAction.animate(
            with: [butterflyTexture(color: color, frame: 0),
                   butterflyTexture(color: color, frame: 1)],
            timePerFrame: 0.12, resize: false, restore: false
        )
        butterfly.run(SKAction.repeatForever(flap), withKey: "flap")

        // 楕円軌道: sin/cos を CGPath で近似
        let path = CGMutablePath()
        let rx: CGFloat = 16
        let ry: CGFloat = 10
        let cy: CGFloat = 16
        let steps = 36
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps) * .pi * 2
            let x = cos(t) * rx
            let y = sin(t) * ry + cy
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else      { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 5.2)
        butterfly.run(SKAction.repeatForever(follow), withKey: "butterflyFloat")
    }

    /// 横長の柔らかい雲（NSCache）
    static func cloudTexture(variant: Int = 0) -> SKTexture {
        let key = "cloud_\(variant)"
        return cached(key) {
            let size = CGSize(width: 96, height: 36)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(UIColor.white.withAlphaComponent(0.85).cgColor)
                cg.fillEllipse(in: CGRect(x: 6,  y: 12, width: 36, height: 22))
                cg.fillEllipse(in: CGRect(x: 28, y: 4,  width: 44, height: 28))
                cg.fillEllipse(in: CGRect(x: 56, y: 12, width: 36, height: 22))
                cg.setFillColor(UIColor.white.withAlphaComponent(0.45).cgColor)
                cg.fillEllipse(in: CGRect(x: 18, y: 18, width: 28, height: 14))
                cg.fillEllipse(in: CGRect(x: 50, y: 18, width: 28, height: 14))
            }
            let t = SKTexture(image: img); t.filteringMode = .linear; return t
        }
    }
}
