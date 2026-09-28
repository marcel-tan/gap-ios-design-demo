import XCTest

/// Walks every screen and writes a PNG per stop. Not a regression test — run via
/// `scripts/capture-screenshots.sh`, which sets `TEST_RUNNER_SCREENSHOT_DIR`.
final class ScreenshotTourTests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !dir.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_SCREENSHOT_DIR to run the screenshot tour")
        }
        outputDirectory = URL(fileURLWithPath: dir, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetOnboarding", "-resetState"]
        app.launch()
    }

    func testTour() {
        XCTAssertTrue(app.buttons["onboarding-skip"].waitForExistence(timeout: 8))
        settle(2); snap("01-onboarding")
        app.buttons["onboarding-skip"].tap()

        XCTAssertTrue(app.element("home").waitForExistence(timeout: 8))
        settle(4); snap("02-home")
        app.buttons["brand-switcher"].tap()
        XCTAssertTrue(app.element("brand-switcher-sheet").waitForExistence(timeout: 5))
        settle(1); snap("03-brand-switcher")
        app.buttons["brand-gap"].tap(); settle(1)

        app.buttons["tab-shop"].tap()
        XCTAssertTrue(app.element("shop-dept-women").waitForExistence(timeout: 5))
        settle(1); snap("04-shop")
        app.element("shop-dept-women").tap()
        XCTAssertTrue(app.element("category-women-tees").waitForExistence(timeout: 5))
        app.element("category-women-tees").tap()
        XCTAssertTrue(app.staticTexts["plp-count"].waitForExistence(timeout: 5))
        settle(4); snap("05-plp-womens-tees")
        app.buttons["plp-filter"].tap()
        XCTAssertTrue(app.element("filter-sheet").waitForExistence(timeout: 5))
        settle(1); snap("05b-plp-filter")
        app.buttons["filter-apply"].tap(); settle(0.5)

        let card = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'product-card-'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let addToBag = app.buttons["pdp-add-to-bag"]
        XCTAssertTrue(addToBag.waitForExistence(timeout: 5))
        settle(4); snap("06-pdp")
        let sizes = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pdp-size-' AND isEnabled == 1"))
        scroll(to: addToBag)
        if sizes.count > 0 { sizes.element(boundBy: 0).tap() }
        settle(0.8); snap("06b-pdp-sizes")
        addToBag.tap()
        XCTAssertTrue(app.element("added-to-bag-sheet").waitForExistence(timeout: 5))
        settle(2.5); snap("07-item-added")
        app.buttons["added-view-bag"].tap()

        XCTAssertTrue(app.element("bag").waitForExistence(timeout: 5))
        let promo = app.textFields["promo-field"]
        scroll(to: promo)
        promo.tap(); promo.typeText("YOURS")
        app.buttons["promo-apply"].tap()
        XCTAssertTrue(app.staticTexts["promo-applied"].waitForExistence(timeout: 5))
        settle(2); snap("08-bag-promo")
        app.buttons["bag-checkout"].tap()
        XCTAssertTrue(app.element("checkout").waitForExistence(timeout: 5))
        settle(2); snap("09-checkout")
        let placeOrder = app.buttons["checkout-place-order"]
        scroll(to: placeOrder)
        placeOrder.tap()
        XCTAssertTrue(app.element("confirmation").waitForExistence(timeout: 8))
        settle(1.5); snap("10-confirmation")
        app.buttons["confirmation-continue"].tap(); settle(0.5)

        app.buttons["tab-offers"].tap()
        XCTAssertTrue(app.element("offers").waitForExistence(timeout: 5))
        settle(3); snap("11-offers")

        app.buttons["tab-account"].tap()
        XCTAssertTrue(app.element("account").waitForExistence(timeout: 5))
        settle(1.5); snap("12-account")
        app.buttons["account-purchase-history"].tap()
        XCTAssertTrue(app.element("purchase-history").waitForExistence(timeout: 5))
        settle(1); snap("12b-purchase-history")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["account-encore-market"].waitForExistence(timeout: 5))
        app.buttons["account-encore-market"].tap()
        XCTAssertTrue(app.element("encore-market").waitForExistence(timeout: 5))
        settle(1); snap("12c-encore-market")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["account-my-store"].waitForExistence(timeout: 5))
        app.buttons["account-my-store"].tap()
        XCTAssertTrue(app.element("store-locator").waitForExistence(timeout: 5))
        settle(4); snap("13-store-locator")

        app.buttons["tab-home"].tap()
        XCTAssertTrue(app.buttons["header-search"].waitForExistence(timeout: 5))
        app.buttons["header-search"].tap()
        XCTAssertTrue(app.textFields["search-field"].waitForExistence(timeout: 5))
        settle(1); snap("14-search")
        app.textFields["search-field"].typeText("tee\n")
        XCTAssertTrue(app.staticTexts["plp-count"].waitForExistence(timeout: 5))
        settle(4); snap("14b-search-results")
    }

    private func scroll(to element: XCUIElement, maxSwipes: Int = 8) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < maxSwipes {
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
            swipes += 1
        }
    }

    private func settle(_ seconds: TimeInterval = 0.6) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    private func snap(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let url = outputDirectory.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: url)
        } catch {
            XCTFail("Could not write \(url.path): \(error)")
        }
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
