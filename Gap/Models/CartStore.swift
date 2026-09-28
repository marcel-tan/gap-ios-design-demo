import Foundation
import Observation

struct CartLine: Identifiable, Hashable, Codable {
    let id: String
    let product: Product
    let color: ProductColor
    let size: String?
    var quantity: Int

    init(product: Product, color: ProductColor, size: String?, quantity: Int = 1) {
        self.id = CartLine.key(product: product, color: color, size: size)
        self.product = product
        self.color = color
        self.size = size
        self.quantity = quantity
    }

    static func key(product: Product, color: ProductColor, size: String?) -> String {
        "\(product.id)|\(color.id)|\(size ?? "-")"
    }

    var unitPrice: Decimal { product.effectivePrice }
    var lineTotal: Decimal { unitPrice * Decimal(quantity) }
}

/// A promo code the bag accepts. Discounts apply to the merchandise subtotal.
struct PromoCode: Hashable, Identifiable, Codable {
    enum Kind: Hashable, Codable {
        case percentOff(Int)
        case freeShipping
    }

    let code: String
    let kind: Kind
    let description: String

    var id: String { code }

    static let fall25 = PromoCode(code: "FALL25", kind: .percentOff(25), description: "25% off your fall outfit")

    static let all: [PromoCode] = [
        fall25,
        PromoCode(code: "YOURS", kind: .percentOff(30), description: "Extra 30% off your order"),
        PromoCode(code: "ENCORE20", kind: .percentOff(20), description: "Encore members save 20%"),
        PromoCode(code: "SHIPFREE", kind: .freeShipping, description: "Free standard shipping"),
    ]

    static func lookup(_ raw: String) -> PromoCode? {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return all.first { $0.code == code }
    }
}

/// How the order reaches the shopper. Pickup is always free; shipping follows the $50 threshold.
enum Fulfillment: Hashable, Codable {
    case ship(address: String)
    case pickup(store: Store)

    var isPickup: Bool {
        if case .pickup = self { return true }
        return false
    }

    var store: Store? {
        if case .pickup(let store) = self { return store }
        return nil
    }

    /// One-line description for Confirmation and Purchase History.
    var label: String {
        switch self {
        case .ship(let address): return "Shipping to \(address)"
        case .pickup(let store): return "Pickup at \(store.name) · \(store.address), \(store.city)"
        }
    }
}

/// Immutable snapshot of every number the Bag, Checkout and Confirmation screens display.
struct CheckoutSummary: Hashable, Codable {
    static let freeShippingThreshold: Decimal = 50
    static let standardShipping: Decimal = 7
    static let taxRate: Decimal = 0.08

    let itemCount: Int
    let subtotal: Decimal
    let discount: Decimal
    let shipping: Decimal
    let estimatedTax: Decimal
    let promo: PromoCode?
    let isPickup: Bool

    var discountedSubtotal: Decimal { subtotal - discount }
    var total: Decimal { discountedSubtotal + shipping + estimatedTax }
    /// Encore earns one point per whole dollar charged.
    var pointsEarned: Int { NSDecimalNumber(decimal: total).intValue }

    init(lines: [CartLine], promo: PromoCode?, isPickup: Bool = false) {
        itemCount = lines.reduce(0) { $0 + $1.quantity }
        subtotal = lines.reduce(0) { $0 + $1.lineTotal }
        self.promo = promo
        self.isPickup = isPickup

        var discount: Decimal = 0
        var shipping: Decimal = subtotal >= CheckoutSummary.freeShippingThreshold || subtotal == 0 || isPickup ? 0 : CheckoutSummary.standardShipping
        switch promo?.kind {
        case .percentOff(let percent):
            discount = CheckoutSummary.round(subtotal * Decimal(percent) / 100)
        case .freeShipping:
            shipping = 0
        case nil:
            break
        }
        self.discount = discount
        self.shipping = shipping
        estimatedTax = CheckoutSummary.round((subtotal - discount) * CheckoutSummary.taxRate)
    }

    static func round(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .bankers)
        return output
    }
}

struct Order: Identifiable, Hashable, Codable {
    let id: String
    let number: String
    let placedAt: Date
    let lines: [CartLine]
    let summary: CheckoutSummary
    let shippingName: String
    let fulfillment: Fulfillment

    var itemCount: Int { summary.itemCount }
    var total: Decimal { summary.total }
    /// Legacy accessor kept for rows that only show a one-line destination.
    var shippingAddress: String { fulfillment.label }
    var pickupReadyLabel: String? {
        fulfillment.isPickup ? "Ready for pickup today by 6 pm" : nil
    }
}

/// The bag. Lines, promo, fulfillment choice and order history persist in `UserDefaults` (FR2) so
/// the demo survives relaunches; `-resetState` clears them.
@Observable
final class CartStore {
    static let maxQuantityPerLine = 10
    static let minQuantityPerLine = 1
    static let linesKey = "bag.lines"
    static let promoKey = "bag.promo"
    static let ordersKey = "bag.orders"
    static let pickupKey = "bag.pickup"
    static let persistedKeys = [linesKey, promoKey, ordersKey, pickupKey]

    private(set) var lines: [CartLine] = [] { didSet { persist(lines, key: CartStore.linesKey) } }
    private(set) var orders: [Order] = [] { didSet { persist(orders, key: CartStore.ordersKey) } }
    private(set) var promo: PromoCode? { didSet { persist(promo, key: CartStore.promoKey) } }
    /// Checkout defaults to in-store pickup (the golden path); toggled from Checkout.
    var prefersPickup = false { didSet { defaults?.set(prefersPickup, forKey: CartStore.pickupKey) } }

    private let defaults: UserDefaults?

    /// `defaults: nil` gives a purely in-memory bag (unit tests).
    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
        guard let defaults else { return }
        lines = CartStore.decode([CartLine].self, from: defaults, key: CartStore.linesKey) ?? []
        orders = CartStore.decode([Order].self, from: defaults, key: CartStore.ordersKey) ?? []
        promo = CartStore.decode(PromoCode.self, from: defaults, key: CartStore.promoKey)
        prefersPickup = defaults.object(forKey: CartStore.pickupKey) == nil ? true : defaults.bool(forKey: CartStore.pickupKey)
    }

    var isEmpty: Bool { lines.isEmpty }
    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    func contains(_ product: Product) -> Bool { lines.contains { $0.product.id == product.id } }
    var summary: CheckoutSummary { CheckoutSummary(lines: lines, promo: promo, isPickup: prefersPickup) }
    var subtotal: Decimal { summary.subtotal }
    var total: Decimal { summary.total }

    @discardableResult
    func add(_ product: Product, color: ProductColor? = nil, size: String? = nil, quantity: Int = 1) -> CartLine? {
        guard quantity > 0, let color = color ?? product.primaryColor else { return nil }
        let key = CartLine.key(product: product, color: color, size: size)
        if let index = lines.firstIndex(where: { $0.id == key }) {
            lines[index].quantity = min(lines[index].quantity + quantity, CartStore.maxQuantityPerLine)
            return lines[index]
        }
        let line = CartLine(product: product, color: color, size: size, quantity: min(quantity, CartStore.maxQuantityPerLine))
        lines.append(line)
        return line
    }

    func setQuantity(_ quantity: Int, for lineID: CartLine.ID) {
        guard let index = lines.firstIndex(where: { $0.id == lineID }) else { return }
        if quantity <= 0 {
            lines.remove(at: index)
        } else {
            lines[index].quantity = min(max(quantity, CartStore.minQuantityPerLine), CartStore.maxQuantityPerLine)
        }
    }

    func increment(_ lineID: CartLine.ID) {
        guard let line = lines.first(where: { $0.id == lineID }) else { return }
        setQuantity(line.quantity + 1, for: lineID)
    }

    func decrement(_ lineID: CartLine.ID) {
        guard let line = lines.first(where: { $0.id == lineID }) else { return }
        setQuantity(max(line.quantity - 1, CartStore.minQuantityPerLine), for: lineID)
    }

    func remove(_ lineID: CartLine.ID) {
        lines.removeAll { $0.id == lineID }
    }

    func clear() {
        lines.removeAll()
        promo = nil
    }

    /// Returns false when the code is unknown; the bag keeps any previously applied code.
    @discardableResult
    func applyPromo(_ raw: String) -> Bool {
        guard let code = PromoCode.lookup(raw) else { return false }
        promo = code
        return true
    }

    func removePromo() {
        promo = nil
    }

    /// Demo checkout: records an order for Purchase History and empties the bag.
    @discardableResult
    func checkout(shippingName: String, fulfillment: Fulfillment, now: Date = Date()) -> Order? {
        guard !lines.isEmpty else { return nil }
        let number = String(format: "GP%08d", (Int(now.timeIntervalSince1970) % 10_000_000) * 10 + orders.count % 10)
        let order = Order(
            id: UUID().uuidString,
            number: number,
            placedAt: now,
            lines: lines,
            summary: CheckoutSummary(lines: lines, promo: promo, isPickup: fulfillment.isPickup),
            shippingName: shippingName,
            fulfillment: fulfillment
        )
        orders.insert(order, at: 0)
        lines.removeAll()
        promo = nil
        return order
    }

    // MARK: - Persistence

    private func persist<T: Encodable>(_ value: T?, key: String) {
        guard let defaults else { return }
        guard let value, let data = try? JSONEncoder().encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum PriceFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.roundingMode = .halfUp
        return f
    }()

    static func string(_ value: Decimal) -> String {
        formatter.string(from: value as NSDecimalNumber) ?? String(format: "$%.2f", NSDecimalNumber(decimal: value).doubleValue)
    }

    static func negative(_ value: Decimal) -> String {
        "-" + string(value)
    }
}
