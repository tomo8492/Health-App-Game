// PixelArtRenderer.swift
// Core/
//
// ドット絵テクスチャをプログラムで生成するユーティリティ
// 参考デザイン: カイロソフト風アイソメトリックシティ + RPGキャラクター
//
// アイソメトリック座標系:
//   - タイル: 128×64 px (ダイアモンド形)
//   - 建物: 128×(tileH + floors*40) px
//   - NPC:  8col×14row の論理ピクセル × 6px = 48×84 px

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

    /// 明度を factor 倍する（0.0=黒, 1.0=変化なし）
    func darkened(by factor: CGFloat = 0.72) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r * factor, green: g * factor, blue: b * factor, alpha: a)
    }
}

// MARK: - NPC Type

enum NPCType: Int, CaseIterable {
    case adventurer = 0  // 旅人（プレイヤーの化身）: 金マント
    case citizen1   = 1  // ハルナ（運動軸）: 緑トラックウェア
    case citizen2   = 2  // ミツル（食事軸）: オレンジエプロン
    case elder      = 3  // ユキ（飲酒自制軸）: 紫作務衣
    case child      = 4  // リク（睡眠軸）: 青ベレー帽
    case citizen3   = 5  // アオイ（生活習慣軸）: ピンクカーディガン

    var roleName: String {
        switch self {
        case .adventurer: "旅人"
        case .citizen1:   "ハルナ"
        case .citizen2:   "ミツル"
        case .elder:      "ユキ"
        case .child:      "リク"
        case .citizen3:   "アオイ"
        }
    }

    var axis: CPAxis? {
        switch self {
        case .adventurer: nil
        case .citizen1:   .exercise
        case .citizen2:   .diet
        case .elder:      .alcohol
        case .child:      .sleep
        case .citizen3:   .lifestyle
        }
    }

    var roleMessages: [String] {
        switch self {
        case .adventurer:
            return [
                "ここまでよく頑張ったね",
                "街が育ってきた",
                "次の旅路を考えよう",
                "この街は君が作った",
                "素晴らしい景色だ",
            ]
        case .citizen1:
            return [
                "今日も走ってきた！",
                "風が気持ちいい",
                "次はあの坂に挑戦",
                "一歩が世界を変える",
                "体を動かすと気分爽快！",
                "朝ランは最高！",
            ]
        case .citizen2:
            return [
                "今朝のトマトは最高",
                "朝食は食べた？",
                "素材の力を信じて",
                "旬の野菜が入ったよ",
                "美味しくて健康！",
                "今日のスープは自信作",
            ]
        case .elder:
            return [
                "深呼吸しよう",
                "静けさに感謝",
                "月が綺麗だ",
                "心を整えよう",
                "お茶でも一杯いかが",
                "焦らなくていい",
            ]
        case .child:
            return [
                "よく寝れた？",
                "今夜は月が綺麗",
                "7時間が黄金律",
                "星が見えるよ",
                "枕を変えたら人生変わる",
                "おやすみの準備はOK？",
            ]
        case .citizen3:
            return [
                "いい本があるよ",
                "水、飲んだ？",
                "継続は力なり",
                "今日も記録しよう",
                "小さな習慣が大きな力に",
                "読書は心の栄養",
            ]
        }
    }

    static var nightMessages: [String] {
        ["静かな夜だ…", "おやすみ", "星がきれい", "良い夢を"]
    }
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

// MARK: - NPC Mood

enum NPCMood: Int {
    case tired  = 0   // CP 0-100:   疲れ顔（目の下にクマ）
    case normal = 1   // CP 100-300: 通常
    case happy  = 2   // CP 300+:    笑顔（^_^ + 頬紅）
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
        case "B025": return .init(topColor: UIColor(hex:"F5F5DC"), leftColor: UIColor(hex:"D9C87A"), rightColor: UIColor(hex:"B8A040"), windowColor: UIColor(hex:"B3E5FC"), accentColor: UIColor(hex:"FFD700"), floors: min(lv+2,5), roofStyle:.pitched)
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
    // 9-color palette: [髪, 肌, 目, 服上, 服下/装飾, ベルト/靴上, 靴, 影, 頬紅]
    static func palette(for type: NPCType) -> [UIColor] {
        switch type {
        case .adventurer:
            return [UIColor(hex:"E8B84B"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"C97520"), UIColor(hex:"FFD700"), UIColor(hex:"8B5E1A"),
                    UIColor(hex:"6B3A1F"), UIColor(hex:"3A1F0A"), UIColor(hex:"F0967A")]
        case .citizen1:
            return [UIColor(hex:"5D3A1A"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"34C759"), UIColor(hex:"2DA44E"), UIColor(hex:"5D4037"),
                    UIColor(hex:"FAFAFA"), UIColor(hex:"BDBDBD"), UIColor(hex:"F0967A")]
        case .citizen2:
            return [UIColor(hex:"3A3A3A"), UIColor(hex:"E8C9A0"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"FF9500"), UIColor(hex:"FFB74D"), UIColor(hex:"5D4037"),
                    UIColor(hex:"D7CCC8"), UIColor(hex:"4E342E"), UIColor(hex:"E8A090")]
        case .elder:
            return [UIColor(hex:"1A1A2E"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"AF52DE"), UIColor(hex:"9C27B0"), UIColor(hex:"F5F5DC"),
                    UIColor(hex:"8D6E63"), UIColor(hex:"37474F"), UIColor(hex:"F0967A")]
        case .child:
            return [UIColor(hex:"8B6914"), UIColor(hex:"FFD59A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"007AFF"), UIColor(hex:"42A5F5"), UIColor(hex:"FAFAFA"),
                    UIColor(hex:"1565C0"), UIColor(hex:"0D47A1"), UIColor(hex:"FFB0A0")]
        case .citizen3:
            return [UIColor(hex:"8B5E3C"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"FF2D55"), UIColor(hex:"FF6B8A"), UIColor(hex:"5D4037"),
                    UIColor(hex:"6A1B9A"), UIColor(hex:"4A148C"), UIColor(hex:"F0967A")]
        }
    }
}

// MARK: - NPC Pixel Sprites (8col × 14row)
// カラーインデックス: 0=transparent, 1-8=palette
// [1=髪, 2=肌, 3=目, 4=服上(腕), 5=服上(胴), 6=ベルト/装飾, 7=脚/服下, 8=靴]

private enum NPCPixels {

    // MARK: - 共通ベース（adventurer / fallback）

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

    // MARK: - ハルナ（citizen1 / 運動）: ショートカット + スリム + ポニーテール

    static func citizen1_idle() -> [[Int]] {
        [[0,0,1,1,1,1,1,0],  // ポニーテール右に1px突出
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,0,2,2,2,2,0,0],  // 細い首
         [0,4,5,5,5,5,4,0],  // スリムな上半身
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],  // スリムな腰
         [0,0,7,7,7,7,0,0],
         [0,0,7,0,0,7,0,0],
         [0,0,8,0,0,8,0,0],
         [0,0,8,0,0,8,0,0],
         [0,8,8,0,0,8,8,0],
         [0,8,0,0,0,0,8,0]]
    }
    static func citizen1_walkL() -> [[Int]] {
        [[0,0,1,1,1,1,1,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,0,2,2,2,2,0,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,7,7,7,0,0],
         [0,7,7,0,0,7,0,0],
         [0,8,0,0,0,8,0,0],
         [8,8,0,0,0,8,0,0],
         [8,0,0,0,0,8,8,0],
         [0,0,0,0,0,0,8,0]]
    }
    static func citizen1_walkR() -> [[Int]] {
        [[0,0,1,1,1,1,1,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,0,2,2,2,2,0,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,0,0,7,7,0],
         [0,0,8,0,0,0,8,0],
         [0,0,8,0,0,0,8,8],
         [0,8,8,0,0,0,0,8],
         [0,8,0,0,0,0,0,0]]
    }
    static func citizen1_walkM() -> [[Int]] {
        [[0,0,1,1,1,1,1,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,0,2,2,2,2,0,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,0,0,7,0,0],
         [0,7,8,0,0,8,7,0],
         [0,8,0,0,0,0,8,0],
         [8,0,8,0,0,8,0,8],
         [8,0,0,0,0,0,0,8]]
    }

    // MARK: - ミツル（citizen2 / 食事）: エプロン + がっしり体格

    static func citizen2_idle() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,5,5,5,5,5,5,4],  // 幅広の上半身
         [4,5,6,6,6,6,5,4],  // エプロン上部
         [4,5,6,6,6,6,5,4],  // エプロン中部
         [4,5,6,6,6,6,5,4],  // エプロン下部
         [0,7,7,6,6,7,7,0],  // エプロン紐
         [0,7,0,0,0,0,7,0],
         [0,8,7,0,0,7,8,0],
         [0,8,8,0,0,8,8,0],
         [8,8,0,0,0,0,8,8],
         [8,0,0,0,0,0,0,8]]
    }
    static func citizen2_walkL() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,5,5,5,5,5,5,4],
         [4,5,6,6,6,6,5,4],
         [4,5,6,6,6,6,5,4],
         [4,5,6,6,6,6,5,4],
         [0,7,7,6,6,7,7,0],
         [7,7,0,0,0,7,0,0],
         [8,8,0,0,0,7,8,0],
         [8,8,0,0,0,8,8,0],
         [8,8,0,0,0,0,8,8],
         [8,0,0,0,0,0,0,8]]
    }
    static func citizen2_walkR() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,5,5,5,5,5,5,4],
         [4,5,6,6,6,6,5,4],
         [4,5,6,6,6,6,5,4],
         [4,5,6,6,6,6,5,4],
         [0,7,7,6,6,7,7,0],
         [0,0,7,0,0,0,7,7],
         [0,8,7,0,0,0,8,8],
         [0,8,8,0,0,0,8,8],
         [8,8,0,0,0,0,8,8],
         [8,0,0,0,0,0,0,8]]
    }
    static func citizen2_walkM() -> [[Int]] {
        [[0,0,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,5,5,5,5,5,5,4],
         [4,5,6,6,6,6,5,4],
         [4,5,6,6,6,6,5,4],
         [4,5,6,6,6,6,5,4],
         [0,7,7,6,6,7,7,0],
         [0,7,0,0,0,0,7,0],
         [7,8,0,0,0,0,8,7],
         [8,0,7,0,0,7,0,8],
         [8,0,8,0,0,8,0,8],
         [8,0,0,0,0,0,0,8]]
    }

    // MARK: - ユキ（elder / 飲酒自制）: 和服ローブ（長い裾）+ 髪束ね

    static func elder_idle() -> [[Int]] {
        [[0,0,1,1,1,0,0,0],  // 束ねた髪（左寄り）
         [0,1,1,2,2,1,0,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],  // 和服の襟
         [4,5,5,6,6,5,5,4],  // 帯
         [0,5,5,6,6,5,5,0],  // 帯
         [0,5,5,5,5,5,5,0],  // 和服の裾（長い）
         [0,5,5,5,5,5,5,0],  // 和服の裾
         [0,5,5,0,0,5,5,0],  // 裾の裂け目
         [0,5,5,0,0,5,5,0],
         [0,8,8,0,0,8,8,0],  // 草履
         [0,8,0,0,0,0,8,0]]
    }
    static func elder_walkL() -> [[Int]] {
        [[0,0,1,1,1,0,0,0],
         [0,1,1,2,2,1,0,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],
         [4,5,5,6,6,5,5,4],
         [0,5,5,6,6,5,5,0],
         [0,5,5,5,5,5,5,0],
         [5,5,5,0,0,5,0,0],
         [8,8,0,0,0,5,8,0],
         [8,0,0,0,0,8,8,0],
         [0,0,0,0,0,0,8,0],
         [0,0,0,0,0,0,0,0]]
    }
    static func elder_walkR() -> [[Int]] {
        [[0,0,1,1,1,0,0,0],
         [0,1,1,2,2,1,0,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],
         [4,5,5,6,6,5,5,4],
         [0,5,5,6,6,5,5,0],
         [0,5,5,5,5,5,5,0],
         [0,0,5,0,0,5,5,5],
         [0,8,5,0,0,0,8,8],
         [0,8,8,0,0,0,0,8],
         [0,8,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0]]
    }
    static func elder_walkM() -> [[Int]] {
        [[0,0,1,1,1,0,0,0],
         [0,1,1,2,2,1,0,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,4],
         [4,5,5,5,5,5,5,4],
         [4,5,5,6,6,5,5,4],
         [0,5,5,6,6,5,5,0],
         [0,5,5,5,5,5,5,0],
         [0,5,5,0,0,5,5,0],
         [5,8,5,0,0,5,8,5],
         [8,0,0,0,0,0,0,8],
         [8,0,8,0,0,8,0,8],
         [0,0,0,0,0,0,0,0]]
    }

    // MARK: - リク（child / 睡眠）: ベレー帽 + 丸眼鏡

    static func child_idle() -> [[Int]] {
        [[0,4,4,4,4,4,0,0],  // ベレー帽（服上色=青）
         [0,1,1,1,1,1,1,0],  // 帽子の縁 + 髪
         [0,1,2,3,3,2,1,0],  // 丸眼鏡（目の周りに色3の枠）
         [0,1,2,2,2,2,1,0],
         [0,4,5,5,5,5,4,0],  // 白衣
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,0,0,7,0,0],
         [0,0,8,7,7,8,0,0],
         [0,0,8,0,0,8,0,0],
         [0,8,8,0,0,8,8,0],
         [0,8,0,0,0,0,8,0]]
    }
    static func child_walkL() -> [[Int]] {
        [[0,4,4,4,4,4,0,0],
         [0,1,1,1,1,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,7,7,7,0,0],
         [0,7,7,0,0,7,0,0],
         [0,8,0,0,0,8,0,0],
         [8,8,0,0,0,8,0,0],
         [8,0,0,0,0,8,8,0],
         [0,0,0,0,0,0,8,0]]
    }
    static func child_walkR() -> [[Int]] {
        [[0,4,4,4,4,4,0,0],
         [0,1,1,1,1,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,0,0,7,7,0],
         [0,0,8,0,0,0,8,0],
         [0,0,8,0,0,0,8,8],
         [0,8,8,0,0,0,0,8],
         [0,8,0,0,0,0,0,0]]
    }
    static func child_walkM() -> [[Int]] {
        [[0,4,4,4,4,4,0,0],
         [0,1,1,1,1,1,1,0],
         [0,1,2,3,3,2,1,0],
         [0,1,2,2,2,2,1,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,5,5,5,4,0],
         [0,4,5,6,6,5,4,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,7,7,7,0,0],
         [0,0,7,0,0,7,0,0],
         [0,7,8,0,0,8,7,0],
         [0,8,0,0,0,0,8,0],
         [8,0,8,0,0,8,0,8],
         [8,0,0,0,0,0,0,8]]
    }

    // MARK: - アオイ（citizen3 / 生活習慣）: ロングスカート + 三つ編み + 本

    static func citizen3_idle() -> [[Int]] {
        [[0,1,1,1,1,1,0,0],  // 三つ編み（左に長い）
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [1,1,2,2,2,2,1,0],  // 三つ編み垂れ
         [4,4,5,5,5,5,4,0],
         [4,5,5,5,5,5,4,0],
         [4,5,5,6,6,5,4,0],
         [0,7,7,7,7,7,7,0],  // スカート上部
         [0,7,7,7,7,7,7,0],
         [0,7,7,7,7,7,7,0],  // ロングスカート
         [0,7,7,7,7,7,7,0],
         [0,0,7,7,7,7,0,0],
         [0,0,8,0,0,8,0,0],
         [0,0,8,0,0,8,0,0]]
    }
    static func citizen3_walkL() -> [[Int]] {
        [[0,1,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [1,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,0],
         [4,5,5,5,5,5,4,0],
         [4,5,5,6,6,5,4,0],
         [0,7,7,7,7,7,7,0],
         [0,7,7,7,7,7,7,0],
         [7,7,7,7,7,7,0,0],
         [8,7,7,0,0,7,0,0],
         [8,0,0,0,0,7,0,0],
         [0,0,0,0,0,8,8,0],
         [0,0,0,0,0,0,8,0]]
    }
    static func citizen3_walkR() -> [[Int]] {
        [[0,1,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [1,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,0],
         [4,5,5,5,5,5,4,0],
         [4,5,5,6,6,5,4,0],
         [0,7,7,7,7,7,7,0],
         [0,7,7,7,7,7,7,0],
         [0,0,7,7,7,7,7,7],
         [0,0,7,0,0,7,7,8],
         [0,0,7,0,0,0,0,8],
         [0,8,8,0,0,0,0,0],
         [0,8,0,0,0,0,0,0]]
    }
    static func citizen3_walkM() -> [[Int]] {
        [[0,1,1,1,1,1,0,0],
         [0,1,1,2,2,1,1,0],
         [0,1,2,3,3,2,1,0],
         [1,1,2,2,2,2,1,0],
         [4,4,5,5,5,5,4,0],
         [4,5,5,5,5,5,4,0],
         [4,5,5,6,6,5,4,0],
         [0,7,7,7,7,7,7,0],
         [0,7,7,7,7,7,7,0],
         [0,7,7,7,7,7,7,0],
         [0,7,7,0,0,7,7,0],
         [0,0,8,0,0,8,0,0],
         [0,8,0,8,8,0,8,0],
         [0,8,0,0,0,0,8,0]]
    }

    // MARK: - 表情変更（顔ピクセル書き換え）

    static func applyFaceMood(_ pixels: [[Int]], mood: NPCMood, blink: Bool) -> [[Int]] {
        var p = pixels
        guard p.count > 3 else { return p }

        // 瞬き: 目(3)→肌(2)で一瞬閉じる
        if blink {
            p[2] = p[2].map { $0 == 3 ? 2 : $0 }
            return p
        }

        switch mood {
        case .tired:
            // 目の周囲に影色(8)でクマ表現
            for i in 0..<p[2].count {
                if p[2][i] == 2 && i > 0 && i < p[2].count - 1 {
                    let hasEyeNeighbor = (i > 0 && p[2][i-1] == 3) || (i < p[2].count-1 && p[2][i+1] == 3)
                    if hasEyeNeighbor { p[2][i] = 8 }
                }
            }
        case .normal:
            break
        case .happy:
            // ^_^ 顔: 目を閉じて笑顔に
            p[2] = p[2].map { $0 == 3 ? 2 : $0 }
            // 口元に笑みライン（目の色で）
            if p[3].count >= 5 { p[3][3] = 3; p[3][4] = 3 }
            // 頬紅（9=blush）
            if p[3].count >= 6 { p[3][2] = 9; p[3][5] = 9 }
        }
        return p
    }

    // MARK: - タイプ別ピクセル取得

    static func pixels(for type: NPCType, frame: Int) -> [[Int]] {
        switch type {
        case .citizen1:
            switch frame % 4 {
            case 1: return citizen1_walkL()
            case 2: return citizen1_walkM()
            case 3: return citizen1_walkR()
            default: return citizen1_idle()
            }
        case .citizen2:
            switch frame % 4 {
            case 1: return citizen2_walkL()
            case 2: return citizen2_walkM()
            case 3: return citizen2_walkR()
            default: return citizen2_idle()
            }
        case .elder:
            switch frame % 4 {
            case 1: return elder_walkL()
            case 2: return elder_walkM()
            case 3: return elder_walkR()
            default: return elder_idle()
            }
        case .child:
            switch frame % 4 {
            case 1: return child_walkL()
            case 2: return child_walkM()
            case 3: return child_walkR()
            default: return child_idle()
            }
        case .citizen3:
            switch frame % 4 {
            case 1: return citizen3_walkL()
            case 2: return citizen3_walkM()
            case 3: return citizen3_walkR()
            default: return citizen3_idle()
            }
        case .adventurer:
            switch frame % 4 {
            case 1: return walkLeft()
            case 2: return walkMid()
            case 3: return walkRight()
            default: return idle()
            }
        }
    }
}

// MARK: - PixelArtRenderer (Public API)

enum PixelArtRenderer {

    static let tileW: CGFloat = 128
    static let tileH: CGFloat = 64
    static let floorH: CGFloat = 40

    // NSCache: スレッドセーフ + メモリ警告時に自動解放（Dictionary より安全）
    private static let cache: NSCache<NSString, SKTexture> = {
        let c = NSCache<NSString, SKTexture>()
        c.countLimit = 500   // テクスチャ枚数上限（建物 + NPC6種×4f×3mood×2blink + タイル + 装飾）
        return c
    }()

    private static func cached(_ key: String, _ make: () -> SKTexture) -> SKTexture {
        let nsKey = key as NSString
        if let t = cache.object(forKey: nsKey) { return t }
        let t = make()
        cache.setObject(t, forKey: nsKey)
        return t
    }

    /// キャッシュを全消去（アプリ設定変更・テスト用）
    static func invalidateCache() { cache.removeAllObjects() }

    #if DEBUG
    static func debugAssetLoadStatus() {
        print("[PixelArt] === Asset Load Status ===")
        print("[PixelArt] Bundle: \(Bundle.main.bundlePath)")
        let hasCar = FileManager.default.fileExists(atPath: Bundle.main.bundlePath + "/Assets.car")
        print("[PixelArt] Assets.car exists: \(hasCar)")
        if !hasCar {
            print("[PixelArt] ⚠️ Assets.car not found — run: xcodegen generate && Clean Build (Cmd+Shift+K)")
        }
        let buildings = ["B001","B002","B003","B004","B005","B006","B007","B008","B009","B010",
                         "B011","B012","B013","B014","B015","B016","B017","B018","B019","B020",
                         "B021","B022","B023","B024","B025","B026","B027","B028","B029","B030"]
        var found = 0, missing = 0
        for id in buildings {
            let name = "bld_\(id)_lv1"
            if let img = UIImage(named: name) {
                found += 1
                print("[PixelArt]   ✅ \(name) (\(Int(img.size.width * img.scale))×\(Int(img.size.height * img.scale)))")
            } else {
                missing += 1
                print("[PixelArt]   ❌ \(name)")
            }
        }
        let tiles = ["tile_grass_0","tile_grass_1","tile_road","tile_sidewalk","tile_water","tile_sand","tile_cobblestone"]
        for t in tiles {
            if UIImage(named: t) != nil { found += 1 }
            else { print("[PixelArt]   ❌ \(t)"); missing += 1 }
        }
        let npcs = (0...5).map { "npc_\($0)_f0" }
        for n in npcs {
            if UIImage(named: n) != nil { found += 1 }
            else { print("[PixelArt]   ❌ \(n)"); missing += 1 }
        }
        print("[PixelArt] Total: \(found) loaded, \(missing) missing")
        print("[PixelArt] ========================")
    }
    #endif

    // MARK: - Asset Catalog Override (PixelLab.ai 画像差し替えパイプライン)
    //
    // Resources/Assets.xcassets に対応する名前の画像が存在すればそれを優先する。
    // 見つからない場合は従来のプロシージャル生成にフォールバック。
    // 命名規則は Resources/AssetNaming.md を参照。
    //
    //   例:
    //     - 建物        : "bld_B001_lv1" … "bld_B030_lv5"
    //     - 旗アニメ    : "bld_B025_lv1_f0" … "bld_B025_lv5_f3"
    //     - 地面タイル  : "tile_grass_0", "tile_grass_1", "tile_road", ...
    //     - NPC        : "npc_0_f0" … "npc_4_f3"
    //     - 木          : "tree_0", "tree_1"
    //     - 装飾        : "deco_streetlamp", "deco_bench"

    private static func assetTexture(_ name: String) -> SKTexture? {
        guard let img = UIImage(named: name) else { return nil }
        let t = SKTexture(image: img)
        t.filteringMode = .nearest   // ピクセルアート → 補間でぼかさない
        return t
    }

    // MARK: - Ground Tiles

    private static func compositeTile(asset: String, baseColor: UIColor) -> SKTexture {
        let w = tileW, h = tileH
        let size = CGSize(width: w, height: h)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let diamond = diamondPath(w: w, h: h)
            baseColor.setFill()
            diamond.fill()
            if let assetImg = UIImage(named: asset) {
                cg.saveGState()
                diamond.addClip()
                assetImg.draw(in: CGRect(origin: .zero, size: size))
                cg.restoreGState()
            }
        }
        let t = SKTexture(image: img)
        t.filteringMode = .nearest
        return t
    }

    static func grassTile(variant: Int = 0) -> SKTexture {
        cached("grass\(variant)") {
            compositeTile(asset: "tile_grass_\(variant)",
                          baseColor: UIColor(hex: variant == 0 ? "6BC845" : "59B035"))
        }
    }
    static func roadTile() -> SKTexture {
        cached("road") {
            compositeTile(asset: "tile_road", baseColor: UIColor(hex: "B0A890"))
        }
    }
    static func sidewalkTile() -> SKTexture {
        cached("sidewalk") {
            compositeTile(asset: "tile_sidewalk", baseColor: UIColor(hex: "D8D0B8"))
        }
    }
    static func waterTile() -> SKTexture {
        cached("water") {
            compositeTile(asset: "tile_water", baseColor: UIColor(hex: "5BB8FF"))
        }
    }
    static func sandTile() -> SKTexture {
        cached("sand") {
            compositeTile(asset: "tile_sand", baseColor: UIColor(hex: "F0D890"))
        }
    }

    static func cobblestoneTile() -> SKTexture {
        cached("cobblestone") {
            compositeTile(asset: "tile_cobblestone", baseColor: UIColor(hex: "C8B8A0"))
        }
    }

    // MARK: - Building Textures

    static func buildingTexture(id: String, level: Int) -> SKTexture {
        cached("bld_\(id)_lv\(level)") {
            let name = "bld_\(id)_lv\(level)"
            if let t = assetTexture(name) {
                #if DEBUG
                print("[PixelArt] ✅ Asset loaded: \(name)")
                #endif
                return t
            }
            #if DEBUG
            print("[PixelArt] ⚠️ Asset NOT found: \(name) → using procedural fallback")
            #endif
            let cfg = BuildingVisualConfig.make(id: id, level: level)
            return isoBuilding(config: cfg, id: id, level: level)
        }
    }

    // MARK: - Building Animation (flag wave for B025)

    /// B025（市庁舎）など旗を持つ建物の 4 フレームアニメーションテクスチャを返す
    /// それ以外の建物は nil
    /// Asset Catalog に bld_B025_lv1_f0〜f3 があれば画像を使用、無ければプロシージャル生成
    static func buildingAnimationTextures(id: String, level: Int) -> [SKTexture]? {
        guard id == "B025" else { return nil }
        let assetFrames: [SKTexture?] = (0..<4).map { assetTexture("bld_\(id)_lv\(level)_f\($0)") }
        if assetFrames.allSatisfy({ $0 != nil }) {
            return assetFrames.compactMap { $0 }
        }
        // 静的アセットがある場合はアニメーションせずそのテクスチャを維持
        if assetTexture("bld_\(id)_lv\(level)") != nil { return nil }
        return (0..<4).map { frame in
            cached("bld_\(id)_lv\(level)_f\(frame)") {
                let cfg = BuildingVisualConfig.make(id: id, level: level)
                return isoBuilding(config: cfg, id: id, level: level, flagFrame: frame)
            }
        }
    }

    /// アセット画像が存在する場合はそのピクセルサイズを返す（なければ nil）
    static func buildingAssetSize(id: String, level: Int) -> CGSize? {
        guard let img = UIImage(named: "bld_\(id)_lv\(level)") else { return nil }
        return CGSize(width: img.size.width * img.scale, height: img.size.height * img.scale)
    }

    /// 建物のスプライトサイズを返す（アセット画像があればそのサイズ、なければ floors ベース）
    static func buildingSpriteSize(id: String, level: Int) -> CGSize {
        if let assetSize = buildingAssetSize(id: id, level: level) {
            if assetSize.width < tileW {
                let s = tileW / assetSize.width
                return CGSize(width: assetSize.width * s, height: assetSize.height * s)
            }
            return assetSize
        }
        let cfg = BuildingVisualConfig.make(id: id, level: level)
        let totalH = tileH + CGFloat(cfg.floors) * floorH
        return CGSize(width: tileW, height: totalH)
    }

    /// 建物アンカー Y 値（anchorPoint.y に使う）
    static func buildingAnchorY(id: String, level: Int) -> CGFloat {
        let spriteSize = buildingSpriteSize(id: id, level: level)
        return (tileH / 2) / spriteSize.height
    }

    // MARK: - NPC Textures

    static func npcTexture(type: NPCType, walkFrame: Int,
                           mood: NPCMood = .normal, blink: Bool = false) -> SKTexture {
        let f = walkFrame % 4
        let key = "npc_\(type.rawValue)_m\(mood.rawValue)_f\(f)\(blink ? "_b" : "")"
        return cached(key) {
            if mood == .normal && !blink,
               let t = assetTexture("npc_\(type.rawValue)_f\(f)") { return t }
            return npcSprite(type: type, frame: f, mood: mood, blink: blink)
        }
    }

    static func npcAllTypes() -> [NPCType] { NPCType.allCases }

    // MARK: - Tree

    static func treeTexture(variant: Int = 0) -> SKTexture {
        cached("tree\(variant)") {
            assetTexture("tree_\(variant)") ?? treeSprite(variant: variant)
        }
    }

    // MARK: - Street Decorations

    static func streetLampTexture() -> SKTexture {
        cached("streetlamp") {
            assetTexture("deco_streetlamp") ?? makeStreetLampTexture()
        }
    }

    private static func makeStreetLampTexture() -> SKTexture {
        let w: CGFloat = 16, h: CGFloat = 44
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            // ポール
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 6, y: 14, width: 4, height: 30))
            // アーム（L字）
            cg.fill(CGRect(x: 2, y: 14, width: 8, height: 4))
            // ランプヘッド
            cg.setFillColor(UIColor(hex: "FFF9C4").cgColor)
            cg.fillEllipse(in: CGRect(x: 0, y: 4, width: 12, height: 12))
            // ランプグロー（外縁）
            cg.setStrokeColor(UIColor(hex: "F9A825").cgColor)
            cg.setLineWidth(1.2)
            cg.strokeEllipse(in: CGRect(x: 0, y: 4, width: 12, height: 12))
            // ランプ中心ハイライト
            cg.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
            cg.fillEllipse(in: CGRect(x: 3, y: 7, width: 4, height: 4))
            // ポールベース
            cg.setFillColor(UIColor(hex: "4E342E").cgColor)
            cg.fill(CGRect(x: 4, y: 40, width: 8, height: 4))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    static func benchTexture() -> SKTexture {
        cached("bench") {
            assetTexture("deco_bench") ?? makeBenchTexture()
        }
    }

    private static func makeBenchTexture() -> SKTexture {
        let w: CGFloat = 32, h: CGFloat = 24
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            // 座面
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 2, y: 8, width: 28, height: 6))
            // 背もたれ
            cg.setFillColor(UIColor(hex: "795548").cgColor)
            cg.fill(CGRect(x: 2, y: 2, width: 28, height: 4))
            // 足（4本）
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 4,  y: 14, width: 4, height: 10))
            cg.fill(CGRect(x: 24, y: 14, width: 4, height: 10))
            // アウトライン
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.25).cgColor)
            cg.setLineWidth(0.8)
            cg.stroke(CGRect(x: 2, y: 2, width: 28, height: 12))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    // MARK: - Flower Pot

    static func flowerPotTexture() -> SKTexture {
        cached("flowerpot") {
            assetTexture("deco_flowerpot") ?? makeFlowerPotTexture()
        }
    }

    private static func makeFlowerPotTexture() -> SKTexture {
        let w: CGFloat = 20, h: CGFloat = 28
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(hex: "A1887F").cgColor)
            cg.fill(CGRect(x: 4, y: 14, width: 12, height: 12))
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 2, y: 14, width: 16, height: 4))
            cg.setFillColor(UIColor(hex: "4CAF50").cgColor)
            cg.fillEllipse(in: CGRect(x: 2, y: 4, width: 8, height: 10))
            cg.fillEllipse(in: CGRect(x: 10, y: 2, width: 8, height: 10))
            cg.setFillColor(UIColor(hex: "FF5252").cgColor)
            cg.fill(CGRect(x: 6, y: 4, width: 4, height: 4))
            cg.setFillColor(UIColor(hex: "FFEB3B").cgColor)
            cg.fill(CGRect(x: 12, y: 2, width: 4, height: 4))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    // MARK: - Signpost

    static func signpostTexture() -> SKTexture {
        cached("signpost") {
            assetTexture("deco_signpost") ?? makeSignpostTexture()
        }
    }

    private static func makeSignpostTexture() -> SKTexture {
        let w: CGFloat = 24, h: CGFloat = 40
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 10, y: 10, width: 4, height: 30))
            cg.setFillColor(UIColor(hex: "FFF9C4").cgColor)
            cg.fill(CGRect(x: 0, y: 4, width: 20, height: 10))
            cg.setStrokeColor(UIColor(hex: "8D6E63").cgColor)
            cg.setLineWidth(1.0)
            cg.stroke(CGRect(x: 0, y: 4, width: 20, height: 10))
            cg.setFillColor(UIColor(hex: "5D4037").withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: 2, y: 6, width: 16, height: 2))
            cg.fill(CGRect(x: 2, y: 10, width: 12, height: 2))
            cg.setFillColor(UIColor(hex: "4E342E").cgColor)
            cg.fill(CGRect(x: 8, y: 36, width: 8, height: 4))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    // MARK: - Water Well

    static func waterWellTexture() -> SKTexture {
        cached("waterwell") {
            assetTexture("deco_waterwell") ?? makeWaterWellTexture()
        }
    }

    private static func makeWaterWellTexture() -> SKTexture {
        let w: CGFloat = 32, h: CGFloat = 36
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(hex: "B0BEC5").cgColor)
            cg.fillEllipse(in: CGRect(x: 2, y: 16, width: 28, height: 16))
            cg.setFillColor(UIColor(hex: "4FC3F7").withAlphaComponent(0.6).cgColor)
            cg.fillEllipse(in: CGRect(x: 6, y: 20, width: 20, height: 8))
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 6, y: 4, width: 4, height: 16))
            cg.fill(CGRect(x: 22, y: 4, width: 4, height: 16))
            cg.fill(CGRect(x: 6, y: 2, width: 20, height: 4))
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 12, y: 0, width: 6, height: 8))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Private: Iso Tile
    // ────────────────────────────────────────────────────────────────

    private static func isoTile(top: UIColor, shadow: UIColor, grass: Bool,
                                roadMarkings: Bool = false, cobblestone: Bool = false) -> SKTexture {
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
                    let px = CGFloat.random(in: 20...108)
                    let py = CGFloat.random(in: 12...52)
                    if abs(px-w/2)/(w/2) + abs(py-h/2)/(h/2) <= 0.85 {
                        cg.fill(CGRect(x: px, y: py, width: 4, height: 4))
                    }
                }
            }
            // 道路センターライン（破線）
            if roadMarkings {
                cg.setFillColor(UIColor(hex: "F5E6A3").withAlphaComponent(0.5).cgColor)
                // アイソメ中心を斜めに走る破線（8px on / 8px off）
                var step: CGFloat = 0
                while step < w {
                    let x = step
                    let y = h/2 - (x - w/2) * (h/2) / (w/2)
                    if Int(step / 8) % 2 == 0 {
                        cg.fill(CGRect(x: x, y: y - 1.5, width: 6, height: 3))
                    }
                    step += 8
                }
            }
            // 石畳パターン（プレミアム用）
            if cobblestone {
                cg.setStrokeColor(shadow.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(1.0)
                for row in stride(from: CGFloat(8), to: h - 4, by: 10) {
                    let offset = Int(row / 10) % 2 == 0 ? CGFloat(0) : CGFloat(12)
                    for col in stride(from: offset + 8, to: w - 8, by: 24) {
                        let bx = col, by = row
                        if abs(bx - w/2)/(w/2) + abs(by - h/2)/(h/2) <= 0.8 {
                            cg.stroke(CGRect(x: bx, y: by, width: 16, height: 8))
                        }
                    }
                }
            }
            // アウトライン
            UIColor.black.withAlphaComponent(0.18).setStroke()
            diamond.lineWidth = 1.0; diamond.stroke()
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

    private static func isoBuilding(
        config: BuildingVisualConfig,
        id: String = "",
        level: Int = 1,
        flagFrame: Int = 0
    ) -> SKTexture {
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
            drawWindows(cg: cg, isLeft: true, bH: bH, baseY: baseY, w: w, config: config)
            // ドア・看板（左面グラウンドフロア）
            drawDoor(cg: cg, baseY: baseY, w: w, config: config)
            drawBuildingSign(cg: cg, baseY: baseY, w: w, config: config)

            // ── 右面 ──────────────────────────────────────────────
            let rp = UIBezierPath()
            rp.move(to:    CGPoint(x: w/2,  y: baseY))
            rp.addLine(to: CGPoint(x: w,    y: baseY - tileH/2))
            rp.addLine(to: CGPoint(x: w,    y: baseY - tileH/2 - bH))
            rp.addLine(to: CGPoint(x: w/2,  y: baseY - bH))
            rp.close()
            config.rightColor.setFill(); rp.fill()
            // 窓（右面）
            drawWindows(cg: cg, isLeft: false, bH: bH, baseY: baseY, w: w, config: config)

            // ── フロア区切りライン ──────────────────────────────────
            drawFloorBeltLines(cg: cg, bH: bH, baseY: baseY, w: w, floors: config.floors)

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
                tp.lineWidth = 1.2; tp.stroke()
                // 屋根と壁の境界にディザリング（グラデーション効果）
                drawRoofEdgeDither(cg: cg, roofBaseY: roofBaseY, w: w, config: config)

            case .pitched:
                // 切妻屋根
                let ridgeH: CGFloat = 20
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
                let domeH: CGFloat = 36
                let domeRect = CGRect(x: w/2 - w/4, y: roofBaseY - domeH, width: w/2, height: domeH)
                cg.saveGState()
                cg.clip(to: CGRect(x: 0, y: 0, width: w, height: roofBaseY))
                cg.setFillColor(config.topColor.cgColor); cg.fillEllipse(in: domeRect)
                cg.setFillColor(UIColor.white.withAlphaComponent(0.25).cgColor)
                cg.fillEllipse(in: CGRect(x: w/2 - w/8, y: roofBaseY - domeH,
                                          width: w/8, height: domeH * 0.55))
                cg.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(1.4); cg.strokeEllipse(in: domeRect)
                cg.restoreGState()
            }

            // ── アウトライン ───────────────────────────────────────
            UIColor.black.withAlphaComponent(0.3).setStroke()
            lp.lineWidth = 1.6; lp.stroke()
            rp.lineWidth = 1.6; rp.stroke()

            // ── 屋根デコレーション（アウトラインの上に描画）──────────
            drawRoofDecoration(cg: cg, id: id, config: config,
                               roofBaseY: roofBaseY, w: w, level: level, flagFrame: flagFrame)

            // ── 軸別グラウンド装飾 ────────────────────────────────
            drawGroundDecoration(cg: cg, id: id, baseY: baseY, w: w, level: level)
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    private static func drawWindows(
        cg: CGContext, isLeft: Bool, bH: CGFloat, baseY: CGFloat,
        w: CGFloat, config: BuildingVisualConfig
    ) {
        let wW: CGFloat = 10, wH: CGFloat = 12
        let fH = floorH
        let cols = 2
        // 1階建てでも窓を表示（ただし上層階のみスキップ）
        let floorsToDraw = max(config.floors, 1)
        for floor in 0..<floorsToDraw {
            let fy = baseY - bH + CGFloat(floor) * fH + 8
            for col in 0..<cols {
                let wx: CGFloat
                if isLeft {
                    wx = CGFloat(col) * 20 + 8 + CGFloat(floor) * (-2)
                } else {
                    wx = w/2 + CGFloat(col) * 20 + 14 + CGFloat(floor) * 2
                }
                let r = CGRect(x: wx, y: fy, width: wW, height: wH)
                cg.setFillColor(config.windowColor.cgColor); cg.fill(r)
                // 窓枠（2px フレーム）
                cg.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(1.0); cg.stroke(r)
                // 窓ガラスのハイライト（左上コーナー）
                cg.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
                cg.fill(CGRect(x: wx, y: fy, width: 4, height: 4))
            }
        }
    }

    // MARK: - Building Detail Helpers

    /// ドア（左面グラウンドフロア中央）
    private static func drawDoor(
        cg: CGContext, baseY: CGFloat, w: CGFloat, config: BuildingVisualConfig
    ) {
        let dW: CGFloat = 10, dH: CGFloat = 18
        // 左面のグラウンドフロア中央付近（X: ~w/8）
        let dx: CGFloat = w/8 - 2
        let dy = baseY - dH - 2
        // ドア枠（左色を暗くした色）
        cg.setFillColor(config.leftColor.darkened(by: 0.65).cgColor)
        cg.fill(CGRect(x: dx - 2, y: dy - 2, width: dW + 4, height: dH + 4))
        // ドアパネル（アクセント色）
        cg.setFillColor(config.accentColor.withAlphaComponent(0.7).cgColor)
        cg.fill(CGRect(x: dx, y: dy, width: dW, height: dH))
        // ドアノブ（小さな点）
        cg.setFillColor(UIColor(hex: "FFD700").withAlphaComponent(0.8).cgColor)
        cg.fill(CGRect(x: dx + dW - 4, y: dy + dH/2, width: 3, height: 3))
        // ステップ（ドア下）
        cg.setFillColor(config.leftColor.darkened(by: 0.55).cgColor)
        cg.fill(CGRect(x: dx - 2, y: baseY - 4, width: dW + 4, height: 4))
    }

    /// 看板（左面グラウンドフロア上部）
    private static func drawBuildingSign(
        cg: CGContext, baseY: CGFloat, w: CGFloat, config: BuildingVisualConfig
    ) {
        let sw: CGFloat = 24, sh: CGFloat = 10
        let sx: CGFloat = 4
        let sy = baseY - floorH + 6   // グラウンドフロア上部
        // 看板背景（アクセント色）
        cg.setFillColor(config.accentColor.cgColor)
        cg.fill(CGRect(x: sx, y: sy, width: sw, height: sh))
        // 看板テキスト（2本のライン）
        cg.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
        cg.fill(CGRect(x: sx + 2, y: sy + 2, width: sw - 6, height: 2))
        cg.fill(CGRect(x: sx + 2, y: sy + 6, width: sw - 10, height: 2))
        // 看板枠
        cg.setStrokeColor(UIColor.black.withAlphaComponent(0.28).cgColor)
        cg.setLineWidth(1.6)
        cg.stroke(CGRect(x: sx, y: sy, width: sw, height: sh))
    }

    /// フロア区切りライン（各階の境界に細いラインを入れる）
    private static func drawFloorBeltLines(
        cg: CGContext, bH: CGFloat, baseY: CGFloat, w: CGFloat, floors: Int
    ) {
        guard floors >= 2 else { return }
        cg.setStrokeColor(UIColor.black.withAlphaComponent(0.15).cgColor)
        cg.setLineWidth(1.4)
        for floor in 1..<floors {
            let y = baseY - CGFloat(floor) * floorH
            // 左面のフロアライン: 右端 (w/2, y) → 左端 (0, y - tileH/2)
            // アイソメ左面は下端から tileH/2 だけ上にオフセットされた平行四辺形
            cg.move(to: CGPoint(x: 0,   y: y - tileH/2))
            cg.addLine(to: CGPoint(x: w/2, y: y))
            cg.strokePath()
            // 右面のフロアライン: 左端 (w/2, y) → 右端 (w, y - tileH/2)
            cg.move(to: CGPoint(x: w/2, y: y))
            cg.addLine(to: CGPoint(x: w,   y: y - tileH/2))
            cg.strokePath()
        }
    }

    /// 屋根エッジのディザリング（屋根と壁の境界をなめらかに見せる）
    private static func drawRoofEdgeDither(
        cg: CGContext, roofBaseY: CGFloat, w: CGFloat, config: BuildingVisualConfig
    ) {
        cg.setFillColor(config.topColor.withAlphaComponent(0.22).cgColor)
        var x: CGFloat = 0
        while x < w/2 {
            let y = roofBaseY + (w/2 - x) * (tileH/2) / (w/2)
            if Int(x/2) % 2 == 0 {
                cg.fill(CGRect(x: x, y: y - 2, width: 2, height: 2))
            }
            x += 2
        }
    }

    /// 屋根デコレーション（建物 ID ごとに異なるシルエット追加）
    private static func drawRoofDecoration(
        cg: CGContext, id: String, config: BuildingVisualConfig,
        roofBaseY: CGFloat, w: CGFloat, level: Int, flagFrame: Int = 0
    ) {
        let ridgeY = roofBaseY - tileH/2

        switch id {
        case "B025":  // 市庁舎 — 旗ポール + 三色旗（4フレームで揺れる）
            let px = w/2 + 6
            let py = ridgeY - 26
            // ポール
            cg.setFillColor(UIColor(hex: "8B7536").cgColor)
            cg.fill(CGRect(x: px, y: py, width: 4, height: 26))
            // 旗（flagFrame で x オフセットを変化させて揺らす）
            let wave = CGFloat(flagFrame % 2) * 2.0
            cg.setFillColor(UIColor(hex: "E63946").cgColor)
            cg.fill(CGRect(x: px+4, y: py,         width: 14-wave, height: 6))
            cg.setFillColor(UIColor(hex: "FFFFFF").cgColor)
            cg.fill(CGRect(x: px+4, y: py+6,       width: 14,      height: 4))
            cg.setFillColor(UIColor(hex: "4A90D9").cgColor)
            cg.fill(CGRect(x: px+4, y: py+10,      width: 14+wave, height: 6))

        case "B026":  // カレンダータワー — 時計
            let cx = w/2 - 10, cy = ridgeY - 20
            cg.setFillColor(UIColor(hex: "FFFDE7").cgColor)
            cg.fillEllipse(in: CGRect(x: cx, y: cy, width: 18, height: 18))
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            cg.setLineWidth(1.0)
            cg.strokeEllipse(in: CGRect(x: cx, y: cy, width: 18, height: 18))
            // 時計の針（12時 + 3時）
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.65).cgColor)
            cg.setLineWidth(1.4)
            cg.move(to: CGPoint(x: cx+9, y: cy+9))
            cg.addLine(to: CGPoint(x: cx+9, y: cy+2)); cg.strokePath()
            cg.move(to: CGPoint(x: cx+9, y: cy+9))
            cg.addLine(to: CGPoint(x: cx+16, y: cy+9)); cg.strokePath()

        case "B001", "B004", "B017":  // ジム / プール / 睡眠クリニック — アンテナ
            cg.setFillColor(UIColor(hex: "9E9E9E").cgColor)
            cg.fill(CGRect(x: w/2 + 4, y: ridgeY - 20, width: 4, height: 20))
            cg.setFillColor(UIColor(hex: "F44336").cgColor)
            cg.fillEllipse(in: CGRect(x: w/2 + 3, y: ridgeY - 24, width: 6, height: 6))

        case "B002":  // スタジアム — フラッグ群
            for i in 0..<3 {
                let fx = w/4 + CGFloat(i) * 16
                cg.setFillColor(UIColor(hex: "FF5722").cgColor)
                cg.fill(CGRect(x: fx, y: ridgeY - 16, width: 4, height: 16))
                let flagColors = ["FF5722", "4CAF50", "2196F3"]
                cg.setFillColor(UIColor(hex: flagColors[i]).cgColor)
                cg.fill(CGRect(x: fx+4, y: ridgeY - 16, width: 8, height: 6))
            }

        case "B018":  // 天文台 — 望遠鏡スリット
            cg.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: w/2 - 4, y: ridgeY - 32, width: 8, height: 20))

        case "B007", "B019", "B028":  // カフェ / 図書館 / 公民館 — 煙突
            let chx = w/4
            cg.setFillColor(config.rightColor.cgColor)
            cg.fill(CGRect(x: chx, y: ridgeY - 16, width: 10, height: 16))
            cg.setFillColor(UIColor(hex: "546E7A").cgColor)
            cg.fill(CGRect(x: chx - 2, y: ridgeY - 16, width: 14, height: 4))
            // 煙
            cg.setFillColor(UIColor.white.withAlphaComponent(0.25).cgColor)
            cg.fillEllipse(in: CGRect(x: chx, y: ridgeY - 26, width: 8, height: 8))

        default: break
        }

        // レベル5 金色トリム（屋根エッジに点線）
        if level >= 5 {
            cg.setFillColor(UIColor(hex: "FFD700").withAlphaComponent(0.55).cgColor)
            var gx: CGFloat = 0
            while gx < w {
                let gy = roofBaseY + (w/2 - gx) * (tileH/2) / (w/2)
                if Int(gx / 6) % 2 == 0 {
                    cg.fill(CGRect(x: gx, y: gy - 2, width: 4, height: 2))
                }
                gx += 6
            }
        }
    }

    /// 軸別グラウンド装飾（建物足元に軸の特徴を描画）
    private static func drawGroundDecoration(
        cg: CGContext, id: String, baseY: CGFloat, w: CGFloat, level: Int
    ) {
        switch id {
        // ── 運動軸: 芝生パッチ + 小旗 ──
        case "B001", "B002", "B003", "B004", "B005", "B006":
            // 右側に小さな芝生
            cg.setFillColor(UIColor(hex: "4CAF50").withAlphaComponent(0.5).cgColor)
            cg.fill(CGRect(x: w - 24, y: baseY - 6, width: 16, height: 4))
            if level >= 3 {
                // ミニ旗
                cg.setFillColor(UIColor(hex: "34C759").cgColor)
                cg.fill(CGRect(x: w - 12, y: baseY - 20, width: 2, height: 14))
                cg.fill(CGRect(x: w - 10, y: baseY - 20, width: 8, height: 6))
            }

        // ── 食事軸: プランター + テラス席 ──
        case "B007", "B008", "B009", "B010", "B011", "B012":
            // プランター（右面足元）
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: w - 20, y: baseY - 10, width: 12, height: 6))
            cg.setFillColor(UIColor(hex: "4CAF50").cgColor)
            cg.fillEllipse(in: CGRect(x: w - 18, y: baseY - 16, width: 8, height: 8))
            if level >= 3 {
                // テラス席（小さなパラソル）
                cg.setFillColor(UIColor(hex: "FF9500").withAlphaComponent(0.6).cgColor)
                cg.fill(CGRect(x: w - 32, y: baseY - 20, width: 12, height: 2))
                cg.setFillColor(UIColor(hex: "6D4C41").cgColor)
                cg.fill(CGRect(x: w - 28, y: baseY - 18, width: 2, height: 14))
            }

        // ── 飲酒軸: 石灯籠 + 砂利 ──
        case "B013", "B014", "B015", "B016":
            // 砂利テクスチャ（足元）
            cg.setFillColor(UIColor(hex: "D7CCC8").withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: w/2 + 4, y: baseY - 4, width: 20, height: 4))
            if level >= 2 {
                // 石灯籠
                cg.setFillColor(UIColor(hex: "9E9E9E").cgColor)
                cg.fill(CGRect(x: w - 16, y: baseY - 20, width: 6, height: 16))
                cg.fill(CGRect(x: w - 18, y: baseY - 22, width: 10, height: 4))
                cg.setFillColor(UIColor(hex: "FFE082").withAlphaComponent(0.6).cgColor)
                cg.fill(CGRect(x: w - 14, y: baseY - 16, width: 2, height: 2))
            }

        // ── 睡眠軸: 星型装飾 + 月のオブジェ ──
        case "B017", "B018", "B020", "B021", "B022":
            if level >= 2 {
                // 小さな星
                cg.setFillColor(UIColor(hex: "FFF176").withAlphaComponent(0.7).cgColor)
                cg.fill(CGRect(x: w - 16, y: baseY - 14, width: 4, height: 4))
                cg.fill(CGRect(x: w - 14, y: baseY - 16, width: 0, height: 0))
            }
            if level >= 4 {
                // 月のオブジェ
                cg.setFillColor(UIColor(hex: "FFF9C4").cgColor)
                cg.fillEllipse(in: CGRect(x: w - 28, y: baseY - 22, width: 10, height: 10))
                cg.setFillColor(UIColor(hex: "007AFF").withAlphaComponent(0.3).cgColor)
                cg.fillEllipse(in: CGRect(x: w - 24, y: baseY - 22, width: 8, height: 8))
            }

        // ── 生活習慣軸: 花壇 + ベンチ ──
        case "B019", "B023", "B024", "B026", "B027", "B028":
            // 花壇
            cg.setFillColor(UIColor(hex: "795548").cgColor)
            cg.fill(CGRect(x: w - 24, y: baseY - 8, width: 16, height: 6))
            let flowerColors = ["FF2D55", "FF9500", "FFEB3B"]
            for (i, hex) in flowerColors.enumerated() {
                cg.setFillColor(UIColor(hex: hex).cgColor)
                cg.fill(CGRect(x: w - 22 + CGFloat(i) * 6, y: baseY - 12, width: 4, height: 4))
            }
            if level >= 3 {
                // ベンチ
                cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
                cg.fill(CGRect(x: 4, y: baseY - 8, width: 16, height: 4))
                cg.setFillColor(UIColor(hex: "5D4037").cgColor)
                cg.fill(CGRect(x: 6, y: baseY - 4, width: 4, height: 4))
                cg.fill(CGRect(x: 14, y: baseY - 4, width: 4, height: 4))
            }

        // ── 市庁舎: 噴水 + 階段 ──
        case "B025":
            if level >= 2 {
                // 階段（3段）
                cg.setFillColor(UIColor(hex: "D9C87A").withAlphaComponent(0.5).cgColor)
                cg.fill(CGRect(x: w/8 - 6, y: baseY - 4, width: 18, height: 4))
                cg.fill(CGRect(x: w/8 - 4, y: baseY - 8, width: 14, height: 4))
            }
            if level >= 4 {
                // 噴水のベース
                cg.setFillColor(UIColor(hex: "B0BEC5").cgColor)
                cg.fillEllipse(in: CGRect(x: w - 28, y: baseY - 12, width: 16, height: 8))
                cg.setFillColor(UIColor(hex: "90CAF9").withAlphaComponent(0.5).cgColor)
                cg.fillEllipse(in: CGRect(x: w - 24, y: baseY - 10, width: 8, height: 4))
            }

        // ── ペナルティ: 散乱ゴミ ──
        case "B029":
            cg.setFillColor(UIColor(hex: "795548").withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: w - 16, y: baseY - 6, width: 6, height: 4))
            cg.fill(CGRect(x: w - 28, y: baseY - 4, width: 4, height: 2))
        case "B030":
            // ツタ（左面）
            cg.setFillColor(UIColor(hex: "4CAF50").withAlphaComponent(0.35).cgColor)
            cg.fill(CGRect(x: 4, y: baseY - 36, width: 6, height: 28))
            cg.fill(CGRect(x: 8, y: baseY - 24, width: 4, height: 8))

        default: break
        }
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Private: NPC Sprite
    // ────────────────────────────────────────────────────────────────

    private static func npcSprite(type: NPCType, frame: Int,
                                  mood: NPCMood = .normal, blink: Bool = false) -> SKTexture {
        let ps: CGFloat = 6
        let cols = 8, rows = 14
        let palette = NPCColors.palette(for: type)
        let pixels = NPCPixels.applyFaceMood(
            NPCPixels.pixels(for: type, frame: frame), mood: mood, blink: blink)
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
        let w: CGFloat = 44, h: CGFloat = 68
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            // 幹
            cg.setFillColor(UIColor(hex:"6B4E2A").cgColor)
            cg.fill(CGRect(x: w/2-4, y: h*0.62, width: 8, height: h*0.38))
            // 葉（3層）
            let lc: [UIColor] = variant == 0
                ? [UIColor(hex:"2D8B1E"), UIColor(hex:"3AAA28"), UIColor(hex:"50CC3E")]
                : [UIColor(hex:"C06A20"), UIColor(hex:"D88030"), UIColor(hex:"ECA040")]
            cg.setFillColor(lc[0].cgColor)
            cg.fillEllipse(in: CGRect(x: 4, y: h*0.36, width: w-8, height: h*0.34))
            cg.setFillColor(lc[1].cgColor)
            cg.fillEllipse(in: CGRect(x: 8, y: h*0.18, width: w-16, height: h*0.28))
            cg.setFillColor(lc[2].cgColor)
            cg.fillEllipse(in: CGRect(x: 12, y: 4, width: w-24, height: h*0.2))
            // ハイライト
            cg.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            cg.fillEllipse(in: CGRect(x: 12, y: h*0.22, width: 10, height: 10))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }
}
