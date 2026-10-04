import DSNYKit
import StoreKit
import WidgetKit

/// Tracks whether Pro is unlocked (bought, or grandfathered from the free version) and mirrors it
/// to `ProStatus` so widgets and intents agree with the app.
@MainActor
@Observable
final class PurchaseManager {
    private(set) var isPro = ProStatus.isPro
    /// `true` when the first install predates Pro, so features the person already had stay free.
    private(set) var isGrandfathered = false

    private var hasPurchasedPro = false
    private var updatesTask: Task<Void, Never>?

    #if DEBUG
    /// Forces Pro on or off for testing; `nil` uses the real entitlement.
    var debugOverride: Bool? {
        didSet { apply() }
    }
    #endif

    init() {
        // Purchases made on other devices, Ask to Buy approvals, and refunds arrive here.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    /// Re-reads entitlements and the original install version. Call on launch.
    func refresh() async {
        for await result in Transaction.unfinished {
            if case .verified(let transaction) = result { await transaction.finish() }
        }

        var ownsPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == ProStatus.ProductID.pro,
               transaction.revocationDate == nil {
                ownsPro = true
            }
        }
        hasPurchasedPro = ownsPro

        if case .verified(let app)? = try? await AppTransaction.shared {
            isGrandfathered = ProStatus.isGrandfathered(originalBuild: app.originalAppVersion)
        }
        apply()
    }

    /// Handles a purchase completed in a `ProductView` or `StoreView`.
    func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
        }
        await refresh()
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    private func apply() {
        var unlocked = hasPurchasedPro || isGrandfathered
        #if DEBUG
        if let debugOverride { unlocked = debugOverride }
        #endif
        guard unlocked != isPro || unlocked != ProStatus.isPro else { return }
        isPro = unlocked
        ProStatus.set(unlocked)
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
    }
}
