//
//  SubscriptionManager.swift
//  YouTag
//
//  Created by Youstanzr on 2025-09-19.
//  Copyright © 2025 Youstanzr. All rights reserved.
//

import Foundation
import StoreKit
import Combine

struct Limits {
    static let freeCap = 25
}

extension SubscriptionManager {
    /// nil = unlimited
    var currentCap: Int? { isPremium ? nil : Limits.freeCap }

    func canImport(currentCount: Int) -> Bool {
        guard let cap = currentCap else { return true }
        return currentCount < cap
    }

    func remainingQuota(currentCount: Int) -> Int? {
        guard let cap = currentCap else { return nil }
        return max(0, cap - currentCount)
    }

    var capLabel: String {
        isPremium ? "Unlimited" : "\(Limits.freeCap)"
    }
    
    func isLocked(index: Int) -> Bool {
        guard let cap = currentCap else { return false }   // premium = unlimited
        return index >= cap
    }
    
    var isCanceledButStillActive: Bool {
        guard isSubscription else { return false }
        if case .canceled(let end) = pendingChange {
            return end.map { $0 > Date() } ?? true
        }
        return false
    }
}

extension Notification.Name {
    static let subscriptionEntitlementDidChange = Notification.Name("subscriptionEntitlementDidChange")
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    private var txListener: Task<Void, Never>?

    enum EntitlementKind: Equatable {
        enum Plan: Equatable { case monthly, yearly, unknown }
        case none
        case lifetime
        case subscription(plan: Plan)
    }
    
    enum PendingChange: Equatable {
        case switching(to: EntitlementKind.Plan, effectiveAt: Date?)
        case canceled(effectiveAt: Date?)
        case inGracePeriod(until: Date?)
        case inBillingRetry
        case none
    }
    
    private enum CacheKeys {
        static let kind = "entitlement.kind.v1"
        static let expiry = "entitlement.expiry.v1"
    }
    
    private enum ProductID {
        static let monthly   = "Youstanzr.Batta.sub.monthly"
        static let yearly    = "Youstanzr.Batta.sub.yearly"
        static let lifetime  = "Youstanzr.Batta.iap.lifetime"
        static let all       = [monthly, yearly, lifetime]
        static let subs      = [monthly, yearly]
    }
    
    enum PurchaseEligibility {
        case allowed
        case alreadyLifetime
        case hasActiveSubscription
    }
    
    // MARK: - Published state
    @Published private(set) var products: [Product] = []
    @Published private(set) var entitlementKind: EntitlementKind = .none
    @Published private(set) var expirationDate: Date? = nil // only for subscriptions
    @Published private(set) var pendingChange: PendingChange = .none
    
    var isPremium: Bool { entitlementKind != .none }
    var isLifetime: Bool { if case .lifetime = entitlementKind { return true } else { return false } }
    var isSubscription: Bool { if case .subscription = entitlementKind { return true } else { return false } }
    
    var currentPlanLabel: String {
        switch entitlementKind {
        case .lifetime: return "Lifetime"
        case .subscription(let plan):
            switch plan { case .monthly: return "Monthly"; case .yearly: return "Yearly"; case .unknown: return "Subscription" }
        case .none: return "Free"
        }
    }
    
    // Map a StoreKit Product to our internal Plan without exposing raw IDs
    func plan(for product: Product) -> EntitlementKind.Plan {
        if product.id == ProductID.monthly { return .monthly }
        if product.id == ProductID.yearly  { return .yearly }
        return .unknown // non-subscription (e.g., Lifetime)
    }
    
    // Is the given product the user's currently active subscription plan?
    func isCurrentPlan(_ product: Product) -> Bool {
        guard case .subscription(let active) = entitlementKind else { return false }
        return active == plan(for: product)
    }
    
    func canPurchase(_ product: Product) -> PurchaseEligibility {
        switch entitlementKind {
        case .lifetime:
            return .alreadyLifetime
        case .subscription:
            // Block purchasing non-subscription (Lifetime) while a sub is active
            if plan(for: product) == .unknown { return .hasActiveSubscription }
            return .allowed
        case .none:
            return .allowed
        }
    }
    
    private init() {}
    
    // MARK: - Load products
    func loadProducts() async {
        do {
            products = try await Product.products(for: ProductID.all)
            await updateEntitlementStatus()
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    print("✅ Purchase verified: \(tx.productID) — finishing…")
                    await tx.finish()
                    await updateEntitlementStatus()
                    print("ℹ️ Entitlement after purchase: \(entitlementKind)\n")
                case .unverified(let tx, let error):
                    // Do NOT finish unverified. Common in StoreKit Testing when simulating billing problems.
                    print("⚠️ Purchase unverified for \(tx.productID). Error: \(String(describing: error))")
                    print("ℹ️ This often indicates a Billing Issue or a test config state. Resolve in Debug ▸ StoreKit ▸ Manage Transactions, or Clear Transaction History and retry.")
                }
                
            case .pending:
                // The user is still authorizing / SCA / parental approval, etc.
                print("⏳ Purchase pending. Waiting for completion…")
                
            case .userCancelled:
                print("🙅‍♂️ Purchase cancelled by user.")
                
            @unknown default:
                print("❓ Unknown purchase result: \(result)")
            }
            
            // Safety: if entitlement didn’t flip, log a concise summary to help debugging
            if !isPremium {
                print("🔎 Post-purchase check: entitlement is still \(entitlementKind). If you expected premium, check .storekit transactions window for Billing Retry / Unfinished.")
            }
        } catch {
            print("❌ Purchase failed: \(error)")
        }
    }
    
    // MARK: - Restore purchases
    func restorePurchases() async {
        do {
            // Triggers App Store account re-sync / authentication if needed
            try await AppStore.sync()
        } catch {
            print("⚠️ AppStore.sync() failed: \(error)")
        }
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("🔄 Restored: \(transaction.productID)")
            }
        }
        await updateEntitlementStatus()
    }
    
    // MARK: - Check entitlement
    private func isBetterSubscription(_ a: Transaction, than b: Transaction) -> Bool {
        let aExp = a.expirationDate
        let bExp = b.expirationDate
        if let aExp, let bExp, aExp != bExp { return aExp > bExp }
        if aExp != nil { return true }
        if bExp != nil { return false }
        return a.purchaseDate > b.purchaseDate
    }

    private func scanCurrentEntitlements() async -> (hasLifetime: Bool, bestSub: Transaction?) {
        print("🔎 Checking current entitlements…")
        var hasLifetime = false
        var bestSub: Transaction? = nil

        do {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let tx):
                    print("  • Entitlement tx: \(tx.productID), starts: \(tx.purchaseDate), expires: \(String(describing: tx.expirationDate))")

                    if tx.productID == ProductID.lifetime {
                        hasLifetime = true
                        // Lifetime wins outright; we can early-return to skip more work.
                        print("➡️ Chose: Lifetime (immediate override)")
                        return (true, nil)
                    }

                    if ProductID.subs.contains(tx.productID) {
                        if let cur = bestSub {
                            if isBetterSubscription(tx, than: cur) { bestSub = tx }
                        } else {
                            bestSub = tx
                        }
                    }

                case .unverified(let tx, let err):
                    print("  • UNVERIFIED entitlement tx: \(tx.productID), error: \(err)")
                }
            }
        }

        return (hasLifetime, bestSub)
    }

    private func unlockedCount(for kind: EntitlementKind, total: Int) -> Int {
        switch kind {
        case .none:
            return min(Limits.freeCap, total)
        default:
            return total // lifetime or subscription == unlimited
        }
    }

    private func updateEntitlementAndNotifyLibraryIfNeeded(newKind: EntitlementKind, newExpiry: Date?) {
        // Compare unlocked span before/after to avoid unnecessary recomputes.
        let total = LibraryManager.shared.libraryArray.count
        let oldUnlocked = unlockedCount(for: self.entitlementKind, total: total)
        let newUnlocked = unlockedCount(for: newKind, total: total)

        self.entitlementKind = newKind
        self.expirationDate  = newExpiry

        if newUnlocked != oldUnlocked {
            print("🎚️ Unlocked span changed: \(oldUnlocked) → \(newUnlocked) (total=\(total)) → bumping Library change token")
            LibraryManager.shared.notifyLibraryChanged()
        } else {
            print("🎚️ Unlocked span unchanged (\(newUnlocked)) — no library bump")
        }
        
        NotificationCenter.default.post(
            name: .subscriptionEntitlementDidChange,
            object: nil,
            userInfo: [
                "kind": self.entitlementKind,
                "expirationDate": self.expirationDate as Any
            ]
        )
        
        cacheEntitlement(kind: self.entitlementKind, expiry: self.expirationDate)
    }
    
    func updateEntitlementStatus() async {
        let (hasLifetime, bestSubTx) = await scanCurrentEntitlements()

        var finalKind: EntitlementKind = .none
        var finalExpiry: Date? = nil

        if hasLifetime {
            finalKind = .lifetime
            finalExpiry = nil
        } else if let best = bestSubTx {
            finalKind = .subscription(plan: (best.productID == ProductID.monthly) ? .monthly : .yearly)
            finalExpiry = best.expirationDate
            print("➡️ Chose subscription: \(best.productID) (starts: \(best.purchaseDate), expires: \(String(describing: best.expirationDate)))")
        } else {
            print("➡️ No active entitlements found.")
        }

        print("➡️ Final entitlementKind: \(finalKind), expiry: \(String(describing: finalExpiry))")
        updateEntitlementAndNotifyLibraryIfNeeded(newKind: finalKind, newExpiry: finalExpiry)
    }
    
    // Call this wherever you already refresh entitlements
    func refreshAllStatuses() async {
        await updateEntitlementStatus()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Read subscription / renewal info
    private func updateSubscriptionStatus() async {
        var best: PendingChange = .none
        func score(_ p: PendingChange) -> Int {
            switch p {
            case .inGracePeriod: return 3
            case .canceled:      return 2
            case .switching:     return 1
            case .inBillingRetry: return 2
            case .none:          return 0
            }
        }
        
        func take(_ candidate: PendingChange) {
            if score(candidate) > score(best) { best = candidate }
            // Grace period is the strongest; bail early to avoid later overwrites.
            if case .inGracePeriod = best { /* no-op here, we just keep best */ }
        }
        
        // Ensure we have products
        if products.isEmpty {
            do { products = try await Product.products(for: ProductID.all) } catch {
                self.pendingChange = .none
                return
            }
        }
        
        for product in products where product.type == .autoRenewable {
            guard let sub = product.subscription else { continue }
            do {
                for status in try await sub.status {
                    guard case .verified(let tx) = status.transaction else { continue }
                    let expiry = tx.expirationDate
                    
                    // 1) Grace period
                    if case .inGracePeriod = status.state {
                        take(.inGracePeriod(until: expiry))
                    }
                    
                    // 2) Cancellation / Switch
                    if case .verified(let ri) = status.renewalInfo {
                        // 1) Auto-renew off
                        if ri.willAutoRenew == false {
                            take(.canceled(effectiveAt: expiry))
                        }

                        // 2) Queued switch (next product set but not active yet)
                        if let nextID = ri.autoRenewPreference, nextID != ri.currentProductID {
                            let to: EntitlementKind.Plan =
                                (nextID == ProductID.monthly) ? .monthly :
                                (nextID == ProductID.yearly)  ? .yearly  : .unknown
                            take(.switching(to: to, effectiveAt: expiry))
                        }

                        // 3) Immediate switch (entitlement already moved this period)
                        //    status.transaction reflects the *current* entitlement.
                        if tx.productID != ri.currentProductID {
                            // UI will already show the active plan via entitlementKind;
                            // we don't show a "pending" badge in this case.
                            // No take(.) here on purpose.
                        }
                    }
                }
            } catch {
                // ignore this product’s errors; keep scanning
            }
        }
        
        self.pendingChange = best
        print("➡️ PendingChange decided: \(best)")
    }
    
    // MARK: Cache Entitlement
    private func cacheEntitlement(kind: EntitlementKind, expiry: Date?) {
        let kindString: String = {
            switch kind {
            case .none: return "none"
            case .lifetime: return "lifetime"
            case .subscription(let p):
                switch p { case .monthly: return "sub.monthly"
                           case .yearly:  return "sub.yearly"
                           case .unknown: return "sub.unknown" }
            }
        }()
        UserDefaults.standard.set(kindString, forKey: CacheKeys.kind)
        UserDefaults.standard.set(expiry?.timeIntervalSince1970, forKey: CacheKeys.expiry)
    }

    func bootstrapEntitlementFromCache() {
        let kindString = UserDefaults.standard.string(forKey: CacheKeys.kind) ?? "none"
        let ts = UserDefaults.standard.object(forKey: CacheKeys.expiry) as? TimeInterval
        let cachedExpiry = ts.map(Date.init(timeIntervalSince1970:))

        let cachedKind: EntitlementKind = {
            switch kindString {
            case "lifetime": return .lifetime
            case "sub.monthly": return .subscription(plan: .monthly)
            case "sub.yearly":  return .subscription(plan: .yearly)
            case "sub.unknown": return .subscription(plan: .unknown)
            default: return .none
            }
        }()

        updateEntitlementAndNotifyLibraryIfNeeded(newKind: cachedKind, newExpiry: cachedExpiry)
    }
    
    // MARK: StoreKit Listener
    /// Start one listener for StoreKit transaction updates.
    func startTransactionListener() {
        guard txListener == nil else { return } // avoid duplicates
        txListener = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                switch result {
                case .verified(let tx):
                    await tx.finish()
                    // hop to main actor; updateEntitlementStatus is @MainActor
                    await self?.updateEntitlementStatus()
                case .unverified(let tx, let error):
                    // Don't finish unverified
                    print("⚠️ Unverified transaction \(tx.productID): \(String(describing: error))")
                }
            }
        }
    }

    /// Stop listening (optional; e.g., on teardown/tests).
    func stopTransactionListener() {
        txListener?.cancel()
        txListener = nil
    }

}
