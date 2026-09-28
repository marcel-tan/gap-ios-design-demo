import SwiftUI

struct ProductDetailView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.productDetail

    let product: Product
    var initialColor: ProductColor? = nil

    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(CartStore.self) private var cart
    @Environment(WishlistStore.self) private var wishlist
    @Environment(StoreLocator.self) private var stores
    @Environment(TabRouter.self) private var router

    @State private var selectedColor: ProductColor?
    @State private var selectedSize: String?
    @State private var imageIndex = 0
    @State private var sizeError = false
    @State private var detailsExpanded = true
    @State private var fabricExpanded = false
    @State private var shippingExpanded = false

    private var color: ProductColor { selectedColor ?? initialColor ?? product.primaryColor ?? product.colors[0] }
    private var hasSizes: Bool { !product.sizes.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                gallery
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock
                    colorPicker
                    if hasSizes { sizePicker }
                    ctaBlock
                    accordion
                    ProductRail(title: "You may also like", products: catalog.related(to: product)) { related in
                        router.push(.product(related, nil), on: appState.selectedTab)
                    }
                    .padding(.horizontal, -Theme.Spacing.screenMargin)
                }
                .padding(Theme.Spacing.screenMargin)
                TabBarSpacer()
            }
            .background(GeometryReader { proxy in
                Color.clear.preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("pdp")).minY)
            })
        }
        .coordinateSpace(name: "pdp")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            let scrolled = offset < -120
            if appState.detailScrolled != scrolled { appState.detailScrolled = scrolled }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .inlineNavigationBar()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(product.brandInfo.displayName.uppercased()).trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button { appState.isSearchPresented = true } label: { Image(systemName: "magnifyingglass") }
                    Button { appState.openBag() } label: {
                        Image(systemName: "bag").overlay(alignment: .topTrailing) {
                            if cart.itemCount > 0 {
                                Text("\(cart.itemCount)").font(Theme.Typography.badge).foregroundStyle(.white)
                                    .padding(3).background(Theme.Colors.navy, in: Circle()).offset(x: 8, y: -6)
                            }
                        }
                    }
                    .accessibilityIdentifier("pdp-bag")
                }
            }
        }
        .onAppear {
            appState.detailDepth += 1
            if selectedColor == nil { selectedColor = initialColor ?? product.primaryColor }
        }
        .onDisappear {
            appState.detailDepth = max(0, appState.detailDepth - 1)
            if appState.detailDepth == 0 { appState.detailScrolled = false }
        }
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("pdp-\(product.id)")
    }

    // MARK: Sections

    private var gallery: some View {
        let urls = color.imageURLs
        return VStack(spacing: 8) {
            TabView(selection: $imageIndex) {
                ForEach(Array(urls.indices), id: \.self) { index in
                    ProductImage(product: product, color: color, index: index)
                        .tag(index)
                }
                if urls.isEmpty {
                    ProductImage(product: product, color: color).tag(0)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 500)
            .overlay(alignment: .topTrailing) {
                HeartButton(product: product, size: 40).padding(Theme.Spacing.screenMargin)
            }
            .overlay(alignment: .topLeading) {
                if product.isNew && !product.isOnSale {
                    PillBadge(text: "New").padding(Theme.Spacing.screenMargin)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("pdp-gallery")
            if urls.count > 1 {
                HStack(spacing: 6) {
                    ForEach(Array(urls.indices), id: \.self) { index in
                        Capsule()
                            .fill(index == imageIndex ? Theme.Colors.ink : Theme.Colors.hairline)
                            .frame(width: index == imageIndex ? 18 : 6, height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: imageIndex)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(Theme.Typography.productName)
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("pdp-name")
            HStack(spacing: 10) {
                PriceLabel(product: product, font: Theme.Typography.bodyStrong)
                if let pct = product.percentOff {
                    PillBadge(text: "\(pct)% off", fill: Theme.Colors.sale)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("pdp-price")
            if product.reviewCount > 0 {
                HStack(spacing: 6) {
                    RatingStars(rating: product.rating)
                    Text(String(format: "%.1f", product.rating)).font(Theme.Typography.small)
                    Text("· \(product.reviewCount) reviews").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text("Color:").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                Text(color.name).font(Theme.Typography.bodyStrong).accessibilityIdentifier("pdp-color-name")
                Spacer()
                Text("\(product.colors.count) \(product.colors.count == 1 ? "color" : "colors")")
                    .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textTertiary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(product.colors) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedColor = option
                                imageIndex = 0
                            }
                        } label: {
                            ProductImage(product: product, color: option)
                                .frame(width: 56, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(option == color ? Theme.Colors.ink : Theme.Colors.hairline, lineWidth: option == color ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("pdp-color-\(option.id)")
                        .accessibilityLabel(option.name)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Size").font(Theme.Typography.bodyStrong)
                if let selectedSize {
                    Text(selectedSize).font(Theme.Typography.body).foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                Button("Size guide") {}
                    .font(Theme.Typography.small).underline().foregroundStyle(Theme.Colors.textSecondary)
            }
            FlowLayout(spacing: 8) {
                ForEach(product.sizes) { size in
                    Chip(title: size.label, selected: selectedSize == size.label, enabled: size.available) {
                        selectedSize = size.label
                        sizeError = false
                    }
                    .accessibilityIdentifier("pdp-size-\(size.label)")
                }
            }
            if sizeError {
                Text("Please select a size").font(Theme.Typography.small).foregroundStyle(Theme.Colors.sale)
                    .accessibilityIdentifier("pdp-size-error")
            }
        }
    }

    private var ctaBlock: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Add to Bag", action: addToBag)
                .accessibilityIdentifier("pdp-add-to-bag")
            PrimaryButton(title: "Buy with Apple Pay", icon: "apple.logo", fill: Theme.Colors.applePay) {
                guard validateSize() else { return }
                cart.add(product, color: color, size: selectedSize)
                appState.openBag()
            }
            .accessibilityIdentifier("pdp-apple-pay")
            HStack(spacing: 8) {
                Image(systemName: "shippingbox").foregroundStyle(Theme.Colors.success)
                Text("Free shipping on orders $50+ · Free returns in store").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
            pickupAvailability
        }
    }

    /// Figma: S06 › store availability row ("In stock at Gap Sainte-Catherine · pick up today").
    private var pickupAvailability: some View {
        let store = stores.preferredStore ?? stores.stores.first { $0.brandInfo == product.brandInfo } ?? stores.stores.first
        return Button { router.push(.storeLocator, on: appState.selectedTab) } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill").foregroundStyle(Theme.Colors.success)
                if let store {
                    Text("In stock at **\(store.name)** · pick up today")
                        .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textPrimary)
                } else {
                    Text("Check store availability").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pdp-pickup")
    }

    private var accordion: some View {
        VStack(spacing: 0) {
            Hairline()
            AccordionRow(title: "Details", expanded: $detailsExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.description).font(Theme.Typography.body).foregroundStyle(Theme.Colors.textPrimary)
                    ForEach(product.details, id: \.self) { detail in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(detail)
                        }
                        .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            Hairline()
            AccordionRow(title: "Fabric & Care", expanded: $fabricExpanded) {
                Text(product.fabric.isEmpty ? "Machine wash cold. Tumble dry low." : product.fabric)
                    .font(Theme.Typography.body).foregroundStyle(Theme.Colors.textPrimary)
            }
            Hairline()
            AccordionRow(title: "Shipping & Returns", expanded: $shippingExpanded) {
                Text("Standard shipping is $7, free on orders over $50. Returns are free within 30 days at any Gap Inc. store or by mail.")
                    .font(Theme.Typography.body).foregroundStyle(Theme.Colors.textPrimary)
            }
            Hairline()
        }
    }

    // MARK: Actions

    private func validateSize() -> Bool {
        if hasSizes && selectedSize == nil {
            withAnimation { sizeError = true }
            return false
        }
        return true
    }

    private func addToBag() {
        guard validateSize() else { return }
        cart.add(product, color: color, size: selectedSize)
        appState.addedToBag = AddedToBagItem(product: product, color: color, size: selectedSize)
    }
}

struct AccordionRow<Content: View>: View {
    let title: String
    @Binding var expanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                HStack {
                    Text(title).font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: expanded ? "minus" : "plus").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.textPrimary)
                }
                .frame(height: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if expanded {
                content().padding(.bottom, 16)
            }
        }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Bottom sheet shown after Add to Bag.
struct AddedToBagSheet: View, FigmaTraced {
    static let figmaNode = FigmaScreens.itemAdded

    let item: AddedToBagItem
    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(CartStore.self) private var cart
    @Environment(TabRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.Colors.success)
                    Text("Added to Bag").font(Theme.Typography.sectionTitle)
                    Spacer()
                    Text("\(cart.itemCount) \(cart.itemCount == 1 ? "item" : "items") in bag").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                }
                HStack(alignment: .top, spacing: 14) {
                    ProductImage(product: item.product, color: item.color)
                        .frame(width: 84, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.product.name).font(Theme.Typography.bodyStrong).lineLimit(2)
                        Text("Color: \(item.color.name)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                        if let size = item.size {
                            Text("Size: \(size)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        PriceLabel(product: item.product)
                    }
                    Spacer()
                }
                VStack(spacing: 10) {
                    PrimaryButton(title: "View Bag (\(cart.itemCount))") {
                        appState.openBag()
                    }
                    .accessibilityIdentifier("added-view-bag")
                    OutlineButton(title: "Continue Shopping") { dismiss() }
                        .accessibilityIdentifier("added-continue")
                }
                let related = catalog.related(to: item.product, limit: 8).filter { !cart.contains($0) }
                if !related.isEmpty {
                    ProductRail(title: "Complete the look", products: related) { product in
                        appState.addedToBag = nil
                        router.push(.product(product, nil), on: appState.selectedTab)
                    }
                    .padding(.horizontal, -Theme.Spacing.screenMargin)
                }
            }
            .padding(Theme.Spacing.screenMargin)
            .padding(.top, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.Colors.surface)
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("added-to-bag-sheet")
    }
}
