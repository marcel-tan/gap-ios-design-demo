import SwiftUI

@main
struct GapApp: App {
    @State private var appState = AppState()
    @State private var catalog = Catalog.load()
    @State private var cart = GapApp.makeCart()
    @State private var wishlist = WishlistStore()
    @State private var stores = StoreLocator.load()
    @State private var account = EncoreAccount()

    /// `-seedBag` pre-loads the fall outfit so demos can start at the Bag.
    static func makeCart(arguments: [String] = ProcessInfo.processInfo.arguments) -> CartStore {
        let cart = CartStore(defaults: .standard)
        if arguments.contains("-seedBag"), cart.isEmpty {
            let catalog = Catalog.load()
            for (id, size) in [("gap-800546", "M"), ("gap-815642", "28"), ("gap-797118", "M")] {
                if let product = catalog.product(id: id) { cart.add(product, size: size) }
            }
        }
        return cart
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(catalog)
                .environment(cart)
                .environment(wishlist)
                .environment(stores)
                .environment(account)
                .tint(Theme.Colors.navy)
                .preferredColorScheme(.light)
        }
    }
}
