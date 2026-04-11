// AppIconView.swift
// Core/DesignSystem/
//
// VITA CITY アプリアイコン – SwiftUI で描画
//
// 使い方:
//   1. Xcode Preview で表示 → スクリーンショット
//   2. 1024×1024 px で書き出し → Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png に配置
//
// デザインコンセプト:
//   - 深夜の都市シルエット（ドット絵調）× 金色 CP リング
//   - 5軸カラーリング（Activity Rings インスパイア）
//   - 中央に "VC" ロゴタイプ

import SwiftUI

// MARK: - AppIcon View（1024×1024 基準）

struct AppIconView: View {

    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // ── 背景グラデーション（深夜の空）──
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.14),  // 深紺
                    Color(red: 0.08, green: 0.06, blue: 0.22),  // 藍
                    Color(red: 0.12, green: 0.04, blue: 0.18),  // 紫がかった夜
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // ── 星空（小さなドット群）──
            StarsLayer(size: size)

            // ── 5軸 Activity リング ──
            FiveAxisRingsLayer(size: size)

            // ── 都市シルエット（下部）──
            CitySilhouetteLayer(size: size)

            // ── 中央ロゴ ──
            CenterLogoLayer(size: size)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225))  // iOS アイコン角丸
    }
}

// MARK: - 星空レイヤー

private struct StarsLayer: View {
    let size: CGFloat

    // 固定シード位置（乱数を使わず再現性を確保）
    private let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
        (0.12, 0.08, 0.8), (0.35, 0.05, 0.6), (0.68, 0.10, 1.0),
        (0.82, 0.04, 0.7), (0.24, 0.15, 0.9), (0.55, 0.12, 0.5),
        (0.90, 0.18, 0.8), (0.42, 0.20, 0.6), (0.75, 0.22, 1.0),
        (0.08, 0.25, 0.7), (0.60, 0.28, 0.9), (0.88, 0.30, 0.5),
        (0.18, 0.32, 0.8), (0.48, 0.35, 0.6), (0.72, 0.38, 0.7),
    ]

    var body: some View {
        ForEach(starPositions.indices, id: \.self) { i in
            let (x, y, alpha) = starPositions[i]
            Circle()
                .fill(.white.opacity(alpha * 0.7))
                .frame(width: size * 0.006, height: size * 0.006)
                .offset(
                    x: x * size - size / 2,
                    y: y * size - size / 2
                )
        }
    }
}

// MARK: - 5軸リングレイヤー

private struct FiveAxisRingsLayer: View {
    let size: CGFloat

    private let axisColors: [Color] = [
        Color(red: 1.00, green: 0.18, blue: 0.33),  // ピンク・生活習慣（最外）
        Color(red: 0.00, green: 0.48, blue: 1.00),  // 青・睡眠
        Color(red: 0.69, green: 0.32, blue: 0.87),  // 紫・飲酒
        Color(red: 1.00, green: 0.58, blue: 0.00),  // オレンジ・食事
        Color(red: 0.20, green: 0.78, blue: 0.35),  // 緑・運動（最内）
    ]
    private let progresses: [Double] = [0.85, 0.72, 0.60, 0.90, 0.78]

    var body: some View {
        ZStack {
            ForEach(axisColors.indices, id: \.self) { i in
                let ringDiameter = size * (0.72 - CGFloat(i) * 0.095)
                let lineWidth    = size * 0.038

                ZStack {
                    // トラック（背景）
                    Circle()
                        .stroke(axisColors[i].opacity(0.18),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                    // 進捗
                    Circle()
                        .trim(from: 0, to: progresses[i])
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [axisColors[i], axisColors[i].opacity(0.7)]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    // 終端ドット
                    Circle()
                        .fill(axisColors[i])
                        .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                        .offset(y: -(ringDiameter / 2))
                        .rotationEffect(.degrees(-90 + progresses[i] * 360))
                        .shadow(color: axisColors[i].opacity(0.6), radius: size * 0.008)
                }
                .frame(width: ringDiameter, height: ringDiameter)
            }
        }
        .offset(y: -size * 0.04)
    }
}

// MARK: - 都市シルエットレイヤー

private struct CitySilhouetteLayer: View {
    let size: CGFloat

    var body: some View {
        GeometryReader { _ in
            // ドット絵風の建物シルエット（Path で描画）
            ZStack(alignment: .bottom) {
                // 遠景ビル群（暗め）
                BuildingRow(
                    size: size,
                    buildings: [
                        (0.08, 0.28, 0.06), (0.16, 0.22, 0.05),
                        (0.28, 0.32, 0.07), (0.38, 0.18, 0.04),
                        (0.52, 0.26, 0.06), (0.64, 0.30, 0.07),
                        (0.76, 0.20, 0.05), (0.88, 0.24, 0.06),
                    ],
                    color: Color(red: 0.14, green: 0.10, blue: 0.28)
                )

                // 近景ビル群（少し明るめ）
                BuildingRow(
                    size: size,
                    buildings: [
                        (0.04, 0.18, 0.07), (0.13, 0.32, 0.09),
                        (0.22, 0.24, 0.08), (0.33, 0.38, 0.10),
                        (0.44, 0.20, 0.07), (0.56, 0.34, 0.09),
                        (0.67, 0.28, 0.08), (0.78, 0.36, 0.10),
                        (0.88, 0.22, 0.07), (0.95, 0.16, 0.06),
                    ],
                    color: Color(red: 0.18, green: 0.14, blue: 0.35)
                )

                // 窓ライト（金色の小さなドット）
                WindowLightsView(size: size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: size, height: size)
    }
}

private struct BuildingRow: View {
    let size: CGFloat
    // (x比率, height比率, width比率)
    let buildings: [(CGFloat, CGFloat, CGFloat)]
    let color: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(buildings.indices, id: \.self) { i in
                let (x, h, w) = buildings[i]
                Rectangle()
                    .fill(color)
                    .frame(width: size * w, height: size * h)
                    .offset(x: (x - 0.5) * size)
            }
        }
        .frame(width: size, height: size * 0.4, alignment: .bottom)
        .offset(y: size * 0.5)
    }
}

private struct WindowLightsView: View {
    let size: CGFloat

    private let lights: [(CGFloat, CGFloat)] = [
        (0.10, 0.76), (0.14, 0.82), (0.22, 0.72), (0.26, 0.78),
        (0.35, 0.68), (0.40, 0.74), (0.44, 0.80), (0.52, 0.70),
        (0.58, 0.76), (0.64, 0.72), (0.70, 0.78), (0.76, 0.68),
        (0.82, 0.74), (0.88, 0.80), (0.93, 0.72),
    ]

    var body: some View {
        ZStack {
            ForEach(lights.indices, id: \.self) { i in
                let (x, y) = lights[i]
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.7))
                    .frame(width: size * 0.018, height: size * 0.022)
                    .offset(
                        x: x * size - size / 2,
                        y: y * size - size / 2
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 中央ロゴレイヤー

private struct CenterLogoLayer: View {
    let size: CGFloat

    var body: some View {
        VStack(spacing: size * 0.015) {
            // "VC" テキストロゴ
            Text("VC")
                .font(.system(size: size * 0.13, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.92, blue: 0.40),
                            Color(red: 1.00, green: 0.70, blue: 0.00),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.6),
                        radius: size * 0.02)

            // "VITA CITY" サブタイトル
            Text("VITA CITY")
                .font(.system(size: size * 0.036, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .tracking(size * 0.004)
        }
        .offset(y: -size * 0.04)
    }
}

// MARK: - Preview

#Preview("AppIcon 1024px") {
    AppIconView(size: 400)
        .preferredColorScheme(.dark)
}

#Preview("AppIcon Small (60px)") {
    AppIconView(size: 60)
        .preferredColorScheme(.dark)
}
