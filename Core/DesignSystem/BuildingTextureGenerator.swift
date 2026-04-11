// BuildingTextureGenerator.swift
// Core/DesignSystem/
//
// ゲーム内建物テクスチャをプログラムで生成（PNG アセット不要）
// UIGraphicsImageRenderer で描画 → SKTexture に変換
// 建物 ID ごとに固有シルエットを定義

import SpriteKit
import UIKit

// MARK: - BuildingTextureGenerator

enum BuildingTextureGenerator {

    // MARK: - キャッシュ

    private static var cache: [String: SKTexture] = [:]

    /// メモリ警告時にキャッシュを全クリア
    static func clearCache() {
        cache.removeAll()
    }

    /// 建物 ID・軸・レベルからテクスチャを生成（キャッシュ付き）
    static func texture(buildingId: String, axis: CPAxis, level: Int) -> SKTexture {
        let key = "\(buildingId)_lv\(level)"
        if let cached = cache[key] { return cached }
        let archetype = BuildingArchetype.archetype(for: buildingId)
        let texture   = generate(archetype: archetype, axis: axis, level: level)
        cache[key] = texture
        return texture
    }

    /// レベルバッジ付きテクスチャを生成
    private static func generate(archetype: BuildingArchetype, axis: CPAxis, level: Int) -> SKTexture {
        let size = CGSize(width: 64, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let color = axis.uiColor
            drawBuilding(cg, archetype: archetype, color: color, size: size, level: level)
        }
        return SKTexture(image: image)
    }

    // MARK: - 建物描画ディスパッチ

    private static func drawBuilding(
        _ ctx: CGContext, archetype: BuildingArchetype, color: UIColor,
        size: CGSize, level: Int
    ) {
        switch archetype {
        case .gym:       drawGym(ctx, color: color, size: size)
        case .stadium:   drawStadium(ctx, color: color, size: size)
        case .park:      drawPark(ctx, color: color, size: size)
        case .pool:      drawPool(ctx, color: color, size: size)
        case .shop:      drawShop(ctx, color: color, size: size)
        case .market:    drawMarket(ctx, color: color, size: size)
        case .cafe:      drawCafe(ctx, color: color, size: size)
        case .tower:     drawTower(ctx, color: color, size: size)
        case .clinic:    drawClinic(ctx, color: color, size: size)
        case .library:   drawLibrary(ctx, color: color, size: size)
        case .townhall:  drawTownHall(ctx, color: color, size: size)
        case .monument:  drawMonument(ctx, color: color, size: size)
        case .house:     drawHouse(ctx, color: color, size: size)
        }
        // レベルバッジ（Lv2以上）
        if level >= 2 { drawLevelBadge(ctx, level: level, size: size, color: color) }
    }

    // MARK: - 個別建物シルエット

    // ─── ジム（運動軸）───
    private static func drawGym(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        // 影
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.15).cgColor)
        ctx.fill(CGRect(x: 8, y: 4, width: w - 14, height: h - 8))
        // 壁
        let wall = CGRect(x: 6, y: 8, width: w - 14, height: h - 14)
        fillRect(ctx, rect: wall, color: color.darkened(0.15))
        // 屋根（三角）
        let roof = CGMutablePath()
        roof.move(to: CGPoint(x: 4, y: h - 12))
        roof.addLine(to: CGPoint(x: w / 2, y: h - 4))
        roof.addLine(to: CGPoint(x: w - 4, y: h - 12))
        roof.closeSubpath()
        ctx.addPath(roof)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        // 窓（2×3 グリッド）
        let winColor = UIColor.white.withAlphaComponent(0.7)
        for row in 0..<2 {
            for col in 0..<3 {
                let wx = 10 + CGFloat(col) * 14
                let wy = 14 + CGFloat(row) * 16
                fillRect(ctx, rect: CGRect(x: wx, y: wy, width: 10, height: 10), color: winColor)
            }
        }
        // ドア
        fillRect(ctx, rect: CGRect(x: w / 2 - 5, y: 8, width: 10, height: 14), color: color.darkened(0.3))
    }

    // ─── スタジアム（運動軸）───
    private static func drawStadium(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.1).cgColor)
        ctx.fill(CGRect(x: 4, y: 2, width: w - 6, height: h - 6))
        // 楕円形スタジアム
        let oval = CGRect(x: 4, y: 16, width: w - 8, height: h - 22)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: oval)
        ctx.setFillColor(color.darkened(0.2).cgColor)
        ctx.fillEllipse(in: oval.insetBy(dx: 8, dy: 6))
        // フィールド（緑）
        ctx.setFillColor(UIColor(red: 0.2, green: 0.65, blue: 0.3, alpha: 1).cgColor)
        ctx.fillEllipse(in: oval.insetBy(dx: 14, dy: 10))
        // 屋根リング
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(2)
        ctx.strokeEllipse(in: oval.insetBy(dx: 2, dy: 2))
        // 看板
        fillRect(ctx, rect: CGRect(x: w/2-14, y: h-10, width: 28, height: 8),
                 color: color.darkened(0.1))
    }

    // ─── 公園（運動軸）───
    private static func drawPark(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        // 地面
        fillRect(ctx, rect: CGRect(x: 4, y: 4, width: w - 8, height: h - 8),
                 color: UIColor(red: 0.35, green: 0.65, blue: 0.3, alpha: 1))
        // 木（3本）
        for i in 0..<3 {
            let tx = 10 + CGFloat(i) * 18
            // 幹
            fillRect(ctx, rect: CGRect(x: tx + 4, y: 8, width: 6, height: 16), color: UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1))
            // 葉
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: tx, y: 18, width: 14, height: 18))
        }
        // 道路
        ctx.setFillColor(UIColor(white: 0.8, alpha: 0.6).cgColor)
        ctx.fill(CGRect(x: w/2-3, y: 4, width: 6, height: h - 8))
    }

    // ─── プール（運動軸）───
    private static func drawPool(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        fillRect(ctx, rect: CGRect(x: 4, y: 8, width: w-8, height: h-14),
                 color: UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1))
        // 水面
        ctx.setFillColor(UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.5).cgColor)
        ctx.fill(CGRect(x: 8, y: 12, width: w-16, height: h-24))
        // 波紋
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(1.5)
        for i in 0..<3 {
            let ly = 18 + CGFloat(i) * 8
            ctx.strokeLineSegments(between: [CGPoint(x: 12, y: ly), CGPoint(x: w-12, y: ly)])
        }
        // 縁
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(2)
        ctx.stroke(CGRect(x: 8, y: 12, width: w-16, height: h-24))
    }

    // ─── ショップ（汎用）───
    private static func drawShop(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        fillRect(ctx, rect: CGRect(x: 8, y: 6, width: w-16, height: h-12), color: color.darkened(0.15))
        // 庇（ひさし）
        fillRect(ctx, rect: CGRect(x: 4, y: h-20, width: w-8, height: 6), color: color)
        // 看板
        fillRect(ctx, rect: CGRect(x: 10, y: h-32, width: w-20, height: 10), color: UIColor.white.withAlphaComponent(0.8))
        // ドア
        fillRect(ctx, rect: CGRect(x: w/2-6, y: 6, width: 12, height: 14), color: color.darkened(0.35))
        // 窓
        fillRect(ctx, rect: CGRect(x: 10, y: h-48, width: 14, height: 12), color: UIColor.white.withAlphaComponent(0.6))
        fillRect(ctx, rect: CGRect(x: w-24, y: h-48, width: 14, height: 12), color: UIColor.white.withAlphaComponent(0.6))
    }

    // ─── マーケット（食事軸）───
    private static func drawMarket(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        // テント屋根
        let tent = CGMutablePath()
        tent.move(to: CGPoint(x: 2, y: h-18))
        tent.addLine(to: CGPoint(x: w/2, y: h-6))
        tent.addLine(to: CGPoint(x: w-2, y: h-18))
        tent.closeSubpath()
        ctx.addPath(tent)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        // 台
        fillRect(ctx, rect: CGRect(x: 6, y: 6, width: w-12, height: h-24), color: color.darkened(0.2))
        // 商品（カラフルな小矩形）
        let prodColors: [UIColor] = [.red, .orange, .green, .yellow]
        for (i, pc) in prodColors.enumerated() {
            fillRect(ctx, rect: CGRect(x: 10 + CGFloat(i)*12, y: h-28, width: 8, height: 6),
                     color: pc.withAlphaComponent(0.8))
        }
    }

    // ─── カフェ（食事軸）───
    private static func drawCafe(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        fillRect(ctx, rect: CGRect(x: 6, y: 6, width: w-12, height: h-12), color: color.darkened(0.12))
        // 丸屋根
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: 4, y: h-22, width: w-8, height: 20))
        // 窓
        let winColor = UIColor.white.withAlphaComponent(0.7)
        fillRect(ctx, rect: CGRect(x: 10, y: h-40, width: 16, height: 14), color: winColor)
        fillRect(ctx, rect: CGRect(x: w-26, y: h-40, width: 16, height: 14), color: winColor)
        // ドア
        fillRect(ctx, rect: CGRect(x: w/2-5, y: 6, width: 10, height: 16), color: color.darkened(0.3))
        // 煙突
        fillRect(ctx, rect: CGRect(x: w-14, y: h-10, width: 6, height: 12), color: color.darkened(0.25))
    }

    // ─── タワー（睡眠軸）───
    private static func drawTower(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        // 影
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.1).cgColor)
        ctx.fill(CGRect(x: w/2-6, y: 2, width: 16, height: h-4))
        // 本体
        fillRect(ctx, rect: CGRect(x: w/2-10, y: 6, width: 20, height: h-14), color: color.darkened(0.15))
        // 屋根（三角）
        let roof = CGMutablePath()
        roof.move(to: CGPoint(x: w/2-12, y: h-12))
        roof.addLine(to: CGPoint(x: w/2, y: h-2))
        roof.addLine(to: CGPoint(x: w/2+12, y: h-12))
        roof.closeSubpath()
        ctx.addPath(roof)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        // 窓（縦列）
        for row in 0..<4 {
            fillRect(ctx, rect: CGRect(x: w/2-4, y: 10 + CGFloat(row)*14, width: 8, height: 8),
                     color: UIColor.white.withAlphaComponent(0.65))
        }
    }

    // ─── クリニック（睡眠軸）───
    private static func drawClinic(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        fillRect(ctx, rect: CGRect(x: 6, y: 8, width: w-12, height: h-14), color: color.darkened(0.1))
        // 平屋根
        fillRect(ctx, rect: CGRect(x: 4, y: h-14, width: w-8, height: 8), color: color)
        // 十字（医療マーク）
        fillRect(ctx, rect: CGRect(x: w/2-2, y: h-24, width: 4, height: 14), color: UIColor.white.withAlphaComponent(0.9))
        fillRect(ctx, rect: CGRect(x: w/2-8, y: h-18, width: 16, height: 4), color: UIColor.white.withAlphaComponent(0.9))
        // 窓
        for row in 0..<2 {
            for col in 0..<2 {
                fillRect(ctx, rect: CGRect(x: 10 + CGFloat(col)*20, y: 14 + CGFloat(row)*18, width: 12, height: 12),
                         color: UIColor.white.withAlphaComponent(0.5))
            }
        }
    }

    // ─── 図書館（生活習慣軸）───
    private static func drawLibrary(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        fillRect(ctx, rect: CGRect(x: 4, y: 6, width: w-8, height: h-10), color: color.darkened(0.1))
        // 三角屋根
        let roof = CGMutablePath()
        roof.move(to: CGPoint(x: 2, y: h-12))
        roof.addLine(to: CGPoint(x: w/2, y: h-2))
        roof.addLine(to: CGPoint(x: w-2, y: h-12))
        roof.closeSubpath()
        ctx.addPath(roof)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        // 柱（2本）
        fillRect(ctx, rect: CGRect(x: 8, y: 6, width: 6, height: h-18), color: UIColor.white.withAlphaComponent(0.25))
        fillRect(ctx, rect: CGRect(x: w-14, y: 6, width: 6, height: h-18), color: UIColor.white.withAlphaComponent(0.25))
        // ドア
        fillRect(ctx, rect: CGRect(x: w/2-7, y: 6, width: 14, height: 18), color: color.darkened(0.4))
        // 本棚（窓風）
        for i in 0..<3 {
            fillRect(ctx, rect: CGRect(x: 18 + CGFloat(i)*10, y: h-36, width: 6, height: 14),
                     color: UIColor.white.withAlphaComponent(0.4))
        }
    }

    // ─── 市庁舎（生活習慣軸: B025）───
    private static func drawTownHall(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        // 本体
        fillRect(ctx, rect: CGRect(x: 4, y: 4, width: w-8, height: h-12), color: color.darkened(0.15))
        // 大きいドーム
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: w/2-12, y: h-20, width: 24, height: 18))
        // フラッグポール
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeLineSegments(between: [CGPoint(x: w/2, y: h-20), CGPoint(x: w/2, y: h-4)])
        // 旗
        ctx.setFillColor(UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1).cgColor)
        ctx.fill(CGRect(x: w/2, y: h-4, width: 8, height: 5))
        // 柱（4本）
        for i in 0..<4 {
            let px = 8 + CGFloat(i) * 12
            fillRect(ctx, rect: CGRect(x: px, y: 4, width: 5, height: h-24),
                     color: UIColor.white.withAlphaComponent(0.2))
        }
        // 窓
        for row in 0..<2 {
            for col in 0..<3 {
                fillRect(ctx, rect: CGRect(x: 10 + CGFloat(col)*16, y: 10 + CGFloat(row)*18, width: 10, height: 12),
                         color: UIColor.white.withAlphaComponent(0.55))
            }
        }
    }

    // ─── モニュメント（生活習慣軸: B026）───
    private static func drawMonument(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        // 台座
        fillRect(ctx, rect: CGRect(x: 8, y: 4, width: w-16, height: 10), color: color.darkened(0.2))
        // 細い塔
        fillRect(ctx, rect: CGRect(x: w/2-5, y: 12, width: 10, height: h-20), color: color.darkened(0.1))
        // 先端
        let tip = CGMutablePath()
        tip.move(to: CGPoint(x: w/2-6, y: h-8))
        tip.addLine(to: CGPoint(x: w/2, y: h-1))
        tip.addLine(to: CGPoint(x: w/2+6, y: h-8))
        tip.closeSubpath()
        ctx.addPath(tip)
        ctx.setFillColor(UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1).cgColor)
        ctx.fillPath()
        // 数字（連続記録日数をイメージ）
        fillRect(ctx, rect: CGRect(x: w/2-4, y: 20, width: 8, height: 10), color: UIColor.white.withAlphaComponent(0.7))
    }

    // ─── 家（汎用小型建物）───
    private static func drawHouse(_ ctx: CGContext, color: UIColor, size: CGSize) {
        let w = size.width, h = size.height
        fillRect(ctx, rect: CGRect(x: 8, y: 6, width: w-16, height: h-16), color: color.darkened(0.15))
        // 三角屋根
        let roof = CGMutablePath()
        roof.move(to: CGPoint(x: 6, y: h-14))
        roof.addLine(to: CGPoint(x: w/2, y: h-4))
        roof.addLine(to: CGPoint(x: w-6, y: h-14))
        roof.closeSubpath()
        ctx.addPath(roof)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        // 窓
        fillRect(ctx, rect: CGRect(x: 10, y: h-30, width: 12, height: 12), color: UIColor.white.withAlphaComponent(0.6))
        fillRect(ctx, rect: CGRect(x: w-22, y: h-30, width: 12, height: 12), color: UIColor.white.withAlphaComponent(0.6))
        // ドア
        fillRect(ctx, rect: CGRect(x: w/2-5, y: 6, width: 10, height: 14), color: color.darkened(0.3))
    }

    // MARK: - レベルバッジ

    private static func drawLevelBadge(_ ctx: CGContext, level: Int, size: CGSize, color: UIColor) {
        let badgeRect = CGRect(x: size.width - 18, y: size.height - 18, width: 16, height: 16)
        // バッジ背景
        ctx.setFillColor(UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.95).cgColor)
        ctx.fillEllipse(in: badgeRect)
        // テキスト "Lv.N"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 7),
            .foregroundColor: UIColor.black
        ]
        let str = NSAttributedString(string: "\(level)", attributes: attrs)
        let textSize = str.size()
        str.draw(at: CGPoint(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2
        ))
    }

    // MARK: - ユーティリティ

    private static func fillRect(_ ctx: CGContext, rect: CGRect, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
    }
}

// MARK: - BuildingArchetype

enum BuildingArchetype {
    case gym, stadium, park, pool
    case shop, market, cafe
    case tower, clinic
    case library, townhall, monument, house

    static func archetype(for id: String) -> BuildingArchetype {
        switch id {
        case "B001": return .gym
        case "B002": return .stadium
        case "B003": return .park
        case "B004": return .pool
        case "B005": return .cafe        // ヨガスタジオ
        case "B006": return .shop        // 自転車ステーション
        case "B007": return .cafe        // オーガニックカフェ
        case "B008": return .market      // ファーマーズマーケット
        case "B009": return .house       // ヘルシーレストラン
        case "B010": return .library     // 料理教室
        case "B011": return .shop        // サラダバー
        case "B012": return .shop        // ジューススタンド
        case "B013": return .clinic      // 瞑想センター
        case "B014": return .shop        // ハーブティーショップ
        case "B015": return .cafe        // セルフケアスパ
        case "B016": return .house       // コミュニティセンター
        case "B017": return .clinic      // 睡眠クリニック
        case "B018": return .tower       // 天文台
        case "B019": return .library     // 図書館（生活習慣軸: CLAUDE.md）
        case "B020": return .shop        // アロマテラピーショップ
        case "B021": return .park        // ムーンライトパーク
        case "B022": return .shop        // 布団・寝具専門店
        case "B023": return .shop        // ウォーターサーバー広場
        case "B024": return .clinic      // メンタルヘルスクリニック
        case "B025": return .townhall    // 市庁舎
        case "B026": return .monument    // 習慣カレンダータワー
        case "B027": return .shop        // ウェルネスショップ
        case "B028": return .house       // 公民館
        // 自動生成（B029 居酒屋・B030 廃墟ビル: CLAUDE.md Key Rule 4）
        case "B029": return .shop        // 居酒屋（スラム地区）
        case "B030": return .house       // 廃墟ビル（スラム地区）
        default:     return .house
        }
    }
}

// MARK: - UIColor ヘルパー

extension UIColor {
    func darkened(_ amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(0, b - amount), alpha: a)
    }
}

// CPAxis → UIColor
extension CPAxis {
    var uiColor: UIColor {
        switch self {
        case .exercise:  return UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        case .diet:      return UIColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1)
        case .alcohol:   return UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1)
        case .sleep:     return UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
        case .lifestyle: return UIColor(red: 1.00, green: 0.18, blue: 0.33, alpha: 1)
        }
    }
}
