// VCComponents.swift
// Core/DesignSystem/
//
// 共通 UI コンポーネント群

import SwiftUI

// MARK: - CP バッジ

struct CPBadgeView: View {
    let cp: Int
    var size: CPBadgeSize = .medium

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: size.fontSize * 0.85))
                .foregroundStyle(Color.vcCP)
            Text("+\(cp)CP")
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vcCP)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(Color.vcCP.opacity(0.15), in: Capsule())
    }

    enum CPBadgeSize {
        case small, medium, large
        var fontSize: CGFloat {
            switch self { case .small: 11; case .medium: 14; case .large: 18 }
        }
        var horizontalPadding: CGFloat {
            switch self { case .small: 8; case .medium: 10; case .large: 14 }
        }
        var verticalPadding: CGFloat {
            switch self { case .small: 4; case .medium: 6; case .large: 8 }
        }
    }
}

// MARK: - 軸ヘッダー

struct AxisHeaderView: View {
    let axis: CPAxis
    let cp: Int

    var body: some View {
        HStack {
            Image(systemName: axis.icon)
                .font(.title2)
                .foregroundStyle(axis.color)
            Text(axis.name)
                .font(.headline)
                .foregroundStyle(Color.vcLabel)
            Spacer()
            CPBadgeView(cp: cp, size: .medium)
        }
        .padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - カード

struct VCCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 保存ボタン

struct VCSaveButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(color, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading)
    }
}

// MARK: - ストリーク表示

struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak > 0 ? Color.orange : Color.vcSecondaryLabel)
            Text(streak > 0 ? "\(streak)日連続" : "記録なし")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(streak > 0 ? Color.vcLabel : Color.vcSecondaryLabel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(streak > 0 ? 0.12 : 0.05), in: Capsule())
    }
}

// MARK: - スライダー（ストレスレベル等）

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let labels: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(currentLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
            if !labels.isEmpty {
                HStack {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(Color.vcSecondaryLabel)
                        if label != labels.last { Spacer() }
                    }
                }
            }
        }
    }

    private var currentLabel: String {
        let idx = Int(value - range.lowerBound)
        guard idx >= 0 && idx < labels.count else { return "\(Int(value))" }
        return labels[idx]
    }
}

// MARK: - ウォータートラッカー

struct WaterCupsView: View {
    @Binding var cups: Int
    let maxCups: Int = 10
    let goal: Int = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("水分摂取")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(cups) / \(goal) 杯")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(cups >= goal ? Color.vcSleep : Color.vcSecondaryLabel)
            }
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 8) {
                ForEach(1...maxCups, id: \.self) { i in
                    Button {
                        cups = cups == i ? i - 1 : i
                    } label: {
                        Image(systemName: i <= cups ? "drop.fill" : "drop")
                            .font(.title3)
                            .foregroundStyle(i <= cups ? Color.vcSleep : Color.vcSleep.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
