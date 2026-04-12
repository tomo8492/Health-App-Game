// AdBannerView.swift
// Core/DesignSystem/
//
// バナー広告ビュー（GADBannerView の SwiftUI ラッパー）
//   - プレミアムユーザーには表示しない
//   - 健康データ入力画面（ExerciseRecord 等）には絶対に配置しない
//   - 配置場所: HomeView 最下部、CityManagementView 上部
//   - SDK 未インストール時はプレースホルダーを表示（開発時のレイアウト確認用）

import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - AdBannerView（外部公開コンポーネント）

/// バナー広告コンテナ。isPremium が true なら高さ 0 で非表示。
struct AdBannerView: View {

    @Environment(AppState.self) private var appState

    /// バナーの標準高さ（GADAdSizeBanner = 320×50 pt）
    private let bannerHeight: CGFloat = 50

    var body: some View {
        if appState.isPremium {
            EmptyView()
        } else {
            BannerAdContainer()
                .frame(maxWidth: .infinity)
                .frame(height: bannerHeight)
                .background(Color.vcBackground)
        }
    }
}

// MARK: - BannerAdContainer（内部実装）

private struct BannerAdContainer: View {
    var body: some View {
        #if canImport(GoogleMobileAds)
        GADBannerRepresentable()
        #else
        // SDK 未インストール時のプレースホルダー
        ZStack {
            Color.black.opacity(0.06)
            Text("AD")
                .font(.caption2)
                .foregroundStyle(Color.vcSecondaryLabel)
        }
        #endif
    }
}

// MARK: - GADBannerRepresentable（UIViewRepresentable）

#if canImport(GoogleMobileAds)
private struct GADBannerRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> GADBannerView {
        let banner                 = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID            = AdConfig.bannerAdUnitID
        banner.rootViewController  = context.coordinator.rootViewController()
        banner.delegate            = context.coordinator

        // HealthKit データは渡さない（App Store ガイドライン 5.1.3 準拠）
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: Coordinator

    final class Coordinator: NSObject, GADBannerViewDelegate {

        func rootViewController() -> UIViewController? {
            UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow }?
                .rootViewController
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {}

        func bannerView(_ bannerView: GADBannerView,
                        didFailToReceiveAdWithError error: Error) {
            // 広告取得失敗時はビューを非表示にする（バナーが消えるだけ）
            bannerView.isHidden = true
        }
    }
}
#endif
