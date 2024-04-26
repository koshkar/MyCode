import StoreKit
import SwiftUI

class PurchaseManager {
    private let productIds = ["beginner_01", "Pro_01", "Influencer_01"]

    private(set) var products: [Product] = []
    private(set) var purchasedProduct: SubscriptionStatus = .none
    private var productsLoaded: Bool = false

    @Atomic
    var subscriptionStatus: SubscriptionStatus = .none {
        didSet {
            streamContinuation?.yield(subscriptionStatus)
        }
    }

    private var streamContinuation: AsyncStream<SubscriptionStatus>.Continuation?

    var subscriptionStatusStream: AsyncStream<SubscriptionStatus> {
        AsyncStream { continuation in
            streamContinuation = continuation
        }
    }

    func loadAllProducts() async throws {
        guard !productsLoaded else { return }
        products = try await Product.products(for: productIds)
        productsLoaded = true
    }

    func purchaseProduct(_ id: Int) async throws {
        let product = products[id]
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            try await updatePurchasedProducts()
        case .userCancelled:
            break
        case .pending:
            break
        case .success(.unverified(_, _)):
            break
        @unknown default:
            break
        }
    }

    func updatePurchasedProducts() async throws {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                let productId = transaction.productID
                guard let subscriptionType = Subscription.ID(rawValue: productId) else {
                    throw SubscriptionError.invalidProductID(id: productId)
                }
                purchasedProduct = .active(Subscription(
                    id: subscriptionType, purchaseDate: transaction.purchaseDate
                ))
            } else {
                purchasedProduct = .none
            }
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            do {
                for await _ in Transaction.updates {
                    try await self.updatePurchasedProducts()
                }
            } catch {
                // Future analytic
            }
        }
    }
}

private extension PurchaseManager {
    enum SubscriptionError: Error {
        case invalidProductID(id: String)
    }
}

enum SubscriptionStatus {
    case none
    case active(Subscription)
    case expired(Subscription)
    case unverified
    case pending(Subscription.ID)
    case abolition(Subscription)
}

struct Subscription {
    let id: ID
    let purchaseDate: Date

    enum ID: String {
        case beginner = "beginner_01"
        case pro = "Pro_01"
        case influencer = "Influencer_01"
    }
}

