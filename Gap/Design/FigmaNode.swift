import SwiftUI

/// A reference to the Figma node a view was built from. Every screen-level view exposes one via
/// `FigmaTraced` so QA can jump from the running app to the design (see docs/figma-nodes.md).
struct FigmaNode: Hashable, Identifiable, Codable {
    static let fileKey = "2amCWqHqUoNvHtOQUxtd7I"

    let id: String
    let name: String
    /// Figma page the node lives on ("01 Wireframes & Flow", "02 Foundations & Components", "03 Screens & Prototype").
    let page: String

    var url: URL {
        URL(string: "https://www.figma.com/design/\(FigmaNode.fileKey)?node-id=\(id.replacingOccurrences(of: ":", with: "-"))")!
    }
}

/// Screens conform to this so the registry and the `-figmaOverlay` debug badge can find them.
protocol FigmaTraced {
    static var figmaNode: FigmaNode { get }
}

/// Hi-fi screen nodes on page "03 Screens & Prototype". Wireframe nodes are listed in docs/figma-nodes.md.
enum FigmaScreens {
    static let onboarding = FigmaNode(id: "17:699", name: "S01 Onboarding", page: "03 Screens & Prototype")
    static let home = FigmaNode(id: "17:730", name: "S02 Home", page: "03 Screens & Prototype")
    static let brandSwitcher = FigmaNode(id: "17:822", name: "S03 Brand switcher", page: "03 Screens & Prototype")
    static let shop = FigmaNode(id: "17:1011", name: "S04 Shop", page: "03 Screens & Prototype")
    static let productListing = FigmaNode(id: "17:1136", name: "S05 Product listing", page: "03 Screens & Prototype")
    static let productDetail = FigmaNode(id: "5:193", name: "S06 Product detail (wireframe)", page: "01 Wireframes & Flow")
    static let itemAdded = FigmaNode(id: "5:246", name: "S07 Item added (wireframe)", page: "01 Wireframes & Flow")
    static let bag = FigmaNode(id: "5:311", name: "S08 Bag (wireframe)", page: "01 Wireframes & Flow")
    static let checkout = FigmaNode(id: "5:373", name: "S09 Checkout (wireframe)", page: "01 Wireframes & Flow")
    static let storeLocator = FigmaNode(id: "5:409", name: "S10 Store locator (wireframe)", page: "01 Wireframes & Flow")
    static let confirmation = FigmaNode(id: "5:444", name: "S11 Order confirmation (wireframe)", page: "01 Wireframes & Flow")
    static let account = FigmaNode(id: "5:472", name: "S12 Account / Encore (wireframe)", page: "01 Wireframes & Flow")
    static let offers = FigmaNode(id: "5:513", name: "S13 Offers (wireframe)", page: "01 Wireframes & Flow")
    static let search = FigmaNode(id: "5:272", name: "S14 Search (wireframe)", page: "01 Wireframes & Flow")

    static let all: [FigmaNode] = [
        onboarding, home, brandSwitcher, shop, productListing, productDetail, itemAdded,
        bag, checkout, storeLocator, confirmation, account, offers, search,
    ]
}

/// Component nodes on page "02 Foundations & Components" that the SwiftUI controls mirror.
enum FigmaComponents {
    static let logo = FigmaNode(id: "15:3", name: "Logo / Gap wordmark", page: "02 Foundations & Components")
    static let button = FigmaNode(id: "15:13", name: "Button", page: "02 Foundations & Components")
    static let chip = FigmaNode(id: "15:19", name: "Chip", page: "02 Foundations & Components")
    static let sizeChip = FigmaNode(id: "15:27", name: "Size chip", page: "02 Foundations & Components")
    static let swatch = FigmaNode(id: "15:35", name: "Colour swatch", page: "02 Foundations & Components")
    static let tabBar = FigmaNode(id: "15:141", name: "Tab bar", page: "02 Foundations & Components")
    static let navHeader = FigmaNode(id: "15:143", name: "Nav header", page: "02 Foundations & Components")
    static let searchBar = FigmaNode(id: "15:150", name: "Search bar", page: "02 Foundations & Components")
    static let productCard = FigmaNode(id: "15:205", name: "Product card", page: "02 Foundations & Components")
    static let bagLineItem = FigmaNode(id: "15:207", name: "Bag line item", page: "02 Foundations & Components")
    static let storeRow = FigmaNode(id: "15:241", name: "Store row", page: "02 Foundations & Components")
    static let offerCard = FigmaNode(id: "15:243", name: "Offer card", page: "02 Foundations & Components")
    static let encoreCard = FigmaNode(id: "15:259", name: "Encore card", page: "02 Foundations & Components")
    static let promoField = FigmaNode(id: "15:267", name: "Promo field", page: "02 Foundations & Components")
    static let summaryRow = FigmaNode(id: "15:279", name: "Summary row", page: "02 Foundations & Components")
    static let brandBadge = FigmaNode(id: "15:299", name: "Brand badge", page: "02 Foundations & Components")
    static let sheet = FigmaNode(id: "15:301", name: "Sheet", page: "02 Foundations & Components")
}

/// Shows the Figma node id in the top-right corner when the app is launched with `-figmaOverlay`,
/// and always exposes it to accessibility so XCUITests can assert screen ↔ design traceability.
struct FigmaOverlay: ViewModifier {
    let node: FigmaNode
    @Environment(\.openURL) private var openURL
    private var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-figmaOverlay") }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if isEnabled {
                    Text(node.id)
                        .font(Theme.Typography.badge.monospaced())
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Theme.Colors.encoreDark.opacity(0.85), in: Capsule())
                        .foregroundStyle(.white)
                        .onTapGesture { openURL(node.url) }
                        .padding(.top, 54).padding(.trailing, 8)
                        .accessibilityIdentifier("figma-badge")
                }
            }
            .accessibilityValue("figma:\(node.id)")
    }
}

extension View {
    func figmaNode(_ node: FigmaNode) -> some View {
        modifier(FigmaOverlay(node: node))
    }
}
