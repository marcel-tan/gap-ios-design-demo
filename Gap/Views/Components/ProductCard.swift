import SwiftUI

/// Grid tile for a listing. Shows the hero image of `item.color`.
struct ProductCard: View {
    let item: ListingItem
    @Environment(WishlistStore.self) private var wishlist

    private var product: Product { item.product }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ProductImage(product: product, color: item.color)
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .overlay(alignment: .topLeading) {
                        if product.isOnSale, let pct = product.percentOff {
                            PillBadge(text: "\(pct)% off", fill: Theme.Colors.sale).padding(8)
                        } else if product.isNew {
                            PillBadge(text: "New").padding(8)
                        }
                    }
                HeartButton(product: product).padding(6)
            }
            Text(product.name)
                .font(Theme.Typography.cardName)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("card-name-\(item.id)")
            PriceLabel(product: product)
            if product.reviewCount > 0 {
                RatingStars(rating: product.rating, count: product.reviewCount)
            }
        }
    }
}

/// Compact tile used in horizontal Home rails and "You may also like". One per product.
struct ProductRailCard: View {
    let product: Product
    var width: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProductImage(product: product)
                .frame(width: width, height: width * 4 / 3)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .overlay(alignment: .topTrailing) { HeartButton(product: product, size: 28).padding(6) }
            Text(product.name)
                .font(Theme.Typography.cardName)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 36, alignment: .top)
            PriceLabel(product: product)
        }
        .frame(width: width)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rail-card-\(product.id)")
    }
}

/// Two-column grid of listing tiles.
struct ProductGrid: View {
    let items: [ListingItem]
    let onSelect: (ListingItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.gridGutter),
        GridItem(.flexible(), spacing: Theme.Spacing.gridGutter),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
            ForEach(items) { item in
                Button { onSelect(item) } label: { ProductCard(item: item) }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("product-card-\(item.id)")
            }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

struct ProductRail: View {
    let title: String
    let products: [Product]
    var seeAll: (() -> Void)? = nil
    let onSelect: (Product) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, action: seeAll)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(products) { product in
                        Button { onSelect(product) } label: { ProductRailCard(product: product) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rail-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }
}
