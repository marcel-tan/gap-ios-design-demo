import Foundation
import Observation

/// Favourites keyed by product ID, persisted in UserDefaults.
@Observable
final class WishlistStore {
    static let storageKey = "wishlist.productIDs"

    private(set) var productIDs: [String] = []
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        productIDs = defaults.stringArray(forKey: WishlistStore.storageKey) ?? []
    }

    var count: Int { productIDs.count }
    var isEmpty: Bool { productIDs.isEmpty }

    func contains(_ product: Product) -> Bool {
        productIDs.contains(product.id)
    }

    /// Returns true when the product was added, false when removed.
    @discardableResult
    func toggle(_ product: Product) -> Bool {
        if let index = productIDs.firstIndex(of: product.id) {
            productIDs.remove(at: index)
            persist()
            return false
        }
        productIDs.insert(product.id, at: 0)
        persist()
        return true
    }

    func remove(_ product: Product) {
        productIDs.removeAll { $0 == product.id }
        persist()
    }

    func clear() {
        productIDs.removeAll()
        persist()
    }

    private func persist() {
        defaults.set(productIDs, forKey: WishlistStore.storageKey)
    }
}
