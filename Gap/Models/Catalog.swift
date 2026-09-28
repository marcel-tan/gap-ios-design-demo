import Foundation
import Observation

/// Bundled catalog: products, departments and categories decoded from the app bundle.
@Observable
final class Catalog {
    private(set) var products: [Product]
    private(set) var departments: [Department]
    private(set) var categories: [Category]
    private(set) var collections: [Collection]

    private let byID: [String: Product]

    init(products: [Product], departments: [Department] = [], categories: [Category] = [], collections: [Collection] = []) {
        self.products = products
        self.departments = departments
        self.categories = categories
        self.collections = collections
        self.byID = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    static func load(bundle: Bundle = .main) -> Catalog {
        do {
            let catalog = try loadFile(named: "products", bundle: bundle) as CatalogFile
            let categories = try loadFile(named: "categories", bundle: bundle) as CategoryFile
            return Catalog(products: catalog.products, departments: categories.departments, categories: categories.categories, collections: categories.collections ?? [])
        } catch {
            assertionFailure("Failed to load catalog: \(error)")
            return Catalog(products: [])
        }
    }

    static func loadFile<T: Decodable>(named name: String, bundle: Bundle = .main) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> CatalogFile {
        try JSONDecoder().decode(CatalogFile.self, from: data)
    }

    // MARK: - Lookup

    func product(id: String) -> Product? { byID[id] }

    func products(ids: [String]) -> [Product] { ids.compactMap { byID[$0] } }

    func products(brand: Brand) -> [Product] { products.filter { $0.brand == brand.rawValue } }

    func department(id: String) -> Department? { departments.first { $0.id == id } }

    func collection(id: String) -> Collection? { collections.first { $0.id == id } }

    /// The seasonal edit shown on Home and Shop; falls back to the first bundled collection.
    var fallEdit: Collection? { collection(id: "fall-edit") ?? collections.first }

    func products(in collection: Collection) -> [Product] { products(ids: collection.productIDs) }

    func category(department: String, id: String) -> Category? {
        categories.first { $0.department == department && $0.id == id }
    }

    /// Departments that have at least one product for `brand`, in catalog order.
    func departments(for brand: Brand) -> [Department] {
        let present = Set(products(brand: brand).map(\.department))
        return departments.filter { present.contains($0.id) }
    }

    /// Categories under `department` that have at least one product for `brand`.
    func categories(for brand: Brand, department: String) -> [Category] {
        let present = Set(products(brand: brand).filter { $0.department == department }.map(\.category))
        return categories
            .filter { $0.department == department && present.contains($0.id) }
            .sorted { $0.order < $1.order }
    }

    // MARK: - Scopes

    func products(in scope: ListingScope) -> [Product] {
        switch scope {
        case .category(let brand, let department, let category):
            return products(brand: brand).filter { $0.department == department && $0.category == category }
        case .department(let brand, let department):
            return products(brand: brand).filter { $0.department == department }
        case .newArrivals(let brand):
            return products(brand: brand).filter(\.isNew)
        case .sale(let brand):
            return products(brand: brand).filter(\.isOnSale)
        case .all(let brand):
            return products(brand: brand)
        case .collection(let id):
            return collection(id: id).map(products(in:)) ?? []
        case .search(let query):
            return search(query)
        }
    }

    func title(for scope: ListingScope) -> String {
        switch scope {
        case .category(_, let department, let category):
            return self.category(department: department, id: category)?.name ?? category.capitalized
        case .department(_, let department):
            return self.department(id: department)?.name ?? department.capitalized
        case .newArrivals: return "New Arrivals"
        case .sale: return "Sale"
        case .all(let brand): return "Shop All \(brand.displayName)"
        case .collection(let id): return collection(id: id)?.name ?? "Edit"
        case .search(let query): return "\"\(query)\""
        }
    }

    /// Case-insensitive match on name, category, department, brand or colour name.
    func search(_ query: String) -> [Product] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let terms = q.split(separator: " ").map(String.init)
        return products.filter { product in
            let haystack = [
                product.name, product.category, product.department, product.brandInfo.displayName,
                product.colors.map(\.name).joined(separator: " "),
            ].joined(separator: " ").lowercased()
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    // MARK: - Listing tiles

    /// Tiles for a product grid after `filter` is applied. Each colorway gets its own tile so the
    /// shopper sees the full range of imagery for the scope.
    func listingItems(in scope: ListingScope, filter: ProductFilter = ProductFilter()) -> [ListingItem] {
        listingItems(from: filter.apply(to: products(in: scope)))
    }

    func listingItems(from products: [Product]) -> [ListingItem] {
        products.flatMap { product in
            product.colors.map { ListingItem(product: product, color: $0) }
        }
    }

    // MARK: - Merchandising

    /// Products shown alongside `product` on the PDP and Item Added sheet.
    func related(to product: Product, limit: Int = 6) -> [Product] {
        let sameCategory = products.filter {
            $0.id != product.id && $0.brand == product.brand && $0.department == product.department && $0.category == product.category
        }
        let sameDepartment = products.filter {
            $0.id != product.id && $0.brand == product.brand && $0.department == product.department && $0.category != product.category
        }
        let companions = collections
            .filter { $0.productIDs.contains(product.id) }
            .flatMap { products(in: $0) }
            .filter { $0.id != product.id }
        var seen = Set<String>()
        let ordered = (companions + sameCategory + sameDepartment).filter { seen.insert($0.id).inserted }
        return Array(ordered.prefix(limit))
    }

    /// Products for a Home rail: `department` optional, biased towards new arrivals.
    func rail(brand: Brand, department: String? = nil, category: String? = nil, onSale: Bool? = nil, limit: Int = 8) -> [Product] {
        var pool = products(brand: brand)
        if let department { pool = pool.filter { $0.department == department } }
        if let category { pool = pool.filter { $0.category == category } }
        if let onSale { pool = pool.filter { $0.isOnSale == onSale } }
        let new = pool.filter(\.isNew)
        let rest = pool.filter { !$0.isNew }
        return Array((new + rest).prefix(limit))
    }
}
