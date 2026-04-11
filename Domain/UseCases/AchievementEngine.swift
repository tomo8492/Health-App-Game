// AchievementEngine.swift
// Domain/UseCases/
//
// 実績・バッジシステム
// CLAUDE.md Phase 4 スコープ
// パターン参考: CareKit (Apple) の観察可能な目標モデル

import Foundation
import SwiftUI

// MARK: - Achievement Model

struct Achievement: Identifiable, Sendable {
    let id:          String
    let title:       String
    let description: String
    let icon:        String    // SF Symbol 名
    let category:    AchievementCategory
    let condition:   AchievementCondition
    var isUnlocked:  Bool = false
    var unlockedAt:  Date? = nil
    var progress:    Double = 0.0  // 0.0〜1.0（進捗表示用）
}

enum AchievementCategory: String, CaseIterable, Sendable {
    case exercise  = "運動"
    case diet      = "食事"
    case alcohol   = "飲酒"
    case sleep     = "睡眠"
    case lifestyle = "生活習慣"
    case city      = "街"
    case streak    = "連続記録"
    case milestone = "マイルストーン"

    var icon: String {
        switch self {
        case .exercise:  return "figure.run"
        case .diet:      return "fork.knife"
        case .alcohol:   return "wineglass"
        case .sleep:     return "moon.zzz.fill"
        case .lifestyle: return "leaf.fill"
        case .city:      return "building.2.fill"
        case .streak:    return "flame.fill"
        case .milestone: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .exercise:  return .vcExercise
        case .diet:      return .vcDiet
        case .alcohol:   return .vcAlcohol
        case .sleep:     return .vcSleep
        case .lifestyle: return .vcLifestyle
        case .city:      return .vcCP
        case .streak:    return .orange
        case .milestone: return .vcCP
        }
    }
}

// MARK: - Achievement Condition

enum AchievementCondition: Sendable {
    case totalCPReached(Int)          // 累計 CP が N 以上
    case streakDays(Int)              // 連続記録 N 日
    case singleDayCP(Int)             // 1日 CP が N 以上
    case perfectDay                   // 1日全軸 100CP
    case exerciseCP100(times: Int)    // 運動 100CP を N 回達成
    case alcoholZeroDays(Int)         // 飲酒ゼロを N 日連続
    case stepGoal(steps: Int, days: Int) // N 歩を D 日達成
    case npcCount(Int)               // 街の住民数が N 人以上
}

// MARK: - Achievement Catalog

enum AchievementCatalog {
    static let all: [Achievement] = [
        // マイルストーン
        .init(id: "M001", title: "初めての一歩",      description: "初めて CP を記録した",
              icon: "star.fill",         category: .milestone,  condition: .totalCPReached(1)),
        .init(id: "M002", title: "100 CP 達成",      description: "累計 100 CP を獲得",
              icon: "medal.fill",        category: .milestone,  condition: .totalCPReached(100)),
        .init(id: "M003", title: "1,000 CP 突破",    description: "累計 1,000 CP を獲得",
              icon: "medal.fill",        category: .milestone,  condition: .totalCPReached(1_000)),
        .init(id: "M004", title: "10,000 CP の街",   description: "累計 10,000 CP を獲得",
              icon: "building.2.crop.circle.fill", category: .milestone, condition: .totalCPReached(10_000)),
        .init(id: "M005", title: "完璧な一日",        description: "1日で全軸 100CP（500CP）を達成",
              icon: "crown.fill",        category: .milestone,  condition: .perfectDay),

        // 連続記録
        .init(id: "S001", title: "3日連続",           description: "3日間連続で記録",
              icon: "flame.fill",        category: .streak,     condition: .streakDays(3)),
        .init(id: "S002", title: "7日連続",           description: "1週間連続で記録",
              icon: "flame.fill",        category: .streak,     condition: .streakDays(7)),
        .init(id: "S003", title: "30日連続",          description: "1ヶ月連続で記録",
              icon: "flame.fill",        category: .streak,     condition: .streakDays(30)),
        .init(id: "S004", title: "100日の軌跡",       description: "100日間連続で記録",
              icon: "flame.fill",        category: .streak,     condition: .streakDays(100)),

        // 運動
        .init(id: "E001", title: "ウォーカー",         description: "1日 10,000 歩を 7 日達成",
              icon: "figure.walk",       category: .exercise,   condition: .stepGoal(steps: 10_000, days: 7)),
        .init(id: "E002", title: "ランナー",           description: "運動 100CP を 10 回達成",
              icon: "figure.run",        category: .exercise,   condition: .exerciseCP100(times: 10)),
        .init(id: "E003", title: "アスリート",         description: "運動 100CP を 30 回達成",
              icon: "figure.run.circle.fill", category: .exercise, condition: .exerciseCP100(times: 30)),

        // 飲酒
        .init(id: "A001", title: "節制の始まり",      description: "飲酒ゼロを 7 日連続",
              icon: "wineglass",         category: .alcohol,    condition: .alcoholZeroDays(7)),
        .init(id: "A002", title: "節制マスター",       description: "飲酒ゼロを 30 日連続",
              icon: "wineglass.fill",    category: .alcohol,    condition: .alcoholZeroDays(30)),

        // 睡眠
        .init(id: "SL01", title: "快眠生活",          description: "睡眠 100CP を 7 回連続達成",
              icon: "moon.zzz.fill",     category: .sleep,      condition: .singleDayCP(100)),

        // 街
        .init(id: "C001", title: "街が賑わってきた",   description: "NPC（住民）が 10 人に",
              icon: "person.3.fill",     category: .city,       condition: .npcCount(10)),
        .init(id: "C002", title: "大都市への道",       description: "累計 5,000 CP（30×30 マップ解放）",
              icon: "map.fill",          category: .city,       condition: .totalCPReached(5_000)),
        .init(id: "C003", title: "メトロポリス",       description: "累計 30,000 CP（最大マップ解放）",
              icon: "building.columns.fill", category: .city,   condition: .totalCPReached(30_000)),
    ]
}

// MARK: - AchievementEngine

@Observable
@MainActor
final class AchievementEngine {

    var achievements: [Achievement] = AchievementCatalog.all
    var recentlyUnlocked: Achievement? = nil  // バナー表示用

    // MARK: - Check（記録保存後に呼び出す）

    func checkAchievements(
        totalCP:      Int,
        streak:       Int,
        npcCount:     Int,
        todayRecord:  DailyRecord?,
        allRecords:   [DailyRecord]
    ) {
        for i in achievements.indices where !achievements[i].isUnlocked {
            let (unlocked, progress) = evaluate(
                condition:   achievements[i].condition,
                totalCP:     totalCP,
                streak:      streak,
                npcCount:    npcCount,
                todayRecord: todayRecord,
                allRecords:  allRecords
            )
            achievements[i].progress = progress
            if unlocked {
                achievements[i].isUnlocked = true
                achievements[i].unlockedAt = Date()
                recentlyUnlocked = achievements[i]
            }
        }
    }

    // MARK: - Evaluate（純粋関数的ロジック）

    private func evaluate(
        condition:   AchievementCondition,
        totalCP:     Int,
        streak:      Int,
        npcCount:    Int,
        todayRecord: DailyRecord?,
        allRecords:  [DailyRecord]
    ) -> (unlocked: Bool, progress: Double) {

        switch condition {

        case .totalCPReached(let target):
            return (totalCP >= target, min(Double(totalCP) / Double(target), 1.0))

        case .streakDays(let target):
            return (streak >= target, min(Double(streak) / Double(target), 1.0))

        case .singleDayCP(let target):
            let cp = todayRecord?.totalCP ?? 0
            return (cp >= target, min(Double(cp) / Double(target), 1.0))

        case .perfectDay:
            guard let r = todayRecord else { return (false, 0) }
            let isPerfect = r.exerciseCP >= 100 && r.dietCP >= 100 &&
                            r.alcoholCP >= 100 && r.sleepCP >= 100 && r.lifestyleCP >= 100
            let avg = Double(r.exerciseCP + r.dietCP + r.alcoholCP + r.sleepCP + r.lifestyleCP) / 500.0
            return (isPerfect, min(avg, 1.0))

        case .exerciseCP100(let times):
            let count = allRecords.filter { $0.exerciseCP >= 100 }.count
            return (count >= times, min(Double(count) / Double(times), 1.0))

        case .alcoholZeroDays(let target):
            // 直近の連続飲酒ゼロ日数をカウント
            let sorted = allRecords.sorted { $0.date > $1.date }
            var consecutive = 0
            for r in sorted {
                if r.alcoholCP >= 100 { consecutive += 1 } else { break }
            }
            return (consecutive >= target, min(Double(consecutive) / Double(target), 1.0))

        case .stepGoal(let steps, let days):
            // 歩数は HealthKit 管理なので今は allRecords の exerciseCP >= 60 で代用
            let count = allRecords.filter { $0.exerciseCP >= 60 }.count
            return (count >= days, min(Double(count) / Double(days), 1.0))

        case .npcCount(let target):
            return (npcCount >= target, min(Double(npcCount) / Double(target), 1.0))
        }
    }

    // MARK: - Unlock Stats

    var unlockedCount: Int { achievements.filter(\.isUnlocked).count }
    var totalCount:    Int { achievements.count }
}
