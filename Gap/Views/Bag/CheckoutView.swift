import SwiftUI

/// Figma: S09 Checkout (wireframe 5:373). Pickup-first: the golden path collects the fall outfit
/// at Gap Sainte-Catherine, pays with the saved Gap card and lands on S11 Order confirmation.
struct CheckoutView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.checkout

    @Environment(AppState.self) private var appState
    @Environment(CartStore.self) private var cart
    @Environment(EncoreAccount.self) private var account
    @Environment(StoreLocator.self) private var stores
    @Environment(TabRouter.self) private var router

    enum Delivery: String, CaseIterable, Identifiable {
        case pickup = "Pick up in store"
        case ship = "Ship to me"
        var id: String { rawValue }
    }

    @State private var isPlacing = false

    private var delivery: Delivery { cart.prefersPickup ? .pickup : .ship }
    /// Only a store of a brand present in the bag can fulfil a pickup order.
    private var pickupStore: Store? {
        let eligible = stores.stores(for: Set(cart.lines.map(\.product.brandInfo)))
        if let preferred = stores.preferredStore, eligible.contains(preferred) { return preferred }
        return eligible.first { $0.brandInfo == appState.selectedBrand } ?? eligible.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                deliverySection
                if delivery == .ship { addressSection } else { pickupSection }
                paymentSection
                itemsSection
                OrderSummaryView(summary: cart.summary)
                encoreLine
                TabBarSpacer()
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .disabled(isPlacing)
        .navigationBarBackButtonHidden(isPlacing)
        .background(Theme.Colors.surface.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                PrimaryButton(title: isPlacing ? "Placing order…" : "Place Order · \(PriceFormatter.string(cart.total))",
                              isEnabled: !isPlacing && !cart.isEmpty, action: placeOrder)
                    .accessibilityIdentifier("checkout-place-order")
                Text("By placing your order you agree to Gap's Terms & Privacy Policy.")
                    .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.screenMargin)
            .background(Theme.Colors.surface.shadow(color: Theme.Colors.shadow, radius: 10, y: -4))
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appState.detailDepth += 1; appState.detailScrolled = true }
        .onDisappear {
            appState.detailDepth = max(0, appState.detailDepth - 1)
            if appState.detailDepth == 0 { appState.detailScrolled = false }
        }
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("checkout")
    }

    private var deliverySection: some View {
        section("Delivery") {
            HStack(spacing: 8) {
                ForEach(Delivery.allCases) { option in
                    Chip(title: option.rawValue, selected: delivery == option, minWidth: 0) { cart.prefersPickup = option == .pickup }
                        .accessibilityIdentifier("checkout-delivery-\(option == .ship ? "ship" : "pickup")")
                }
            }
        }
    }

    private var addressSection: some View {
        section("Shipping address") {
            card {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.fullName).font(Theme.Typography.bodyStrong)
                    Text(account.shippingAddress).font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                    Text(cart.summary.shipping == 0 ? "Standard shipping · Free · Arrives in 3–5 days" : "Standard shipping · \(PriceFormatter.string(cart.summary.shipping)) · Arrives in 3–5 days")
                        .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.success).padding(.top, 4)
                }
            }
        }
    }

    /// Figma component: Store row (15:241) in its selected state, plus a "Change store" link to S10.
    private var pickupSection: some View {
        section("Pickup store") {
            card {
                if let store = pickupStore {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.Colors.success)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.name).font(Theme.Typography.bodyStrong)
                                .accessibilityIdentifier("checkout-pickup-store")
                            Text("\(store.address), \(store.city)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                            Text("\(store.distanceLabel) · \(store.hours)").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                            Text("In stock · Ready today by 6 pm · Free").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.success).padding(.top, 4)
                        }
                    }
                }
                Button("Change store") { router.push(.storeLocator, on: appState.selectedTab) }
                    .font(Theme.Typography.small).foregroundStyle(Theme.Colors.navy)
                    .accessibilityIdentifier("checkout-change-store")
            }
        }
    }

    private var paymentSection: some View {
        section("Payment") {
            card {
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill").font(.system(size: 20)).foregroundStyle(Theme.Colors.navy)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.paymentLabel).font(Theme.Typography.bodyStrong)
                        Text("Earn 5 points per $1 with your Gap card").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.Colors.success)
                }
            }
        }
    }

    private var itemsSection: some View {
        section("Items (\(cart.itemCount))") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(cart.lines) { line in
                        ProductImage(product: line.product, color: line.color)
                            .frame(width: 72, height: 96)
                            .clipped()
                            .overlay(alignment: .bottomTrailing) {
                                if line.quantity > 1 {
                                    Text("×\(line.quantity)").font(Theme.Typography.badge).padding(4)
                                        .background(Theme.Colors.ink, in: Capsule()).foregroundStyle(Theme.Colors.onInk).padding(4)
                                }
                            }
                    }
                }
            }
        }
    }

    private var encoreLine: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(Theme.Colors.encoreGold)
            Text("You'll earn **\(cart.summary.pointsEarned) Encore points** with this order.")
                .font(Theme.Typography.small)
            Spacer()
        }
        .padding(12)
        .background(Theme.Colors.canvas)
        .accessibilityIdentifier("checkout-points")
    }

    private func placeOrder() {
        isPlacing = true
        let fulfillment: Fulfillment
        if delivery == .pickup, let store = pickupStore {
            fulfillment = .pickup(store: store)
        } else {
            fulfillment = .ship(address: account.shippingAddress)
        }
        let reviewedTotal = cart.total
        Task {
            try? await Task.sleep(for: .milliseconds(ProcessInfo.processInfo.arguments.contains("-uiTesting") ? 50 : 700))
            guard cart.total == reviewedTotal,
                  let order = cart.checkout(shippingName: account.fullName, fulfillment: fulfillment) else {
                isPlacing = false
                return
            }
            account.earn(order.summary.pointsEarned)
            router.push(.confirmation(order), on: appState.selectedTab)
            isPlacing = false
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
            content()
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Rectangle().stroke(Theme.Colors.hairline))
    }
}

/// Figma: S11 Order confirmation (wireframe 5:444). Success mark, order number, pickup details,
/// Encore points earned (Encore card 15:259) and the itemised summary.
struct OrderConfirmationView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.confirmation

    let order: Order
    @Environment(AppState.self) private var appState
    @Environment(EncoreAccount.self) private var account
    @Environment(TabRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(Theme.Colors.success)
                    Text("Thanks, \(order.shippingName.split(separator: " ").first.map(String.init) ?? order.shippingName)!")
                        .font(Theme.Typography.display)
                    Text("Order #\(order.number)").font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textSecondary)
                        .accessibilityIdentifier("confirmation-number")
                    Text("A confirmation email is on its way to \(account.email).")
                        .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("encore").font(Theme.Typography.encoreWordmark).foregroundStyle(Theme.Colors.encoreGold)
                        Text("+\(order.summary.pointsEarned) points earned")
                            .font(Theme.Typography.bodyStrong)
                        Text("You now have \(account.pointsLabel) · \(account.pointsToNextReward) to next reward")
                            .font(Theme.Typography.caption).foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Text(EncoreAccount.formatPoints(account.points)).font(Theme.Typography.screenTitle)
                }
                .padding(14)
                .background(LinearGradient(colors: [Theme.Colors.encoreDark, Theme.Colors.navy], startPoint: .leading, endPoint: .trailing))
                .foregroundStyle(.white)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("confirmation-points")

                VStack(alignment: .leading, spacing: 10) {
                    Text(order.fulfillment.isPickup ? "Pickup" : "Shipping to").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                    if let store = order.fulfillment.store {
                        Text(store.name).font(Theme.Typography.bodyStrong)
                            .accessibilityIdentifier("confirmation-store")
                        Text("\(store.address), \(store.city)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                        if let ready = order.pickupReadyLabel {
                            Label(ready, systemImage: "clock").font(Theme.Typography.small).foregroundStyle(Theme.Colors.success)
                        }
                        Text("Bring a photo ID and your order number. We'll hold it for 7 days.")
                            .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textTertiary)
                    } else {
                        Text(order.fulfillment.label).font(Theme.Typography.body)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(order.lines) { line in
                        OrderLineRow(line: line)
                        Hairline()
                    }
                }
                OrderSummaryView(summary: order.summary)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("confirmation-summary")

                VStack(spacing: 10) {
                    PrimaryButton(title: "Continue Shopping") {
                        router.popToRoot(.bag)
                        appState.selectedTab = .home
                    }
                    .accessibilityIdentifier("confirmation-continue")
                    OutlineButton(title: "View Purchase History") {
                        router.popToRoot(.bag)
                        appState.selectedTab = .account
                        router.push(.purchaseHistory, on: .account)
                    }
                    .accessibilityIdentifier("confirmation-history")
                }
                TabBarSpacer()
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("Order Confirmed")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("confirmation")
    }
}

struct OrderLineRow: View {
    let line: CartLine

    var body: some View {
        HStack(spacing: 12) {
            ProductImage(product: line.product, color: line.color)
                .frame(width: 60, height: 80)
                .clipped()
            VStack(alignment: .leading, spacing: 3) {
                Text(line.product.name).font(Theme.Typography.bodyStrong).lineLimit(2)
                Text([line.color.name, line.size.map { "Size \($0)" }, "Qty \(line.quantity)"].compactMap { $0 }.joined(separator: " · "))
                    .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            Text(PriceFormatter.string(line.lineTotal)).font(Theme.Typography.bodyStrong)
        }
        .padding(.vertical, 10)
    }
}
