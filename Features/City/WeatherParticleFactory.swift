// WeatherParticleFactory.swift
// Features/City/
//
// 天気パーティクルを SKEmitterNode でプログラムから生成
// .sks ファイル不要 — CLAUDE.md Key Rule 5 の精神に準拠

import SpriteKit

// MARK: - WeatherParticleFactory

enum WeatherParticleFactory {

    /// 指定した天気タイプの SKEmitterNode を生成して返す
    /// nil の場合はパーティクル不要の天気（晴れ・曇り）
    static func emitter(for weather: WeatherType, sceneSize: CGSize) -> SKEmitterNode? {
        switch weather {
        case .rainy:  return makeRain(sceneSize: sceneSize)
        case .stormy: return makeStorm(sceneSize: sceneSize)
        default:      return nil
        }
    }

    // MARK: - 雨

    private static func makeRain(sceneSize: CGSize) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // 粒子テクスチャ（細長い線）
        emitter.particleTexture     = dropTexture()
        emitter.particleColor       = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.8)
        emitter.particleColorBlendFactor = 1.0

        // 生成位置（上端から横方向にランダム）
        emitter.position            = CGPoint(x: 0, y: sceneSize.height / 2 + 20)
        emitter.particlePositionRange = CGVector(dx: sceneSize.width + 40, dy: 0)

        // 速度・角度（斜め雨）
        emitter.particleSpeed       = 400
        emitter.particleSpeedRange  = 80
        emitter.emissionAngle       = -.pi / 2 - .pi / 8  // やや斜め
        emitter.emissionAngleRange  = .pi / 16

        // サイズ
        emitter.particleSize        = CGSize(width: 2, height: 10)
        emitter.particleScaleRange  = 0.3

        // ライフタイム
        emitter.particleLifetime    = 0.8
        emitter.particleLifetimeRange = 0.2

        // レート
        emitter.particleBirthRate   = 150

        // アルファ
        emitter.particleAlpha       = 0.7
        emitter.particleAlphaRange  = 0.2
        emitter.particleAlphaSpeed  = -0.5

        emitter.zPosition           = 200

        return emitter
    }

    // MARK: - 嵐

    private static func makeStorm(sceneSize: CGSize) -> SKEmitterNode {
        let emitter = makeRain(sceneSize: sceneSize)

        // 嵐は雨粒を増量・高速化・ランダム化
        emitter.particleBirthRate   = 300
        emitter.particleSpeed       = 600
        emitter.particleSpeedRange  = 150
        emitter.emissionAngle       = -.pi / 2 - .pi / 5   // さらに斜め
        emitter.emissionAngleRange  = .pi / 8
        emitter.particleAlpha       = 0.85
        emitter.particleColor       = UIColor(red: 0.6, green: 0.75, blue: 1.0, alpha: 0.9)

        return emitter
    }

    // MARK: - 雪（将来拡張用）

    static func makeSnow(sceneSize: CGSize) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleTexture     = snowflakeTexture()
        emitter.particleColor       = .white
        emitter.particleColorBlendFactor = 1.0
        emitter.position            = CGPoint(x: 0, y: sceneSize.height / 2 + 20)
        emitter.particlePositionRange = CGVector(dx: sceneSize.width + 40, dy: 0)
        emitter.particleSpeed       = 80
        emitter.particleSpeedRange  = 30
        emitter.emissionAngle       = -.pi / 2
        emitter.emissionAngleRange  = .pi / 6
        emitter.particleSize        = CGSize(width: 6, height: 6)
        emitter.particleLifetime    = 3.0
        emitter.particleBirthRate   = 40
        emitter.particleAlpha       = 0.9
        emitter.particleAlphaSpeed  = -0.2
        emitter.zPosition           = 200
        return emitter
    }

    // MARK: - 稲妻フラッシュ（嵐用）

    /// 嵐シーンに短時間の白フラッシュを追加
    static func addLightningFlash(to scene: SKScene) {
        let flash = SKSpriteNode(color: .white, size: scene.size)
        flash.alpha     = 0
        flash.zPosition = 250
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 2.0...6.0)),
            SKAction.fadeAlpha(to: 0.4, duration: 0.05),
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeAlpha(to: 0.3, duration: 0.03),
            SKAction.fadeOut(withDuration: 0.08),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - テクスチャ生成

    private static func dropTexture() -> SKTexture {
        let size = CGSize(width: 3, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            // グラデーション風の雨粒（上が濃く・下が薄い）
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.cgColor,
                    UIColor.white.withAlphaComponent(0.1).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width/2, y: size.height),
                end:   CGPoint(x: size.width/2, y: 0),
                options: []
            )
        }
        return SKTexture(image: image)
    }

    private static func snowflakeTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 6, height: 6))
        }
        return SKTexture(image: image)
    }
}

// MARK: - 雲スプライト生成

enum CloudFactory {

    static func makeCloud(for weather: WeatherType, sceneWidth: CGFloat) -> SKNode? {
        guard weather != .sunny else { return nil }
        let cloud = SKNode()
        let count = weather == .cloudy || weather == .stormy ? 5 : 3
        let baseAlpha: CGFloat = weather == .stormy ? 0.55 : (weather == .cloudy ? 0.4 : 0.25)

        for i in 0..<count {
            let puff = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 50...90),
                                                      height: CGFloat.random(in: 25...45)))
            puff.fillColor  = UIColor(white: 0.9, alpha: baseAlpha)
            puff.strokeColor = .clear
            puff.position   = CGPoint(x: CGFloat(i) * 30 - CGFloat(count) * 15,
                                      y: CGFloat.random(in: -10...10))
            cloud.addChild(puff)
        }

        // ゆったりと流れる
        let duration = Double.random(in: 20.0...35.0)
        let startX   = sceneWidth / 2 + 120
        let endX     = -sceneWidth / 2 - 120
        cloud.position = CGPoint(x: startX, y: CGFloat.random(in: 80...120))
        cloud.run(SKAction.sequence([
            SKAction.moveTo(x: endX, duration: duration),
            SKAction.removeFromParent()
        ]))

        return cloud
    }
}
