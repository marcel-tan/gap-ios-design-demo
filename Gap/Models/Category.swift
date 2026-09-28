import Foundation

struct Department: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let symbol: String
}

struct Category: Codable, Hashable, Identifiable {
    let id: String
    let department: String
    let name: String
    let order: Int

    /// Unique across departments (the same `id` such as "tees" appears under Women and Men).
    var key: String { "\(department)/\(id)" }
}

/// Merchandised edit (e.g. the Fall Edit) — a curated, ordered list of product ids.
struct Collection: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let productIDs: [String]
}

struct CategoryFile: Codable {
    let departments: [Department]
    let categories: [Category]
    let collections: [Collection]?
}

/// The set of products a listing screen shows before filtering.
enum ListingScope: Hashable {
    case category(brand: Brand, department: String, category: String)
    case department(brand: Brand, department: String)
    case newArrivals(brand: Brand)
    case sale(brand: Brand)
    case all(brand: Brand)
    case collection(String)
    case search(String)

    var brand: Brand? {
        switch self {
        case .category(let brand, _, _), .department(let brand, _), .newArrivals(let brand), .sale(let brand), .all(let brand):
            return brand
        case .collection, .search:
            return nil
        }
    }

    /// Stable identifier used for accessibility hooks.
    var identifier: String {
        switch self {
        case .category(_, let department, let category): return "\(department)-\(category)"
        case .department(_, let department): return department
        case .newArrivals: return "new-arrivals"
        case .sale: return "sale"
        case .all: return "all"
        case .collection(let id): return "collection-\(id)"
        case .search: return "search"
        }
    }
}
