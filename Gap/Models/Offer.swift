import Foundation

struct Offer: Codable, Hashable, Identifiable {
    let id: String
    let brand: String
    let eyebrow: String
    let title: String
    let body: String
    let code: String?
    let expires: String
    let isMembersOnly: Bool

    var brandInfo: Brand { Brand(rawValue: brand) ?? .gap }
}

struct OfferFile: Codable {
    let offers: [Offer]
}

extension Offer {
    static func load(bundle: Bundle = .main) -> [Offer] {
        let file: OfferFile? = try? Catalog.loadFile(named: "offers", bundle: bundle)
        return file?.offers ?? []
    }
}
