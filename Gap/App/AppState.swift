import Foundation
import Observation

enum AppTab: Int, CaseIterable, Identifiable {
    case home, shop, offers, bag, account

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Gap"
        case .shop: return "Shop"
        case .offers: return "Offers"
        case .bag: return "Bag"
        case .account: return "Account"
        }
    }

    /// SF Symbol; `.home` draws the circular brand logo instead.
    var symbol: String? {
        switch self {
        case .home: return nil
        case .shop: return "square.grid.2x2"
        case .offers: return "tag"
        case .bag: return "bag"
        case .account: return "person"
        }
    }

    var identifier: String {
        switch self {
        case .home: return "tab-home"
        case .shop: return "tab-shop"
        case .offers: return "tab-offers"
        case .bag: return "tab-bag"
        case .account: return "tab-account"
        }
    }
}

/// Item shown in the Item Added to Bag sheet. The size is the shopper's PDP selection.
struct AddedToBagItem: Hashable, Identifiable {
    let product: Product
    let color: ProductColor
    let size: String?

    var id: String { "\(product.id)|\(color.id)|\(size ?? "")" }
}

@Observable
final class AppState {
    static let onboardingKey = "hasCompletedOnboarding"
    static let recentSearchesKey = "search.recent"
    static let brandKey = "brand.selected"

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: AppState.onboardingKey) }
    }
    var selectedBrand: Brand {
        didSet { defaults.set(selectedBrand.rawValue, forKey: AppState.brandKey) }
    }
    var selectedTab: AppTab = .home
    var isSearchPresented = false
    var isWishlistPresented = false
    var isBrandSwitcherPresented = false
    /// Non-nil while the Item Added to Bag sheet is up; the tab bar hides.
    var addedToBag: AddedToBagItem?
    var isAddedToBagPresented: Bool { addedToBag != nil }
    /// Set by a scrolled PDP; the tab bar hides while true.
    var detailScrolled = false
    var detailDepth = 0
    /// Product to push onto whichever navigation stack is currently frontmost.
    var pendingProduct: Product?
    /// Toast shown above the tab bar.
    var toast: String?

    var isTabBarHidden: Bool { (detailDepth > 0 && detailScrolled) || isAddedToBagPresented }
    var isCoverPresented: Bool { isSearchPresented || isWishlistPresented }

    private(set) var recentSearches: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.defaults = defaults
        if arguments.contains("-resetOnboarding") || arguments.contains("-resetState") {
            for key in [AppState.onboardingKey, WishlistStore.storageKey, StoreLocator.preferredKey,
                        AppState.recentSearchesKey, AppState.brandKey, EncoreAccount.pointsKey] + CartStore.persistedKeys {
                defaults.removeObject(forKey: key)
            }
        }
        if arguments.contains("-skipOnboarding") {
            defaults.set(true, forKey: AppState.onboardingKey)
        }
        hasCompletedOnboarding = defaults.bool(forKey: AppState.onboardingKey)
        selectedBrand = Brand(rawValue: defaults.string(forKey: AppState.brandKey) ?? "") ?? .gap
        recentSearches = defaults.stringArray(forKey: AppState.recentSearchesKey) ?? []
    }

    func showToast(_ message: String) {
        toast = message
    }

    func openBag() {
        isSearchPresented = false
        isWishlistPresented = false
        addedToBag = nil
        selectedTab = .bag
    }

    func signOut() {
        hasCompletedOnboarding = false
        selectedTab = .home
        isSearchPresented = false
        isWishlistPresented = false
    }

    func recordSearch(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(q) == .orderedSame }
        recentSearches.insert(q, at: 0)
        recentSearches = Array(recentSearches.prefix(8))
        defaults.set(recentSearches, forKey: AppState.recentSearchesKey)
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        defaults.removeObject(forKey: AppState.recentSearchesKey)
    }
}
