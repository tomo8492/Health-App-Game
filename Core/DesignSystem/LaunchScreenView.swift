// LaunchScreenView.swift
// Core/DesignSystem/
//
// アプリ内ローンチアニメーション
// システムのローンチスクリーン（Info.plist）→ このビューへ遷移
// VitaCityApp.swift から isLaunching フラグで制御

import SwiftUI

// MARK: - LaunchScreenView

struct LaunchScreenView: View {
    @State private var ringScale:    CGFloat = 0.4
    @State private var ringOpacity:  Double  = 0.0
    @State private var logoScale:    CGFloat = 0.6
    @State private var logoOpacity:  Double  = 0.0
    @State private var glowRadius:   CGFloat = 0.0

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.14),
                    Color(red: 0.10, green: 0.06, blue: 0.22),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // ─── 5軸アイコンリング ───
                ZStack {
                    ForEach(Array(ringColors.enumerated()), id: \.offset) { i, color in
                        let diameter = 120.0 - CGFloat(i) * 16
                        Circle()
                            .trim(from: 0, to: 0.8)
                            .stroke(
                                color,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: diameter, height: diameter)
                            .rotationEffect(.degrees(-90 + Double(i) * 15))
                    }

                    // 中央 VC
                    Text("VC")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.vcCP, Color.vcCPGlow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.vcCP.opacity(0.6), radius: glowRadius)
                }
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

                // ─── アプリ名 ───
                VStack(spacing: 4) {
                    Text("VITA CITY")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(4)

                    Text("健康で街を育てよう")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
            }
        }
        .onAppear { startAnimation() }
    }

    // MARK: - Animation

    private func startAnimation() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
            ringScale   = 1.0
            ringOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.5)) {
            glowRadius = 12
        }
    }

    // MARK: - 5軸カラー（外→内）

    private let ringColors: [Color] = [
        Color(red: 1.00, green: 0.18, blue: 0.33),  // 生活習慣
        Color(red: 0.00, green: 0.48, blue: 1.00),  // 睡眠
        Color(red: 0.69, green: 0.32, blue: 0.87),  // 飲酒
        Color(red: 1.00, green: 0.58, blue: 0.00),  // 食事
        Color(red: 0.20, green: 0.78, blue: 0.35),  // 運動
    ]
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
        .preferredColorScheme(.dark)
}
