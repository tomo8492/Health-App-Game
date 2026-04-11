// AchievementsView.swift
// Features/Achievements/
// SCR: 実績・バッジ一覧画面

import SwiftUI

// MARK: - AchievementsView

struct AchievementsView: View {

    @Environment(AchievementEngine.self) private var engine
    @State private var selectedCategory: AchievementCategory? = nil
    @Environment(AppState.self) private var appState

    private var filtered: [Achievement] {
        guard let cat = selectedCategory else { return engine.achievements }
        return engine.achievements.filter { $0.category == cat }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressHeader
                    .padding(.horizontal)

                categoryFilter
                    .padding(.horizontal)

                achievementList
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("実績")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - ヘッダー（解除数 / 全数）

    private var progressHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("解除済み実績")
                    .font(.headline)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(engine.unlockedCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vcCP)
                    Text("/ \(engine.totalCount)")
                        .font(.title3)
                        .foregroundStyle(Color.vcSecondaryLabel)
                }
            }
            Spacer()
            // 進捗リング
            ZStack {
                Circle()
                    .stroke(Color.vcSecondaryLabel.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(engine.unlockedCount) / CGFloat(max(engine.totalCount, 1)))
                    .stroke(
                        LinearGradient(colors: [.vcCP, .vcCPGlow], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: engine.unlockedCount)
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(Color.vcCP)
            }
            .frame(width: 72, height: 72)
        }
        .padding()
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - カテゴリフィルター

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChipSimple(label: "すべて", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(AchievementCategory.allCases, id: \.self) { cat in
                    FilterChipSimple(label: cat.rawValue, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
        }
    }

    // MARK: - 実績リスト

    private var achievementList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filtered) { achievement in
                AchievementRow(achievement: achievement)
            }
        }
    }
}

// MARK: - AchievementRow

struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 14) {
            // アイコン
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? achievement.category.color.opacity(0.15)
                          : Color.vcSecondaryLabel.opacity(0.08))
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(achievement.isUnlocked
                                     ? achievement.category.color
                                     : Color.vcSecondaryLabel)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(achievement.isUnlocked ? Color.vcLabel : Color.vcSecondaryLabel)
                    Spacer()
                    if achievement.isUnlocked, let date = achievement.unlockedAt {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption2)
                            .foregroundStyle(Color.vcSecondaryLabel)
                    }
                }
                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(Color.vcSecondaryLabel)

                // 進捗バー（未解除のみ）
                if !achievement.isUnlocked && achievement.progress > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(achievement.category.color.opacity(0.12))
                            Capsule()
                                .fill(achievement.category.color)
                                .frame(width: geo.size.width * achievement.progress)
                        }
                        .frame(height: 4)
                    }
                    .frame(height: 4)
                }
            }
        }
        .padding(12)
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - FilterChipSimple

private struct FilterChipSimple: View {
    let label:      String
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? .white : Color.vcLabel)
                .background(
                    isSelected ? Color.vcCP : Color.vcSecondaryLabel.opacity(0.15),
                    in: Capsule()
                )
        }
    }
}

// MARK: - Achievement Banner（アプリ内通知）

struct AchievementBannerView: View {
    let achievement: Achievement
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(achievement.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundStyle(achievement.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("実績解除！")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vcCP)
                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(Color.vcSecondaryLabel)
            }
            Spacer()
            Button {
                withAnimation { isVisible = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(Color.vcSecondaryLabel)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vcCP.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - AchievementBannerModifier（全画面で使えるViewModifier）

struct AchievementBannerModifier: ViewModifier {
    @Binding var achievement: Achievement?

    @State private var showBanner = false
    @State private var displayed: Achievement? = nil

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if showBanner, let a = displayed {
                AchievementBannerView(achievement: a, isVisible: $showBanner)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(1000)
            }
        }
        .onChange(of: achievement) { _, new in
            guard let new else { return }
            displayed = new
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showBanner = true
            }
            // 4秒後に自動非表示
            Task {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                withAnimation { showBanner = false }
                achievement = nil
            }
        }
    }
}

extension View {
    func achievementBanner(_ achievement: Binding<Achievement?>) -> some View {
        modifier(AchievementBannerModifier(achievement: achievement))
    }
}
