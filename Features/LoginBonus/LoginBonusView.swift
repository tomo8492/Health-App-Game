// LoginBonusView.swift
// Features/LoginBonus/
//
// 日替わりログインボーナスの祝福 UI
// 起動時に pendingBonus があれば自動表示され、タップで閉じる

import SwiftUI

// MARK: - LoginBonusOverlay Modifier

struct LoginBonusOverlayModifier: ViewModifier {
    @Binding var bonus: LoginBonus?
    @State private var appeared = false
    @State private var sparklePhase = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if let b = bonus {
                // 半透明背景（タップで閉じる）
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { dismiss() }

                LoginBonusCard(bonus: b, onDismiss: dismiss)
                    .padding(.horizontal, 32)
                    .scaleEffect(appeared ? 1.0 : 0.75)
                    .opacity(appeared ? 1.0 : 0.0)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.75), value: bonus != nil)
        .onChange(of: bonus != nil) { _, isShowing in
            if isShowing {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05)) {
                    appeared = true
                }
                HapticEngine.success()
                if bonus?.isMilestone == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        HapticEngine.levelUpBurst()
                    }
                }
            } else {
                appeared = false
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            bonus = nil
        }
    }
}

extension View {
    func loginBonusOverlay(_ bonus: Binding<LoginBonus?>) -> some View {
        modifier(LoginBonusOverlayModifier(bonus: bonus))
    }
}

// MARK: - LoginBonusCard

private struct LoginBonusCard: View {
    let bonus: LoginBonus
    let onDismiss: () -> Void

    @State private var cpCountUp: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            // ── ヘッダー ──
            VStack(spacing: 4) {
                Image(systemName: bonus.isMilestone ? "star.circle.fill" : "gift.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: bonus.isMilestone
                                ? [Color.yellow, Color.orange]
                                : [Color.vcCP, Color.vcCP.opacity(0.7)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.vcCP.opacity(0.6), radius: 12)

                Text(bonus.isMilestone ? "連続ログイン達成！" : "ログインボーナス")
                    .font(.title3.bold())
                    .foregroundStyle(Color.primary)

                Text("\(bonus.loginStreak) 日連続")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15), in: Capsule())
            }

            Divider()

            // ── 内訳 ──
            VStack(spacing: 8) {
                bonusRow(label: "ログインボーナス", amount: bonus.baseCP,
                         icon: "star.fill", color: .vcCP)

                if bonus.streakBonus > 0 {
                    bonusRow(label: "連続ログイン +\(bonus.loginStreak - 1)日",
                             amount: bonus.streakBonus,
                             icon: "flame.fill", color: .orange)
                }

                if bonus.milestoneCP > 0 {
                    bonusRow(label: "\(bonus.loginStreak)日マイルストーン",
                             amount: bonus.milestoneCP,
                             icon: "crown.fill", color: .yellow)
                }
            }

            Divider()

            // ── 合計 ──
            VStack(spacing: 4) {
                Text("獲得 CP")
                    .font(.caption)
                    .foregroundStyle(Color.vcSecondaryLabel)
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.vcCP)
                    Text("+\(cpCountUp)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.vcCP)
                        .contentTransition(.numericText())
                }
            }

            // ── 閉じるボタン ──
            Button(action: onDismiss) {
                Text("受け取る")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.vcCP, Color.vcCP.opacity(0.8)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
        }
        .padding(24)
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.4), radius: 24, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    bonus.isMilestone ? Color.yellow.opacity(0.6) : Color.vcCP.opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                cpCountUp = bonus.totalCP
            }
        }
    }

    private func bonusRow(label: String, amount: Int,
                          icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
            Spacer()
            Text("+\(amount) CP")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
        }
    }
}
