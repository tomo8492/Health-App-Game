// PixelArtRenderer.swift
// Core/
//
// ドット絵テクスチャをプログラムで生成するユーティリティ
// 参考デザイン: カイロソフト風アイソメトリックシティ + RPGキャラクター
//
// アイソメトリック座標系:
//   - タイル: 64×32 px (ダイアモンド形)
//   - 建物: 64×(tileH + floors*20) px
//   - NPC:  8col×14row の論理ピクセル × 3px = 24×42 px

import SpriteKit
import UIKit

// MARK: - UIColor Hex Helper

extension UIColor {
    convenience init(hex: String) {
        let s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let a, r, g, b: UInt64
        switch s.count {
        case 3: (a,r,g,b) = (255,(v>>8)*17,(v>>4 & 0xF)*17,(v & 0xF)*17)
        case 6: (a,r,g,b) = (255,v>>16,v>>8 & 0xFF,v & 0xFF)
        case 8: (a,r,g,b) = (v>>24,v>>16 & 0xFF,v>>8 & 0xFF,v & 0xFF)
        default:(a,r,g,b) = (255,255,255,255)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255,
                  blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
}

// MARK: - NPC Type

enum NPCType: Int, CaseIterable {
    case adventurer = 0  // 参考画像2: ブロンド+オレンジ外套+ティールチュニック
    case citizen1   = 1  // 青系市民
    case citizen2   = 2  // 赤系市民
    case elder      = 3  // 白髪のお年寄り
    case child      = 4  // 子ども
}

// MARK: - Building Visual Config

struct BuildingVisualConfig {
    let topColor:    UIColor
    let leftColor:   UIColor
    let rightColor:  UIColor
    let windowColor: UIColor
    let accentColor: UIColor
    let floors:      Int
    let roofStyle:   RoofStyle

    enum RoofStyle { case flat, pitched, dome }
}

// MARK: - Building Config Factory

extension BuildingVisualConfig {
    // swiftlint:disable:next function_body_length
    static func make(id: String, level: Int) -> BuildingVisualConfig {
        let lv = min(max(level, 1), 5)
        switch id {
        // ── 運動軸 ──────────────────────────────────────────────────
        case "B001": return .init(topColor: UIColor(hex:"81C784"), leftColor: UIColor(hex:"4CAF50"), rightColor: UIColor(hex:"388E3C"), windowColor: UIColor(hex:"B3E5FC"), accentColor: UIColor(hex:"FF5722"), floors: min(lv+1,5), roofStyle:.flat)
        case "B002": return .init(topColor: UIColor(hex:"AEDD8A"), leftColor: UIColor(hex:"7BC050"), rightColor: UIColor(hex:"5A9030"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"FF5722"), floors: min(lv+2,5), roofStyle:.flat)
        case "B003": return .init(topColor: UIColor(hex:"8BC34A"), leftColor: UIColor(hex:"689F38"), rightColor: UIColor(hex:"4CAF50"), windowColor: UIColor(hex:"B3E5FC"), accentColor: UIColor(hex:"4CAF50"), floors: 1, roofStyle:.flat)
        case "B004": return .init(topColor: UIColor(hex:"B3E5FC"), leftColor: UIColor(hex:"4FC3F7"), rightColor: UIColor(hex:"0288D1"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"29B6F6"), floors: min(lv+1,3), roofStyle:.flat)
        case "B005": return .init(topColor: UIColor(hex:"E1BEE7"), leftColor: UIColor(hex:"CE93D8"), rightColor: UIColor(hex:"9C27B0"), windowColor: UIColor(hex:"F3E5F5"), accentColor: UIColor(hex:"E91E63"), floors: 2, roofStyle:.flat)
        case "B006": return .init(topColor: UIColor(hex:"FFF176"), leftColor: UIColor(hex:"FDD835"), rightColor: UIColor(hex:"F9A825"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"F44336"), floors: 1, roofStyle:.flat)
        // ── 食事軸 ──────────────────────────────────────────────────
        case "B007": return .init(topColor: UIColor(hex:"FFCC80"), leftColor: UIColor(hex:"FFA726"), rightColor: UIColor(hex:"E65100"), windowColor: UIColor(hex:"FFECB3"), accentColor: UIColor(hex:"8D6E63"), floors: 2, roofStyle:.flat)
        case "B008": return .init(topColor: UIColor(hex:"A5D6A7"), leftColor: UIColor(hex:"66BB6A"), rightColor: UIColor(hex:"388E3C"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"FF8F00"), floors: 1, roofStyle:.pitched)
        case "B009": return .init(topColor: UIColor(hex:"EF9A9A"), leftColor: UIColor(hex:"E53935"), rightColor: UIColor(hex:"B71C1C"), windowColor: UIColor(hex:"FFECB3"), accentColor: UIColor(hex:"FF9800"), floors: min(lv+1,3), roofStyle:.flat)
        case "B010": return .init(topColor: UIColor(hex:"FFCDD2"), leftColor: UIColor(hex:"FF8A65"), rightColor: UIColor(hex:"BF360C"), windowColor: UIColor(hex:"B3E5FC"), accentColor: UIColor(hex:"FDD835"), floors: 2, roofStyle:.flat)
        case "B011": return .init(topColor: UIColor(hex:"DCEDC8"), leftColor: UIColor(hex:"9CCC65"), rightColor: UIColor(hex:"558B2F"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"FF8F00"), floors: 1, roofStyle:.flat)
        case "B012": return .init(topColor: UIColor(hex:"FFE082"), leftColor: UIColor(hex:"FFC107"), rightColor: UIColor(hex:"FF8F00"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"8BC34A"), floors: 1, roofStyle:.flat)
        // ── 飲酒軸（中央広場寄与: CLAUDE.md Key Rule 2）────────────
        case "B013": return .init(topColor: UIColor(hex:"E8EAF6"), leftColor: UIColor(hex:"9FA8DA"), rightColor: UIColor(hex:"3949AB"), windowColor: UIColor(hex:"E8EAF6"), accentColor: UIColor(hex:"7E57C2"), floors: 3, roofStyle:.dome)
        case "B014": return .init(topColor: UIColor(hex:"F3E5F5"), leftColor: UIColor(hex:"CE93D8"), rightColor: UIColor(hex:"6A1B9A"), windowColor: UIColor(hex:"F3E5F5"), accentColor: UIColor(hex:"AB47BC"), floors: 2, roofStyle:.flat)
        case "B015": return .init(topColor: UIColor(hex:"EDE7F6"), leftColor: UIColor(hex:"B39DDB"), rightColor: UIColor(hex:"512DA8"), windowColor: UIColor(hex:"E1F5FE"), accentColor: UIColor(hex:"FF80AB"), floors: 3, roofStyle:.flat)
        case "B016": return .init(topColor: UIColor(hex:"D7CCC8"), leftColor: UIColor(hex:"A1887F"), rightColor: UIColor(hex:"4E342E"), windowColor: UIColor(hex:"FFECB3"), accentColor: UIColor(hex:"9C27B0"), floors: 2, roofStyle:.flat)
        // ── 睡眠軸 ──────────────────────────────────────────────────
        case "B017": return .init(topColor: UIColor(hex:"E3F2FD"), leftColor: UIColor(hex:"64B5F6"), rightColor: UIColor(hex:"1565C0"), windowColor: UIColor(hex:"E3F2FD"), accentColor: UIColor(hex:"29B6F6"), floors: min(lv+1,4), roofStyle:.flat)
        case "B018": return .init(topColor: UIColor(hex:"B0BEC5"), leftColor: UIColor(hex:"78909C"), rightColor: UIColor(hex:"37474F"), windowColor: UIColor(hex:"E1F5FE"), accentColor: UIColor(hex:"FFF176"), floors: 3, roofStyle:.dome)
        case "B019": return .init(topColor: UIColor(hex:"FFCCBC"), leftColor: UIColor(hex:"FF7043"), rightColor: UIColor(hex:"BF360C"), windowColor: UIColor(hex:"FFF9C4"), accentColor: UIColor(hex:"5D4037"), floors: 2, roofStyle:.pitched)
        case "B020": return .init(topColor: UIColor(hex:"F8BBD0"), leftColor: UIColor(hex:"F06292"), rightColor: UIColor(hex:"C2185B"), windowColor: UIColor(hex:"F3E5F5"), accentColor: UIColor(hex:"AB47BC"), floors: 1, roofStyle:.flat)
        case "B021": return .init(topColor: UIColor(hex:"1A237E"), leftColor: UIColor(hex:"283593"), rightColor: UIColor(hex:"0D1464"), windowColor: UIColor(hex:"E8EAF6"), accentColor: UIColor(hex:"FFF176"), floors: 1, roofStyle:.flat)
        case "B022": return .init(topColor: UIColor(hex:"FAFAFA"), leftColor: UIColor(hex:"E0E0E0"), rightColor: UIColor(hex:"9E9E9E"), windowColor: UIColor(hex:"B3E5FC"), accentColor: UIColor(hex:"1976D2"), floors: 2, roofStyle:.flat)
        // ── 生活習慣軸 ──────────────────────────────────────────────
        case "B023": return .init(topColor: UIColor(hex:"B3E5FC"), leftColor: UIColor(hex:"4FC3F7"), rightColor: UIColor(hex:"0277BD"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"00BCD4"), floors: 1, roofStyle:.flat)
        case "B024": return .init(topColor: UIColor(hex:"E8F5E9"), leftColor: UIColor(hex:"81C784"), rightColor: UIColor(hex:"1B5E20"), windowColor: UIColor(hex:"E3F2FD"), accentColor: UIColor(hex:"4CAF50"), floors: min(lv+2,5), roofStyle:.flat)
        case "B025": return .init(topColor: UIColor(hex:"F5F5DC"), leftColor: UIColor(hex:"FFFDE7"), rightColor: UIColor(hex:"D4D490"), windowColor: UIColor(hex:"B3E5FC"), accentColor: UIColor(hex:"FFD700"), floors: min(lv+2,5), roofStyle:.pitched)
        case "B026": return .init(topColor: UIColor(hex:"FFF9C4"), leftColor: UIColor(hex:"FDD835"), rightColor: UIColor(hex:"F57F17"), windowColor: UIColor(hex:"FFFFFF"), accentColor: UIColor(hex:"FF9800"), floors: min(lv+3,5), roofStyle:.flat)
        case "B027": return .init(topColor: UIColor(hex:"F9FBE7"), leftColor: UIColor(hex:"C5E1A5"), rightColor: UIColor(hex:"558B2F"), windowColor: UIColor(hex:"DCEDC8"), accentColor: UIColor(hex:"FFA000"), floors: 2, roofStyle:.flat)
        case "B028": return .init(topColor: UIColor(hex:"D7CCC8"), leftColor: UIColor(hex:"BCAAA4"), rightColor: UIColor(hex:"6D4C41"), windowColor: UIColor(hex:"FFF9C4"), accentColor: UIColor(hex:"795548"), floors: 2, roofStyle:.flat)
        // ── 自動生成（ペナルティ） ───────────────────────────────
        case "B029": return .init(topColor: UIColor(hex:"FF6F00"), leftColor: UIColor(hex:"E65100"), rightColor: UIColor(hex:"8B3A00"), windowColor: UIColor(hex:"FF8F00"), accentColor: UIColor(hex:"B71C1C"), floors: 2, roofStyle:.flat)
        case "B030": return .init(topColor: UIColor(hex:"616161"), leftColor: UIColor(hex:"424242"), rightColor: UIColor(hex:"212121"), windowColor: UIColor(hex:"37474F"), accentColor: UIColor(hex:"B71C1C"), floors: min(lv+1,4), roofStyle:.flat)
        default:     return .init(topColor: UIColor(hex:"E0E0E0"), leftColor: UIColor(hex:"BDBDBD"), rightColor: UIColor(hex:"9E9E9E"), windowColor: UIColor(hex:"B3E5FC"), accentColor: UIColor(hex:"FF9800"), floors: 2, roofStyle:.flat)
        }
    }
}

// MARK: - NPC Color Palettes

private enum NPCColors {
    /// Returns 8-color palette for the NPC type
    static func palette(for type: NPCType) -> [UIColor] {
        switch type {
        case .adventurer:  // 参考画像2のキャラクター
            return [UIColor(hex:"E8B84B"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"C97520"), UIColor(hex:"3D8B7A"), UIColor(hex:"8B5E1A"),
                    UIColor(hex:"6B3A1F"), UIColor(hex:"3A1F0A")]
        case .citizen1:
            return [UIColor(hex:"3A2B1F"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"1565C0"), UIColor(hex:"42A5F5"), UIColor(hex:"5D4037"),
                    UIColor(hex:"455A64"), UIColor(hex:"212121")]
        case .citizen2:
            return [UIColor(hex:"6B3A1F"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"B71C1C"), UIColor(hex:"EF5350"), UIColor(hex:"4E342E"),
                    UIColor(hex:"3E2723"), UIColor(hex:"212121")]
        case .elder:
            return [UIColor(hex:"EEEEEE"), UIColor(hex:"E8C9A0"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"78909C"), UIColor(hex:"B0BEC5"), UIColor(hex:"607D8B"),
                    UIColor(hex:"546E7A"), UIColor(hex:"37474F")]
        case .child:
            return [UIColor(hex:"E8B84B"), UIColor(hex:"FFD59A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"FF7043"), UIColor(hex:"FFCC80"), UIColor(hex:"8D6E63"),
                    UIColor(hex:"1565C0"), UIColor(hex:"212121")]
        }
    }
}

// MARK: - NPC Pixel Sprites (8col × 14row)
// カラーインデックス: 0=transparent, 1-8=palette

private enum NPCPixels {
    static func idle() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],
         [4,5,6,6,6,6,5,4],
         [4,7,7,7,7,7,7,4],
         [0,7,7,7,7,7,7,0],
         [0,7,0,0,0,0,7,0],
         [0,8,7,0,0,7,8,0],
         [0,8,8,0,0,8,8,0],
         [8,8,0,0,0,0,8,8],
         [8,0,0,0,0,0,0,8]]
    }
    static func walkLeft() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],
         [4,5,6,6,6,6,5,4],
         [4,7,7,7,7,7,7,4],
         [0,7,7,7,7,7,7,0],
         [7,7,0,0,0,7,0,0],
         [8,8,0,0,0,7,8,0],
         [8,8,0,0,0,8,8,0],
         [8,8,0,0,0,0,8,8],
         [8,0,0,0,0,0,0,8]]
    }
    static func walkRight() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],
         [4,5,6,6,6,6,5,4],
         [4,7,7,7,7,7,7,4],
         [0,7,7,7,7,7,7,0],
         [0,0,7,0,0,0,7,7],
         [0,8,7,0,0,0,8,8],
         [0,8,8,0,0,0,8,8],
         [8,8,0,0,0,0,8,8],
         [8,0,0,0,0,0,0,8]]
    }
    /// 歩行中間フレーム（両足クロス）: frame 2 で使用
    static func walkMid() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],
         [4,5,6,6,6,6,5,4],
         [4,7,7,7,7,7,7,4],
         [0,7,7,7,7,7,7,0],
         [0,7,0,0,0,0,7,0],
         [7,8,0,0,0,0,8,7],
         [8,0,7,0,0,7,0,8],
         [8,0,8,0,0,8,0,8],
         [8,0,0,0,0,0,0,8]]
    }
}

// MARK: - PixelArtRenderer (Public API)

enum PixelArtRenderer {

    static let tileW: CGFloat = 64
    static let tileH: CGFloat = 32
    static let floorH: CGFloat = 20

    private static var cache: [String: SKTexture] = [:]
    private static func cached(_ key: String, _ make: () -> SKTexture) -> SKTexture {
        if let t = cache[key] { return t }
        let t = make(); cache[key] = t; return t
    }

    // MARK: - Ground Tiles

    static func grassTile(variant: Int = 0) -> SKTexture {
        cached("grass\(variant)") {
            isoTile(top: UIColor(hex: variant == 0 ? "6BC845" : "59B035"),
                    shadow: UIColor(hex:"3A8A20"), grass: true)
        }
    }
    static func roadTile() -> SKTexture {
        cached("road") { isoTile(top: UIColor(hex:"B0A890"), shadow: UIColor(hex:"706850"), grass: false) }
    }
    static func sidewalkTile() -> SKTexture {
        cached("sidewalk") { isoTile(top: UIColor(hex:"D8D0B8"), shadow: UIColor(hex:"989078"), grass: false) }
    }
    static func waterTile() -> SKTexture {
        cached("water") { isoTile(top: UIColor(hex:"5BB8FF"), shadow: UIColor(hex:"2A7AC0"), grass: false) }
    }
    static func sandTile() -> SKTexture {
        cached("sand") { isoTile(top: UIColor(hex:"F0D890"), shadow: UIColor(hex:"C0A850"), grass: false) }
    }

    // MARK: - Building Textures

    static func buildingTexture(id: String, level: Int) -> SKTexture {
        cached("bld_\(id)_lv\(level)") {
            let cfg = BuildingVisualConfig.make(id: id, level: level)
            return isoBuilding(config: cfg)
        }
    }

    /// 建物アンカー Y 値（anchorPoint.y に使う）
    static func buildingAnchorY(id: String, level: Int) -> CGFloat {
        let cfg = BuildingVisualConfig.make(id: id, level: level)
        let bH = CGFloat(cfg.floors) * floorH
        return (tileH / 2) / (tileH + bH)
    }

    // MARK: - NPC Textures

    static func npcTexture(type: NPCType, walkFrame: Int) -> SKTexture {
        let f = walkFrame % 4
        return cached("npc_\(type.rawValue)_f\(f)") { npcSprite(type: type, frame: f) }
    }

    // MARK: - Tree

    static func treeTexture(variant: Int = 0) -> SKTexture {
        cached("tree\(variant)") { treeSprite(variant: variant) }
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Private: Iso Tile
    // ────────────────────────────────────────────────────────────────

    private static func isoTile(top: UIColor, shadow: UIColor, grass: Bool) -> SKTexture {
        let w = tileW, h = tileH
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            // ダイアモンド上面
            let diamond = diamondPath(w: w, h: h)
            top.setFill(); diamond.fill()
            // 左半分を少し暗く（奥行き感）
            let leftHalf = UIBezierPath()
            leftHalf.move(to: CGPoint(x: w/2, y: h))
            leftHalf.addLine(to: CGPoint(x: 0, y: h/2))
            leftHalf.addLine(to: CGPoint(x: w/2, y: 0))
            leftHalf.close()
            shadow.withAlphaComponent(0.12).setFill(); leftHalf.fill()
            // 草地テクスチャ（ランダムドット）
            if grass {
                cg.setFillColor(UIColor.black.withAlphaComponent(0.07).cgColor)
                for _ in 0..<6 {
                    let px = CGFloat.random(in: 10...54)
                    let py = CGFloat.random(in: 6...26)
                    if abs(px-w/2)/(w/2) + abs(py-h/2)/(h/2) <= 0.85 {
                        cg.fill(CGRect(x: px, y: py, width: 2, height: 2))
                    }
                }
            }
            // アウトライン
            UIColor.black.withAlphaComponent(0.18).setStroke()
            diamond.lineWidth = 0.5; diamond.stroke()
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    private static func diamondPath(w: CGFloat, h: CGFloat) -> UIBezierPath {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: w/2, y: 0))
        p.addLine(to: CGPoint(x: w, y: h/2))
        p.addLine(to: CGPoint(x: w/2, y: h))
        p.addLine(to: CGPoint(x: 0, y: h/2))
        p.close(); return p
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Private: Iso Building
    // 座標系: UIKit Y-down, baseY = 画像の一番下 = tileH + buildH
    // ────────────────────────────────────────────────────────────────

    private static func isoBuilding(config: BuildingVisualConfig) -> SKTexture {
        let w = tileW
        let bH = CGFloat(config.floors) * floorH
        let totalH = tileH + bH
        let baseY = totalH  // 画像底 = タイル前面頂点

        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: totalH)).image { ctx in
            let cg = ctx.cgContext

            // ── 左面 ──────────────────────────────────────────────
            let lp = UIBezierPath()
            lp.move(to:    CGPoint(x: 0,    y: baseY - tileH/2))
            lp.addLine(to: CGPoint(x: w/2,  y: baseY))
            lp.addLine(to: CGPoint(x: w/2,  y: baseY - bH))
            lp.addLine(to: CGPoint(x: 0,    y: baseY - tileH/2 - bH))
            lp.close()
            config.leftColor.setFill(); lp.fill()
            // 窓（左面）
            drawWindows(cg: cg, isLeft: true, bH: bH, baseY: baseY,
                        w: w, config: config)

            // ── 右面 ──────────────────────────────────────────────
            let rp = UIBezierPath()
            rp.move(to:    CGPoint(x: w/2,  y: baseY))
            rp.addLine(to: CGPoint(x: w,    y: baseY - tileH/2))
            rp.addLine(to: CGPoint(x: w,    y: baseY - tileH/2 - bH))
            rp.addLine(to: CGPoint(x: w/2,  y: baseY - bH))
            rp.close()
            config.rightColor.setFill(); rp.fill()
            // 窓（右面）
            drawWindows(cg: cg, isLeft: false, bH: bH, baseY: baseY,
                        w: w, config: config)

            // ── 屋根 ──────────────────────────────────────────────
            let roofBaseY = baseY - tileH/2 - bH
            switch config.roofStyle {
            case .flat:
                // 平屋根ダイアモンド
                let tp = UIBezierPath()
                tp.move(to:    CGPoint(x: w/2, y: roofBaseY - tileH/2))
                tp.addLine(to: CGPoint(x: w,   y: roofBaseY))
                tp.addLine(to: CGPoint(x: w/2, y: roofBaseY + tileH/2))
                tp.addLine(to: CGPoint(x: 0,   y: roofBaseY))
                tp.close()
                config.topColor.setFill(); tp.fill()
                UIColor.black.withAlphaComponent(0.08).setFill(); tp.fill()
                UIColor.black.withAlphaComponent(0.25).setStroke()
                tp.lineWidth = 0.6; tp.stroke()

            case .pitched:
                // 切妻屋根
                let ridgeH: CGFloat = 10
                let ls = UIBezierPath()
                ls.move(to:    CGPoint(x: 0,   y: roofBaseY))
                ls.addLine(to: CGPoint(x: w/2, y: roofBaseY + tileH/2))
                ls.addLine(to: CGPoint(x: w/2, y: roofBaseY + tileH/2 - ridgeH))
                ls.addLine(to: CGPoint(x: 0,   y: roofBaseY - ridgeH))
                ls.close()
                config.topColor.setFill(); ls.fill()
                let rs = UIBezierPath()
                rs.move(to:    CGPoint(x: w,   y: roofBaseY))
                rs.addLine(to: CGPoint(x: w/2, y: roofBaseY + tileH/2))
                rs.addLine(to: CGPoint(x: w/2, y: roofBaseY + tileH/2 - ridgeH))
                rs.addLine(to: CGPoint(x: w,   y: roofBaseY - ridgeH))
                rs.close()
                // 右面: topColor ベース + アクセント色でアイソメ奥行き影を表現
                config.topColor.setFill(); rs.fill()
                config.accentColor.withAlphaComponent(0.35).setFill(); rs.fill()

            case .dome:
                // ドーム屋根
                let domeH: CGFloat = 18
                let domeRect = CGRect(x: w/2 - w/4, y: roofBaseY - domeH, width: w/2, height: domeH)
                cg.saveGState()
                cg.clip(to: CGRect(x: 0, y: 0, width: w, height: roofBaseY))
                cg.setFillColor(config.topColor.cgColor); cg.fillEllipse(in: domeRect)
                cg.setFillColor(UIColor.white.withAlphaComponent(0.25).cgColor)
                cg.fillEllipse(in: CGRect(x: w/2 - w/8, y: roofBaseY - domeH,
                                          width: w/8, height: domeH * 0.55))
                cg.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(0.7); cg.strokeEllipse(in: domeRect)
                cg.restoreGState()
            }

            // ── アウトライン ───────────────────────────────────────
            UIColor.black.withAlphaComponent(0.3).setStroke()
            lp.lineWidth = 0.8; lp.stroke()
            rp.lineWidth = 0.8; rp.stroke()
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    private static func drawWindows(
        cg: CGContext, isLeft: Bool, bH: CGFloat, baseY: CGFloat,
        w: CGFloat, config: BuildingVisualConfig
    ) {
        guard config.floors >= 2 else { return }
        let wW: CGFloat = 5, wH: CGFloat = 6
        let fH = floorH
        let cols = 2
        for floor in 0..<config.floors {
            let fy = baseY - bH + CGFloat(floor) * fH + 4
            for col in 0..<cols {
                let wx: CGFloat
                if isLeft {
                    wx = CGFloat(col) * 10 + 4 + CGFloat(floor) * (-1)
                } else {
                    wx = w/2 + CGFloat(col) * 10 + 7 + CGFloat(floor) * 1
                }
                let r = CGRect(x: wx, y: fy, width: wW, height: wH)
                cg.setFillColor(config.windowColor.cgColor); cg.fill(r)
                cg.setStrokeColor(UIColor.black.withAlphaComponent(0.25).cgColor)
                cg.setLineWidth(0.4); cg.stroke(r)
            }
        }
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Private: NPC Sprite
    // ────────────────────────────────────────────────────────────────

    private static func npcSprite(type: NPCType, frame: Int) -> SKTexture {
        let ps: CGFloat = 3   // 1論理ピクセル = 3×3 実ピクセル
        let cols = 8, rows = 14
        let palette = NPCColors.palette(for: type)
        let pixels: [[Int]]
        switch frame % 4 {
        case 1: pixels = NPCPixels.walkLeft()
        case 2: pixels = NPCPixels.walkMid()
        case 3: pixels = NPCPixels.walkRight()
        default: pixels = NPCPixels.idle()
        }
        let img = UIGraphicsImageRenderer(
            size: CGSize(width: CGFloat(cols)*ps, height: CGFloat(rows)*ps)
        ).image { ctx in
            for row in 0..<rows {
                for col in 0..<cols {
                    guard row < pixels.count, col < pixels[row].count else { continue }
                    let ci = pixels[row][col]
                    guard ci > 0, ci <= palette.count else { continue }
                    ctx.cgContext.setFillColor(palette[ci-1].cgColor)
                    ctx.cgContext.fill(CGRect(x: CGFloat(col)*ps, y: CGFloat(row)*ps,
                                             width: ps, height: ps))
                }
            }
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Private: Tree
    // ────────────────────────────────────────────────────────────────

    private static func treeSprite(variant: Int) -> SKTexture {
        let w: CGFloat = 22, h: CGFloat = 34
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            // 幹
            cg.setFillColor(UIColor(hex:"6B4E2A").cgColor)
            cg.fill(CGRect(x: w/2-2, y: h*0.62, width: 4, height: h*0.38))
            // 葉（3層）
            let lc: [UIColor] = variant == 0
                ? [UIColor(hex:"2D8B1E"), UIColor(hex:"3AAA28"), UIColor(hex:"50CC3E")]
                : [UIColor(hex:"C06A20"), UIColor(hex:"D88030"), UIColor(hex:"ECA040")]
            cg.setFillColor(lc[0].cgColor)
            cg.fillEllipse(in: CGRect(x: 2, y: h*0.36, width: w-4, height: h*0.34))
            cg.setFillColor(lc[1].cgColor)
            cg.fillEllipse(in: CGRect(x: 4, y: h*0.18, width: w-8, height: h*0.28))
            cg.setFillColor(lc[2].cgColor)
            cg.fillEllipse(in: CGRect(x: 6, y: 2, width: w-12, height: h*0.2))
            // ハイライト
            cg.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            cg.fillEllipse(in: CGRect(x: 6, y: h*0.22, width: 5, height: 5))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }
}
