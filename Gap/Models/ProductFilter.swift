import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case featured = "Featured"
    case newest = "New Arrivals"
    case priceLowHigh = "Price: Low to High"
    case priceHighLow = "Price: High to Low"
    case topRated = "Top Rated"

    var id: String { rawValue }

    var identifier: String {
        switch self {
        case .featured: return "featured"
        case .newest: return "newest"
        case .priceLowHigh: return "price-asc"
        case .priceHighLow: return "price-desc"
        case .topRated: return "rating"
        }
    }

    func sort(_ products: [Product]) -> [Product] {
        switch self {
        case .featured: return products
        case .newest: return products.stablySorted { $0.isNew && !$1.isNew }
        case .priceLowHigh: return products.stablySorted { $0.effectivePrice < $1.effectivePrice }
        case .priceHighLow: return products.stablySorted { $0.effectivePrice > $1.effectivePrice }
        case .topRated: return products.stablySorted { $0.rating > $1.rating }
        }
    }
}

/// Filter + sort state for a product listing.
struct ProductFilter: Hashable {
    var sort: SortOption = .featured
    var colors: Set<String> = []
    var sizes: Set<String> = []
    var onSaleOnly = false
    var minPrice: Decimal?
    var maxPrice: Decimal?

    var hasActiveFilters: Bool {
        !colors.isEmpty || !sizes.isEmpty || onSaleOnly || minPrice != nil || maxPrice != nil
    }

    var activeCount: Int {
        colors.count + sizes.count + (onSaleOnly ? 1 : 0) + (minPrice != nil || maxPrice != nil ? 1 : 0)
    }

    func matches(_ product: Product) -> Bool {
        if !colors.isEmpty, !product.colors.contains(where: { colors.contains(ProductFilter.colorFamily($0.name)) }) { return false }
        if !sizes.isEmpty, !product.sizes.contains(where: { $0.available && sizes.contains($0.label) }) { return false }
        if onSaleOnly, !product.isOnSale { return false }
        if let minPrice, product.effectivePrice < minPrice { return false }
        if let maxPrice, product.effectivePrice > maxPrice { return false }
        return true
    }

    func apply(to products: [Product]) -> [Product] {
        sort.sort(products.filter(matches))
    }

    mutating func clear() {
        self = ProductFilter(sort: sort)
    }

    // MARK: Facets

    static let families = ["Black", "White", "Blue", "Grey", "Green", "Red", "Pink", "Brown", "Beige", "Purple", "Yellow", "Orange", "Multi"]

    /// Collapses "Light Blue Indigo", "Medium Wash", "Heather Grey" … into a swatch family.
    static func colorFamily(_ name: String) -> String {
        let n = name.lowercased()
        let table: [(String, String)] = [
            ("black", "Black"), ("noir", "Black"), ("night", "Black"),
            ("white", "White"), ("ivory", "White"), ("cream", "White"), ("ecru", "White"), ("frost", "White"),
            ("wash", "Blue"), ("indigo", "Blue"), ("rinse", "Blue"), ("denim", "Blue"), ("blue", "Blue"), ("navy", "Blue"),
            ("grey", "Grey"), ("gray", "Grey"), ("charcoal", "Grey"), ("heather", "Grey"),
            ("green", "Green"), ("olive", "Green"), ("hunter", "Green"), ("sage", "Green"), ("palm", "Green"), ("khaki", "Beige"),
            ("red", "Red"), ("burgundy", "Red"), ("bordeaux", "Red"), ("wine", "Red"), ("cardinal", "Red"),
            ("pink", "Pink"), ("mauve", "Pink"), ("rose", "Pink"), ("blush", "Pink"),
            ("brown", "Brown"), ("mocha", "Brown"), ("camel", "Brown"), ("almond", "Brown"), ("truffle", "Brown"), ("umber", "Brown"),
            ("beige", "Beige"), ("tan", "Beige"), ("oatmeal", "Beige"), ("stone", "Beige"), ("sand", "Beige"),
            ("purple", "Purple"), ("lilac", "Purple"), ("dahlia", "Purple"), ("orchid", "Purple"),
            ("yellow", "Yellow"), ("maize", "Yellow"), ("gold", "Yellow"),
            ("orange", "Orange"), ("apricot", "Orange"), ("rust", "Orange"),
        ]
        for (needle, family) in table where n.contains(needle) { return family }
        return "Multi"
    }

    static func colorOptions(_ products: [Product]) -> [String] {
        let present = Set(products.flatMap { $0.colors.map { colorFamily($0.name) } })
        return families.filter(present.contains)
    }

    /// In-stock size labels only, ordered as they appear in the catalog.
    static func sizeOptions(_ products: [Product]) -> [String] {
        var seen: [String] = []
        for p in products {
            for s in p.sizes where s.available && !seen.contains(s.label) { seen.append(s.label) }
        }
        return seen
    }

    struct PriceBand: Hashable, Identifiable {
        let id: String
        let label: String
        let min: Decimal?
        let max: Decimal?
    }

    static let priceBands: [PriceBand] = [
        PriceBand(id: "under-25", label: "Under $25", min: nil, max: 24.99),
        PriceBand(id: "25-50", label: "$25 – $50", min: 25, max: 50),
        PriceBand(id: "50-100", label: "$50 – $100", min: 50.01, max: 100),
        PriceBand(id: "over-100", label: "Over $100", min: 100.01, max: nil),
    ]
}

extension Array {
    /// `sorted(by:)` is not guaranteed stable; keep catalog order for ties.
    func stablySorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        enumerated()
            .sorted { a, b in
                if areInIncreasingOrder(a.element, b.element) { return true }
                if areInIncreasingOrder(b.element, a.element) { return false }
                return a.offset < b.offset
            }
            .map(\.element)
    }
}

extension Set {
    mutating func toggleMember(_ member: Element) {
        if contains(member) { remove(member) } else { insert(member) }
    }
}
