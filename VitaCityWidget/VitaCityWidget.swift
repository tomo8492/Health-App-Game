// VitaCityWidget.swift
// VitaCityWidget/
//
// WidgetKit 実装（CLAUDE.md Phase 4）
// - 小サイズ: 今日の合計 CP（無料）
// - 中サイズ: 5軸リングと合計 CP（プレミアム）
// - 大サイズ: 5軸リング + 連続記録日数 + 天気（プレミアム）

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct VitaCityEntry: TimelineEntry {
    let date:        Date
    let totalCP:     Int
    let exerciseCP:  Int
    let dietCP:      Int
    let alcoholCP:   Int
    let sleepCP:     Int
    let lifestyleCP: Int
    let streak:      Int
    let isPremium:   Bool

    static let placeholder = VitaCityEntry(
        date:        Date(),
        totalCP:     320,
        exerciseCP:  80,
        dietCP:      70,
        alcoholCP:   100,
        sleepCP:     60,
        lifestyleCP: 10,
        streak:      7,
        isPremium:   false
    )

    func cp(for axis: WidgetAxis) -> Int {
        switch axis {
        case .exercise:  return exerciseCP
        case .diet:      return dietCP
        case .alcohol:   return alcoholCP
        case .sleep:     return sleepCP
        case .lifestyle: return lifestyleCP
        }
    }
}

// Axis の軽量版（SwiftData 非依存）
enum WidgetAxis: CaseIterable {
    case exercise, diet, alcohol, sleep, lifestyle

    var name: String {
        switch self {
        case .exercise:  return "運動"
        case .diet:      return "食事"
        case .alcohol:   return "飲酒"
        case .sleep:     return "睡眠"
        case .lifestyle: return "生活"
        }
    }

    var icon: String {
        switch self {
        case .exercise:  return "figure.run"
        case .diet:      return "fork.knife"
        case .alcohol:   return "wineglass"
        case .sleep:     return "moon.zzz.fill"
        case .lifestyle: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .exercise:  return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .diet:      return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .alcohol:   return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .sleep:     return Color(red: 0.00, green: 0.48, blue: 1.00)
        case .lifestyle: return Color(red: 1.00, green: 0.18, blue: 0.33)
        }
    }
}

// MARK: - Timeline Provider

struct VitaCityProvider: TimelineProvider {

    func placeholder(in context: Context) -> VitaCityEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (VitaCityEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VitaCityEntry>) -> Void) {
        let entry = loadEntry()
        // 1時間ごとにリフレッシュ
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // App Group 経由で今日のデータを読む
    private func loadEntry() -> VitaCityEntry {
        let defaults = UserDefaults(suiteName: "group.com.vitacity.app") ?? .standard
        return VitaCityEntry(
            date:        Date(),
            totalCP:     defaults.integer(forKey: "todayTotalCP"),
            exerciseCP:  defaults.integer(forKey: "todayExerciseCP"),
            dietCP:      defaults.integer(forKey: "todayDietCP"),
            alcoholCP:   defaults.integer(forKey: "todayAlcoholCP"),
            sleepCP:     defaults.integer(forKey: "todaySleepCP"),
            lifestyleCP: defaults.integer(forKey: "todayLifestyleCP"),
            streak:      defaults.integer(forKey: "currentStreak"),
            isPremium:   defaults.bool(forKey: "isPremium")
        )
    }
}

// MARK: - Small Widget View（無料）

struct SmallWidgetView: View {
    let entry: VitaCityEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.00))
            Text("\(entry.totalCP)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.00))
            Text("CP")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(Date().formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Medium Widget View（プレミアム）

struct MediumWidgetView: View {
    let entry: VitaCityEntry

    var body: some View {
        if entry.isPremium {
            HStack(spacing: 16) {
                // 5軸ミニリング
                VStack(spacing: 6) {
                    ForEach(WidgetAxis.allCases, id: \.self) { axis in
                        HStack(spacing: 6) {
                            Image(systemName: axis.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(axis.color)
                                .frame(width: 14)
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(axis.color.opacity(0.15))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(axis.color)
                                    .frame(width: CGFloat(entry.cp(for: axis)) / 100.0 * 60, height: 5)
                            }
                            .frame(width: 60)
                            Text("\(entry.cp(for: axis))")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(axis.color)
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }

                Divider()

                // 合計 CP & 連続日数
                VStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text("\(entry.totalCP)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.00))
                        Text("今日の CP")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("\(entry.streak)日連続")
                            .font(.caption2.weight(.semibold))
                    }
                }
            }
            .padding()
            .containerBackground(.background, for: .widget)
        } else {
            premiumLockView
        }
    }

    private var premiumLockView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("プレミアム限定")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Large Widget View（プレミアム）

struct LargeWidgetView: View {
    let entry: VitaCityEntry

    var body: some View {
        if entry.isPremium {
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.00))
                    Text("VITA CITY")
                        .font(.headline.bold())
                    Spacer()
                    Text(Date().formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // 5軸バー
                ForEach(WidgetAxis.allCases, id: \.self) { axis in
                    HStack(spacing: 10) {
                        Image(systemName: axis.icon)
                            .font(.subheadline)
                            .foregroundStyle(axis.color)
                            .frame(width: 20)
                        Text(axis.name)
                            .font(.caption)
                            .frame(width: 30, alignment: .leading)
                        ZStack(alignment: .leading) {
                            Capsule().fill(axis.color.opacity(0.12))
                            Capsule().fill(axis.color)
                                .frame(width: CGFloat(entry.cp(for: axis)) / 100.0 * 130)
                        }
                        .frame(width: 130, height: 6)
                        Text("\(entry.cp(for: axis))")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(axis.color)
                    }
                }

                Divider()

                HStack {
                    VStack {
                        Text("\(entry.totalCP)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.00))
                        Text("合計 CP")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text("\(entry.streak)").font(.title2.bold())
                        }
                        Text("日連続").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .containerBackground(.background, for: .widget)
        } else {
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct VitaCityWidget: Widget {
    let kind = "VitaCityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VitaCityProvider()) { entry in
            VitaCityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VITA CITY")
        .description("今日の健康 CP を表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct VitaCityWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: VitaCityEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Bundle

@main
struct VitaCityWidgetBundle: WidgetBundle {
    var body: some Widget {
        VitaCityWidget()
    }
}
