import XCTest

extension XCUIApplication {
    /// Matches any element type — screen containers, sheets and rows expose identifiers as `Other`,
    /// while cards and rows that are buttons expose them as `Button`.
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
