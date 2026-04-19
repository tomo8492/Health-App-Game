// LevelUpRewardView.swift
// Features/City/
//
// 街レベルアップ時の報酬祝福オーバーレイ
// レベルごとのボーナスCP・称号を表示する

import SwiftUI

// MARK: - LevelUpRewardOverlay Modifier

struct LevelUpRewardOverlayModifier: ViewModifier {
    @Binding var reward: CityLevelReward?
    @State private var appeared = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if let r = reward {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { dismiss() }

                LevelUpRewardCard(reward: r, onDismiss: dismiss)
                    .padding(.horizontal, 40)
                    .scaleEffect(appeared ? 1.0 : 0.7)
                    .opacity(appeared ? 1.0 : 0.0)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: reward != nil)
        .onChange(of: reward != nil) { _, isShowing in
            if isShowing {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.05)) {
                    appeared = true
                }
            } else {
                appeared = false
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            reward = nil
        }
    }
}

extension View {
    func levelUpRewardOverlay(_ reward: Binding<CityLevelReward?>) -> some View {
        modifier(LevelUpRewardOverlayModifier(reward: reward))
    }
}

// MARK: - LevelUpRewardCard

private struct LevelUpRewardCard: View {
    let reward: CityLevelReward
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // レベルバッジ
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.vcCP, Color.vcCP.opacity(0.3)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)

                Text("Lv.\(reward.level)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.vcCP.opacity(0.5), radius: 16)

            // タイトル
            Text("LEVEL UP!")
                .font(.caption.weight(.heavy))
                .tracking(3)
                .foregroundStyle(Color.vcCP)

            Text(reward.title)
                .font(.title3.bold())

            Text(reward.description)
                .font(.subheadline)
                .foregroundStyle(Color.vcSecondaryLabel)
                .multilineTextAlignment(.center)

            Divider()

            // ボーナスCP
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.vcCP)
                Text("ボーナス +\(reward.bonusCP) CP")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.vcCP)
            }
            .padding(.vertical, 4)

            // 閉じるボタン
            Button(action: onDismiss) {
                Text("OK")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.vcCP, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.4), radius: 20, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.vcCP.opacity(0.4), lineWidth: 1.5)
        )
    }
}
