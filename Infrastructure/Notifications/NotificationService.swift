// NotificationService.swift
// Infrastructure/Notifications/
//
// ローカル通知の管理サービス
//   - 毎日のリマインダー（夜20時・未記録の場合）
//   - 実績解放通知（即時）
//   - ストリークマイルストーン通知（即時）
//   - CP マイルストーン通知（即時）
//   - 記録完了時にリマインダーをキャンセル
//
// UserNotifications フレームワークのみ使用（外部依存なし）

import Foundation
import UserNotifications

// MARK: - NotificationService

@Observable
@MainActor
final class NotificationService {

    // MARK: - 通知識別子

    private enum ID {
        static let dailyReminder    = "vitacity.daily.reminder"
        static let achievement      = "vitacity.achievement"
        static let streak           = "vitacity.streak"
        static let cpMilestone      = "vitacity.cp.milestone"
    }

    // MARK: - State

    /// ユーザーが通知を許可しているか
    private(set) var isAuthorized: Bool = false

    // MARK: - 初期化

    init() {}

    // MARK: - 認可リクエスト（起動時に1回呼ぶ）

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()

        // 既存の設定を確認
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            isAuthorized = true
            return
        case .notDetermined:
            break
        default:
            isAuthorized = false
            return
        }

        // 許可ダイアログを表示
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - 毎日リマインダー（夜20時）

    /// 今日まだ記録していない場合のリマインダーをスケジュール
    /// - Parameter hour: 通知する時刻（デフォルト20時）
    func scheduleDailyReminder(hour: Int = 20) {
        guard isAuthorized else { return }

        let center = UNUserNotificationCenter.current()

        // 既存のリマインダーを一度削除して再登録
        center.removePendingNotificationRequests(withIdentifiers: [ID.dailyReminder])

        let content = UNMutableNotificationContent()
        content.title = "今日の健康記録"
        content.body  = "今日の記録をつけて街を発展させましょう！"
        content.sound = .default
        content.badge = 1

        var dateComponents        = DateComponents()
        dateComponents.hour       = hour
        dateComponents.minute     = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: ID.dailyReminder,
            content:    content,
            trigger:    trigger
        )
        center.add(request)
    }

    /// 記録完了時にその日のリマインダーをキャンセル（翌日分は残す）
    func cancelTodayReminder() {
        // 繰り返しトリガーは削除せず、バッジのみクリア
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    /// リマインダーを完全に無効化（設定から通知をオフにしたユーザー向け）
    func disableDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [ID.dailyReminder])
    }

    // MARK: - 実績解放通知（即時）

    func sendAchievementNotification(title: String, description: String, icon: String) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title    = "🏆 実績解放：\(title)"
        content.body     = description
        content.sound    = .defaultRingtone
        content.badge    = 0

        // カテゴリ識別子（将来のアクションボタン拡張用）
        content.categoryIdentifier = "achievement"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(ID.achievement).\(UUID().uuidString)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - ストリーク通知（即時）

    func sendStreakNotification(streak: Int) {
        guard isAuthorized else { return }
        guard [3, 7, 14, 30, 60, 100].contains(streak) else { return }

        let content = UNMutableNotificationContent()
        content.title = "🔥 \(streak)日連続記録達成！"
        content.body  = streakMessage(for: streak)
        content.sound = .defaultRingtone

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(ID.streak).\(streak)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - CP マイルストーン通知（即時）

    func sendCPMilestoneNotification(totalCP: Int) {
        guard isAuthorized else { return }

        // マイルストーン値のみ通知（毎回送らない）
        let milestones = [100, 500, 1_000, 3_000, 5_000, 10_000, 15_000, 30_000, 50_000]
        guard milestones.contains(totalCP) else { return }

        let content = UNMutableNotificationContent()
        content.title = "🌆 街が成長しました！"
        content.body  = cpMilestoneMessage(for: totalCP)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(ID.cpMilestone).\(totalCP)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - バッジクリア

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Private helpers

    private func streakMessage(for streak: Int) -> String {
        switch streak {
        case 3:   return "3日連続で健康記録を続けています。この調子で！"
        case 7:   return "1週間連続達成！街の住民たちも喜んでいます 🎉"
        case 14:  return "2週間連続！あなたの習慣が街を輝かせています ✨"
        case 30:  return "30日連続！素晴らしい健康習慣が身についています 🏆"
        case 60:  return "60日連続達成！街はあなたのおかげで大発展中 🌇"
        case 100: return "100日の軌跡！あなたは真の健康マスターです 👑"
        default:  return "\(streak)日連続記録中！引き続き頑張りましょう"
        }
    }

    private func cpMilestoneMessage(for cp: Int) -> String {
        switch cp {
        case 100:    return "累計 100 CP 達成！街に最初の建物が増えました"
        case 500:    return "累計 500 CP 達成！街に活気が出てきました"
        case 1_000:  return "累計 1,000 CP 突破！商業エリアが拡大中"
        case 3_000:  return "累計 3,000 CP！住民たちの笑顔が増えています"
        case 5_000:  return "累計 5,000 CP！マップが 30×30 に拡大しました 🗺️"
        case 10_000: return "累計 10,000 CP！大都市への道が開けてきました"
        case 15_000: return "累計 15,000 CP！マップが 40×40 に拡大しました 🏙️"
        case 30_000: return "累計 30,000 CP！最大マップ 50×50 に到達！ 🌆"
        case 50_000: return "累計 50,000 CP！あなたの街は大都市になりました 👑"
        default:     return "累計 \(cp) CP 達成！素晴らしい進歩です"
        }
    }
}
