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
    // 8-color palette: [髪, 肌, 目, 服上, 服下/装飾, ベルト/靴上, 靴, 影]
    static func palette(for type: NPCType) -> [UIColor] {
        switch type {
        case .adventurer:  // 旅人: 金髪・茶の旅人服・金のマント
            return [UIColor(hex:"E8B84B"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"C97520"), UIColor(hex:"FFD700"), UIColor(hex:"8B5E1A"),
                    UIColor(hex:"6B3A1F"), UIColor(hex:"3A1F0A")]
        case .citizen1:  // ハルナ: 濃茶髪・緑トラックウェア・白スニーカー
            return [UIColor(hex:"5D3A1A"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"34C759"), UIColor(hex:"2DA44E"), UIColor(hex:"5D4037"),
                    UIColor(hex:"FAFAFA"), UIColor(hex:"BDBDBD")]
        case .citizen2:  // ミツル: 白髪混じり黒髪・オレンジエプロン・ベージュ
            return [UIColor(hex:"3A3A3A"), UIColor(hex:"E8C9A0"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"FF9500"), UIColor(hex:"FFB74D"), UIColor(hex:"5D4037"),
                    UIColor(hex:"D7CCC8"), UIColor(hex:"4E342E")]
        case .elder:  // ユキ: 黒髪束ね・紫作務衣・草履
            return [UIColor(hex:"1A1A2E"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"AF52DE"), UIColor(hex:"9C27B0"), UIColor(hex:"F5F5DC"),
                    UIColor(hex:"8D6E63"), UIColor(hex:"37474F")]
        case .child:  // リク: 茶髪・青ベレー帽・白衣+青パジャマ風
            return [UIColor(hex:"8B6914"), UIColor(hex:"FFD59A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"007AFF"), UIColor(hex:"42A5F5"), UIColor(hex:"FAFAFA"),
                    UIColor(hex:"1565C0"), UIColor(hex:"0D47A1")]
        case .citizen3:  // アオイ: 栗色髪・ピンクカーディガン・濃紫スカート
            return [UIColor(hex:"8B5E3C"), UIColor(hex:"F5C09A"), UIColor(hex:"3A2B1F"),
                    UIColor(hex:"FF2D55"), UIColor(hex:"FF6B8A"), UIColor(hex:"5D4037"),
                    UIColor(hex:"6A1B9A"), UIColor(hex:"4A148C")]
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

    static let tileW: CGFloat = 64
    static let tileH: CGFloat = 32
    static let floorH: CGFloat = 20

    // NSCache: スレッドセーフ + メモリ警告時に自動解放（Dictionary より安全）
    private static let cache: NSCache<NSString, SKTexture> = {
        let c = NSCache<NSString, SKTexture>()
        c.countLimit = 280   // テクスチャ枚数上限（建物30種×5Lv + NPC6種×4f + タイル + 装飾）
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
    /// 起動時に全アセットの読み込み状態をコンソールに出力
    static func debugAssetLoadStatus() {
        print("[PixelArt] === Asset Load Status ===")
        let buildings = ["B001","B002","B003","B004","B005","B006","B007","B008","B009","B010",
                         "B011","B012","B013","B014","B015","B016","B017","B018","B019","B020",
                         "B021","B022","B023","B024","B025","B026","B027","B028","B029","B030"]
        var found = 0, missing = 0
        for id in buildings {
            let name = "bld_\(id)_lv1"
            if UIImage(named: name) != nil { found += 1 }
            else { print("[PixelArt]   ❌ Missing: \(name)"); missing += 1 }
        }
        let tiles = ["tile_grass_0","tile_grass_1","tile_road","tile_sidewalk","tile_water","tile_sand","tile_cobblestone"]
        for t in tiles {
            if UIImage(named: t) != nil { found += 1 }
            else { print("[PixelArt]   ❌ Missing: \(t)"); missing += 1 }
        }
        let npcs = (0...5).map { "npc_\($0)_f0" }
        for n in npcs {
            if UIImage(named: n) != nil { found += 1 }
            else { print("[PixelArt]   ❌ Missing: \(n)"); missing += 1 }
        }
        print("[PixelArt] ✅ Found: \(found), ❌ Missing: \(missing)")
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

    static func grassTile(variant: Int = 0) -> SKTexture {
        cached("grass\(variant)") {
            assetTexture("tile_grass_\(variant)") ??
            isoTile(top: UIColor(hex: variant == 0 ? "6BC845" : "59B035"),
                    shadow: UIColor(hex:"3A8A20"), grass: true)
        }
    }
    static func roadTile() -> SKTexture {
        cached("road") {
            assetTexture("tile_road") ??
            isoTile(top: UIColor(hex:"B0A890"), shadow: UIColor(hex:"706850"),
                    grass: false, roadMarkings: true)
        }
    }
    static func sidewalkTile() -> SKTexture {
        cached("sidewalk") {
            assetTexture("tile_sidewalk") ??
            isoTile(top: UIColor(hex:"D8D0B8"), shadow: UIColor(hex:"989078"), grass: false)
        }
    }
    static func waterTile() -> SKTexture {
        waterTile(frame: 0)
    }

    /// 3 フレーム分の波アニメーション付き水タイル。
    /// frame 0-2 のサイクルで波の白ハイライト位置が変化する。
    /// Asset Catalog に tile_water_f0..f2 があればそちらを優先、無ければ tile_water、
    /// それも無ければプロシージャル（isoTile）に自動フォールバックする。
    static func waterTile(frame: Int) -> SKTexture {
        let f = ((frame % 3) + 3) % 3
        return cached("water_f\(f)") {
            if let t = assetTexture("tile_water_f\(f)") { return t }
            if f == 0, let base = assetTexture("tile_water") { return base }
            return isoWaterTile(frame: f)
        }
    }
    static func sandTile() -> SKTexture {
        cached("sand") {
            assetTexture("tile_sand") ??
            isoTile(top: UIColor(hex:"F0D890"), shadow: UIColor(hex:"C0A850"), grass: false)
        }
    }

    static func cobblestoneTile() -> SKTexture {
        cached("cobblestone") {
            assetTexture("tile_cobblestone") ??
            isoTile(top: UIColor(hex:"C8B8A0"), shadow: UIColor(hex:"8A7A60"),
                    grass: false, cobblestone: true)
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

    /// 旗を持つ建物の 4 フレームアニメーションテクスチャを返す（対象: B001, B025）
    /// それ以外の建物は nil
    /// Asset Catalog に bld_{id}_lv{level}_f0〜f3 があれば画像を使用、無ければプロシージャル生成
    static func buildingAnimationTextures(id: String, level: Int) -> [SKTexture]? {
        guard ["B001", "B025"].contains(id) else { return nil }
        // 4 フレーム全てが Asset Catalog に存在するかチェック
        let assetFrames: [SKTexture?] = (0..<4).map { assetTexture("bld_\(id)_lv\(level)_f\($0)") }
        if assetFrames.allSatisfy({ $0 != nil }) {
            return assetFrames.compactMap { $0 }
        }
        // 一部欠けていればプロシージャル生成（旗位置オフセット付き）
        return (0..<4).map { frame in
            cached("bld_\(id)_lv\(level)_f\(frame)") {
                let cfg = BuildingVisualConfig.make(id: id, level: level)
                return isoBuilding(config: cfg, id: id, level: level, flagFrame: frame)
            }
        }
    }

    /// 煙突を持つ建物かどうか（煙エフェクトの対象判定）
    /// 参考画像に煙突が見える建物タイプをここで一元管理する
    static func buildingHasChimney(id: String) -> Bool {
        switch id {
        // 食事軸: カフェ・レストラン・ベーカリー（オーブンの煙）
        case "B007", "B008", "B009", "B010", "B011", "B012": return true
        // 生活軸: 家屋系（暖炉の煙）
        case "B019", "B026", "B028": return true
        // ペナルティ: 居酒屋（厨房の煙）
        case "B029": return true
        default: return false
        }
    }

    /// 煙突のスプライト内相対位置（中心を 0,0 とした座標 / UIKit 座標系の反転前）
    /// 建物ノード基準で addChild する際のオフセットとして使う
    /// - Returns: (x, y) 単位は SpriteKit のポイント。y は建物の上方向が正。
    static func buildingChimneyOffset(id: String, level: Int) -> CGPoint {
        let size = buildingSpriteSize(id: id, level: level)
        // 基本位置: 屋根の右端やや上
        let baseX: CGFloat = 8
        let baseY: CGFloat = size.height * 0.42
        return CGPoint(x: baseX, y: baseY)
    }

    /// アセット画像が存在する場合はそのピクセルサイズを返す（なければ nil）
    static func buildingAssetSize(id: String, level: Int) -> CGSize? {
        guard let img = UIImage(named: "bld_\(id)_lv\(level)") else { return nil }
        return CGSize(width: img.size.width * img.scale, height: img.size.height * img.scale)
    }

    /// 建物のスプライトサイズを返す（アセット画像があればそのサイズ、なければ floors ベース）
    static func buildingSpriteSize(id: String, level: Int) -> CGSize {
        if let assetSize = buildingAssetSize(id: id, level: level) {
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

    static func npcTexture(type: NPCType, walkFrame: Int) -> SKTexture {
        // 8 フレーム化：Asset Catalog に f4〜f7 があればそれを使い、
        // 無ければ対応する 0-3 のテクスチャを返すフォールバック。
        let raw = ((walkFrame % 8) + 8) % 8
        let cacheKey = "npc_\(type.rawValue)_f\(raw)"
        return cached(cacheKey) {
            if let t = assetTexture("npc_\(type.rawValue)_f\(raw)") { return t }
            // fallback: 4-7 は 0-3 に折り返す
            let fallback = raw % 4
            if raw >= 4, let t2 = assetTexture("npc_\(type.rawValue)_f\(fallback)") { return t2 }
            return npcSprite(type: type, frame: fallback)
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
        let w: CGFloat = 8, h: CGFloat = 22
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            // ポール
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 3, y: 7, width: 2, height: 15))
            // アーム（L字）
            cg.fill(CGRect(x: 1, y: 7, width: 4, height: 2))
            // ランプヘッド
            cg.setFillColor(UIColor(hex: "FFF9C4").cgColor)
            cg.fillEllipse(in: CGRect(x: 0, y: 2, width: 6, height: 6))
            // ランプグロー（外縁）
            cg.setStrokeColor(UIColor(hex: "F9A825").cgColor)
            cg.setLineWidth(0.6)
            cg.strokeEllipse(in: CGRect(x: 0, y: 2, width: 6, height: 6))
            // ランプ中心ハイライト
            cg.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
            cg.fillEllipse(in: CGRect(x: 1.5, y: 3.5, width: 2, height: 2))
            // ポールベース
            cg.setFillColor(UIColor(hex: "4E342E").cgColor)
            cg.fill(CGRect(x: 2, y: 20, width: 4, height: 2))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    static func benchTexture() -> SKTexture {
        cached("bench") {
            assetTexture("deco_bench") ?? makeBenchTexture()
        }
    }

    private static func makeBenchTexture() -> SKTexture {
        let w: CGFloat = 16, h: CGFloat = 12
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            // 座面
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 1, y: 4, width: 14, height: 3))
            // 背もたれ
            cg.setFillColor(UIColor(hex: "795548").cgColor)
            cg.fill(CGRect(x: 1, y: 1, width: 14, height: 2))
            // 足（4本）
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 2,  y: 7, width: 2, height: 5))
            cg.fill(CGRect(x: 12, y: 7, width: 2, height: 5))
            // アウトライン
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.25).cgColor)
            cg.setLineWidth(0.4)
            cg.stroke(CGRect(x: 1, y: 1, width: 14, height: 6))
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
        let w: CGFloat = 10, h: CGFloat = 14
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(hex: "A1887F").cgColor)
            cg.fill(CGRect(x: 2, y: 7, width: 6, height: 6))
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 1, y: 7, width: 8, height: 2))
            cg.setFillColor(UIColor(hex: "4CAF50").cgColor)
            cg.fillEllipse(in: CGRect(x: 1, y: 2, width: 4, height: 5))
            cg.fillEllipse(in: CGRect(x: 5, y: 1, width: 4, height: 5))
            cg.setFillColor(UIColor(hex: "FF5252").cgColor)
            cg.fill(CGRect(x: 3, y: 2, width: 2, height: 2))
            cg.setFillColor(UIColor(hex: "FFEB3B").cgColor)
            cg.fill(CGRect(x: 6, y: 1, width: 2, height: 2))
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
        let w: CGFloat = 12, h: CGFloat = 20
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 5, y: 5, width: 2, height: 15))
            cg.setFillColor(UIColor(hex: "FFF9C4").cgColor)
            cg.fill(CGRect(x: 0, y: 2, width: 10, height: 5))
            cg.setStrokeColor(UIColor(hex: "8D6E63").cgColor)
            cg.setLineWidth(0.5)
            cg.stroke(CGRect(x: 0, y: 2, width: 10, height: 5))
            cg.setFillColor(UIColor(hex: "5D4037").withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: 1, y: 3, width: 8, height: 1))
            cg.fill(CGRect(x: 1, y: 5, width: 6, height: 1))
            cg.setFillColor(UIColor(hex: "4E342E").cgColor)
            cg.fill(CGRect(x: 4, y: 18, width: 4, height: 2))
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
        let w: CGFloat = 16, h: CGFloat = 18
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(hex: "B0BEC5").cgColor)
            cg.fillEllipse(in: CGRect(x: 1, y: 8, width: 14, height: 8))
            cg.setFillColor(UIColor(hex: "4FC3F7").withAlphaComponent(0.6).cgColor)
            cg.fillEllipse(in: CGRect(x: 3, y: 10, width: 10, height: 4))
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 3, y: 2, width: 2, height: 8))
            cg.fill(CGRect(x: 11, y: 2, width: 2, height: 8))
            cg.fill(CGRect(x: 3, y: 1, width: 10, height: 2))
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 6, y: 0, width: 3, height: 4))
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
                    let px = CGFloat.random(in: 10...54)
                    let py = CGFloat.random(in: 6...26)
                    if abs(px-w/2)/(w/2) + abs(py-h/2)/(h/2) <= 0.85 {
                        cg.fill(CGRect(x: px, y: py, width: 2, height: 2))
                    }
                }
            }
            // 道路センターライン（破線）
            if roadMarkings {
                cg.setFillColor(UIColor(hex: "F5E6A3").withAlphaComponent(0.5).cgColor)
                // アイソメ中心を斜めに走る破線（4px on / 4px off）
                var step: CGFloat = 0
                while step < w {
                    let x = step
                    let y = h/2 - (x - w/2) * (h/2) / (w/2)
                    if Int(step / 4) % 2 == 0 {
                        cg.fill(CGRect(x: x, y: y - 0.75, width: 3, height: 1.5))
                    }
                    step += 2
                }
            }
            // 石畳パターン（プレミアム用）
            if cobblestone {
                cg.setStrokeColor(shadow.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(0.5)
                for row in stride(from: CGFloat(4), to: h - 2, by: 5) {
                    let offset = Int(row / 5) % 2 == 0 ? CGFloat(0) : CGFloat(6)
                    for col in stride(from: offset + 4, to: w - 4, by: 12) {
                        let bx = col, by = row
                        if abs(bx - w/2)/(w/2) + abs(by - h/2)/(h/2) <= 0.8 {
                            cg.stroke(CGRect(x: bx, y: by, width: 8, height: 4))
                        }
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

    /// 3 フレームの波パターンを描いた水タイル（frame 0/1/2）
    /// 白いキラメキ点の位置と青の明暗が微妙に変化する。
    private static func isoWaterTile(frame: Int) -> SKTexture {
        let w = tileW, h = tileH
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            let diamond = diamondPath(w: w, h: h)
            // ベース水色
            UIColor(hex: "5BB8FF").setFill(); diamond.fill()
            // 影（左半分）
            let leftHalf = UIBezierPath()
            leftHalf.move(to: CGPoint(x: w/2, y: h))
            leftHalf.addLine(to: CGPoint(x: 0, y: h/2))
            leftHalf.addLine(to: CGPoint(x: w/2, y: 0))
            leftHalf.close()
            UIColor(hex: "2A7AC0").withAlphaComponent(0.22).setFill(); leftHalf.fill()

            // 波の横ライン（frame で上下シフト）
            cg.setFillColor(UIColor(hex: "9AD5FF").withAlphaComponent(0.7).cgColor)
            let yOffsets: [CGFloat] = [0, 2, -2]
            let yOff = yOffsets[frame % 3]
            let waves: [(CGFloat, CGFloat, CGFloat)] = [
                (18, h/2 - 4 + yOff, 8),
                (38, h/2 + 3 + yOff, 10),
                (12, h/2 + 8 + yOff, 6)
            ]
            for (x, y, len) in waves {
                cg.fill(CGRect(x: x, y: y, width: len, height: 1))
            }
            // キラメキ点（frame ごとに位置変化）
            cg.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            let sparkles: [[(CGFloat, CGFloat)]] = [
                [(26, 10), (42, 18)],
                [(18, 14), (48, 10), (32, 20)],
                [(36, 8), (22, 22)]
            ]
            for (sx, sy) in sparkles[frame % 3] {
                cg.fill(CGRect(x: sx, y: sy, width: 2, height: 1))
            }
            // アウトライン
            UIColor.black.withAlphaComponent(0.14).setStroke()
            diamond.lineWidth = 0.5; diamond.stroke()
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Environment Props (牧場・風車・市場・花壇・樽)
    // ────────────────────────────────────────────────────────────────

    /// 牛（ホルスタイン風白黒）— 2 フレーム（idle / chew）
    static func cowTexture(frame: Int = 0) -> SKTexture {
        let f = ((frame % 2) + 2) % 2
        return cached("cow_f\(f)") {
            if let t = assetTexture("deco_cow_f\(f)") { return t }
            return cowSprite(frame: f)
        }
    }

    private static func cowSprite(frame: Int) -> SKTexture {
        // 論理 16×12 を 2px ズーム → 32×24
        let ps: CGFloat = 2
        let cols = 16, rows = 12
        let body = UIColor.white
        let spot = UIColor(hex: "1A1A1A")
        let snout = UIColor(hex: "F5C09A")
        let hoof = UIColor(hex: "2A1A0A")
        let udder = UIColor(hex: "FFB3B3")
        // ピクセルマップ: 0=透明, 1=白, 2=黒, 3=鼻, 4=蹄, 5=乳
        // frame 1 は頭がわずかに下がる
        let base: [[Int]] = [
            [0,0,2,2,0,0,0,0,0,0,0,0,1,1,0,0],
            [0,2,1,1,2,0,0,0,1,1,1,1,1,2,0,0],
            [0,2,1,3,3,2,1,1,1,2,2,1,1,2,2,0],
            [0,0,2,3,3,1,1,2,2,2,1,1,1,1,0,0],
            [0,0,0,2,2,1,1,1,1,1,1,1,1,2,0,0],
            [0,0,0,1,1,1,1,1,2,2,1,1,2,2,0,0],
            [0,0,0,1,1,1,1,2,2,1,1,1,2,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,5,1,1,0,0,0],
            [0,0,0,4,0,4,0,0,0,0,4,0,4,0,0,0],
            [0,0,0,4,0,4,0,0,0,0,4,0,4,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        ]
        let size = CGSize(width: CGFloat(cols) * ps, height: CGFloat(rows) * ps)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            for r in 0..<rows {
                for c in 0..<cols {
                    let v = base[r][c]
                    guard v > 0 else { continue }
                    let col: UIColor
                    switch v { case 1: col = body; case 2: col = spot; case 3: col = snout; case 4: col = hoof; case 5: col = udder; default: col = body }
                    let yShift: CGFloat = (frame == 1 && r <= 3) ? ps : 0
                    cg.setFillColor(col.cgColor)
                    cg.fill(CGRect(x: CGFloat(c) * ps, y: CGFloat(r) * ps + yShift, width: ps, height: ps))
                }
            }
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    /// 木の柵（0 = 横一枚, 1 = 角パーツ）
    static func fenceTexture(variant: Int = 0) -> SKTexture {
        let v = ((variant % 2) + 2) % 2
        return cached("fence_v\(v)") {
            if let t = assetTexture("deco_fence_\(v)") { return t }
            return fenceSprite(variant: v)
        }
    }

    private static func fenceSprite(variant: Int) -> SKTexture {
        let size = CGSize(width: 24, height: 18)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let wood = UIColor(hex: "A8753A")
            let woodDark = UIColor(hex: "6B4822")
            cg.setFillColor(wood.cgColor)
            if variant == 0 {
                // 2 本の縦支柱
                cg.fill(CGRect(x: 4, y: 4, width: 3, height: 14))
                cg.fill(CGRect(x: 17, y: 4, width: 3, height: 14))
                // 2 本の横ビーム
                cg.fill(CGRect(x: 2, y: 7, width: 20, height: 2))
                cg.fill(CGRect(x: 2, y: 13, width: 20, height: 2))
            } else {
                // 角（3 支柱 + 横短め）
                cg.fill(CGRect(x: 4, y: 4, width: 3, height: 14))
                cg.fill(CGRect(x: 11, y: 2, width: 3, height: 16))
                cg.fill(CGRect(x: 17, y: 4, width: 3, height: 14))
                cg.fill(CGRect(x: 2, y: 7, width: 12, height: 2))
                cg.fill(CGRect(x: 2, y: 13, width: 12, height: 2))
            }
            // シェーディング
            cg.setFillColor(woodDark.cgColor)
            cg.fill(CGRect(x: 4, y: 16, width: 3, height: 2))
            cg.fill(CGRect(x: 17, y: 16, width: 3, height: 2))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    /// 風車（本体 + 羽）を 4 フレームで回転させる
    static func windmillTexture(bladeFrame: Int = 0) -> SKTexture {
        let f = ((bladeFrame % 4) + 4) % 4
        return cached("windmill_f\(f)") {
            if let t = assetTexture("deco_windmill_f\(f)") { return t }
            return windmillSprite(bladeFrame: f)
        }
    }

    private static func windmillSprite(bladeFrame: Int) -> SKTexture {
        let size = CGSize(width: 36, height: 64)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            // 本体（石造りタワー）
            cg.setFillColor(UIColor(hex: "D7CCC8").cgColor)
            cg.fill(CGRect(x: 12, y: 26, width: 12, height: 32))
            cg.setFillColor(UIColor(hex: "A1887F").cgColor)
            cg.fill(CGRect(x: 11, y: 26, width: 2, height: 32))
            // 屋根（円錐）
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 10, y: 22, width: 16, height: 6))
            cg.fill(CGRect(x: 13, y: 18, width: 10, height: 4))
            // 窓
            cg.setFillColor(UIColor(hex: "FFF176").cgColor)
            cg.fill(CGRect(x: 16, y: 38, width: 4, height: 5))
            // ドア
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 15, y: 52, width: 6, height: 6))
            // 羽根（4枚） — frame で角度シフト（0°, 22.5°, 45°, 67.5° に近似した 4 パターン）
            cg.saveGState()
            cg.translateBy(x: 18, y: 26)
            let angle = CGFloat.pi / 2 * CGFloat(bladeFrame) / 4
            cg.rotate(by: angle)
            cg.setFillColor(UIColor(hex: "FAFAFA").cgColor)
            for i in 0..<4 {
                cg.saveGState()
                cg.rotate(by: CGFloat.pi / 2 * CGFloat(i))
                cg.fill(CGRect(x: -1, y: -14, width: 3, height: 14))
                cg.fill(CGRect(x: 2, y: -12, width: 4, height: 10))
                cg.restoreGState()
            }
            // ハブ
            cg.setFillColor(UIColor(hex: "424242").cgColor)
            cg.fillEllipse(in: CGRect(x: -2, y: -2, width: 4, height: 4))
            cg.restoreGState()
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    /// 市場スタンド（0=野菜, 1=魚, 2=パン）
    static func marketStallTexture(variant: Int = 0) -> SKTexture {
        let v = ((variant % 3) + 3) % 3
        return cached("market_v\(v)") {
            if let t = assetTexture("deco_market_\(v)") { return t }
            return marketStallSprite(variant: v)
        }
    }

    private static func marketStallSprite(variant: Int) -> SKTexture {
        let size = CGSize(width: 28, height: 32)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            // 屋根（ストライプテント）
            let stripe1: UIColor
            let stripe2: UIColor
            let goodsColors: [UIColor]
            switch variant {
            case 1: // 魚屋（青白ストライプ / 魚）
                stripe1 = UIColor(hex: "1976D2"); stripe2 = UIColor(hex: "FAFAFA")
                goodsColors = [UIColor(hex: "B0BEC5"), UIColor(hex: "78909C")]
            case 2: // パン屋（茶黄ストライプ / パン）
                stripe1 = UIColor(hex: "A1887F"); stripe2 = UIColor(hex: "FFE082")
                goodsColors = [UIColor(hex: "D7A36A"), UIColor(hex: "8D6E63")]
            default: // 野菜屋（赤白 / 野菜）
                stripe1 = UIColor(hex: "E53935"); stripe2 = UIColor(hex: "FAFAFA")
                goodsColors = [UIColor(hex: "E57373"), UIColor(hex: "81C784"), UIColor(hex: "FFEE58")]
            }
            // 屋根（ストライプ）
            for i in 0..<7 {
                cg.setFillColor(i % 2 == 0 ? stripe1.cgColor : stripe2.cgColor)
                cg.fill(CGRect(x: 2 + CGFloat(i) * 3.4, y: 4, width: 4, height: 6))
            }
            // 屋根影
            cg.setFillColor(UIColor.black.withAlphaComponent(0.22).cgColor)
            cg.fill(CGRect(x: 2, y: 10, width: 24, height: 2))
            // ポール
            cg.setFillColor(UIColor(hex: "6B4822").cgColor)
            cg.fill(CGRect(x: 3, y: 10, width: 2, height: 14))
            cg.fill(CGRect(x: 23, y: 10, width: 2, height: 14))
            // カウンター
            cg.setFillColor(UIColor(hex: "A8753A").cgColor)
            cg.fill(CGRect(x: 2, y: 20, width: 24, height: 4))
            cg.setFillColor(UIColor(hex: "6B4822").cgColor)
            cg.fill(CGRect(x: 2, y: 24, width: 24, height: 2))
            // 商品（3 列）
            for (i, col) in goodsColors.enumerated() {
                cg.setFillColor(col.cgColor)
                let x = 5 + CGFloat(i) * 6
                cg.fill(CGRect(x: x, y: 16, width: 4, height: 4))
            }
            // 足
            cg.setFillColor(UIColor(hex: "4E342E").cgColor)
            cg.fill(CGRect(x: 3, y: 26, width: 2, height: 4))
            cg.fill(CGRect(x: 23, y: 26, width: 2, height: 4))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    /// 花壇（0=赤系, 1=紫系）
    static func flowerBedTexture(variant: Int = 0) -> SKTexture {
        let v = ((variant % 2) + 2) % 2
        return cached("flowerbed_v\(v)") {
            if let t = assetTexture("deco_flowerbed_\(v)") { return t }
            return flowerBedSprite(variant: v)
        }
    }

    private static func flowerBedSprite(variant: Int) -> SKTexture {
        let size = CGSize(width: 28, height: 16)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            // 木枠
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: 1, y: 4, width: 26, height: 10))
            cg.setFillColor(UIColor(hex: "5D4037").cgColor)
            cg.fill(CGRect(x: 1, y: 12, width: 26, height: 2))
            // 土
            cg.setFillColor(UIColor(hex: "4E342E").cgColor)
            cg.fill(CGRect(x: 3, y: 6, width: 22, height: 6))
            // 葉
            cg.setFillColor(UIColor(hex: "4CAF50").cgColor)
            for x in stride(from: CGFloat(4), to: 24, by: 3) {
                cg.fill(CGRect(x: x, y: 5, width: 2, height: 2))
            }
            // 花（バリアント別）
            let flowerColors: [UIColor]
            if variant == 0 {
                flowerColors = [UIColor(hex: "F44336"), UIColor(hex: "FF9800"), UIColor(hex: "FFEB3B")]
            } else {
                flowerColors = [UIColor(hex: "AB47BC"), UIColor(hex: "EC407A"), UIColor(hex: "7E57C2")]
            }
            var fi = 0
            for x in stride(from: CGFloat(4), to: 24, by: 3) {
                cg.setFillColor(flowerColors[fi % flowerColors.count].cgColor)
                cg.fill(CGRect(x: x, y: 3, width: 2, height: 2))
                cg.setFillColor(UIColor(hex: "FFEB3B").cgColor)
                cg.fill(CGRect(x: x, y: 3, width: 1, height: 1))
                fi += 1
            }
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    /// 樽
    static func barrelTexture() -> SKTexture {
        cached("barrel") {
            if let t = assetTexture("deco_barrel") { return t }
            return barrelSprite()
        }
    }

    private static func barrelSprite() -> SKTexture {
        let size = CGSize(width: 16, height: 20)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            // 胴体（薄茶）
            cg.setFillColor(UIColor(hex: "A8753A").cgColor)
            cg.fill(CGRect(x: 2, y: 3, width: 12, height: 14))
            // 影
            cg.setFillColor(UIColor(hex: "6B4822").cgColor)
            cg.fill(CGRect(x: 2, y: 3, width: 2, height: 14))
            // 鉄輪
            cg.setFillColor(UIColor(hex: "424242").cgColor)
            cg.fill(CGRect(x: 1, y: 5, width: 14, height: 1))
            cg.fill(CGRect(x: 1, y: 14, width: 14, height: 1))
            cg.fill(CGRect(x: 2, y: 2, width: 12, height: 2))
            cg.fill(CGRect(x: 2, y: 16, width: 12, height: 2))
            // 天面
            cg.setFillColor(UIColor(hex: "D7A36A").cgColor)
            cg.fill(CGRect(x: 4, y: 2, width: 8, height: 1))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    /// 木箱
    static func crateTexture() -> SKTexture {
        cached("crate") {
            if let t = assetTexture("deco_crate") { return t }
            return crateSprite()
        }
    }

    private static func crateSprite() -> SKTexture {
        let size = CGSize(width: 18, height: 16)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(hex: "B8843C").cgColor)
            cg.fill(CGRect(x: 2, y: 2, width: 14, height: 12))
            cg.setFillColor(UIColor(hex: "7A5220").cgColor)
            cg.stroke(CGRect(x: 2, y: 2, width: 14, height: 12))
            // 板目（X 型補強）
            cg.setStrokeColor(UIColor(hex: "7A5220").cgColor)
            cg.setLineWidth(1)
            cg.move(to: CGPoint(x: 2, y: 2)); cg.addLine(to: CGPoint(x: 16, y: 14)); cg.strokePath()
            cg.move(to: CGPoint(x: 16, y: 2)); cg.addLine(to: CGPoint(x: 2, y: 14)); cg.strokePath()
            // 外枠
            cg.setStrokeColor(UIColor(hex: "5C3A18").cgColor)
            cg.setLineWidth(1)
            cg.stroke(CGRect(x: 2, y: 2, width: 14, height: 12))
        }
        let tex = SKTexture(image: img); tex.filteringMode = .nearest; return tex
    }

    /// 煙粒子テクスチャ（灰色のソフトな円、キャッシュ）
    static func smokePuffTexture() -> SKTexture {
        cached("smoke_puff") {
            if let t = assetTexture("fx_smoke_puff") { return t }
            let size = CGSize(width: 12, height: 12)
            let img = UIGraphicsImageRenderer(size: size).image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(UIColor(white: 0.75, alpha: 0.75).cgColor)
                cg.fillEllipse(in: CGRect(x: 1, y: 1, width: 10, height: 10))
                cg.setFillColor(UIColor(white: 0.95, alpha: 0.6).cgColor)
                cg.fillEllipse(in: CGRect(x: 3, y: 2, width: 5, height: 5))
            }
            let t = SKTexture(image: img); t.filteringMode = .linear; return t
        }
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
                tp.lineWidth = 0.6; tp.stroke()
                // 屋根と壁の境界にディザリング（グラデーション効果）
                drawRoofEdgeDither(cg: cg, roofBaseY: roofBaseY, w: w, config: config)

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
        let wW: CGFloat = 5, wH: CGFloat = 6
        let fH = floorH
        let cols = 2
        // 1階建てでも窓を表示（ただし上層階のみスキップ）
        let floorsToDraw = max(config.floors, 1)
        for floor in 0..<floorsToDraw {
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
                // 窓枠（1px フレーム）
                cg.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(0.5); cg.stroke(r)
                // 窓ガラスのハイライト（左上コーナー）
                cg.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
                cg.fill(CGRect(x: wx, y: fy, width: 2, height: 2))
            }
        }
    }

    // MARK: - Building Detail Helpers

    /// ドア（左面グラウンドフロア中央）
    private static func drawDoor(
        cg: CGContext, baseY: CGFloat, w: CGFloat, config: BuildingVisualConfig
    ) {
        let dW: CGFloat = 5, dH: CGFloat = 9
        // 左面のグラウンドフロア中央付近（X: ~w/8）
        let dx: CGFloat = w/8 - 1
        let dy = baseY - dH - 1
        // ドア枠（左色を暗くした色）
        cg.setFillColor(config.leftColor.darkened(by: 0.65).cgColor)
        cg.fill(CGRect(x: dx - 1, y: dy - 1, width: dW + 2, height: dH + 2))
        // ドアパネル（アクセント色）
        cg.setFillColor(config.accentColor.withAlphaComponent(0.7).cgColor)
        cg.fill(CGRect(x: dx, y: dy, width: dW, height: dH))
        // ドアノブ（小さな点）
        cg.setFillColor(UIColor(hex: "FFD700").withAlphaComponent(0.8).cgColor)
        cg.fill(CGRect(x: dx + dW - 2, y: dy + dH/2, width: 1.5, height: 1.5))
        // ステップ（ドア下）
        cg.setFillColor(config.leftColor.darkened(by: 0.55).cgColor)
        cg.fill(CGRect(x: dx - 1, y: baseY - 2, width: dW + 2, height: 2))
    }

    /// 看板（左面グラウンドフロア上部）
    private static func drawBuildingSign(
        cg: CGContext, baseY: CGFloat, w: CGFloat, config: BuildingVisualConfig
    ) {
        let sw: CGFloat = 12, sh: CGFloat = 5
        let sx: CGFloat = 2
        let sy = baseY - floorH + 3   // グラウンドフロア上部
        // 看板背景（アクセント色）
        cg.setFillColor(config.accentColor.cgColor)
        cg.fill(CGRect(x: sx, y: sy, width: sw, height: sh))
        // 看板テキスト（2本のライン）
        cg.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
        cg.fill(CGRect(x: sx + 1, y: sy + 1, width: sw - 3, height: 1))
        cg.fill(CGRect(x: sx + 1, y: sy + 3, width: sw - 5, height: 1))
        // 看板枠
        cg.setStrokeColor(UIColor.black.withAlphaComponent(0.28).cgColor)
        cg.setLineWidth(0.4)
        cg.stroke(CGRect(x: sx, y: sy, width: sw, height: sh))
    }

    /// フロア区切りライン（各階の境界に細いラインを入れる）
    private static func drawFloorBeltLines(
        cg: CGContext, bH: CGFloat, baseY: CGFloat, w: CGFloat, floors: Int
    ) {
        guard floors >= 2 else { return }
        cg.setStrokeColor(UIColor.black.withAlphaComponent(0.15).cgColor)
        cg.setLineWidth(0.7)
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
            if Int(x) % 2 == 0 {
                cg.fill(CGRect(x: x, y: y - 1, width: 1, height: 1))
            }
            x += 1
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
            let px = w/2 + 3
            let py = ridgeY - 13
            // ポール
            cg.setFillColor(UIColor(hex: "8B7536").cgColor)
            cg.fill(CGRect(x: px, y: py, width: 2, height: 13))
            // 旗（flagFrame で x オフセットを変化させて揺らす）
            let wave = CGFloat(flagFrame % 2) * 1.0
            cg.setFillColor(UIColor(hex: "E63946").cgColor)
            cg.fill(CGRect(x: px+2, y: py,         width: 7-wave, height: 3))
            cg.setFillColor(UIColor(hex: "FFFFFF").cgColor)
            cg.fill(CGRect(x: px+2, y: py+3,       width: 7,      height: 2))
            cg.setFillColor(UIColor(hex: "4A90D9").cgColor)
            cg.fill(CGRect(x: px+2, y: py+5,       width: 7+wave, height: 3))

        case "B026":  // カレンダータワー — 時計
            let cx = w/2 - 5, cy = ridgeY - 10
            cg.setFillColor(UIColor(hex: "FFFDE7").cgColor)
            cg.fillEllipse(in: CGRect(x: cx, y: cy, width: 9, height: 9))
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            cg.setLineWidth(0.5)
            cg.strokeEllipse(in: CGRect(x: cx, y: cy, width: 9, height: 9))
            // 時計の針（12時 + 3時）
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.65).cgColor)
            cg.setLineWidth(0.7)
            cg.move(to: CGPoint(x: cx+4.5, y: cy+4.5))
            cg.addLine(to: CGPoint(x: cx+4.5, y: cy+1)); cg.strokePath()
            cg.move(to: CGPoint(x: cx+4.5, y: cy+4.5))
            cg.addLine(to: CGPoint(x: cx+8,   y: cy+4.5)); cg.strokePath()

        case "B001", "B004", "B017":  // ジム / プール / 睡眠クリニック — アンテナ
            cg.setFillColor(UIColor(hex: "9E9E9E").cgColor)
            cg.fill(CGRect(x: w/2 + 2, y: ridgeY - 10, width: 2, height: 10))
            cg.setFillColor(UIColor(hex: "F44336").cgColor)
            cg.fillEllipse(in: CGRect(x: w/2 + 1.5, y: ridgeY - 12, width: 3, height: 3))

        case "B002":  // スタジアム — フラッグ群
            for i in 0..<3 {
                let fx = w/4 + CGFloat(i) * 8
                cg.setFillColor(UIColor(hex: "FF5722").cgColor)
                cg.fill(CGRect(x: fx, y: ridgeY - 8, width: 2, height: 8))
                let flagColors = ["FF5722", "4CAF50", "2196F3"]
                cg.setFillColor(UIColor(hex: flagColors[i]).cgColor)
                cg.fill(CGRect(x: fx+2, y: ridgeY - 8, width: 4, height: 3))
            }

        case "B018":  // 天文台 — 望遠鏡スリット
            cg.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: w/2 - 2, y: ridgeY - 16, width: 4, height: 10))

        case "B007", "B019", "B028":  // カフェ / 図書館 / 公民館 — 煙突
            let chx = w/4
            cg.setFillColor(config.rightColor.cgColor)
            cg.fill(CGRect(x: chx, y: ridgeY - 8, width: 5, height: 8))
            cg.setFillColor(UIColor(hex: "546E7A").cgColor)
            cg.fill(CGRect(x: chx - 1, y: ridgeY - 8, width: 7, height: 2))
            // 煙
            cg.setFillColor(UIColor.white.withAlphaComponent(0.25).cgColor)
            cg.fillEllipse(in: CGRect(x: chx, y: ridgeY - 13, width: 4, height: 4))

        default: break
        }

        // レベル5 金色トリム（屋根エッジに点線）
        if level >= 5 {
            cg.setFillColor(UIColor(hex: "FFD700").withAlphaComponent(0.55).cgColor)
            var gx: CGFloat = 0
            while gx < w {
                let gy = roofBaseY + (w/2 - gx) * (tileH/2) / (w/2)
                if Int(gx / 3) % 2 == 0 {
                    cg.fill(CGRect(x: gx, y: gy - 1, width: 2, height: 1))
                }
                gx += 3
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
            cg.fill(CGRect(x: w - 12, y: baseY - 3, width: 8, height: 2))
            if level >= 3 {
                // ミニ旗
                cg.setFillColor(UIColor(hex: "34C759").cgColor)
                cg.fill(CGRect(x: w - 6, y: baseY - 10, width: 1, height: 7))
                cg.fill(CGRect(x: w - 5, y: baseY - 10, width: 4, height: 3))
            }

        // ── 食事軸: プランター + テラス席 ──
        case "B007", "B008", "B009", "B010", "B011", "B012":
            // プランター（右面足元）
            cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
            cg.fill(CGRect(x: w - 10, y: baseY - 5, width: 6, height: 3))
            cg.setFillColor(UIColor(hex: "4CAF50").cgColor)
            cg.fillEllipse(in: CGRect(x: w - 9, y: baseY - 8, width: 4, height: 4))
            if level >= 3 {
                // テラス席（小さなパラソル）
                cg.setFillColor(UIColor(hex: "FF9500").withAlphaComponent(0.6).cgColor)
                cg.fill(CGRect(x: w - 16, y: baseY - 10, width: 6, height: 1))
                cg.setFillColor(UIColor(hex: "6D4C41").cgColor)
                cg.fill(CGRect(x: w - 14, y: baseY - 9, width: 1, height: 7))
            }

        // ── 飲酒軸: 石灯籠 + 砂利 ──
        case "B013", "B014", "B015", "B016":
            // 砂利テクスチャ（足元）
            cg.setFillColor(UIColor(hex: "D7CCC8").withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: w/2 + 2, y: baseY - 2, width: 10, height: 2))
            if level >= 2 {
                // 石灯籠
                cg.setFillColor(UIColor(hex: "9E9E9E").cgColor)
                cg.fill(CGRect(x: w - 8, y: baseY - 10, width: 3, height: 8))
                cg.fill(CGRect(x: w - 9, y: baseY - 11, width: 5, height: 2))
                cg.setFillColor(UIColor(hex: "FFE082").withAlphaComponent(0.6).cgColor)
                cg.fill(CGRect(x: w - 7, y: baseY - 8, width: 1, height: 1))
            }

        // ── 睡眠軸: 星型装飾 + 月のオブジェ ──
        case "B017", "B018", "B020", "B021", "B022":
            if level >= 2 {
                // 小さな星
                cg.setFillColor(UIColor(hex: "FFF176").withAlphaComponent(0.7).cgColor)
                cg.fill(CGRect(x: w - 8, y: baseY - 7, width: 2, height: 2))
                cg.fill(CGRect(x: w - 7, y: baseY - 8, width: 0, height: 0))
            }
            if level >= 4 {
                // 月のオブジェ
                cg.setFillColor(UIColor(hex: "FFF9C4").cgColor)
                cg.fillEllipse(in: CGRect(x: w - 14, y: baseY - 11, width: 5, height: 5))
                cg.setFillColor(UIColor(hex: "007AFF").withAlphaComponent(0.3).cgColor)
                cg.fillEllipse(in: CGRect(x: w - 12, y: baseY - 11, width: 4, height: 4))
            }

        // ── 生活習慣軸: 花壇 + ベンチ ──
        case "B019", "B023", "B024", "B026", "B027", "B028":
            // 花壇
            cg.setFillColor(UIColor(hex: "795548").cgColor)
            cg.fill(CGRect(x: w - 12, y: baseY - 4, width: 8, height: 3))
            let flowerColors = ["FF2D55", "FF9500", "FFEB3B"]
            for (i, hex) in flowerColors.enumerated() {
                cg.setFillColor(UIColor(hex: hex).cgColor)
                cg.fill(CGRect(x: w - 11 + CGFloat(i) * 3, y: baseY - 6, width: 2, height: 2))
            }
            if level >= 3 {
                // ベンチ
                cg.setFillColor(UIColor(hex: "8D6E63").cgColor)
                cg.fill(CGRect(x: 2, y: baseY - 4, width: 8, height: 2))
                cg.setFillColor(UIColor(hex: "5D4037").cgColor)
                cg.fill(CGRect(x: 3, y: baseY - 2, width: 2, height: 2))
                cg.fill(CGRect(x: 7, y: baseY - 2, width: 2, height: 2))
            }

        // ── 市庁舎: 噴水 + 階段 ──
        case "B025":
            if level >= 2 {
                // 階段（3段）
                cg.setFillColor(UIColor(hex: "D9C87A").withAlphaComponent(0.5).cgColor)
                cg.fill(CGRect(x: w/8 - 3, y: baseY - 2, width: 9, height: 2))
                cg.fill(CGRect(x: w/8 - 2, y: baseY - 4, width: 7, height: 2))
            }
            if level >= 4 {
                // 噴水のベース
                cg.setFillColor(UIColor(hex: "B0BEC5").cgColor)
                cg.fillEllipse(in: CGRect(x: w - 14, y: baseY - 6, width: 8, height: 4))
                cg.setFillColor(UIColor(hex: "90CAF9").withAlphaComponent(0.5).cgColor)
                cg.fillEllipse(in: CGRect(x: w - 12, y: baseY - 5, width: 4, height: 2))
            }

        // ── ペナルティ: 散乱ゴミ ──
        case "B029":
            cg.setFillColor(UIColor(hex: "795548").withAlphaComponent(0.4).cgColor)
            cg.fill(CGRect(x: w - 8, y: baseY - 3, width: 3, height: 2))
            cg.fill(CGRect(x: w - 14, y: baseY - 2, width: 2, height: 1))
        case "B030":
            // ツタ（左面）
            cg.setFillColor(UIColor(hex: "4CAF50").withAlphaComponent(0.35).cgColor)
            cg.fill(CGRect(x: 2, y: baseY - 18, width: 3, height: 14))
            cg.fill(CGRect(x: 4, y: baseY - 12, width: 2, height: 4))

        default: break
        }
    }

    // ────────────────────────────────────────────────────────────────
    // MARK: - Private: NPC Sprite
    // ────────────────────────────────────────────────────────────────

    private static func npcSprite(type: NPCType, frame: Int) -> SKTexture {
        let ps: CGFloat = 3
        let cols = 8, rows = 14
        let palette = NPCColors.palette(for: type)
        let pixels = NPCPixels.pixels(for: type, frame: frame)
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
