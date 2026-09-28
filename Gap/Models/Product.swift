import Foundation

struct ProductColor: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let hex: String
    let imageURLs: [URL]
}

struct ProductSize: Codable, Hashable, Identifiable {
    let label: String
    let available: Bool
    var id: String { label }
}

struct Product: Codable, Hashable, Identifiable {
    let id: String
    let brand: String
    let name: String
    let category: String
    let department: String
    let price: Decimal
    let salePrice: Decimal?
    let isNew: Bool
    let rating: Double
    let reviewCount: Int
    let description: String
    let details: [String]
    let fabric: String
    let colors: [ProductColor]
    let sizes: [ProductSize]

    var effectivePrice: Decimal { salePrice ?? price }
    var isOnSale: Bool { salePrice != nil }
    var primaryColor: ProductColor? { colors.first }
    var brandInfo: Brand { Brand(rawValue: brand) ?? .gap }

    func color(id: String) -> ProductColor? {
        colors.first { $0.id == id }
    }

    var percentOff: Int? {
        guard let salePrice, price > 0 else { return nil }
        let ratio = ((price - salePrice) / price * 100) as NSDecimalNumber
        return Int(ratio.doubleValue.rounded())
    }
}

/// One tile in a product grid (PLP, Search). Carries the colorway whose hero image the tile shows.
struct ListingItem: Hashable, Identifiable {
    let product: Product
    let color: ProductColor

    var id: String { "\(product.id)|\(color.id)" }
}

struct CatalogFile: Codable {
    let products: [Product]
}
