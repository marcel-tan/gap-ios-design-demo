import SwiftUI

struct AccountView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.account

    @Environment(AppState.self) private var appState
    @Environment(EncoreAccount.self) private var account
    @Environment(CartStore.self) private var cart
    @Environment(StoreLocator.self) private var stores
    @Environment(TabRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            StoreHeader(title: "Account")
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    encoreCard
                    quickLinks
                    menu
                    Button("Sign Out") { appState.signOut() }
                        .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("account-sign-out")
                    TabBarSpacer()
                }
                .padding(.top, 8)
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("account")
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(Greeting.text()), \(account.firstName)")
                .font(Theme.Typography.greeting)
                .accessibilityIdentifier("account-greeting")
            Text(account.email).font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private var encoreCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Gap Encore").font(Theme.Typography.wordmark).tracking(Theme.Typography.wordmarkTracking)
                Spacer()
                PillBadge(text: account.tier, fill: Theme.Colors.encoreGold, foreground: Theme.Colors.encoreDark)
                    .accessibilityIdentifier("account-tier")
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(account.pointsLabel).font(Theme.Typography.heroTitle).accessibilityIdentifier("account-points")
                Text("points").font(Theme.Typography.body).foregroundStyle(.white.opacity(0.8))
            }
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: account.nextRewardProgress).tint(Theme.Colors.encoreGold)
                Text("\(account.pointsToNextReward) points to your next $5 reward")
                    .font(Theme.Typography.caption).foregroundStyle(.white.opacity(0.8))
            }
            Text("Member since \(account.memberSince) · 1 point per $1 · Free shipping & returns")
                .font(Theme.Typography.caption).foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(
            LinearGradient(colors: [Theme.Colors.encoreDark, Theme.Colors.navy], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("account-encore-card")
    }

    private var quickLinks: some View {
        HStack(spacing: 10) {
            quickLink("Purchase\nHistory", symbol: "shippingbox", id: "account-purchase-history") { router.push(.purchaseHistory, on: .account) }
            quickLink("Encore\nOffers", symbol: "tag", id: "account-encore-offers") { router.push(.encoreOffers, on: .account) }
            quickLink("Encore\nMarket", symbol: "gift", id: "account-encore-market") { router.push(.encoreMarket, on: .account) }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func quickLink(_ title: String, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 22)).foregroundStyle(Theme.Colors.navy)
                Text(title).font(Theme.Typography.small).multilineTextAlignment(.center).foregroundStyle(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(Theme.Colors.canvas, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var menu: some View {
        VStack(spacing: 0) {
            menuRow("My Store", detail: stores.preferredStore?.name ?? "Choose a store", symbol: "mappin.and.ellipse", id: "account-my-store") {
                router.push(.storeLocator(), on: .account)
            }
            menuRow("Profile & Addresses", detail: account.shippingAddress, symbol: "person", id: "account-profile") {
                router.push(.profile, on: .account)
            }
            menuRow("Payment Methods", detail: account.paymentLabel, symbol: "creditcard", id: "account-payment") {
                router.push(.profile, on: .account)
            }
            menuRow("Wishlist", detail: nil, symbol: "heart", id: "account-wishlist") {
                appState.isWishlistPresented = true
            }
            menuRow("Help & Support", detail: "Chat, returns, order issues", symbol: "questionmark.circle", id: "account-help") {
                appState.showToast("Support chat is a demo placeholder")
            }
        }
    }

    private func menuRow(_ title: String, detail: String?, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(Theme.Colors.textPrimary).frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textPrimary)
                        if let detail {
                            Text(detail).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .frame(height: 60)
                Hairline().padding(.leading, Theme.Spacing.screenMargin)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

struct PurchaseHistoryView: View {
    @Environment(CartStore.self) private var cart
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var router

    var body: some View {
        Group {
            if cart.orders.isEmpty {
                EmptyState(symbol: "shippingbox", title: "No orders yet",
                           message: "Orders you place in this session show up here.",
                           actionTitle: "Start Shopping") {
                    router.popToRoot(.account)
                    appState.selectedTab = .shop
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cart.orders) { order in
                            Button { router.push(.orderDetail(order), on: .account) } label: {
                                HStack(spacing: 12) {
                                    ProductImage(product: order.lines[0].product, color: order.lines[0].color)
                                        .frame(width: 64, height: 84)
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Order #\(order.number)").font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textPrimary)
                                        Text(order.placedAt.formatted(date: .abbreviated, time: .shortened)).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                                        Text("\(order.itemCount) \(order.itemCount == 1 ? "item" : "items") · \(PriceFormatter.string(order.total))")
                                            .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textPrimary)
                                            .accessibilityIdentifier("order-total-\(order.number)")
                                        PillBadge(text: "Processing", fill: Theme.Colors.canvas, foreground: Theme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.Colors.hairline))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("order-\(order.number)")
                        }
                        TabBarSpacer()
                    }
                    .padding(Theme.Spacing.screenMargin)
                }
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("Purchase History")
        .inlineNavigationBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("purchase-history")
    }
}

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.number)").font(Theme.Typography.sectionTitle)
                    Text(order.placedAt.formatted(date: .long, time: .shortened)).font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.shippingAddress.hasPrefix("Pickup") ? "Pickup" : "Shipping to").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                    Text(order.shippingName).font(Theme.Typography.bodyStrong)
                    Text(order.shippingAddress).font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                }
                VStack(spacing: 0) {
                    ForEach(order.lines) { line in
                        OrderLineRow(line: line)
                        Hairline()
                    }
                }
                OrderSummaryView(summary: order.summary)
                TabBarSpacer()
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("Order Details")
        .inlineNavigationBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("order-detail")
    }
}

struct EncoreOffersView: View {
    @State private var offers = Offer.load().filter(\.isMembersOnly)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Exclusive to Premier members. Codes apply automatically at checkout when you tap Apply.")
                    .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                ForEach(offers) { OfferCard(offer: $0) }
                TabBarSpacer()
            }
            .padding(.top, 12)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("Encore Offers")
        .inlineNavigationBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("encore-offers")
    }
}

struct EncoreMarketView: View {
    @Environment(EncoreAccount.self) private var account
    @Environment(AppState.self) private var appState

    private struct Reward: Identifiable {
        let id: String
        let title: String
        let points: Int
        let symbol: String
    }

    private let rewards = [
        Reward(id: "reward-5", title: "$5 Reward", points: 500, symbol: "dollarsign.circle"),
        Reward(id: "reward-10", title: "$10 Reward", points: 1000, symbol: "dollarsign.circle.fill"),
        Reward(id: "reward-shipping", title: "Free Express Shipping", points: 750, symbol: "shippingbox"),
        Reward(id: "reward-denim", title: "Free Denim Hemming", points: 1500, symbol: "scissors"),
        Reward(id: "reward-donate", title: "Donate $5 to Gap Foundation", points: 500, symbol: "heart"),
        Reward(id: "reward-early", title: "Early Access: Fall Drop", points: 2000, symbol: "sparkles"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Available balance").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(account.pointsLabel) pts").font(Theme.Typography.bodyStrong)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(rewards) { reward in
                        let affordable = account.points >= reward.points
                        Button { appState.showToast(affordable ? "Reward redemption is a demo placeholder" : "Not enough points yet") } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: reward.symbol).font(.system(size: 24)).foregroundStyle(Theme.Colors.encoreGold)
                                Text(reward.title).font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textPrimary).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                Text("\(EncoreAccount.formatPoints(reward.points)) pts")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(affordable ? Theme.Colors.success : Theme.Colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 140)
                            .padding(14)
                            .background(Theme.Colors.canvas, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("market-\(reward.id)")
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                TabBarSpacer()
            }
            .padding(.top, 12)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("Encore Market")
        .inlineNavigationBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("encore-market")
    }
}

struct ProfileView: View {
    @Environment(EncoreAccount.self) private var account

    var body: some View {
        List {
            Section("Profile") {
                LabeledContent("Name", value: account.fullName)
                LabeledContent("Email", value: account.email)
                LabeledContent("Member since", value: account.memberSince)
            }
            Section("Default address") {
                Text(account.shippingAddress)
            }
            Section("Payment") {
                LabeledContent("Card", value: account.paymentLabel)
            }
        }
        .navigationTitle("Profile")
        .inlineNavigationBar()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profile")
    }
}
