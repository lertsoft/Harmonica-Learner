import Combine
import StoreKit

@MainActor
final class FullAccessStore: ObservableObject {
    // Create this non-consumable product in App Store Connect before release.
    static let productID = "com.kosukobo.Harmonica.fullunlock"

    @Published private(set) var product: Product?
    @Published private(set) var hasFullAccess = false
    @Published private(set) var hasCheckedEntitlement = false
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    init() {
        Task {
            await refreshEntitlement()
            await loadProduct()
        }
        Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await refreshEntitlement()
            }
        }
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID])
                .first(where: { $0.type == .nonConsumable })
            if product == nil {
                errorMessage = "The purchase is not available yet. Please try again later."
            } else {
                errorMessage = nil
            }
        } catch {
            errorMessage = "Could not load the purchase: \(error.localizedDescription)"
        }
    }

    func refreshEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                entitled = true
            }
        }
        hasFullAccess = entitled
        hasCheckedEntitlement = true
    }

    func purchase() async {
        guard let product else {
            await loadProduct()
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlement()
                } else {
                    errorMessage = "The purchase could not be verified. Please try restoring purchases."
                }
            case .pending:
                errorMessage = "Your purchase is pending approval. Access will unlock when Apple confirms it."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "The purchase could not be completed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !hasFullAccess {
                errorMessage = "No full-access purchase was found for this Apple Account."
            }
        } catch {
            errorMessage = "Could not restore purchases: \(error.localizedDescription)"
        }
    }
}
