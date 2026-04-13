// IsoTileTextureGenerator.swift
// Core/DesignSystem/
//
// アイソメトリックタイルのテクスチャ生成
// SKShapeNode.fillTexture として使用（ひし形パスに自動クリッピング）
// タイルサイズ 64×32 px（CityScene.generateDefaultMap と一致）

import SpriteKit
import UIKit

// MARK: - TileStyle

enum TileStyle {
    case grassBright   // 中央広場（明るい緑）
    case grassMid      // 通常の芝生
    case grassDark     // 外周（暗い草地）
    case road          // アスファルト道路
    case plaza         // 石畳広場（市庁舎周辺）
}

// MARK: - IsoTileTextureGenerator

enum IsoTileTextureGenerator {

    private static var cache: [TileStyle: SKTexture] = [:]

    // MARK: - 公開 API

    /// タイルスタイルに対応する SKTexture を返す（キャッシュ付き）
    /// - Parameters:
    ///   - style: タイルの種類
    ///   - tileW: タイル横幅（default 64: generateDefaultMap と一致）
    ///   - tileH: タイル縦幅（default 32: generateDefaultMap と一致）
    static func texture(for style: TileStyle,
                        tileW: CGFloat = 64,
                        tileH: CGFloat = 32) -> SKTexture {
        if let cached = cache[style] { return cached }
        let image   = render(style: style, w: tileW, h: tileH)
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest  // ピクセルアート: 補間なし
        cache[style] = texture
        return texture
    }

    // MARK: - 描画ディスパッチ

    private static func render(style: TileStyle, w: CGFloat, h: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            switch style {
            case .grassBright:
                drawGrass(cg, w: w, h: h,
                          base: UIColor(red: 0.54, green: 0.83, blue: 0.42, alpha: 1),
                          bright: true)
            case .grassMid:
                drawGrass(cg, w: w, h: h,
                          base: UIColor(red: 0.44, green: 0.73, blue: 0.32, alpha: 1),
                          bright: false)
            case .grassDark:
                drawGrass(cg, w: w, h: h,
                          base: UIColor(red: 0.35, green: 0.62, blue: 0.24, alpha: 1),
                          bright: false)
            case .road:
                drawRoad(cg, w: w, h: h)
            case .plaza:
                drawPlaza(cg, w: w, h: h)
            }
        }
    }

    // MARK: - 芝生タイル

    private static func drawGrass(_ cg: CGContext, w: CGFloat, h: CGFloat,
                                   base: UIColor, bright: Bool) {
        // ベース塗り
        cg.setFillColor(base.cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: w, height: h))

        // アイソメトリックの「手前上」ハイライト（奥行き感）
        if bright {
            cg.setFillColor(UIColor.white.withAlphaComponent(0.10).cgColor)
            cg.fill(CGRect(x: w * 0.50, y: 0, width: w * 0.50, height: h * 0.50))
        }

        // 暗い草ドット（固定パターン: ランダム不使用で再現性確保）
        cg.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
        for (px, py) in darkDots {
            cg.fill(CGRect(x: px * w - 1, y: py * h - 1, width: 2, height: 2))
        }

        // 明るい草ドット
        cg.setFillColor(UIColor.white.withAlphaComponent(0.14).cgColor)
        for (px, py) in lightDots {
            cg.fill(CGRect(x: px * w - 1, y: py * h - 1, width: 2, height: 2))
        }
    }

    // 固定ドットパターン（再現性のある草模様）
    private static let darkDots: [(CGFloat, CGFloat)] = [
        (0.14, 0.28), (0.58, 0.20), (0.82, 0.44),
        (0.26, 0.65), (0.70, 0.72), (0.42, 0.82),
        (0.90, 0.34), (0.06, 0.78),
    ]
    private static let lightDots: [(CGFloat, CGFloat)] = [
        (0.35, 0.18), (0.65, 0.38), (0.18, 0.58),
        (0.50, 0.55), (0.85, 0.62),
    ]

    // MARK: - 道路タイル

    private static func drawRoad(_ cg: CGContext, w: CGFloat, h: CGFloat) {
        // アスファルトベース（濃いグレー）
        cg.setFillColor(UIColor(red: 0.26, green: 0.27, blue: 0.30, alpha: 1).cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: w, height: h))

        // 路面のかすかなグレインテクスチャ
        cg.setFillColor(UIColor.white.withAlphaComponent(0.04).cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: w * 0.5, height: h))

        // 縁の白線（左右エッジ）
        cg.setFillColor(UIColor.white.withAlphaComponent(0.28).cgColor)
        cg.fill(CGRect(x: 0, y: h * 0.10, width: w, height: 1.5))
        cg.fill(CGRect(x: 0, y: h * 0.82, width: w, height: 1.5))

        // センター破線（白）
        cg.setFillColor(UIColor.white.withAlphaComponent(0.62).cgColor)
        let dashW: CGFloat = w / 10
        for i in 0..<4 {
            let x = w * 0.08 + CGFloat(i) * dashW * 2.3
            if x + dashW * 1.1 <= w * 0.92 {
                cg.fill(CGRect(x: x, y: h * 0.43, width: dashW * 1.1, height: 2.0))
            }
        }
    }

    // MARK: - 広場タイル（石畳）

    private static func drawPlaza(_ cg: CGContext, w: CGFloat, h: CGFloat) {
        // 石畳ベース（温かみのある薄ベージュ）
        cg.setFillColor(UIColor(red: 0.87, green: 0.82, blue: 0.70, alpha: 1).cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: w, height: h))

        // ハイライト（奥行き感）
        cg.setFillColor(UIColor.white.withAlphaComponent(0.08).cgColor)
        cg.fill(CGRect(x: w * 0.50, y: 0, width: w * 0.50, height: h * 0.50))

        // 石の目地（縦横グリッド）
        cg.setFillColor(UIColor(red: 0.66, green: 0.60, blue: 0.50, alpha: 0.65).cgColor)
        // 縦線 3本（4分割）
        for i in 1...3 {
            let x = w * CGFloat(i) / 4.0
            cg.fill(CGRect(x: x, y: 0, width: 0.8, height: h))
        }
        // 横線 1本（2分割）
        cg.fill(CGRect(x: 0, y: h * 0.50, width: w, height: 0.8))
    }
}
