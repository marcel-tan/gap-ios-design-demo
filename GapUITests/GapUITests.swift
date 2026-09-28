import XCTest

final class GapUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-skipOnboarding", "-resetState"]
        app.launch()
    }

    private func wait(_ element: XCUIElement, timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(element) did not appear", file: file, line: line)
    }

    private func scrollTo(_ element: XCUIElement, in container: XCUIElement, maxSwipes: Int = 8) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < maxSwipes {
            container.swipeUp(velocity: .slow)
            swipes += 1
        }
    }

    private func openWomensTees() {
        app.buttons["tab-shop"].tap()
        wait(app.element("shop-dept-women"))
        app.element("shop-dept-women").tap()
        wait(app.element("category-women-tees"))
        app.element("category-women-tees").tap()
        wait(app.staticTexts["plp-count"])
    }

    private func firstProductCard() -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'product-card-'")).firstMatch
    }

    private func openFirstPDP() {
        let card = firstProductCard()
        wait(card)
        card.tap()
        wait(app.buttons["pdp-add-to-bag"])
    }

    private func addFirstAvailableSizeToBag() {
        let sizes = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pdp-size-' AND isEnabled == 1"))
        let addToBag = app.buttons["pdp-add-to-bag"]
        scrollTo(addToBag, in: app.scrollViews.firstMatch)
        if sizes.count > 0 {
            sizes.element(boundBy: 0).tap()
        }
        addToBag.tap()
    }

    // MARK: - Tests

    func testOnboardingShowsOnFreshInstallAndCanBeSkipped() {
        app.terminate()
        app.launchArguments = ["-uiTesting", "-resetOnboarding"]
        app.launch()
        wait(app.element("onboarding"))
        wait(app.buttons["onboarding-skip"])
        app.buttons["onboarding-skip"].tap()
        wait(app.element("home"))
        XCTAssertTrue(app.element("wordmark").exists)
    }

    func testHomeShowsEncoreGreetingAndFiveTabs() {
        wait(app.element("home"))
        wait(app.element("home-encore"))
        for tab in ["tab-home", "tab-shop", "tab-offers", "tab-bag", "tab-account"] {
            XCTAssertTrue(app.buttons[tab].exists, tab)
        }
        XCTAssertTrue(app.staticTexts["Good morning, Gwenyth"].exists
                      || app.staticTexts["Good afternoon, Gwenyth"].exists
                      || app.staticTexts["Good evening, Gwenyth"].exists)
    }

    func testBrandSwitcherChangesStorefront() {
        wait(app.buttons["brand-switcher"])
        app.buttons["brand-switcher"].tap()
        wait(app.buttons["brand-oldnavy"])
        app.buttons["brand-oldnavy"].tap()
        wait(app.element("home"))
        app.buttons["tab-shop"].tap()
        wait(app.staticTexts["Shop All Old Navy"])
        app.buttons["shop-change-brand"].tap()
        wait(app.buttons["brand-gap"])
        app.buttons["brand-gap"].tap()
        wait(app.staticTexts["Shop All Gap"])
    }

    func testWomensShortSleeveTeesListingOpensProductDetail() {
        openWomensTees()
        XCTAssertTrue(app.staticTexts["Short Sleeve Tees"].exists)
        XCTAssertTrue(app.staticTexts["plp-count"].label.hasSuffix("items"))
        openFirstPDP()
        XCTAssertTrue(app.staticTexts["pdp-name"].exists)
        XCTAssertTrue(app.element("pdp-price").exists)
        let swatches = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pdp-color-'"))
        XCTAssertEqual(swatches.count, 5, "each tee style carries five colours on the PDP")
    }

    func testSortMenuChangesOrderAndFilterSheetApplies() {
        openWomensTees()
        app.buttons["plp-sort"].tap()
        wait(app.buttons["Price: High to Low"])
        app.buttons["Price: High to Low"].tap()
        wait(app.staticTexts["plp-count"])
        app.buttons["plp-filter"].tap()
        wait(app.element("filter-sheet"))
        app.element("filter-sheet").swipeUp()
        let saleToggle = app.switches["filter-sale"]
        wait(saleToggle)
        saleToggle.tap()
        XCTAssertEqual(saleToggle.value as? String, "1")
        app.buttons["filter-apply"].tap()
        wait(app.staticTexts["plp-count"])
        XCTAssertFalse(app.element("filter-sheet").exists)
    }

    func testAddToBagRequiresSizeThenShowsItemAddedSheet() {
        openWomensTees()
        openFirstPDP()
        let addToBag = app.buttons["pdp-add-to-bag"]
        scrollTo(addToBag, in: app.scrollViews.firstMatch)
        addToBag.tap()
        wait(app.staticTexts["pdp-size-error"])
        addFirstAvailableSizeToBag()
        wait(app.element("added-to-bag-sheet"))
        app.buttons["added-view-bag"].tap()
        wait(app.element("bag"))
        XCTAssertTrue(app.staticTexts["summary-total"].exists)
    }

    func testPromoCodeDiscountsBagAndCheckoutCompletesWithMatchingTotals() {
        openWomensTees()
        openFirstPDP()
        addFirstAvailableSizeToBag()
        wait(app.buttons["added-view-bag"])
        app.buttons["added-view-bag"].tap()
        wait(app.element("bag"))

        let totalBefore = app.staticTexts["summary-total"].label
        let promo = app.textFields["promo-field"]
        scrollTo(promo, in: app.scrollViews.firstMatch)
        promo.tap()
        promo.typeText("YOURS")
        app.buttons["promo-apply"].tap()
        wait(app.staticTexts["promo-applied"])
        wait(app.staticTexts["summary-discount"])
        let totalAfter = app.staticTexts["summary-total"].label
        XCTAssertNotEqual(totalBefore, totalAfter, "applying a 30% promo changes the total")

        app.buttons["bag-checkout"].tap()
        wait(app.element("checkout"))
        XCTAssertEqual(app.staticTexts["summary-total"].label, totalAfter)
        XCTAssertTrue(app.staticTexts["summary-discount"].exists)
        let placeOrder = app.buttons["checkout-place-order"]
        XCTAssertTrue(placeOrder.label.contains(totalAfter))
        placeOrder.tap()

        wait(app.element("confirmation"))
        XCTAssertTrue(app.staticTexts["confirmation-number"].label.hasPrefix("Order #GP"))
        XCTAssertTrue(app.staticTexts["confirmation-points"].exists)
        XCTAssertEqual(app.staticTexts["summary-total"].label, totalAfter, "confirmation charges the discounted total")

        app.buttons["confirmation-history"].tap()
        wait(app.element("purchase-history"))
        let historyTotal = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'order-total-'")).firstMatch
        wait(historyTotal)
        XCTAssertTrue(historyTotal.label.hasSuffix(totalAfter))
    }

    func testBagQuantityStepperAndRemove() {
        openWomensTees()
        openFirstPDP()
        addFirstAvailableSizeToBag()
        wait(app.buttons["added-view-bag"])
        app.buttons["added-view-bag"].tap()
        wait(app.element("bag"))
        let plus = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'qty-plus-'")).firstMatch
        plus.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'qty-' AND label == '2'")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["bag-badge"].exists || app.staticTexts["bag-badge"].exists)
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'line-remove-'")).firstMatch.tap()
        wait(app.element("bag-empty"))
    }

    func testSearchFindsJeans() {
        wait(app.buttons["header-search"])
        app.buttons["header-search"].tap()
        wait(app.textFields["search-field"])
        app.textFields["search-field"].typeText("jeans\n")
        wait(app.staticTexts["plp-count"])
        XCTAssertTrue(app.staticTexts["plp-count"].label.hasSuffix("items"))
        openFirstPDP()
        XCTAssertTrue(app.staticTexts["pdp-name"].label.localizedCaseInsensitiveContains("jean"))
    }

    func testWishlistHeartPersistsAcrossRelaunch() {
        openWomensTees()
        openFirstPDP()
        let name = app.staticTexts["pdp-name"].label
        let heart = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'heart-'")).firstMatch
        heart.tap()
        app.terminate()
        app.launchArguments = ["-uiTesting", "-skipOnboarding"]
        app.launch()
        wait(app.buttons["header-wishlist"])
        app.buttons["header-wishlist"].tap()
        wait(app.element("wishlist"))
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'wishlist-remove-'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Your wishlist is empty"].waitForExistence(timeout: 5))
    }

    func testOffersApplyCodeToBag() {
        app.buttons["tab-offers"].tap()
        wait(app.element("offers"))
        let apply = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'offer-apply-'")).firstMatch
        wait(apply)
        apply.tap()
        wait(app.staticTexts["toast"])
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == 'Applied'")).firstMatch.waitForExistence(timeout: 3))
    }

    func testAccountShowsEncoreAndNavigates() {
        app.buttons["tab-account"].tap()
        wait(app.element("account"))
        XCTAssertTrue(app.staticTexts["account-greeting"].label.hasSuffix("Gwenyth"))
        XCTAssertEqual(app.staticTexts["account-points"].label, "2,124")
        XCTAssertTrue(app.staticTexts["Premier Member"].exists)
        app.buttons["account-purchase-history"].tap()
        wait(app.element("purchase-history"))
        XCTAssertTrue(app.staticTexts["No orders yet"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        wait(app.buttons["account-encore-market"])
        app.buttons["account-encore-market"].tap()
        wait(app.element("encore-market"))
        XCTAssertTrue(app.buttons["market-reward-5"].exists)
    }

    func testStoreLocatorFiltersAndSetsPreferredStore() {
        app.buttons["tab-account"].tap()
        wait(app.buttons["account-my-store"])
        app.buttons["account-my-store"].tap()
        wait(app.element("store-locator"))
        wait(app.staticTexts["store-count"])
        let allCount = app.staticTexts["store-count"].label
        app.buttons["store-filter-athleta"].tap()
        XCTAssertNotEqual(app.staticTexts["store-count"].label, allCount)
        app.buttons["store-filter-all"].tap()
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'store-row-'")).firstMatch
        wait(row)
        row.tap()
        let setPreferred = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'store-set-preferred-'")).firstMatch
        wait(setPreferred)
        setPreferred.tap()
        XCTAssertTrue(app.staticTexts["My Store"].waitForExistence(timeout: 3))
    }

    // MARK: - Golden path (PRD §5): fall outfit → FALL25 → pickup at Gap Sainte-Catherine → confirmation → history

    private func addToBag(size: String) {
        let sizeChip = app.buttons["pdp-size-\(size)"]
        scrollTo(sizeChip, in: app.scrollViews.firstMatch)
        sizeChip.tap()
        let addToBag = app.buttons["pdp-add-to-bag"]
        scrollTo(addToBag, in: app.scrollViews.firstMatch)
        addToBag.tap()
        wait(app.element("added-to-bag-sheet"))
    }

    func testFallOutfitGoldenPathEndsInPickupOrderAndPurchaseHistory() {
        // S02 Home: greeting + "Build your fall outfit" rail
        wait(app.element("home-encore"))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Gwenyth'")).firstMatch.exists)
        let cardigan = app.element("home-outfit-gap-800546")
        scrollTo(cardigan, in: app.scrollViews.firstMatch)
        cardigan.tap()

        // S06 PDP: CashSoft Crop Cardigan, Modern Red, size M
        wait(app.element("pdp-gap-800546"))
        XCTAssertEqual(app.staticTexts["pdp-color-name"].label, "Modern Red")
        XCTAssertTrue(app.element("pdp-pickup").exists || app.buttons["pdp-pickup"].exists)
        addToBag(size: "M")
        app.buttons["added-continue"].tap()

        // Back to the outfit rail for the '90s jeans
        app.navigationBars.buttons.firstMatch.tap()
        let jeans = app.element("home-outfit-gap-815642")
        scrollTo(jeans, in: app.scrollViews.firstMatch)
        jeans.tap()
        wait(app.element("pdp-gap-815642"))
        addToBag(size: "28")
        app.buttons["added-continue"].tap()
        app.navigationBars.buttons.firstMatch.tap()

        // S14 Search: Icon Denim Jacket
        wait(app.buttons["header-search"])
        app.buttons["header-search"].tap()
        let field = app.textFields["search-field"]
        wait(field)
        field.tap()
        field.typeText("Icon Denim Jacket\n")
        let jacket = app.element("product-card-gap-797118")
        wait(jacket)
        jacket.tap()
        wait(app.element("pdp-gap-797118"))
        addToBag(size: "M")
        app.buttons["added-view-bag"].tap()

        // S08 Bag: three lines, FALL25
        wait(app.element("bag"))
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'bag-line-'")).count, 3)
        let promo = app.textFields["promo-field"]
        scrollTo(promo, in: app.scrollViews.firstMatch)
        promo.tap()
        promo.typeText("FALL25")
        app.buttons["promo-apply"].tap()
        wait(app.staticTexts["promo-applied"])
        XCTAssertEqual(app.staticTexts["summary-discount"].label, "-$59.96")
        XCTAssertEqual(app.staticTexts["summary-total"].label, "$194.28")
        app.buttons["bag-checkout"].tap()

        // S09 Checkout: pickup at Gap Sainte-Catherine, saved Gap card
        wait(app.element("checkout"))
        XCTAssertEqual(app.staticTexts["checkout-pickup-store"].label, "Gap Sainte-Catherine")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '4021'")).firstMatch.exists)
        XCTAssertEqual(app.staticTexts["summary-total"].label, "$194.28")
        let placeOrder = app.buttons["checkout-place-order"]
        XCTAssertTrue(placeOrder.label.contains("$194.28"))
        placeOrder.tap()

        // S11 Confirmation: order number, +194 Encore points, pickup store
        wait(app.element("confirmation"))
        XCTAssertTrue(app.staticTexts["confirmation-number"].label.hasPrefix("Order #GP"))
        XCTAssertTrue(app.element("confirmation-points").label.contains("+194 points"))
        XCTAssertEqual(app.staticTexts["confirmation-store"].label, "Gap Sainte-Catherine")
        XCTAssertEqual(app.staticTexts["summary-total"].label, "$194.28")

        // S12 Purchase history shows the order
        app.buttons["confirmation-history"].tap()
        wait(app.element("purchase-history"))
        let historyTotal = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'order-total-'")).firstMatch
        wait(historyTotal)
        XCTAssertTrue(historyTotal.label.hasSuffix("$194.28"))
    }

    func testSeedBagLaunchArgumentPreloadsOutfitAndFigmaOverlayShowsNodeIDs() {
        app.launchArguments = ["-uiTesting", "-skipOnboarding", "-resetState", "-seedBag", "-figmaOverlay"]
        app.launch()
        wait(app.element("home"))
        XCTAssertEqual(app.element("home").value as? String, "figma:17:730")
        XCTAssertTrue(app.staticTexts["17:730"].exists, "-figmaOverlay shows the Figma node badge")
        app.buttons["tab-bag"].tap()
        wait(app.element("bag"))
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'bag-line-'")).count, 3)
        XCTAssertEqual(app.staticTexts["summary-total"].label, "$259.04", "239.85 + 8% tax, pickup, no promo")
    }
}
