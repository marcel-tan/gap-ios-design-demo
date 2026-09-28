import SwiftUI

struct OffersView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.offers

    @Environment(AppState.self) private var appState
    @Environment(CartStore.self) private var cart
    @Environment(TabRouter.self) private var router
    @State private var offers = Offer.load()

    private var brandOffers: [Offer] { offers.filter { $0.brandInfo == appState.selectedBrand } }
    private var otherOffers: [Offer] { offers.filter { $0.brandInfo != appState.selectedBrand } }

    var body: some View {
        VStack(spacing: 0) {
            StoreHeader(title: "Offers")
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if brandOffers.isEmpty && otherOffers.isEmpty {
                        EmptyState(symbol: "tag", title: "No offers right now", message: "Check back soon.")
                    }
                    if !brandOffers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("For \(appState.selectedBrand.displayName)").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                                .padding(.horizontal, Theme.Spacing.screenMargin)
                            ForEach(brandOffers) { OfferCard(offer: $0) }
                        }
                    }
                    if !otherOffers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Across Gap Inc.").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                                .padding(.horizontal, Theme.Spacing.screenMargin)
                            ForEach(otherOffers) { OfferCard(offer: $0) }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.top, 8)
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("offers")
    }
}

struct OfferCard: View {
    let offer: Offer
    @Environment(AppState.self) private var appState
    @Environment(CartStore.self) private var cart
    @Environment(TabRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    BrandLogo(brand: offer.brandInfo, size: 18)
                    Text(offer.eyebrow).trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                if offer.isMembersOnly {
                    PillBadge(text: "Encore", fill: Theme.Colors.encoreGold, foreground: Theme.Colors.encoreDark)
                }
            }
            Text(offer.title).font(Theme.Typography.sectionTitle).foregroundStyle(Theme.Colors.textPrimary)
            Text(offer.body).font(Theme.Typography.body).foregroundStyle(Theme.Colors.textSecondary)
            HStack {
                if let code = offer.code {
                    Text(code)
                        .font(Theme.Typography.promo)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 4).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundStyle(Theme.Colors.chipBorder))
                        .accessibilityIdentifier("offer-code-\(offer.id)")
                }
                Spacer()
                Text(offer.expires).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textTertiary)
            }
            if let code = offer.code {
                Button {
                    if cart.applyPromo(code) {
                        appState.showToast(cart.isEmpty ? "\(code) will apply at checkout" : "\(code) applied to your bag")
                    }
                } label: {
                    Text(cart.promo?.code == code ? "Applied" : "Apply to Bag")
                        .font(Theme.Typography.button)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(cart.promo?.code == code ? Theme.Colors.success : Theme.Colors.ink, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                        .foregroundStyle(Theme.Colors.onInk)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("offer-apply-\(offer.id)")
            } else {
                Button {
                    appState.selectedBrand = offer.brandInfo
                    router.push(.listing(.sale(brand: offer.brandInfo)), on: .offers)
                } label: {
                    Text("Shop the offer")
                        .font(Theme.Typography.button)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.button).stroke(Theme.Colors.ink, lineWidth: 1.5))
                        .foregroundStyle(Theme.Colors.ink)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("offer-shop-\(offer.id)")
            }
        }
        .padding(16)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.Colors.hairline))
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("offer-\(offer.id)")
    }
}
