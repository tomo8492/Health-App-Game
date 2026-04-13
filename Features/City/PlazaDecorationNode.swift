// PlazaDecorationNode.swift
// Features/City/
//
// 中央広場の装飾ノード（噴水・街灯・ベンチ）
// - プログラム生成（PNG アセット不要）
// - 噴水: アニメーション付き水しぶき + 波紋
// - 街灯: 夜間グロー点滅アニメーション
// - ベンチ: 4方向対応（facing で向きを指定）

import SpriteKit

// MARK: - PlazaDecorationType

enum PlazaDecorationType {
    case fountain
    case streetlight
    case bench(facing: BenchFacing)
}

enum BenchFacing {
    case northEast   // アイソメ: 右上向き
    case southWest   // アイソメ: 左下向き
    case northWest   // アイソメ: 左上向き
    case southEast   // アイソメ: 右下向き
}

// MARK: - PlazaDecorationNode

final class PlazaDecorationNode: SKNode {

    init(type: PlazaDecorationType) {
        super.init()
        switch type {
        case .fountain:             setupFountain()
        case .streetlight:          setupStreetlight()
        case .bench(let facing):    setupBench(facing: facing)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 噴水

    private func setupFountain() {

        // ── 地面影 ──────────────────────────────────────────────────────
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 44, height: 16))
        shadow.fillColor   = UIColor.black.withAlphaComponent(0.16)
        shadow.strokeColor = .clear
        shadow.position    = CGPoint(x: 3, y: -18)
        shadow.zPosition   = -2
        addChild(shadow)

        // ── 石組みベース（大） ──────────────────────────────────────────
        let base = SKShapeNode(ellipseOf: CGSize(width: 40, height: 16))
        base.fillColor   = UIColor(red: 0.68, green: 0.63, blue: 0.55, alpha: 1)
        base.strokeColor = UIColor(red: 0.50, green: 0.46, blue: 0.40, alpha: 1)
        base.lineWidth   = 1.0
        base.position    = CGPoint(x: 0, y: -10)
        base.zPosition   = 0
        addChild(base)

        // ── 水面 ────────────────────────────────────────────────────────
        let water = SKShapeNode(ellipseOf: CGSize(width: 32, height: 12))
        water.fillColor   = UIColor(red: 0.36, green: 0.70, blue: 0.92, alpha: 0.82)
        water.strokeColor = UIColor(red: 0.20, green: 0.52, blue: 0.82, alpha: 0.50)
        water.lineWidth   = 0.8
        water.position    = CGPoint(x: 0, y: -10)
        water.zPosition   = 1
        addChild(water)

        // ── 中央台座 ────────────────────────────────────────────────────
        let pedestal = SKShapeNode(rectOf: CGSize(width: 8, height: 22), cornerRadius: 2)
        pedestal.fillColor   = UIColor(red: 0.72, green: 0.67, blue: 0.58, alpha: 1)
        pedestal.strokeColor = UIColor(red: 0.52, green: 0.48, blue: 0.40, alpha: 0.7)
        pedestal.lineWidth   = 0.6
        pedestal.position    = CGPoint(x: 0, y: -1)
        pedestal.zPosition   = 2
        addChild(pedestal)

        // ── 水しぶき（4方向） ───────────────────────────────────────────
        let sprayAngles: [CGFloat] = [.pi/4, 3*.pi/4, 5*.pi/4, 7*.pi/4]
        for (i, angle) in sprayAngles.enumerated() {
            let spray = SKShapeNode(ellipseOf: CGSize(width: 4, height: 10))
            spray.fillColor   = UIColor(red: 0.68, green: 0.88, blue: 1.00, alpha: 0.75)
            spray.strokeColor = .clear
            let r: CGFloat = 5
            spray.position = CGPoint(
                x: r * cos(angle),
                y: r * sin(angle) * 0.4 + 12  // 上方向に傾ける
            )
            spray.zRotation = angle + .pi / 2
            spray.zPosition = 3
            addChild(spray)

            // 位相をずらしたパルスアニメーション
            let wait   = SKAction.wait(forDuration: Double(i) * 0.18)
            let pulse  = SKAction.repeatForever(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.90, duration: 0.55),
                    SKAction.scaleX(to: 1.0, y: 1.35, duration: 0.55),
                ]),
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.30, duration: 0.55),
                    SKAction.scaleX(to: 0.75, y: 0.65, duration: 0.55),
                ]),
            ]))
            spray.run(SKAction.sequence([wait, pulse]))
        }

        // ── 波紋（繰り返し拡大→フェード） ──────────────────────────────
        let ripple = SKShapeNode(ellipseOf: CGSize(width: 22, height: 9))
        ripple.fillColor   = .clear
        ripple.strokeColor = UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 0.45)
        ripple.lineWidth   = 1.0
        ripple.position    = CGPoint(x: 0, y: -10)
        ripple.zPosition   = 1.5
        addChild(ripple)

        let rippleAnim = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { ripple.setScale(0.7); ripple.alpha = 0.45 },
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 1.4),
                SKAction.fadeOut(withDuration: 1.4),
            ]),
        ]))
        ripple.run(rippleAnim)
    }

    // MARK: - 街灯

    private func setupStreetlight() {

        // ── 台座 ────────────────────────────────────────────────────────
        let base = SKShapeNode(rectOf: CGSize(width: 9, height: 5), cornerRadius: 1)
        base.fillColor   = UIColor(red: 0.52, green: 0.52, blue: 0.54, alpha: 1)
        base.strokeColor = UIColor(red: 0.36, green: 0.36, blue: 0.38, alpha: 0.6)
        base.lineWidth   = 0.5
        base.position    = CGPoint(x: 0, y: -10)
        base.zPosition   = 0
        addChild(base)

        // ── ポール ──────────────────────────────────────────────────────
        let pole = SKShapeNode(rectOf: CGSize(width: 3, height: 30), cornerRadius: 0.5)
        pole.fillColor   = UIColor(red: 0.58, green: 0.58, blue: 0.60, alpha: 1)
        pole.strokeColor = UIColor(red: 0.38, green: 0.38, blue: 0.40, alpha: 0.5)
        pole.lineWidth   = 0.4
        pole.position    = CGPoint(x: 0, y: 6)
        pole.zPosition   = 0
        addChild(pole)

        // ── アーム（横ブラケット） ───────────────────────────────────────
        let arm = SKShapeNode(rectOf: CGSize(width: 11, height: 2))
        arm.fillColor   = UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1)
        arm.strokeColor = .clear
        arm.position    = CGPoint(x: 5, y: 21)
        arm.zPosition   = 0
        addChild(arm)

        // ── ランプヘッド ─────────────────────────────────────────────────
        let lampHousing = SKShapeNode(rectOf: CGSize(width: 11, height: 5), cornerRadius: 2)
        lampHousing.fillColor   = UIColor(red: 0.50, green: 0.50, blue: 0.52, alpha: 1)
        lampHousing.strokeColor = UIColor(red: 0.36, green: 0.36, blue: 0.38, alpha: 0.6)
        lampHousing.lineWidth   = 0.5
        lampHousing.position    = CGPoint(x: 5, y: 19)
        lampHousing.zPosition   = 1
        addChild(lampHousing)

        let lamp = SKShapeNode(ellipseOf: CGSize(width: 9, height: 4))
        lamp.fillColor   = UIColor(red: 1.00, green: 0.92, blue: 0.55, alpha: 1)
        lamp.strokeColor = UIColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 0.5)
        lamp.lineWidth   = 0.4
        lamp.position    = CGPoint(x: 5, y: 17)
        lamp.zPosition   = 2
        addChild(lamp)

        // ── グロー効果（夜間点滅） ───────────────────────────────────────
        let glow = SKShapeNode(ellipseOf: CGSize(width: 22, height: 14))
        glow.fillColor   = UIColor(red: 1.00, green: 0.95, blue: 0.62, alpha: 0.12)
        glow.strokeColor = .clear
        glow.position    = CGPoint(x: 5, y: 14)
        glow.zPosition   = -1
        addChild(glow)

        let glowPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.22, duration: 2.2),
            SKAction.fadeAlpha(to: 0.07, duration: 2.2),
        ]))
        glow.run(glowPulse)
    }

    // MARK: - ベンチ

    private func setupBench(facing: BenchFacing) {
        // アイソメビューで読めるように向きを回転
        switch facing {
        case .northEast:  zRotation =  0
        case .southWest:  zRotation =  .pi
        case .northWest:  zRotation =  .pi / 2
        case .southEast:  zRotation = -.pi / 2
        }

        // ── 座面スラット（3本） ─────────────────────────────────────────
        let slatColors: [UIColor] = [
            UIColor(red: 0.60, green: 0.38, blue: 0.15, alpha: 1),
            UIColor(red: 0.66, green: 0.44, blue: 0.20, alpha: 1),
            UIColor(red: 0.58, green: 0.36, blue: 0.13, alpha: 1),
        ]
        for (i, color) in slatColors.enumerated() {
            let slat = SKShapeNode(rectOf: CGSize(width: 20, height: 3), cornerRadius: 0.5)
            slat.fillColor   = color
            slat.strokeColor = UIColor(red: 0.36, green: 0.22, blue: 0.08, alpha: 0.4)
            slat.lineWidth   = 0.3
            slat.position    = CGPoint(x: 0, y: CGFloat(i) * 3.2 - 3)
            slat.zPosition   = 1
            addChild(slat)
        }

        // ── 背もたれ ────────────────────────────────────────────────────
        let back = SKShapeNode(rectOf: CGSize(width: 20, height: 3), cornerRadius: 0.5)
        back.fillColor   = UIColor(red: 0.55, green: 0.33, blue: 0.12, alpha: 1)
        back.strokeColor = UIColor(red: 0.36, green: 0.22, blue: 0.08, alpha: 0.4)
        back.lineWidth   = 0.3
        back.position    = CGPoint(x: 0, y: 13)
        back.zPosition   = 2
        addChild(back)

        // ── 脚（2本） ────────────────────────────────────────────────────
        for lx in [-8.0, 8.0] {
            let leg = SKShapeNode(rectOf: CGSize(width: 2.5, height: 10), cornerRadius: 0.4)
            leg.fillColor   = UIColor(red: 0.44, green: 0.30, blue: 0.14, alpha: 1)
            leg.strokeColor = .clear
            leg.position    = CGPoint(x: lx, y: -7)
            leg.zPosition   = 0
            addChild(leg)
        }
    }
}
