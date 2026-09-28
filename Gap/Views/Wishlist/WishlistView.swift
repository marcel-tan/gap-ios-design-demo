import SwiftUI

struct WishlistView: View {
    var body: some View {
        CoverStack {
            WishlistContent()
        }
    }
}

private struct WishlistContent: View {
    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(WishlistStore.self) private var wishlist
    @Environment(CartStore.self) private var cart
    @Environment(TabRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    private var products: [Product] { catalog.products(ids: wishlist.productIDs) }

    var body: some View {
        Group {
            if products.isEmpty {
                EmptyState(symbol: "heart", title: "Your wishlist is empty",
                           message: "Tap the heart on any product to save it here.",
                           actionTitle: "Start shopping") { dismiss() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(products) { product in
                            row(product)
                            Hairline().padding(.leading, Theme.Spacing.screenMargin)
                        }
                    }
                }
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("Wishlist (\(wishlist.count))")
        .inlineNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }.accessibilityIdentifier("wishlist-close")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wishlist")
    }

    private func row(_ product: Product) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Button { router.push(.product(product, nil), on: .home) } label: {
                ProductImage(product: product)
                    .frame(width: 96, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 6) {
                Text(product.name).font(Theme.Typography.bodyStrong).lineLimit(2)
                Text("\(product.colors.count) \(product.colors.count == 1 ? "color" : "colors")")
                    .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                PriceLabel(product: product)
                Spacer(minLength: 4)
                HStack(spacing: 10) {
                    Button {
                        if product.sizes.isEmpty {
                            cart.add(product)
                            appState.showToast("Added to bag")
                        } else {
                            router.push(.product(product, nil), on: .home)
                        }
                    } label: {
                        Text(product.sizes.isEmpty ? "Add to Bag" : "Select Size")
                            .font(Theme.Typography.small).fontWeight(.semibold)
                            .padding(.horizontal, 14).frame(height: 34)
                            .background(Theme.Colors.ink, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                            .foregroundStyle(Theme.Colors.onInk)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("wishlist-add-\(product.id)")
                    Button { withAnimation { wishlist.remove(product) } } label: {
                        Image(systemName: "trash").font(.system(size: 14)).foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.button).stroke(Theme.Colors.chipBorder))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("wishlist-remove-\(product.id)")
                }
            }
            Spacer()
        }
        .padding(Theme.Spacing.screenMargin)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wishlist-row-\(product.id)")
    }
}
