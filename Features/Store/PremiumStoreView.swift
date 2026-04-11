// PremiumStoreView.swift
// Features/Store/
//
// プレミアム購入画面
// CLAUDE.md Key Rule 3: StoreKit2 のみ。RevenueCat 不使用。

import SwiftUI
import StoreKit

// MARK: - PremiumStoreView

struct PremiumStoreView: View {

    @State private var purchaseService = PurchaseService()
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    heroSection
                    featuresSection
                    purchaseSection
                    restoreButton
                    legalNote
                }
                .padding(.vertical)
            }
            .navigationTitle("VITA CITY プレミアム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .onChange(of: purchaseService.isPremiumUnlocked) { _, unlocked in
            if unlocked {
                appState.isPremium = true
                dismiss()
            }
        }
    }

    // MARK: - ヒーローセクション

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.vcCP, .vcCPGlow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.vcCP.opacity(0.4), radius: 12, y: 6)

            Text("VITA CITY プレミアム")
                .font(.title2.bold())

            Text("買い切り・永久ライセンス")
                .font(.subheadline)
                .foregroundStyle(Color.vcSecondaryLabel)

            if !purchaseService.priceString.isEmpty && purchaseService.priceString != "..." {
                Text(purchaseService.priceString)
                    .font(.title.bold())
                    .foregroundStyle(Color.vcCP)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 機能一覧

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(premiumFeatures, id: \.title) { feature in
                PremiumFeatureRow(feature: feature)
                if feature.title != premiumFeatures.last?.title {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - 購入ボタン

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchaseService.purchase() }
            } label: {
                HStack(spacing: 10) {
                    if purchaseService.state == .purchasing || purchaseService.state == .loading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "crown.fill")
                    }
                    Text(purchaseButtonLabel)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.vcCP, .vcCPGlow],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .foregroundStyle(.black)
            }
            .disabled(purchaseService.state == .purchasing || purchaseService.state == .loading)

            if case .failed(let msg) = purchaseService.state {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }

    private var purchaseButtonLabel: String {
        switch purchaseService.state {
        case .loading:    return "読み込み中..."
        case .purchasing: return "処理中..."
        case .success:    return "解放済み"
        default:          return "プレミアムを購入"
        }
    }

    // MARK: - 購入復元

    private var restoreButton: some View {
        Button("以前の購入を復元") {
            Task { await purchaseService.restorePurchases() }
        }
        .font(.subheadline)
        .foregroundStyle(Color.vcSecondaryLabel)
    }

    // MARK: - 注意事項

    private var legalNote: some View {
        Text("""
            VITA CITY プレミアムは買い切りの非消耗型アイテムです。\
            ファミリー共有に対応しています。\
            購入は Apple ID に紐づき、同じ Apple ID を使う全デバイスで有効です。
            """)
            .font(.caption2)
            .foregroundStyle(Color.vcSecondaryLabel)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
}

// MARK: - Premium Features

private struct PremiumFeature {
    let icon:        String
    let color:       Color
    let title:       String
    let description: String
}

private let premiumFeatures: [PremiumFeature] = [
    .init(icon: "nosign",            color: .vcLifestyle, title: "広告非表示",
          description: "すべての広告を完全に除去。純粋なゲーム体験へ"),
    .init(icon: "map.fill",         color: .vcExercise,  title: "マップ無制限拡張",
          description: "最大 50×50 の巨大マップを解放"),
    .init(icon: "chart.line.uptrend.xyaxis", color: .vcSleep, title: "全期間統計",
          description: "90日以上の記録を無制限に閲覧"),
    .init(icon: "rectangle.stack.fill", color: .vcDiet,   title: "ウィジェット全サイズ",
          description: "中・大サイズのウィジェットを解放"),
    .init(icon: "waveform.path.ecg", color: .vcAlcohol,   title: "詳細ヘルスレポート",
          description: "週次・月次の健康トレンドを分析"),
    .init(icon: "cloud.fill",        color: .vcSleep,     title: "データ無制限保存",
          description: "記録データが永久に保持される"),
    .init(icon: "paintpalette.fill", color: .vcCP,        title: "プレミアムテーマ",
          description: "街のビジュアルテーマを変更可能"),
]

private struct PremiumFeatureRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: feature.icon)
                    .font(.subheadline)
                    .foregroundStyle(feature.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(Color.vcSecondaryLabel)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vcCP)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
