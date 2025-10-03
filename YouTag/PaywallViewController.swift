//
//  PaywallViewController.swift
//  YouTag
//
//  Created by Youstanzr on 2025-09-19.
//  Copyright © 2025 Youstanzr. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices

final class PaywallViewController: UIViewController {
    // MARK: – UI
    private let container = UIView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Go Unlimited"
        l.font = UIFont(name: "DINCondensed-Bold", size: 36)
        l.textColor = GraphicColors.cloudWhite
        l.textAlignment = .center
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Unlock unlimited songs, tagging, and smart playlists."
        l.font = UIFont(name: "DINCondensed-Bold", size: 18)
        l.textColor = GraphicColors.medGray
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "DINCondensed-Bold", size: 16)
        l.textColor = GraphicColors.obsidianBlack
        l.textAlignment = .center
        l.numberOfLines = 1
        l.isHidden = true
        l.backgroundColor = GraphicColors.orange
        l.layer.cornerRadius = 16
        l.layer.masksToBounds = true
        l.layer.borderWidth = 0
        l.text = nil
        return l
    }()
    private let stack = UIStackView()
    private let restoreButton = UIButton(type: .system)
    private let manageButton = UIButton(type: .system)
    private let bottomBar = UIStackView()
    private let linksStack = UIStackView()
    private let privacyButton = UIButton(type: .system)
    private let termsButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .large)
    private var planButtons: [UIButton] = []
    private var planProducts: [Product] = []
    private var isPurchasing = false
    private var renderVersion = 0

    private var entitlementUpdatesTask: Task<Void, Never>? = nil

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        layoutUI()
        configure()
        Task { @MainActor in
            activity.startAnimating()
            if SubscriptionManager.shared.isPremium {
                self.updatePremiumUI()
            }
            if SubscriptionManager.shared.products.isEmpty {
                await SubscriptionManager.shared.loadProducts()
            }
            reloadPlans()
            activity.stopAnimating()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { @MainActor in
            await self.refreshEntitlementAndUI()
            self.startObservingEntitlementChanges()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingEntitlementChanges()
    }

    // MARK: – UI setup
    private func setupUI() {
        view.backgroundColor = GraphicColors.obsidianBlack

        // full-screen container
        view.addSubview(container)
        container.backgroundColor = GraphicColors.obsidianBlack
        container.layer.cornerRadius = 0
        container.layer.masksToBounds = true
        container.layer.borderWidth = 0

        // Title & subtitle styling
        titleLabel.text = "Go Unlimited"
        titleLabel.font = UIFont(name: "DINCondensed-Bold", size: 44)
        titleLabel.textColor = GraphicColors.cloudWhite
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Unlimited songs — Remove the 25‑track cap"
        subtitleLabel.font = UIFont(name: "DINCondensed-Bold", size: 20)
        subtitleLabel.textColor = GraphicColors.medGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // status badge default style
        statusLabel.isHidden = true
        statusLabel.contentInset(top: 6, left: 12, bottom: 6, right: 12)

        // Close button (top-left)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = GraphicColors.medGray
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Plans stack
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill

        // Restore / close buttons styling
        restoreButton.setTitle("Restore Purchases", for: .normal)
        restoreButton.tintColor = GraphicColors.orange
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)

        closeButton.setTitle(nil, for: .normal)

        // Manage Subscription
        manageButton.setTitle("Manage Subscription", for: .normal)
        manageButton.tintColor = GraphicColors.medGray
        manageButton.addTarget(self, action: #selector(manageTapped), for: .touchUpInside)

        // Bottom bar stack (Restore + Manage)
        bottomBar.axis = .horizontal
        bottomBar.distribution = .fillEqually
        bottomBar.spacing = 16

        // Links stack (Privacy Policy + Terms of Use)
        linksStack.axis = .horizontal
        linksStack.distribution = .fillEqually
        linksStack.spacing = 16

        // Privacy Policy
        privacyButton.setTitle("Privacy Policy", for: .normal)
        privacyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        privacyButton.tintColor = GraphicColors.medGray
        privacyButton.addTarget(self, action: #selector(openPrivacy), for: .touchUpInside)

        // Terms of Use (EULA)
        termsButton.setTitle("Terms of Use", for: .normal)
        termsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        termsButton.tintColor = GraphicColors.medGray
        termsButton.addTarget(self, action: #selector(openTerms), for: .touchUpInside)

        // Activity indicator (hidden by default)
        activity.hidesWhenStopped = true
    }

    private func layoutUI() {
        container.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        manageButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        activity.translatesAutoresizingMaskIntoConstraints = false
        linksStack.translatesAutoresizingMaskIntoConstraints = false
        privacyButton.translatesAutoresizingMaskIntoConstraints = false
        termsButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(container)
        container.addSubview(closeButton)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(statusLabel)
        container.addSubview(activity)
        container.addSubview(stack)
        container.addSubview(bottomBar)
        container.addSubview(linksStack)
        linksStack.addArrangedSubview(privacyButton)
        linksStack.addArrangedSubview(termsButton)
        
        // Bottom bar contains restore + manage
        bottomBar.addArrangedSubview(restoreButton)
        bottomBar.addArrangedSubview(manageButton)

        // Stack defaults
        stack.alignment = .fill
        stack.distribution = .fill

        NSLayoutConstraint.activate([
            // Full screen container
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // Title / subtitle
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Status label below subtitle
            statusLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 32),

            // Plans stack between status label and bottom bar
            stack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomBar.topAnchor, constant: -16),

            // Bottom bar above the links
            bottomBar.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: linksStack.topAnchor, constant: -8),
            bottomBar.heightAnchor.constraint(equalToConstant: 44),

            // Links stack pinned to the safe area bottom
            linksStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            linksStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            linksStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            linksStack.heightAnchor.constraint(equalToConstant: 24),
            
            // Activity centered in container
            activity.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        updateStackAxisForTraits()
    }

    private func updateStackAxisForTraits() {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        stack.axis = isLandscape ? .horizontal : .vertical
        stack.spacing = isLandscape ? 16 : 12
        // In landscape, spread buttons equally horizontally; in portrait, allow natural vertical sizing
        stack.distribution = isLandscape ? .fillEqually : .fill
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateStackAxisForTraits()
    }

    private func configure() {}

    // MARK: – Build plan buttons
    private func titles(for product: Product) -> (title: String, subtitle: String) {
        let plan  = SubscriptionManager.shared.plan(for: product)
        let price = product.displayPrice
        let sm    = SubscriptionManager.shared

        // Show "Restart" only when canceled but the current period is still active
        if sm.isCanceledButStillActive {
            switch plan {
            case .monthly: return ("Restart Monthly", price)
            case .yearly:  return ("Restart Yearly",  price + "  •  Best value")
            case .unknown: return ("Upgrade to Lifetime", price)
            }
        }

        // Normal path
        switch sm.entitlementKind {
        case .none:
            switch plan {
            case .monthly: return ("Start Monthly", price)
            case .yearly:  return ("Start Yearly",  price + "  •  Best value")
            case .unknown: return ("Unlock Lifetime", price)
            }
        case .subscription(let p):
            switch plan {
            case .monthly where p != .monthly: return ("Switch to Monthly", price)
            case .yearly  where p != .yearly:  return ("Switch to Yearly",  price + "  •  Best value")
            case .unknown:                     return ("Upgrade to Lifetime", price)
            default:                           return (product.displayName, price)
            }
        case .lifetime:
            return (product.displayName, price)
        }
    }
    
    private func reloadPlans() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        planButtons.removeAll()
        planProducts.removeAll()

        let all = SubscriptionManager.shared.products
        // Desired order by plan: monthly, yearly, then non-subscription (e.g., lifetime)
        func orderIndex(for p: Product) -> Int {
            switch SubscriptionManager.shared.plan(for: p) {
            case .monthly: return 0
            case .yearly:  return 1
            case .unknown: return 2
            }
        }
        let sorted = all.sorted { lhs, rhs in orderIndex(for: lhs) < orderIndex(for: rhs) }
        planProducts = sorted

        guard !sorted.isEmpty else {
            let lbl = UILabel()
            lbl.text = "Products unavailable. Please try again later."
            lbl.textColor = GraphicColors.medGray
            lbl.font = UIFont(name: "DINCondensed-Bold", size: 18)
            lbl.textAlignment = .center
            lbl.numberOfLines = 0
            stack.addArrangedSubview(lbl)
            activity.stopAnimating()
            return
        }

        for p in sorted {
            let b = makePlanButton(for: p)
            // Overwrite button title/subtitle to be explicit (Start / Switch / Upgrade)
            if var cfg = b.configuration {
                let t = titles(for: p)
                cfg.title = t.title
                cfg.subtitle = t.subtitle
                b.configuration = cfg
            }
            planButtons.append(b)
            stack.addArrangedSubview(b)
        }
        applyEligibilityStyling()
        activity.stopAnimating()
    }
    
    private func applyEligibilityStyling() {
        guard planButtons.count == planProducts.count else { return }
        let sm = SubscriptionManager.shared
        let isCanceled = { if case .canceled = sm.pendingChange { return true } else { return false } }()

        for (product, button) in zip(planProducts, planButtons) {
            button.isEnabled = true
            button.alpha = 1.0

            // If canceled: leave all enabled, no "Current plan" subtitle
            if !isCanceled {
                switch sm.canPurchase(product) {
                case .alreadyLifetime:
                    button.isEnabled = false
                    button.alpha = 0.5
                case .hasActiveSubscription, .allowed:
                    break
                }

                if sm.isCurrentPlan(product) {
                    button.isEnabled = false
                    button.alpha = 0.5
                    if var cfg = button.configuration {
                        cfg.subtitle = "Current plan"
                        button.configuration = cfg
                    }
                }
            }

            // Keep the "Switch scheduled" decoration if applicable
            if case .switching(let to, _) = sm.pendingChange,
               sm.plan(for: product) == to,
               var cfg = button.configuration {
                cfg.subtitle = "Switch scheduled"
                button.configuration = cfg
            }
        }
    }
    
    private func makePlanButton(for product: Product) -> UIButton {
        let b = UIButton(type: .system)
        var cfg = UIButton.Configuration.filled()

        // Visual hierarchy by plan
        switch SubscriptionManager.shared.plan(for: product) {
        case .yearly:
            cfg.baseBackgroundColor = GraphicColors.orange
            cfg.baseForegroundColor = GraphicColors.obsidianBlack
            cfg.image = UIImage(systemName: "crown.fill")
        case .monthly:
            cfg.baseBackgroundColor = .clear
            cfg.baseForegroundColor = GraphicColors.cloudWhite
            cfg.background.strokeColor = GraphicColors.darkGray
            cfg.image = UIImage(systemName: "calendar")
        case .unknown: // non-subscription (e.g., Lifetime)
            cfg.baseBackgroundColor = .clear
            cfg.baseForegroundColor = GraphicColors.cloudWhite
            cfg.background.strokeColor = GraphicColors.darkGray
            cfg.background.strokeWidth = 1
            cfg.image = UIImage(systemName: "infinity")
        }

        cfg.imagePlacement = .leading
        cfg.imagePadding = 10
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        cfg.cornerStyle = .large

        // Title/subtitle will be set by `reloadPlans()` via `titles(for:)`
        cfg.title = ""
        cfg.subtitle = ""

        b.configuration = cfg
        // Prefer a comfortable height, but allow shrinking on compact heights
        let h = b.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        h.priority = .defaultHigh
        h.isActive = true
        b.layer.cornerRadius = 12
        b.layer.masksToBounds = true
        // Let the button compress vertically if needed to satisfy the overall layout when rotating
        b.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        b.setContentHuggingPriority(.defaultLow, for: .vertical)

        b.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            // Check purchase eligibility before proceeding
            let eligibility = SubscriptionManager.shared.canPurchase(product)
            switch eligibility {
            case .allowed:
                break
            case .alreadyLifetime:
                self.notify(.warning)
                self.showErrorAlert(title: "Already Lifetime", message: "You already own the Lifetime unlock. No additional purchase is needed.")
                return
            case .hasActiveSubscription:
                // Keep the button enabled, but instruct the user to manage/cancel first.
                self.promptManageForLifetimeUpgrade()
                return
            }
            self.impact(.medium)
            self.setPurchasing(true)
            Task { @MainActor in
                await SubscriptionManager.shared.purchase(product)
                await self.refreshEntitlementAndUI()
                self.setPurchasing(false)
                if !SubscriptionManager.shared.isPremium {
                    self.notify(.error)
                    self.showErrorAlert(title: "Purchase not completed", message: "The transaction was cancelled or failed. Please try again.")
                } else {
                    self.notify(.success)
                }
            }
        }, for: .touchUpInside)
        return b
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    private func setPurchasing(_ purchasing: Bool) {
        isPurchasing = purchasing
        if purchasing {
            activity.startAnimating()
            (planButtons + [restoreButton, manageButton, closeButton]).forEach { $0.isEnabled = false }
            planButtons.forEach { $0.alpha = 0.6 }
        } else {
            activity.stopAnimating()
            (planButtons + [restoreButton, manageButton, closeButton]).forEach { $0.isEnabled = true }
            // Re-apply eligibility-based styling (disables & dims current/blocked plans)
            applyEligibilityStyling()
        }
    }

    @objc private func restoreTapped() {
        impact(.light)
        setPurchasing(true) // show spinner + disable buttons
        Task { @MainActor in
            await SubscriptionManager.shared.restorePurchases()
            await self.refreshEntitlementAndUI()
            setPurchasing(false) // stop spinner

            if SubscriptionManager.shared.isPremium {
                notify(.success)
                showMessage(title: "Purchases Restored", message: "Unlimited is now unlocked on this device.")
            } else {
                notify(.warning)
                showMessage(title: "Nothing to Restore", message: "No previous purchases were found for this account.")
            }
        }
    }

    // MARK: – Entitlement observation and refresh
    private func refreshEntitlementAndUI() async {
        print("🔄 Refreshing entitlement + UI…")
        await SubscriptionManager.shared.refreshAllStatuses()
        let v = (renderVersion &+ 1)
        renderVersion = v
        await MainActor.run {
            guard v == self.renderVersion else { return }
            print("🎨 Rendering UI for entitlement=\(SubscriptionManager.shared.entitlementKind), " +
                  "pending=\(SubscriptionManager.shared.pendingChange)")
            self.reloadPlans()
            self.updatePremiumUI()
            self.updatePendingBadge()
        }
    }
    
    // MARK: - Badge text
    private func updatePendingBadge() {
        let sm = SubscriptionManager.shared
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none

        // If no sub or no pending – do nothing here.
        guard sm.isSubscription, sm.pendingChange != .none else { return }

        switch sm.pendingChange {
        case .switching(let to, let date):
            let plan = (to == .monthly ? "Monthly" : to == .yearly ? "Yearly" : "Subscription")
            let when = date.map { " on \(df.string(from: $0))" } ?? ""
            statusLabel.isHidden = false
            statusLabel.text = " Switch scheduled → \(plan)\(when) "
            statusLabel.backgroundColor = GraphicColors.darkGray

        case .canceled(let date):
            let when = date.map { "Ends \(df.string(from: $0))" } ?? "Ends soon"
            statusLabel.isHidden = false
            statusLabel.text = " Auto-renew off · \(when) "
            statusLabel.backgroundColor = GraphicColors.darkGray

        case .inGracePeriod(let until):
            let when = until.map { " until \(df.string(from: $0))" } ?? ""
            statusLabel.isHidden = false
            statusLabel.text = " Grace period\(when) "
            statusLabel.backgroundColor = GraphicColors.orange

        case .inBillingRetry, .none:
            return
        }
    }
    
    private func startObservingEntitlementChanges() {
        entitlementUpdatesTask?.cancel()
        entitlementUpdatesTask = Task { [weak self] in
            for await _ in Transaction.updates {
                guard let self else { return }
                await self.refreshEntitlementAndUI()
            }
        }
    }

    private func stopObservingEntitlementChanges() {
        entitlementUpdatesTask?.cancel()
        entitlementUpdatesTask = nil
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    @objc private func manageTapped() {
        impact(.light)
        guard case .subscription = SubscriptionManager.shared.entitlementKind else { return }
        Task { @MainActor in
            guard let scene = activeWindowScene() else { return }
            do {
                try await AppStore.showManageSubscriptions(in: scene)
                // When this returns, the sheet is gone; force a status refresh.
                await SubscriptionManager.shared.refreshAllStatuses()
            } catch {
                self.showErrorAlert(title: "Unavailable", message: "Manage Subscriptions couldn't be opened. Please try again later.")
            }
            await self.refreshEntitlementAndUI()
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func dismissIfPremium() async {
        await SubscriptionManager.shared.updateEntitlementStatus()
        if SubscriptionManager.shared.isPremium {
            titleLabel.text = "You're Premium"
            subtitleLabel.text = "Thank you for supporting Batta Player."
        } else {
            titleLabel.text = "Go Unlimited"
            subtitleLabel.text = "Unlimited songs — Remove the 25‑track cap"
        }
        await MainActor.run { self.updatePremiumUI() }
    }

    private func updatePremiumUI() {
        let sm = SubscriptionManager.shared

        if sm.isSubscription, sm.pendingChange != .none {
            // Pending badge will be drawn by updatePendingBadge()
            return
        }

        statusLabel.isHidden = false
        switch sm.entitlementKind {
        case .lifetime:
            statusLabel.text = " Premium Active · Lifetime "
            statusLabel.backgroundColor = GraphicColors.orange
            manageButton.isHidden = true
        case .subscription(let plan):
            let planText = (plan == .monthly) ? "Monthly" : (plan == .yearly ? "Yearly" : "Subscription")
            statusLabel.text = " Premium Active · \(planText) "
            statusLabel.backgroundColor = GraphicColors.orange
            manageButton.isHidden = false
        case .none:
            statusLabel.isHidden = true
            manageButton.isHidden = true
        }
        applyEligibilityStyling()
    }
    
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: – Presentation API
    private func promptManageForLifetimeUpgrade() {
        let alert = UIAlertController(
            title: "Lifetime Requires Cancel",
            message: "You already have an active subscription. To unlock Lifetime, please cancel your current subscription first in Manage Subscriptions.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Manage Subscription", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.impact(.light)
            Task { @MainActor in
                guard let scene = self.activeWindowScene() else { return }
                do {
                    try await AppStore.showManageSubscriptions(in: scene)
                } catch {
                    self.showErrorAlert(title: "Unavailable", message: "Manage Subscriptions couldn't be opened. Please try again later.")
                }
            }
        }))
        present(alert, animated: true)
    }
    
    @objc private func openPrivacy() {
        guard let url = URL(string: "https://youstanzr.github.io/YouTag/privacy") else { return }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }

    @objc private func openTerms() {
        guard let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else { return }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
}

// Helper for UILabel padding
fileprivate extension UILabel {
    func contentInset(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        // Simulate padding by embedding insets in an attributed string
        guard let txt = self.text, !txt.isEmpty else { return }
        let inset = NSAttributedString(string: " ", attributes: [.font: self.font as Any])
        let composed = NSMutableAttributedString()
        composed.append(inset)
        composed.append(NSAttributedString(string: txt))
        composed.append(inset)
        self.attributedText = composed
    }
}
