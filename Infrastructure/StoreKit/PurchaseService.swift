// PurchaseService.swift
// Infrastructure/StoreKit/
//
// CLAUDE.md Key Rule 3: StoreKit2 のみ使用（RevenueCat 不使用）
// - オンデバイス検証のみ（Transaction.currentEntitlements）
// - プロダクト ID: com.vitacity.premium.lifetime（非消耗型）
// - ファミリー共有: 有効（StoreKit2 デフォルト）

import Foundation
import StoreKit

// MARK: - PurchaseService

@Observable
@MainActor
final class PurchaseService {

    // MARK: - State

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case success
        case failed(String)
        case cancelled
    }

    var state: PurchaseState = .idle
    var product: Product? = nil
    var isPremiumUnlocked: Bool = false

    // プロダクト ID（CLAUDE.md Key Rule 3）
    static let premiumProductID = "com.vitacity.premium.lifetime"

    // MARK: - Init

    init() {
        Task { await loadProduct() }
        Task { await listenForTransactionUpdates() }
    }

    // MARK: - 製品フェッチ

    func loadProduct() async {
        state = .loading
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
            // 既存の購入状態を確認
            await checkCurrentEntitlements()
            state = .idle
        } catch {
            state = .failed("製品の読み込みに失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - 購入フロー

    func purchase() async {
        guard let product else {
            state = .failed("製品が見つかりません")
            return
        }
        state = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handleVerification(verification)
            case .userCancelled:
                state = .cancelled
            case .pending:
                // 保護者承認待ちなど
                state = .idle
            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed("購入処理に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - 購入復元

    func restorePurchases() async {
        state = .loading
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
            state = .idle
        } catch {
            state = .failed("購入の復元に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - トランザクション検証

    private func handleVerification(_ verification: VerificationResult<Transaction>) async {
        switch verification {
        case .verified(let transaction):
            await transaction.finish()
            isPremiumUnlocked = true
            state = .success
        case .unverified(_, let error):
            // 不正な署名 → 解放しない
            state = .failed("トランザクションの検証に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - 現在の権利確認（起動時）

    private func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                isPremiumUnlocked = true
                await transaction.finish()
                return
            }
        }
    }

    // MARK: - トランザクション更新リスナー（App 起動中は常時監視）

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.premiumProductID {
                    if transaction.revocationDate == nil {
                        isPremiumUnlocked = true
                    } else {
                        // 払い戻しなど
                        isPremiumUnlocked = false
                    }
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - 価格文字列

    var priceString: String {
        product?.displayPrice ?? "..."
    }
}
