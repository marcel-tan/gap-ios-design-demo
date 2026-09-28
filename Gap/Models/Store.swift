import Foundation
import CoreLocation
import Observation

struct Store: Codable, Hashable, Identifiable {
    let id: String
    let brand: String
    let name: String
    let address: String
    let city: String
    let phone: String
    let latitude: Double
    let longitude: Double
    let hours: String
    let services: [String]
    let distanceKm: Double

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
    var brandInfo: Brand { Brand(rawValue: brand) ?? .gap }
    var distanceLabel: String { String(format: "%.1f km", distanceKm) }
}

struct StoreFile: Codable {
    let stores: [Store]
}

/// Seeded Montréal stores with a persisted "My Store" preference.
@Observable
final class StoreLocator {
    static let preferredKey = "stores.preferredID"

    private(set) var stores: [Store]
    var preferredStoreID: String? {
        didSet { defaults.set(preferredStoreID, forKey: StoreLocator.preferredKey) }
    }

    private let defaults: UserDefaults

    init(stores: [Store], defaults: UserDefaults = .standard) {
        self.stores = stores.sorted { $0.distanceKm < $1.distanceKm }
        self.defaults = defaults
        preferredStoreID = defaults.string(forKey: StoreLocator.preferredKey)
    }

    static func load(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> StoreLocator {
        let file: StoreFile? = try? Catalog.loadFile(named: "stores", bundle: bundle)
        return StoreLocator(stores: file?.stores ?? [], defaults: defaults)
    }

    var preferredStore: Store? { stores.first { $0.id == preferredStoreID } }

    func stores(for brands: Set<Brand>) -> [Store] {
        guard !brands.isEmpty else { return stores }
        return stores.filter { brands.contains($0.brandInfo) }
    }

    func setPreferred(_ store: Store) {
        preferredStoreID = store.id
    }
}
