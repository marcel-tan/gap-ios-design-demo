import SwiftUI

struct BagView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.bag

    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(CartStore.self) private var cart
    @Environment(TabRouter.self) private var router
    @State private var promoText = ""
    @State private var promoError = false

    var body: some View {
        VStack(spacing: 0) {
            StoreHeader(title: cart.isEmpty ? "Bag" : "Bag (\(cart.itemCount))")
            if cart.isEmpty {
                emptyBag
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        shippingProgress
                        VStack(spacing: 0) {
                            ForEach(cart.lines) { line in
                                BagLineRow(line: line)
                                Hairline().padding(.leading, Theme.Spacing.screenMargin)
                            }
                        }
                        promoField
                        OrderSummaryView(summary: cart.summary)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                        PrimaryButton(title: "Checkout · \(PriceFormatter.string(cart.total))") {
                            router.push(.checkout, on: .bag)
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                        .accessibilityIdentifier("bag-checkout")
                        ProductRail(title: "You may also like",
                                    products: cart.lines.first.map { catalog.related(to: $0.product) } ?? []) { product in
                            router.push(.product(product, nil), on: .bag)
                        }
                        TabBarSpacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("bag")
    }

    private var emptyBag: some View {
        VStack(spacing: 0) {
            EmptyState(symbol: "bag", title: "Your bag is empty",
                       message: "Looks like you haven't added anything yet.",
                       actionTitle: "Start Shopping") {
                appState.selectedTab = .shop
            }
            let picks = catalog.rail(brand: appState.selectedBrand, limit: 8)
            ProductRail(title: "Trending now", products: picks) { product in
                router.push(.product(product, nil), on: .bag)
            }
            TabBarSpacer()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bag-empty")
    }

    private var shippingProgress: some View {
        let remaining = CheckoutSummary.freeShippingThreshold - cart.summary.discountedSubtotal
        let progress = min(1, NSDecimalNumber(decimal: cart.summary.discountedSubtotal / CheckoutSummary.freeShippingThreshold).doubleValue)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: remaining <= 0 ? "checkmark.circle.fill" : "shippingbox")
                    .foregroundStyle(Theme.Colors.success)
                Text(remaining <= 0 ? "You've unlocked free shipping" : "Add \(PriceFormatter.string(remaining)) for free shipping")
                    .font(Theme.Typography.small)
            }
            ProgressView(value: progress).tint(Theme.Colors.success)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .accessibilityIdentifier("bag-shipping-progress")
    }

    private var promoField: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let promo = cart.promo {
                HStack {
                    Image(systemName: "tag.fill").foregroundStyle(Theme.Colors.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(promo.code).font(Theme.Typography.promo)
                        Text(promo.description).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    Button("Remove") { cart.removePromo() }
                        .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                        .accessibilityIdentifier("promo-remove")
                }
                .padding(12)
                .background(Theme.Colors.canvas, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
                .accessibilityIdentifier("promo-applied")
            } else {
                HStack(spacing: 8) {
                    TextField("Promo code", text: $promoText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(Theme.Typography.body)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.button).stroke(promoError ? Theme.Colors.sale : Theme.Colors.chipBorder))
                        .accessibilityIdentifier("promo-field")
                    Button("Apply") {
                        if cart.applyPromo(promoText) {
                            promoText = ""
                            promoError = false
                        } else {
                            promoError = true
                        }
                    }
                    .font(Theme.Typography.button)
                    .foregroundStyle(Theme.Colors.onInk)
                    .frame(width: 88, height: 44)
                    .background(promoText.isEmpty ? Theme.Colors.chipBorder : Theme.Colors.ink, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                    .disabled(promoText.isEmpty)
                    .accessibilityIdentifier("promo-apply")
                }
                if promoError {
                    Text("That code isn't valid. Try YOURS for 30% off.")
                        .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.sale)
                        .accessibilityIdentifier("promo-error")
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

struct BagLineRow: View {
    let line: CartLine
    @Environment(CartStore.self) private var cart
    @Environment(WishlistStore.self) private var wishlist
    @Environment(TabRouter.self) private var router
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button { router.push(.product(line.product, line.color), on: appState.selectedTab) } label: {
                ProductImage(product: line.product, color: line.color)
                    .frame(width: 96, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(line.product.name).font(Theme.Typography.bodyStrong).lineLimit(2)
                    Spacer()
                    Text(PriceFormatter.string(line.lineTotal)).font(Theme.Typography.bodyStrong)
                        .accessibilityIdentifier("line-total-\(line.id)")
                }
                Text("Color: \(line.color.name)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                if let size = line.size {
                    Text("Size: \(size)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer(minLength: 4)
                HStack(spacing: 12) {
                    QuantityStepper(quantity: line.quantity,
                                    onDecrement: { cart.decrement(line.id) },
                                    onIncrement: { cart.increment(line.id) },
                                    identifier: line.id)
                    Spacer()
                    Button {
                        if !wishlist.contains(line.product) { wishlist.toggle(line.product) }
                        cart.remove(line.id)
                        appState.showToast("Saved to wishlist")
                    } label: { Image(systemName: "heart").font(.system(size: 15)) }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .accessibilityIdentifier("line-save-\(line.id)")
                    Button { withAnimation { cart.remove(line.id) } } label: { Image(systemName: "trash").font(.system(size: 15)) }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .accessibilityIdentifier("line-remove-\(line.id)")
                }
            }
        }
        .padding(Theme.Spacing.screenMargin)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bag-line-\(line.id)")
    }
}

struct QuantityStepper: View {
    let quantity: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    var identifier: String = ""

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: "minus").font(.system(size: 12, weight: .semibold)).frame(width: 32, height: 32)
            }
            .disabled(quantity <= CartStore.minQuantityPerLine)
            .accessibilityIdentifier("qty-minus-\(identifier)")
            Text("\(quantity)").font(Theme.Typography.bodyStrong).frame(minWidth: 24)
                .accessibilityIdentifier("qty-\(identifier)")
            Button(action: onIncrement) {
                Image(systemName: "plus").font(.system(size: 12, weight: .semibold)).frame(width: 32, height: 32)
            }
            .disabled(quantity >= CartStore.maxQuantityPerLine)
            .accessibilityIdentifier("qty-plus-\(identifier)")
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.button).stroke(Theme.Colors.chipBorder))
    }
}

/// Subtotal / discount / shipping / tax / total block shared by Bag, Checkout and Confirmation.
struct OrderSummaryView: View {
    let summary: CheckoutSummary
    var title: String? = "Order Summary"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title).font(Theme.Typography.bodyStrong)
            }
            row("Subtotal (\(summary.itemCount) \(summary.itemCount == 1 ? "item" : "items"))", PriceFormatter.string(summary.subtotal), id: "summary-subtotal")
            if summary.discount > 0, let promo = summary.promo {
                row("Promo · \(promo.code)", PriceFormatter.negative(summary.discount), id: "summary-discount", tint: Theme.Colors.success)
            }
            row("Shipping", summary.shipping == 0 ? "Free" : PriceFormatter.string(summary.shipping), id: "summary-shipping",
                tint: summary.shipping == 0 ? Theme.Colors.success : Theme.Colors.textPrimary)
            row("Estimated tax", PriceFormatter.string(summary.estimatedTax), id: "summary-tax")
            Hairline()
            HStack {
                Text("Order total").font(Theme.Typography.bodyStrong)
                Spacer()
                Text(PriceFormatter.string(summary.total)).font(Theme.Typography.sectionTitle)
                    .accessibilityIdentifier("summary-total")
            }
        }
        .padding(14)
        .background(Theme.Colors.canvas, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("order-summary")
    }

    private func row(_ label: String, _ value: String, id: String, tint: Color = Theme.Colors.textPrimary) -> some View {
        HStack {
            Text(label).font(Theme.Typography.body).foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value).font(Theme.Typography.body).foregroundStyle(tint).accessibilityIdentifier(id)
        }
    }
}
