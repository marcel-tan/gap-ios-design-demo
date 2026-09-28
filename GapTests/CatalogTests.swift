import XCTest
@testable import Gap

final class CatalogTests: XCTestCase {
    private var catalog: Catalog!

    override func setUp() {
        super.setUp()
        catalog = Catalog.load(bundle: Bundle(for: AppState.self))
    }

    func testBundledCatalogDecodes() {
        XCTAssertGreaterThanOrEqual(catalog.products.count, 60)
        XCTAssertGreaterThanOrEqual(catalog.products(brand: .gap).count, 40)
        for brand in [Brand.oldnavy, .bananarepublic, .athleta] {
            XCTAssertGreaterThanOrEqual(catalog.products(brand: brand).count, 4, "\(brand) should have products")
        }
        XCTAssertEqual(catalog.departments.map(\.id), ["women", "men", "girls", "boys", "baby"])
    }

    func testEveryProductHasColorsSizesAndImagery() {
        for product in catalog.products {
            XCTAssertFalse(product.colors.isEmpty, product.id)
            XCTAssertFalse(product.sizes.isEmpty, product.id)
            XCTAssertFalse(product.name.isEmpty, product.id)
            XCTAssertGreaterThan(product.price, 0, product.id)
            for color in product.colors {
                XCTAssertFalse(color.imageURLs.isEmpty, "\(product.id) \(color.name)")
                XCTAssertTrue(color.hex.hasPrefix("#") && color.hex.count == 7, "\(product.id) \(color.name) hex")
            }
        }
    }

    func testProductIDsAreUnique() {
        let ids = catalog.products.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testWomensShortSleeveTeesHaveFourStylesWithFiveColors() {
        let tees = catalog.products(in: .category(brand: .gap, department: "women", category: "tees"))
        XCTAssertEqual(tees.count, 4)
        XCTAssertEqual(Set(tees.map(\.name)), [
            "Organic Cotton VintageSoft T-Shirt",
            "Modern Crew T-Shirt",
            "Modern Rib T-Shirt",
            "CloseKnit Jersey T-Shirt",
        ])
        for tee in tees {
            XCTAssertEqual(tee.colors.count, 5, tee.name)
            XCTAssertEqual(Set(tee.colors.map(\.id)).count, 5, "\(tee.name) colour ids must be unique")
        }
    }

    func testHeroJeansMatchReference() {
        let jeans = catalog.products.first { $0.name == "Low Rise '90s Loose Jeans" }
        XCTAssertNotNil(jeans)
        XCTAssertEqual(jeans?.price, Decimal(string: "79.95"))
        XCTAssertEqual(jeans?.primaryColor?.name, "Light Blue Indigo")
    }

    func testLookupByID() {
        let product = catalog.products[0]
        XCTAssertEqual(catalog.product(id: product.id), product)
        XCTAssertNil(catalog.product(id: "missing"))
        XCTAssertEqual(catalog.products(ids: [product.id, "missing"]), [product])
    }

    func testSearchMatchesNameAndCategoryCaseInsensitively() {
        let jeans = catalog.search("JEANS")
        XCTAssertFalse(jeans.isEmpty)
        XCTAssertTrue(jeans.allSatisfy { $0.name.localizedCaseInsensitiveContains("jean") || $0.category == "jeans" })
        XCTAssertTrue(catalog.search("   ").isEmpty)
        XCTAssertTrue(catalog.search("zzzzqqq").isEmpty)
    }

    func testListingItemsCarryColourSpecificImagery() {
        let items = catalog.listingItems(in: .category(brand: .gap, department: "women", category: "tees"))
        XCTAssertFalse(items.isEmpty)
        for item in items {
            XCTAssertTrue(item.product.colors.contains(item.color))
            XCTAssertEqual(item.id, "\(item.product.id)|\(item.color.id)")
        }
    }

    func testListingItemsOnlyContainProductsFromScope() {
        let scopeProducts = Set(catalog.products(in: .department(brand: .gap, department: "men")).map(\.id))
        let items = catalog.listingItems(in: .department(brand: .gap, department: "men"))
        XCTAssertEqual(Set(items.map(\.product.id)), scopeProducts)
    }

    func testHomeRailsReturnDistinctProducts() {
        let rail = catalog.rail(brand: .gap, department: "women", category: "tees")
        XCTAssertEqual(rail.count, Set(rail.map(\.id)).count)
        XCTAssertEqual(rail.count, 4)
        let newArrivals = catalog.rail(brand: .gap, limit: 8)
        XCTAssertLessThanOrEqual(newArrivals.count, 8)
        XCTAssertEqual(newArrivals.count, Set(newArrivals.map(\.id)).count)
    }

    func testSaleScopeOnlyContainsDiscountedProducts() {
        let sale = catalog.products(in: .sale(brand: .gap))
        XCTAssertFalse(sale.isEmpty)
        XCTAssertTrue(sale.allSatisfy(\.isOnSale))
        XCTAssertTrue(sale.allSatisfy { $0.salePrice! < $0.price })
    }

    func testRelatedProductsExcludeSelf() {
        let product = catalog.products[0]
        let related = catalog.related(to: product)
        XCTAssertFalse(related.contains(product))
        XCTAssertLessThanOrEqual(related.count, 6)
    }

    func testStoresOffersAndCategoriesDecode() {
        let bundle = Bundle(for: AppState.self)
        let locator = StoreLocator.load(bundle: bundle, defaults: UserDefaults(suiteName: "CatalogTests.stores")!)
        XCTAssertGreaterThanOrEqual(locator.stores.count, 6)
        XCTAssertEqual(Set(locator.stores.map(\.brandInfo)), Set(Brand.allCases))
        XCTAssertEqual(locator.stores.map(\.distanceKm), locator.stores.map(\.distanceKm).sorted())

        let offers = Offer.load(bundle: bundle)
        XCTAssertGreaterThanOrEqual(offers.count, 5)
        XCTAssertTrue(offers.contains { $0.code == "YOURS" })

        XCTAssertFalse(catalog.categories(for: .gap, department: "women").isEmpty)
        XCTAssertEqual(catalog.categories(for: .gap, department: "women").first?.name, "Short Sleeve Tees")
    }
}
