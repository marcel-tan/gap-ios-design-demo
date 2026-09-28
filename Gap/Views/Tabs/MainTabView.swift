import SwiftUI

/// Every push destination shared by the tab stacks.
enum Route: Hashable {
    case product(Product, ProductColor?)
    case listing(ListingScope)
    case department(Brand, String)
    case checkout
    case confirmation(Order)
    case purchaseHistory
    case orderDetail(Order)
    case storeLocator
    case encoreMarket
    case encoreOffers
    case profile
}

/// One navigation path per tab. A router created with `fixedTab` (search / wishlist covers) routes
/// every push onto that single stack regardless of the tab requested.
@Observable
final class TabRouter {
    var paths: [AppTab: NavigationPath] = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, NavigationPath()) })
    let fixedTab: AppTab?

    init(fixedTab: AppTab? = nil) {
        self.fixedTab = fixedTab
    }

    func path(_ tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.paths[tab] = $0 }
        )
    }

    func push(_ route: Route, on tab: AppTab) {
        paths[fixedTab ?? tab, default: NavigationPath()].append(route)
    }

    func popToRoot(_ tab: AppTab) {
        paths[tab] = NavigationPath()
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(CartStore.self) private var cart
    @State private var router = TabRouter()

    var body: some View {
        @Bindable var appState = appState
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .home: tabStack(.home) { HomeView() }
                case .shop: tabStack(.shop) { ShopView() }
                case .offers: tabStack(.offers) { OffersView() }
                case .bag: tabStack(.bag) { BagView() }
                case .account: tabStack(.account) { AccountView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 10) {
                if let toast = appState.toast {
                    ToastView(message: toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: toast) {
                            try? await Task.sleep(for: .seconds(2))
                            if appState.toast == toast { appState.toast = nil }
                        }
                }
                if !appState.isTabBarHidden {
                    FloatingTabBar()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: appState.isTabBarHidden)
            .animation(.spring(duration: 0.3), value: appState.toast)
        }
        .fullScreenCover(isPresented: $appState.isSearchPresented) {
            SearchView()
        }
        .fullScreenCover(isPresented: $appState.isWishlistPresented) {
            WishlistView()
        }
        .sheet(isPresented: $appState.isBrandSwitcherPresented) {
            BrandSwitcherView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .addedToBagSheet(whenCoverPresented: false)
        .environment(router)
        .onChange(of: appState.pendingProduct) { _, product in
            guard let product else { return }
            appState.isSearchPresented = false
            appState.isWishlistPresented = false
            appState.addedToBag = nil
            router.push(.product(product, nil), on: appState.selectedTab)
            appState.pendingProduct = nil
        }
        .onChange(of: appState.selectedTab) { _, _ in appState.detailScrolled = false }
    }

    private func tabStack<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: router.path(tab)) {
            content()
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route)
                }
        }
    }
}

/// Presents the Item Added sheet from whichever presentation context is frontmost: the tab shell
/// when no full-screen cover is up, otherwise the cover itself.
struct AddedToBagSheetModifier: ViewModifier {
    let whenCoverPresented: Bool
    @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content.sheet(item: Binding(
            get: { appState.isCoverPresented == whenCoverPresented ? appState.addedToBag : nil },
            set: { appState.addedToBag = $0 }
        )) { item in
            AddedToBagSheet(item: item)
                .presentationDetents([.fraction(0.62), .large])
                .presentationDragIndicator(.visible)
        }
    }
}

extension View {
    func addedToBagSheet(whenCoverPresented: Bool) -> some View {
        modifier(AddedToBagSheetModifier(whenCoverPresented: whenCoverPresented))
    }
}

/// Full-screen cover shell (Search, Wishlist) with its own navigation stack.
struct CoverStack<Content: View>: View {
    @State private var router = TabRouter(fixedTab: .home)
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack(path: router.path(.home)) {
            content()
                .navigationDestination(for: Route.self) { route in RouteView(route: route) }
        }
        .addedToBagSheet(whenCoverPresented: true)
        .environment(router)
    }
}

/// Resolves a `Route` into its screen.
struct RouteView: View {
    let route: Route

    var body: some View {
        switch route {
        case .product(let product, let color): ProductDetailView(product: product, initialColor: color)
        case .listing(let scope): ProductListView(scope: scope)
        case .department(let brand, let department): DepartmentView(brand: brand, departmentID: department)
        case .checkout: CheckoutView()
        case .confirmation(let order): OrderConfirmationView(order: order)
        case .purchaseHistory: PurchaseHistoryView()
        case .orderDetail(let order): OrderDetailView(order: order)
        case .storeLocator: StoreLocatorView()
        case .encoreMarket: EncoreMarketView()
        case .encoreOffers: EncoreOffersView()
        case .profile: ProfileView()
        }
    }
}

/// Five-item floating pill bar; the first item is the circular brand logo.
struct FloatingTabBar: View {
    @Environment(AppState.self) private var appState
    @Environment(CartStore.self) private var cart
    @Environment(TabRouter.self) private var router

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    if appState.selectedTab == tab {
                        router.popToRoot(tab)
                    } else {
                        appState.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            if let symbol = tab.symbol {
                                Image(systemName: appState.selectedTab == tab ? symbol + ".fill" : symbol)
                                    .font(.system(size: Theme.Sizes.navIcon, weight: .regular))
                                    .frame(height: 26)
                            } else {
                                BrandLogo(brand: appState.selectedBrand, size: 26, isMuted: appState.selectedTab != tab)
                            }
                            if tab == .bag, cart.itemCount > 0 {
                                Text("\(cart.itemCount)")
                                    .font(Theme.Typography.badge)
                                    .foregroundStyle(Theme.Colors.onNavy)
                                    .padding(.horizontal, 4)
                                    .frame(minWidth: 15, minHeight: 15)
                                    .background(Theme.Colors.sale, in: Capsule())
                                    .offset(x: 8, y: -4)
                                    .accessibilityIdentifier("bag-badge")
                            }
                        }
                        Text(tab == .home ? appState.selectedBrand.displayName.uppercased() : tab.title.uppercased())
                            .font(Theme.Typography.tabLabel)
                            .tracking(0.6)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(appState.selectedTab == tab ? Theme.Colors.ink : Theme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(tab.identifier)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(appState.selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Theme.Sizes.tabBarHeight)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.tabBar, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tabBar, style: .continuous).stroke(Theme.Colors.hairline, lineWidth: 1))
        .floatingShadow()
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.bottom, Theme.Sizes.tabBarBottomPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tab-bar")
    }
}

/// Reserves space so scroll content clears the floating tab bar.
struct TabBarSpacer: View {
    var body: some View {
        Color.clear.frame(height: Theme.Sizes.tabBarReserved + 16)
    }
}

/// Standard header row: wordmark or title on the left, search / wishlist / bag on the right.
struct StoreHeader: View {
    var title: String? = nil
    var showsBrandSwitcher = false
    @Environment(AppState.self) private var appState
    @Environment(CartStore.self) private var cart
    @Environment(WishlistStore.self) private var wishlist

    var body: some View {
        HStack(spacing: 4) {
            if let title {
                Text(title).font(Theme.Typography.screenTitle).foregroundStyle(Theme.Colors.textPrimary)
            } else if showsBrandSwitcher {
                Button { appState.isBrandSwitcherPresented = true } label: {
                    HStack(spacing: 6) {
                        Wordmark(brand: appState.selectedBrand)
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("brand-switcher")
            } else {
                Wordmark(brand: appState.selectedBrand)
            }
            Spacer()
            IconButton(symbol: "magnifyingglass", identifier: "header-search") { appState.isSearchPresented = true }
            IconButton(symbol: wishlist.isEmpty ? "heart" : "heart.fill", identifier: "header-wishlist", badge: wishlist.count) { appState.isWishlistPresented = true }
            IconButton(symbol: "bag", identifier: "header-bag", badge: cart.itemCount) { appState.openBag() }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .frame(height: Theme.Sizes.headerRowHeight)
    }
}
