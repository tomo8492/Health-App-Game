// CPRingView.swift
// Core/DesignSystem/
//
// Apple Watch Activity Rings インスパイアの5軸 CP 表示リング
// etaletovic/ActivityRings パターンを参考に独自実装

import SwiftUI

// MARK: - 単一リング

struct CPSingleRingView: View {
    let progress: Double    // 0.0 〜 1.0
    let color: Color
    let lineWidth: CGFloat

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            // 背景トラック
            Circle()
                .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // 進捗
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.8)]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: clampedProgress)

            // 終端のドット（完了感を演出）
            if clampedProgress > 0.02 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                    .offset(y: -(lineWidth * 0.5))
                    .rotationEffect(.degrees(-90 + clampedProgress * 360))
                    .shadow(color: color.opacity(0.5), radius: 3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: clampedProgress)
            }
        }
    }
}

// MARK: - 5軸まとめてリング（ダッシュボード用）

struct CPFiveRingsView: View {
    let record: DailyRecord?
    var size: CGFloat = 220

    private let lineWidth: CGFloat

    init(record: DailyRecord?, size: CGFloat = 220) {
        self.record = record
        self.size   = size
        self.lineWidth = size * 0.068  // 比率でラインの太さを決定
    }

    private var axes: [CPAxis] = CPAxis.allCases.reversed()  // 内側から: lifestyle→sleep→alcohol→diet→exercise

    var body: some View {
        ZStack {
            ForEach(Array(axes.enumerated()), id: \.element) { index, axis in
                let ringSize = size - CGFloat(index) * (lineWidth * 2.2)
                CPSingleRingView(
                    progress: Double(axis.cp(from: record)) / 100.0,
                    color: axis.color,
                    lineWidth: lineWidth
                )
                .frame(width: ringSize, height: ringSize)
            }

            // 中央 CP 数値
            VStack(spacing: 2) {
                Text("\(record?.totalCP ?? 0)")
                    .font(.system(size: size * 0.165, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vcCP)
                    .contentTransition(.numericText())
                Text("CP")
                    .font(.system(size: size * 0.065, weight: .semibold))
                    .foregroundStyle(Color.vcSecondaryLabel)
            }
        }
    }
}

// MARK: - 小型リング（クイック記録ボタン用）

struct CPSmallRingView: View {
    let axis: CPAxis
    let cp: Int
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            CPSingleRingView(
                progress: Double(cp) / 100.0,
                color: axis.color,
                lineWidth: size * 0.10
            )
            .frame(width: size, height: size)

            Image(systemName: cp > 0 ? "checkmark" : axis.icon)
                .font(.system(size: size * 0.28, weight: .semibold))
                .foregroundStyle(cp > 0 ? axis.color : axis.color.opacity(0.7))
        }
    }
}

// MARK: - Preview

#Preview("FiveRings") {
    @Previewable @State var mockRecord: DailyRecord? = nil

    VStack(spacing: 32) {
        CPFiveRingsView(record: mockRecord, size: 240)
        HStack(spacing: 20) {
            ForEach(CPAxis.allCases, id: \.self) { axis in
                CPSmallRingView(axis: axis, cp: Int.random(in: 0...100), size: 60)
            }
        }
    }
    .padding()
}
