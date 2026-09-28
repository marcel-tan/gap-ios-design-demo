import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fill: Color = Theme.Colors.navy
    var foreground: Color = Theme.Colors.onNavy
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(Theme.Typography.button)
                    .tracking(Theme.Typography.buttonTracking)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Sizes.ctaHeight)
            .background(isEnabled ? fill : Theme.Colors.chipBorder, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
            .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct OutlineButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(Theme.Typography.button)
                    .tracking(Theme.Typography.buttonTracking)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Sizes.ctaHeight)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.button).stroke(Theme.Colors.ink, lineWidth: 1.5))
            .foregroundStyle(Theme.Colors.ink)
        }
        .buttonStyle(.plain)
    }
}

/// Circular icon button used in headers.
struct IconButton: View {
    let symbol: String
    var identifier: String? = nil
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Theme.Colors.ink)
                .frame(width: 40, height: 40)
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text("\(badge)")
                            .font(Theme.Typography.badge)
                            .foregroundStyle(Theme.Colors.onNavy)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Theme.Colors.navy, in: Capsule())
                            .offset(x: 2, y: 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier ?? "icon-\(symbol)")
    }
}

/// Heart toggle. Hearting is keyed by the product, so every tile for the same product shares one state.
struct HeartButton: View {
    let product: Product
    var size: CGFloat = 32
    @Environment(WishlistStore.self) private var wishlist

    var body: some View {
        let saved = wishlist.contains(product)
        Button {
            withAnimation(.spring(duration: 0.3)) { _ = wishlist.toggle(product) }
        } label: {
            Image(systemName: saved ? "heart.fill" : "heart")
                .font(.system(size: size * 0.5, weight: .regular))
                .foregroundStyle(saved ? Theme.Colors.sale : Theme.Colors.ink)
                .frame(width: size, height: size)
                .background(Theme.Colors.surface.opacity(0.92), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("heart-\(product.id)")
        .accessibilityLabel(saved ? "Remove from wishlist" : "Add to wishlist")
    }
}

struct Swatch: View {
    let hex: String
    var size: CGFloat = Theme.Sizes.swatch
    var selected = false

    var body: some View {
        Circle()
            .fill(Color(hexString: hex) ?? Theme.Colors.chipFill)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Theme.Colors.hairline, lineWidth: 1))
            .padding(3)
            .overlay(Circle().stroke(selected ? Theme.Colors.ink : Color.clear, lineWidth: 1.5))
    }
}

struct PillBadge: View {
    let text: String
    var fill: Color = Theme.Colors.ink
    var foreground: Color = Theme.Colors.onInk

    var body: some View {
        Text(text)
            .font(Theme.Typography.badge)
            .tracking(0.8)
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(fill, in: Capsule())
            .foregroundStyle(foreground)
    }
}

struct PriceLabel: View {
    let product: Product
    var font: Font = Theme.Typography.price

    var body: some View {
        HStack(spacing: 6) {
            if let sale = product.salePrice {
                Text(PriceFormatter.string(sale)).font(font).foregroundStyle(Theme.Colors.sale)
                Text(PriceFormatter.string(product.price)).font(font).strikethrough().foregroundStyle(Theme.Colors.textTertiary)
            } else {
                Text(PriceFormatter.string(product.price)).font(font).foregroundStyle(Theme.Colors.textPrimary)
            }
        }
    }
}

struct RatingStars: View {
    let rating: Double
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: Double(i) + 1 <= rating ? "star.fill" : (Double(i) + 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                        .font(.system(size: 11))
                }
            }
            .foregroundStyle(Theme.Colors.ink)
            if let count {
                Text("(\(count))").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle = "See all"

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Theme.Typography.sectionTitle).foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            if let action {
                Button(actionTitle, action: action)
                    .font(Theme.Typography.small)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle().fill(Theme.Colors.hairline).frame(height: Theme.Sizes.hairline)
    }
}

/// Selectable filter/size chip.
struct Chip: View {
    let title: String
    var selected = false
    var enabled = true
    var minWidth: CGFloat = Theme.Sizes.sizeChipMinWidth
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.chip)
                .padding(.horizontal, 14)
                .frame(minWidth: minWidth)
                .frame(height: Theme.Sizes.sizeChipHeight)
                .background(selected ? Theme.Colors.ink : Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.button).stroke(selected ? Theme.Colors.ink : Theme.Colors.chipBorder, lineWidth: 1))
                .foregroundStyle(selected ? Theme.Colors.onInk : (enabled ? Theme.Colors.textPrimary : Theme.Colors.textTertiary))
                .overlay {
                    if !enabled {
                        Rectangle().fill(Theme.Colors.chipBorder).frame(height: 1).rotationEffect(.degrees(-20))
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Toast anchored above the tab bar.
struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.Typography.bodyStrong)
            .foregroundStyle(Theme.Colors.onInk)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Theme.Colors.ink, in: Capsule())
            .floatingShadow()
            .accessibilityIdentifier("toast")
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(title).font(Theme.Typography.sectionTitle)
            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, 8)
                    .frame(maxWidth: 260)
            }
        }
        .padding(Theme.Spacing.screenMargin * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Small header wordmark used above tab roots: the Gap logo asset, or the brand name for other brands.
struct Wordmark: View {
    var brand: Brand = .gap
    var body: some View {
        Group {
            if brand == .gap {
                GapWordmark(height: 24, color: brand.color)
            } else {
                Text(brand.displayName.uppercased())
                    .font(Theme.Typography.wordmark)
                    .tracking(Theme.Typography.wordmarkTracking)
                    .foregroundStyle(brand.color)
            }
        }
        .accessibilityIdentifier("wordmark")
    }
}
