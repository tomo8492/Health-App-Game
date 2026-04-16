// HapticEngine.swift
// Core/
//
// 触覚フィードバックの統一窓口。
// 記録保存・建設・レベルアップ・ペナルティ等のゲーム体験を物理的にも感じられるようにする。
//
// 設計方針:
//   - すべて MainActor 上で動作（UIFeedbackGenerator が要求）
//   - 起動コストを抑えるため軽量にラップ
//   - SpriteKit / SwiftUI どちらからでも呼べる

import UIKit

@MainActor
enum HapticEngine {

    // MARK: - 軽量タップ（CP 加算・ボタンタップ）
    static func tapLight() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred(intensity: 0.6)
    }

    // MARK: - 中強度（建物選択・モーダル開閉）
    static func tapMedium() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred(intensity: 0.8)
    }

    // MARK: - 強インパクト（建設完了・レベルアップ）
    static func tapHeavy() {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        g.impactOccurred(intensity: 1.0)
    }

    // MARK: - 達成（記録保存・全軸完了）
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    // MARK: - 警告（ペナルティ建物出現・嵐）
    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }

    // MARK: - 失敗（建設失敗・CP 不足）
    static func error() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.error)
    }

    // MARK: - セレクション（軸切替・カタログスクロール）
    static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }

    // MARK: - 連打: 建物 LvUP 時の二段震動
    static func levelUpBurst() {
        tapMedium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            tapHeavy()
        }
    }

    // MARK: - 連打: 建設完了 → 着地感のある三段震動
    static func constructionLanding() {
        tapLight()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { tapMedium() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { success() }
    }
}
