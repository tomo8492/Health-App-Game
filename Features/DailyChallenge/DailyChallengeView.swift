// DailyChallengeView.swift
// Features/DailyChallenge/
//
// ホーム画面に表示する日替わりチャレンジバッジ

import SwiftUI

// MARK: - DailyChallengeBadge（コンパクト表示、ホーム画面用）

struct DailyChallengeBadge: View {
    let challenge: DailyChallenge
    let isCompleted: Bool
    let currentAxisCP: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: challenge.axis.icon)
                .font(.system(size: 10))
                .foregroundStyle(isCompleted ? .white : challenge.axis.color)

            VStack(alignment: .leading, spacing: 1) {
                Text("今日のチャレンジ")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(isCompleted ? .white.opacity(0.8) : Color.white.opacity(0.6))
                HStack(spacing: 3) {
                    Text(challenge.axis.shortName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isCompleted ? .white : challenge.axis.color)
                    Text(isCompleted ? "達成！" : "\(currentAxisCP)/\(challenge.targetCP)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(isCompleted ? .white : Color.white)
                }
            }

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            isCompleted
                ? AnyShapeStyle(challenge.axis.color)
                : AnyShapeStyle(Color.white.opacity(0.12)),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

// MARK: - DailyChallengeCompletionOverlay

struct DailyChallengeCompletionModifier: ViewModifier {
    @Binding var challenge: DailyChallenge?
    @State private var appeared = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if let c = challenge {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { dismiss() }

                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(c.axis.color)
                        .shadow(color: c.axis.color.opacity(0.5), radius: 12)

                    Text("チャレンジ達成！")
                        .font(.title3.bold())

                    HStack(spacing: 4) {
                        Image(systemName: c.axis.icon)
                            .foregroundStyle(c.axis.color)
                        Text("\(c.axis.name) \(c.targetCP) CP 達成")
                            .font(.subheadline)
                            .foregroundStyle(Color.vcSecondaryLabel)
                    }

                    Divider()

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.vcCP)
                        Text("ボーナス +\(c.bonusCP) CP")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.vcCP)
                    }

                    Button(action: dismiss) {
                        Text("OK")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(c.axis.color, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
                .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.35), radius: 20)
                .padding(.horizontal, 44)
                .scaleEffect(appeared ? 1.0 : 0.75)
                .opacity(appeared ? 1.0 : 0.0)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: challenge != nil)
        .onChange(of: challenge != nil) { _, isShowing in
            if isShowing {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.05)) {
                    appeared = true
                }
                HapticEngine.success()
            } else {
                appeared = false
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            challenge = nil
        }
    }
}

extension View {
    func dailyChallengeCompletion(_ challenge: Binding<DailyChallenge?>) -> some View {
        modifier(DailyChallengeCompletionModifier(challenge: challenge))
    }
}
