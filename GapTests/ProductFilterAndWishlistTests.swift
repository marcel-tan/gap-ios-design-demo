import XCTest
@testable import Gap

final class ProductFilterTests: XCTestCase {
    private func product(_ id: String, price: Decimal, sale: Decimal? = nil, isNew: Bool = false, rating: Double = 4, colors: [String] = ["Black"], sizes: [(String, Bool)] = [("M", true)]) -> Product {
        Product(
            id: id, brand: "gap", name: id, category: "tees", department: "women",
            price: price, salePrice: sale, isNew: isNew, rating: rating, reviewCount: 1,
            description: "", details: [], fabric: "",
            colors: colors.map { ProductColor(id: $0, name: $0, hex: "000000", imageURLs: []) },
            sizes: sizes.map { ProductSize(label: $0.0, available: $0.1) }
        )
    }

    private lazy var products = [
        product("a", price: 30, colors: ["Black", "Light Blue Indigo"]),
        product("b", price: 80, sale: 49.99, isNew: true, rating: 4.8, colors: ["Heather Grey"], sizes: [("S", true), ("L", false)]),
        product("c", price: 15, rating: 3.2, colors: ["Optic White"]),
    ]

    func testEmptyFilterKeepsCatalogOrder() {
        XCTAssertEqual(ProductFilter().apply(to: products).map(\.id), ["a", "b", "c"])
        XCTAssertFalse(ProductFilter().hasActiveFilters)
    }

    func testSorts() {
        var f = ProductFilter(sort: .priceLowHigh)
        XCTAssertEqual(f.apply(to: products).map(\.id), ["c", "a", "b"], "sale price is used")
        f.sort = .priceHighLow
        XCTAssertEqual(f.apply(to: products).map(\.id), ["b", "a", "c"])
        f.sort = .newest
        XCTAssertEqual(f.apply(to: products).map(\.id), ["b", "a", "c"])
        f.sort = .topRated
        XCTAssertEqual(f.apply(to: products).map(\.id), ["b", "a", "c"])
    }

    func testColourFamilyFilterNarrowsProducts() {
        var f = ProductFilter()
        f.colors = ["Blue"]
        XCTAssertEqual(f.apply(to: products).map(\.id), ["a"])
        f.colors = ["Grey", "White"]
        XCTAssertEqual(f.apply(to: products).map(\.id), ["b", "c"])
        XCTAssertEqual(f.activeCount, 2)
    }

    func testSizeFilterIgnoresSoldOutSizes() {
        var f = ProductFilter()
        f.sizes = ["L"]
        XCTAssertTrue(f.apply(to: products).isEmpty)
        f.sizes = ["S"]
        XCTAssertEqual(f.apply(to: products).map(\.id), ["b"])
    }

    func testSaleAndPriceBands() {
        var f = ProductFilter()
        f.onSaleOnly = true
        XCTAssertEqual(f.apply(to: products).map(\.id), ["b"])
        f = ProductFilter()
        f.minPrice = 25
        f.maxPrice = 50
        XCTAssertEqual(f.apply(to: products).map(\.id), ["a", "b"])
        f.clear()
        XCTAssertFalse(f.hasActiveFilters)
    }

    func testColourFamilies() {
        XCTAssertEqual(ProductFilter.colorFamily("Light Blue Indigo"), "Blue")
        XCTAssertEqual(ProductFilter.colorFamily("Medium Wash"), "Blue")
        XCTAssertEqual(ProductFilter.colorFamily("Heather Grey"), "Grey")
        XCTAssertEqual(ProductFilter.colorFamily("Optic White"), "White")
        XCTAssertEqual(ProductFilter.colorFamily("Khaki"), "Beige")
        XCTAssertEqual(ProductFilter.colorFamily("Rainbow Stripe"), "Multi")
        XCTAssertEqual(ProductFilter.colorOptions(products), ["Black", "White", "Blue", "Grey"])
        XCTAssertEqual(ProductFilter.sizeOptions(products), ["M", "S"])
    }
}

final class WishlistStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WishlistStoreTests")
        defaults.removePersistentDomain(forName: "WishlistStoreTests")
    }

    private func product(_ id: String) -> Product {
        Product(id: id, brand: "gap", name: id, category: "tees", department: "women", price: 10, salePrice: nil, isNew: false, rating: 4, reviewCount: 0, description: "", details: [], fabric: "",
                colors: [ProductColor(id: "a", name: "A", hex: "000000", imageURLs: []), ProductColor(id: "b", name: "B", hex: "ffffff", imageURLs: [])],
                sizes: [])
    }

    func testToggleIsKeyedByProductAndPersists() {
        let store = WishlistStore(defaults: defaults)
        let p = product("tee")
        XCTAssertTrue(store.toggle(p))
        XCTAssertTrue(store.contains(p))
        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(WishlistStore(defaults: defaults).productIDs, ["tee"])
        XCTAssertFalse(store.toggle(p))
        XCTAssertTrue(store.isEmpty)
    }

    func testNewestFirstRemoveAndClear() {
        let store = WishlistStore(defaults: defaults)
        store.toggle(product("one"))
        store.toggle(product("two"))
        XCTAssertEqual(store.productIDs, ["two", "one"])
        store.remove(product("one"))
        XCTAssertEqual(store.productIDs, ["two"])
        store.clear()
        XCTAssertTrue(store.isEmpty)
        XCTAssertEqual(defaults.stringArray(forKey: WishlistStore.storageKey), [])
    }

    func testPreferredStorePersists() {
        let file: StoreFile = try! Catalog.loadFile(named: "stores", bundle: Bundle(for: AppState.self))
        let locator = StoreLocator(stores: file.stores, defaults: defaults)
        XCTAssertNil(locator.preferredStore)
        locator.setPreferred(locator.stores[2])
        XCTAssertEqual(StoreLocator(stores: file.stores, defaults: defaults).preferredStore?.id, locator.stores[2].id)
        XCTAssertEqual(locator.stores(for: [.gap]).count, file.stores.filter { $0.brand == "gap" }.count)
    }
}
