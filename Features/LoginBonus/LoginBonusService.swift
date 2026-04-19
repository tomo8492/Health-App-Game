// LoginBonusService.swift
// Features/LoginBonus/
//
// 日替わりログインボーナス機能
// - UserDefaults で最終ログイン日と連続ログイン日数を永続化
// - 日付が変わった最初の起動でボーナス CP を付与
// - 連続ログインでボーナスが増え、7日ごとの週間マイルストーンで大幅 UP
//
// 健康記録とは独立した報酬:
//   totalCP には加算するが todayCP には加算しない
//   → 日々の健康達成度（天気判定）には影響せず、街の成長だけが進む

import Foundation
import Observation

// MARK: - LoginBonus

struct LoginBonus: Equatable {
    let baseCP:       Int     // 基本付与 CP
    let streakBonus:  Int     // 連続ログイン日数ボーナス
    let milestoneCP:  Int     // 週間マイルストーン追加 CP（7日ごと）
    let loginStreak:  Int     // 付与後の連続ログイン日数
    let isMilestone:  Bool    // 7, 14, 30 日等のマイルストーンか

    var totalCP: Int { baseCP + streakBonus + milestoneCP }
}

// MARK: - LoginBonusService

@Observable
@MainActor
final class LoginBonusService {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let lastLoginDate = "vitacity.loginBonus.lastDate"
        static let loginStreak   = "vitacity.loginBonus.streak"
        static let totalLogins   = "vitacity.loginBonus.total"
    }

    private let defaults: UserDefaults

    // MARK: - Public State

    /// 現在保留中のログインボーナス（UI 表示用）。表示後に nil にする
    var pendingBonus: LoginBonus? = nil

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - ボーナス判定（起動時に呼ぶ）

    /// 日付が変わっていればログインボーナスを計算して pendingBonus に設定する
    /// - Returns: 付与すべきボーナス（新しい日の初回起動時のみ）
    @discardableResult
    func checkAndAwardDailyBonus(now: Date = Date()) -> LoginBonus? {
        let today = Calendar.current.startOfDay(for: now)

        // 最終ログイン日を取得
        let lastLogin = defaults.object(forKey: Keys.lastLoginDate) as? Date
        let lastLoginDay = lastLogin.map { Calendar.current.startOfDay(for: $0) }

        // 同じ日なら何もしない（ボーナス重複付与を防止）
        if lastLoginDay == today { return nil }

        // 連続ログイン判定
        let previousStreak = defaults.integer(forKey: Keys.loginStreak)
        let newStreak: Int
        if let last = lastLoginDay,
           let diff = Calendar.current.dateComponents([.day], from: last, to: today).day,
           diff == 1 {
            // 昨日ログインしていれば連続ログイン継続
            newStreak = previousStreak + 1
        } else {
            // 2日以上空いたらリセット
            newStreak = 1
        }

        let bonus = Self.calculateBonus(loginStreak: newStreak)

        // 永続化
        defaults.set(now,                       forKey: Keys.lastLoginDate)
        defaults.set(newStreak,                 forKey: Keys.loginStreak)
        defaults.set(defaults.integer(forKey: Keys.totalLogins) + 1,
                     forKey: Keys.totalLogins)

        pendingBonus = bonus
        return bonus
    }

    // MARK: - 純粋関数（テスト可能）

    /// 連続ログイン日数からボーナス内訳を算出する
    static func calculateBonus(loginStreak: Int) -> LoginBonus {
        // 基本 CP: 10（毎日固定）
        let base = 10

        // 連続ボーナス: 1日 +2CP（上限 50CP = 25日分）
        let streakBonus = min((loginStreak - 1) * 2, 50)

        // 週間マイルストーン: 7, 14, 21, 30, 50, 100 日で大幅ボーナス
        let milestone: Int
        let isMilestone: Bool
        switch loginStreak {
        case 100: milestone = 500; isMilestone = true
        case 50:  milestone = 250; isMilestone = true
        case 30:  milestone = 150; isMilestone = true
        case 21:  milestone = 100; isMilestone = true
        case 14:  milestone = 75;  isMilestone = true
        case 7:   milestone = 50;  isMilestone = true
        default:
            // それ以外の7の倍数でも小さなマイルストーン
            if loginStreak > 7 && loginStreak % 7 == 0 {
                milestone = 30
                isMilestone = true
            } else {
                milestone = 0
                isMilestone = false
            }
        }

        return LoginBonus(
            baseCP:       base,
            streakBonus:  streakBonus,
            milestoneCP:  milestone,
            loginStreak:  loginStreak,
            isMilestone:  isMilestone
        )
    }

    // MARK: - 現在の統計（UI 表示用）

    var currentLoginStreak: Int { defaults.integer(forKey: Keys.loginStreak) }
    var totalLoginCount:    Int { defaults.integer(forKey: Keys.totalLogins) }
}
