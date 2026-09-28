import XCTest
@testable import Gap

final class CartStoreTests: XCTestCase {
    private func product(id: String = "p1", price: Decimal, salePrice: Decimal? = nil, colors: Int = 2) -> Product {
        Product(
            id: id, brand: "gap", name: "Test \(id)", category: "tees", department: "women",
            price: price, salePrice: salePrice, isNew: false, rating: 4.5, reviewCount: 10,
            description: "", details: [], fabric: "",
            colors: (0..<colors).map { ProductColor(id: "c\($0)", name: "Colour \($0)", hex: "112233", imageURLs: [URL(string: "https://example.com/\(id)-\($0).jpg")!]) },
            sizes: [ProductSize(label: "S", available: true), ProductSize(label: "M", available: false)]
        )
    }

    func testAddMergesSameProductColourAndSize() {
        let cart = CartStore()
        let p = product(price: 20)
        cart.add(p, size: "S")
        cart.add(p, size: "S")
        cart.add(p, size: "M")
        cart.add(p, color: p.colors[1], size: "S")
        XCTAssertEqual(cart.lines.count, 3)
        XCTAssertEqual(cart.lines[0].quantity, 2)
        XCTAssertEqual(cart.itemCount, 4)
        XCTAssertEqual(cart.subtotal, 80)
    }

    func testQuantityIsClampedBetweenOneAndTen() {
        let cart = CartStore()
        let line = cart.add(product(price: 10))!
        cart.setQuantity(25, for: line.id)
        XCTAssertEqual(cart.lines[0].quantity, CartStore.maxQuantityPerLine)
        cart.increment(line.id)
        XCTAssertEqual(cart.lines[0].quantity, 10)
        cart.setQuantity(1, for: line.id)
        cart.decrement(line.id)
        XCTAssertEqual(cart.lines[0].quantity, 1, "decrement never removes a line")
        cart.setQuantity(0, for: line.id)
        XCTAssertTrue(cart.isEmpty)
    }

    func testRemoveAndClear() {
        let cart = CartStore()
        let a = cart.add(product(id: "a", price: 10))!
        cart.add(product(id: "b", price: 10))
        cart.applyPromo("YOURS")
        cart.remove(a.id)
        XCTAssertEqual(cart.lines.map(\.product.id), ["b"])
        cart.clear()
        XCTAssertTrue(cart.isEmpty)
        XCTAssertNil(cart.promo)
    }

    func testSalePriceIsUsedForLineTotals() {
        let cart = CartStore()
        cart.add(product(price: Decimal(string: "59.95")!, salePrice: Decimal(string: "39.99")!), quantity: 2)
        XCTAssertEqual(cart.subtotal, Decimal(string: "79.98"))
    }

    func testShippingIsFreeAtThreshold() {
        let cart = CartStore()
        cart.add(product(price: Decimal(string: "49.99")!))
        XCTAssertEqual(cart.summary.shipping, CheckoutSummary.standardShipping)
        cart.add(product(id: "p2", price: Decimal(string: "0.01")!))
        XCTAssertEqual(cart.summary.shipping, 0)
        XCTAssertEqual(CartStore().summary.shipping, 0, "empty bag never charges shipping")
    }

    func testTotalsWithoutPromo() {
        let cart = CartStore()
        cart.add(product(price: Decimal(string: "79.95")!))
        let s = cart.summary
        XCTAssertEqual(s.subtotal, Decimal(string: "79.95"))
        XCTAssertEqual(s.discount, 0)
        XCTAssertEqual(s.shipping, 0)
        XCTAssertEqual(s.estimatedTax, Decimal(string: "6.40"))
        XCTAssertEqual(s.total, Decimal(string: "86.35"))
        XCTAssertEqual(s.pointsEarned, 86)
    }

    func testPercentPromoReducesSubtotalTaxAndTotal() {
        let cart = CartStore()
        cart.add(product(price: 100))
        XCTAssertTrue(cart.applyPromo(" yours "))
        let s = cart.summary
        XCTAssertEqual(s.promo?.code, "YOURS")
        XCTAssertEqual(s.discount, 30)
        XCTAssertEqual(s.discountedSubtotal, 70)
        XCTAssertEqual(s.estimatedTax, Decimal(string: "5.60"), "tax is computed on the discounted subtotal")
        XCTAssertEqual(s.total, Decimal(string: "75.60"))
        XCTAssertEqual(s.total, s.subtotal - s.discount + s.shipping + s.estimatedTax)
    }

    func testFreeShippingPromoOnlyRemovesShipping() {
        let cart = CartStore()
        cart.add(product(price: 20))
        XCTAssertEqual(cart.summary.shipping, 7)
        cart.applyPromo("SHIPFREE")
        let s = cart.summary
        XCTAssertEqual(s.shipping, 0)
        XCTAssertEqual(s.discount, 0)
        XCTAssertEqual(s.total, Decimal(string: "21.60"))
    }

    func testUnknownPromoIsRejectedAndKeepsExistingCode() {
        let cart = CartStore()
        cart.add(product(price: 20))
        cart.applyPromo("ENCORE20")
        XCTAssertFalse(cart.applyPromo("NOPE"))
        XCTAssertEqual(cart.promo?.code, "ENCORE20")
        cart.removePromo()
        XCTAssertNil(cart.promo)
    }

    func testDiscountRoundsToCents() {
        let cart = CartStore()
        cart.add(product(price: Decimal(string: "19.99")!))
        cart.applyPromo("YOURS")
        XCTAssertEqual(cart.summary.discount, Decimal(string: "6.00"))
        XCTAssertEqual(cart.summary.estimatedTax, Decimal(string: "1.12"))
    }

    func testCheckoutRecordsOrderWithChargedTotalAndEmptiesBag() {
        let cart = CartStore()
        cart.add(product(price: 100), size: "S")
        cart.applyPromo("YOURS")
        let expected = cart.summary
        let order = cart.checkout(shippingName: "Gwenyth", fulfillment: .ship(address: "Montréal"), now: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertNotNil(order)
        XCTAssertEqual(order?.summary, expected)
        XCTAssertEqual(order?.total, Decimal(string: "75.60"))
        XCTAssertEqual(order?.summary.pointsEarned, 75)
        XCTAssertEqual(order?.number, "GP00000000")
        XCTAssertEqual(order?.lines.count, 1)
        XCTAssertTrue(cart.isEmpty)
        XCTAssertNil(cart.promo)
        XCTAssertEqual(cart.orders.first, order)
    }

    func testCheckoutOnEmptyBagReturnsNil() {
        XCTAssertNil(CartStore().checkout(shippingName: "x", fulfillment: .ship(address: "y")))
    }

    // MARK: - Golden path (PRD §6 pricing example)

    private var fallOutfit: [Product] {
        [product(id: "gap-800546", price: Decimal(string: "69.95")!),
         product(id: "gap-815642", price: Decimal(string: "79.95")!),
         product(id: "gap-797118", price: Decimal(string: "89.95")!)]
    }

    private var sainteCatherine: Store {
        Store(id: "gap-ste-catherine", brand: "gap", name: "Gap Sainte-Catherine", address: "1255 Rue Sainte-Catherine O",
              city: "Montréal, QC H3G 1P7", phone: "(514) 866-0670", latitude: 45.4995, longitude: -73.5735,
              hours: "Mon–Sat 10am–9pm", services: ["Buy Online, Pick Up In Store"], distanceKm: 0.8)
    }

    func testFallOutfitWithFALL25AndPickupMatchesPRDPricing() {
        let cart = CartStore()
        cart.prefersPickup = true
        fallOutfit.forEach { cart.add($0, size: "M") }
        XCTAssertTrue(cart.applyPromo("fall25"))
        let s = cart.summary
        XCTAssertEqual(s.itemCount, 3)
        XCTAssertEqual(s.subtotal, Decimal(string: "239.85"))
        XCTAssertEqual(s.discount, Decimal(string: "59.96"))
        XCTAssertEqual(s.shipping, 0, "pickup is always free")
        XCTAssertEqual(s.estimatedTax, Decimal(string: "14.39"))
        XCTAssertEqual(s.total, Decimal(string: "194.28"))
        XCTAssertEqual(s.pointsEarned, 194)
    }

    func testPickupWaivesShippingBelowThreshold() {
        let cart = CartStore()
        cart.add(product(price: 20))
        XCTAssertEqual(cart.summary.shipping, CheckoutSummary.standardShipping)
        cart.prefersPickup = true
        XCTAssertEqual(cart.summary.shipping, 0)
        XCTAssertTrue(cart.summary.isPickup)
    }

    func testCheckoutForPickupRecordsStoreAndReadyLabel() {
        let cart = CartStore()
        fallOutfit.forEach { cart.add($0, size: "M") }
        cart.applyPromo("FALL25")
        let order = cart.checkout(shippingName: "Gwenyth Paltrow-Lee", fulfillment: .pickup(store: sainteCatherine), now: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(order?.fulfillment.store?.id, "gap-ste-catherine")
        XCTAssertEqual(order?.total, Decimal(string: "194.28"))
        XCTAssertEqual(order?.summary.pointsEarned, 194)
        XCTAssertNotNil(order?.pickupReadyLabel)
        XCTAssertTrue(order?.shippingAddress.hasPrefix("Pickup at Gap Sainte-Catherine") ?? false)
        XCTAssertTrue(cart.isEmpty)
    }

    func testBagPromoAndOrdersPersistAcrossInstances() {
        let suite = "CartStoreTests.persistence"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let cart = CartStore(defaults: defaults)
        XCTAssertTrue(cart.prefersPickup, "first launch defaults to pickup")
        fallOutfit.forEach { cart.add($0, size: "M") }
        cart.applyPromo("FALL25")
        cart.prefersPickup = false

        let restored = CartStore(defaults: defaults)
        XCTAssertEqual(restored.lines, cart.lines)
        XCTAssertEqual(restored.promo?.code, "FALL25")
        XCTAssertFalse(restored.prefersPickup)
        XCTAssertEqual(restored.total, cart.total)

        restored.checkout(shippingName: "Gwenyth", fulfillment: .pickup(store: sainteCatherine))
        let afterOrder = CartStore(defaults: defaults)
        XCTAssertTrue(afterOrder.isEmpty)
        XCTAssertNil(afterOrder.promo)
        XCTAssertEqual(afterOrder.orders.count, 1)
        XCTAssertEqual(afterOrder.orders.first?.fulfillment.store?.name, "Gap Sainte-Catherine")
        defaults.removePersistentDomain(forName: suite)
    }
}

final class EncoreAccountTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "EncoreAccountTests")
        defaults.removePersistentDomain(forName: "EncoreAccountTests")
    }

    func testDefaultsToPremierMemberWithBasePoints() {
        let account = EncoreAccount(defaults: defaults)
        XCTAssertEqual(account.firstName, "Gwenyth")
        XCTAssertEqual(account.tier, "Premier Member")
        XCTAssertEqual(account.points, 2124)
        XCTAssertEqual(account.pointsLabel, "2,124")
        XCTAssertEqual(account.pointsToNextReward, 376)
    }

    func testEarnPersists() {
        let account = EncoreAccount(defaults: defaults)
        account.earn(86)
        XCTAssertEqual(account.points, 2210)
        XCTAssertEqual(EncoreAccount(defaults: defaults).points, 2210)
        account.reset()
        XCTAssertEqual(account.points, 2124)
    }

    func testGreetingByTimeOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func at(_ hour: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: hour))!
        }
        XCTAssertEqual(Greeting.text(for: at(8), calendar: calendar), "Good morning")
        XCTAssertEqual(Greeting.text(for: at(14), calendar: calendar), "Good afternoon")
        XCTAssertEqual(Greeting.text(for: at(20), calendar: calendar), "Good evening")
    }
}
