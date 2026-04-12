// AdService.swift
// Infrastructure/Ads/
//
// 広告管理サービス（Google Mobile Ads SDK v11 ラッパー）
//
// 収益モデル: 無料＋バナー広告＋買い切り広告除去（¥980）
//   - バナー広告: HomeView 下部（記録画面では非表示）
//   - リワード広告: 街管理画面でボーナス CP と交換
//   - プレミアム購入済みユーザーには広告を一切表示しない
//
// App Store ガイドライン 5.1.3:
//   HealthKit で収集したデータを広告ターゲティングに使用することは禁止。
//   コンテクスチュアル広告（健康データ非連携）のみ使用。
//
// SDK 追加手順:
//   Xcode → File → Add Package Dependencies
//   URL: https://github.com/googleads/swift-package-manager-google-mobile-ads
//   Version: 11.x.x 以上

import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - リワード種別

enum AdRewardType {
    case bonusCP(amount: Int)    // ボーナス CP（+50）
}

// MARK: - AdService

@Observable
@MainActor
final class AdService {

    // MARK: - State

    /// SDK 初期化完了フラグ
    private(set) var isReady: Bool = false

    /// リワード広告のロード完了フラグ
    private(set) var isRewardAdReady: Bool = false

    /// リワード広告の結果（nil = 未完了 / .some = 完了または却下）
    var rewardResult: AdRewardType? = nil

    #if canImport(GoogleMobileAds)
    private var rewardedAd: GADRewardedAd?
    #endif

    // MARK: - SDK 初期化（アプリ起動時に1回呼ぶ）

    func initialize() async {
        #if canImport(GoogleMobileAds)
        await GADMobileAds.sharedInstance().start()
        isReady = true
        await loadRewardAd()
        #else
        // SDK 未インストール時はモック動作
        isReady = true
        isRewardAdReady = true
        #endif
    }

    // MARK: - リワード広告のロード

    func loadRewardAd() async {
        #if canImport(GoogleMobileAds)
        let request = GADRequest()
        do {
            rewardedAd = try await GADRewardedAd.load(
                withAdUnitID: AdConfig.rewardedAdUnitID,
                request:      request
            )
            isRewardAdReady = rewardedAd != nil
        } catch {
            isRewardAdReady = false
        }
        #endif
    }

    // MARK: - リワード広告の表示

    /// リワード広告を表示し、完了後に bonusCP を AppState に反映する
    /// - Parameters:
    ///   - viewController: 広告を表示するルート ViewController
    ///   - completion: 報酬を付与すべき場合に呼ばれるクロージャ
    func showRewardAd(
        from viewController: UIViewController,
        completion: @escaping (AdRewardType) -> Void
    ) {
        #if canImport(GoogleMobileAds)
        guard let ad = rewardedAd else { return }
        isRewardAdReady = false

        ad.present(fromRootViewController: viewController) { [weak self] in
            // HealthKit データは渡さない（App Store 5.1.3 準拠）
            completion(.bonusCP(amount: AdConfig.rewardedAdCPBonus))
            Task { await self?.loadRewardAd() }
        }
        #else
        // SDK 未インストール時はモック報酬を即時付与（開発用）
        completion(.bonusCP(amount: AdConfig.rewardedAdCPBonus))
        Task { await loadRewardAd() }
        #endif
    }

    // MARK: - バナー広告の有効性

    /// プレミアム購入済みユーザーには広告を表示しない
    func shouldShowAds(isPremium: Bool) -> Bool {
        return !isPremium && isReady
    }
}
