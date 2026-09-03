import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let lifetimeProductID = "com.yourcompany.SocialControl.lifetime"

    @Published var hasPremium = false
    @Published var displayPrice: String?
    @Published var isBusy = false
    @Published var errorMessage: String?

    private var lifetimeProduct: Product?
    private var transactionTask: Task<Void, Never>?

    init() {
        transactionTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    deinit {
        transactionTask?.cancel()
    }

    func prepare() async {
        await refreshEntitlements()
        do {
            lifetimeProduct = try await Product.products(for: [Self.lifetimeProductID]).first
            displayPrice = lifetimeProduct?.displayPrice
        } catch {
            errorMessage = error.localizedDescription
        }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-unlockPremium") {
            hasPremium = true
        }
        #endif
    }

    func purchaseLifetime() async {
        guard let lifetimeProduct else {
            errorMessage = "StoreKit product is not configured yet."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await lifetimeProduct.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "Purchase verification failed."
                    return
                }
                await transaction.finish()
                await refreshEntitlements()

            case .pending, .userCancelled:
                break

            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.lifetimeProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }

        hasPremium = unlocked
    }
}
