// OnboardingView.swift
// Features/Onboarding/
//
// 初回起動時の 3 ステップオンボーディング
// 1. VITA CITY の紹介（コンセプト）
// 2. 記録 → CP → 街の成長の説明
// 3. HealthKit 連携の説明
//
// UserDefaults で表示済みフラグを管理し、2 回目以降は表示しない

import SwiftUI

// MARK: - OnboardingOverlay Modifier

struct OnboardingOverlayModifier: ViewModifier {
    @State private var isShowingOnboarding: Bool

    init() {
        let shown = UserDefaults.standard.bool(forKey: "vitacity.onboarding.completed")
        _isShowingOnboarding = State(initialValue: !shown)
    }

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isShowingOnboarding) {
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: "vitacity.onboarding.completed")
                    isShowingOnboarding = false
                }
            }
    }
}

extension View {
    func onboardingOverlay() -> some View {
        modifier(OnboardingOverlayModifier())
    }
}

// MARK: - OnboardingView

private struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "building.2.crop.circle.fill",
            iconColor: .vcCP,
            title: "VITA CITY へようこそ",
            subtitle: "健康習慣で街を育てる\n新感覚シティビルダー",
            description: "毎日の運動・食事・睡眠などの記録が\nあなたの街の発展に繋がります"
        ),
        OnboardingPage(
            icon: "star.circle.fill",
            iconColor: .orange,
            title: "記録して CP を獲得",
            subtitle: "5つの健康軸で最大 500 CP/日",
            description: "CP が貯まると建物が建ち、NPC が増え、\n天気が良くなり、街がレベルアップします"
        ),
        OnboardingPage(
            icon: "heart.circle.fill",
            iconColor: .pink,
            title: "HealthKit と連携",
            subtitle: "歩数・睡眠は自動で取得",
            description: "Apple ヘルスケアと連携すると\n運動と睡眠が自動で記録されます"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ページコンテンツ
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // ページインジケーター
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.vcCP : Color.vcSecondaryLabel.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 24)

            // ボタン
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vcCP, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            // スキップ
            if currentPage < pages.count - 1 {
                Button("スキップ") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundStyle(Color.vcSecondaryLabel)
                .padding(.bottom, 12)
            } else {
                Spacer().frame(height: 32)
            }
        }
        .background(Color.vcBackground.ignoresSafeArea())
    }
}

// MARK: - OnboardingPage Data

private struct OnboardingPage {
    let icon:        String
    let iconColor:   Color
    let title:       String
    let subtitle:    String
    let description: String
}

// MARK: - OnboardingPageView

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.iconColor)
                .shadow(color: page.iconColor.opacity(0.4), radius: 16)

            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.vcSecondaryLabel)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundStyle(Color.vcSecondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }
}
