// NotificationService.swift
// Infrastructure/Notifications/
//
// ローカル通知管理（CLAUDE.md Phase 4 スコープ）
//   - 毎日の記録リマインダー（夜20時）
//   - 連続記録が途切れそうな警告（夜21時・前日未記録時）
//   - 実績解除通知（即時）

import Foundation
import UserNotifications

// MARK: - NotificationService

@MainActor
final class NotificationService: NSObject {

    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - 認可要求

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - 毎日リマインダー（20:00）

    func scheduleDailyReminder() async {
        let granted = await requestAuthorization()
        guard granted else { return }

        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "VITA CITY"
        content.body  = "今日の健康記録はお済みですか？街の住民が待っています🏙"
        content.sound = .default

        var components       = DateComponents()
        components.hour      = 20
        components.minute    = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats:      true
        )
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content:    content,
            trigger:    trigger
        )
        try? await center.add(request)
    }

    // MARK: - 連続記録警告（21:00・当日未記録の場合）

    func scheduleStreakWarning(currentStreak: Int) async {
        guard currentStreak > 0 else { return }  // 連続記録がない場合は不要

        center.removePendingNotificationRequests(withIdentifiers: ["streak_warning"])

        let content = UNMutableNotificationContent()
        content.title = "🔥 \(currentStreak)日連続記録が途切れそう！"
        content.body  = "今日の記録をして連続記録を守りましょう。"
        content.sound = .defaultCritical

        var components   = DateComponents()
        components.hour  = 21
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats:      false   // 当日限り（毎日 setupApp で再スケジュール）
        )
        let request = UNNotificationRequest(
            identifier: "streak_warning",
            content:    content,
            trigger:    trigger
        )
        try? await center.add(request)
    }

    // MARK: - 実績解除通知（即時）

    func sendAchievementUnlockedNotification(title: String, description: String) async {
        let content = UNMutableNotificationContent()
        content.title    = "🏆 実績解除！"
        content.subtitle = title
        content.body     = description
        content.sound    = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content:    content,
            trigger:    trigger
        )
        try? await center.add(request)
    }

    // MARK: - バッジリセット

    func resetBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    // MARK: - 全通知削除

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// アプリがフォアグラウンドでも通知バナーを表示
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
