import SwiftUI

/// Gap brand tokens, mirroring the Figma variable collections `Gap / Color` and `Gap / Space` and the
/// text styles on page "02 Foundations & Components". Views pull colors, type, spacing and shape from
/// here — no literals in views.
enum Theme {
    enum Colors {
        static let navy = Color(hex: 0x002868)
        static let ink = Color(hex: 0x141414)
        static let surface = Color.white
        static let canvas = Color(hex: 0xF6F6F4)
        static let hairline = Color(hex: 0xE4E4E1)
        static let textPrimary = Color(hex: 0x141414)
        static let textSecondary = Color(hex: 0x6B6B6B)
        static let textTertiary = Color(hex: 0x9A9A9A)
        static let chipFill = Color(hex: 0xF1F1EF)
        static let chipBorder = Color(hex: 0xC8C8C4)
        static let sale = Color(hex: 0xB3261E)
        static let success = Color(hex: 0x1E7A43)
        static let onNavy = Color.white
        static let onInk = Color.white
        static let dim = Color.black.opacity(0.45)
        static let shadow = Color.black.opacity(0.14)
        static let encoreGold = Color(hex: 0xC8A45C)
        static let encoreDark = Color(hex: 0x0E1B3A)
        static let applePay = Color.black
    }

    enum Typography {
        static let wordmark = Font.system(size: 22, weight: .bold, design: .serif)
        static let wordmarkTracking: CGFloat = -0.5

        static let display = Font.system(size: 34, weight: .bold)
        static let screenTitle = Font.system(size: 24, weight: .bold)
        static let sectionTitle = Font.system(size: 20, weight: .bold)
        static let greeting = Font.system(size: 28, weight: .bold)
        static let productName = Font.system(size: 22, weight: .semibold)
        static let cardName = Font.system(size: 14, weight: .regular)
        static let heroTitle = Font.system(size: 34, weight: .regular, design: .serif)
        /// Display/Hero — editorial serif (Playfair Display in Figma, New York on iOS).
        static let editorial = Font.system(size: 30, weight: .regular, design: .serif)
        static let encoreWordmark = Font.system(size: 14, weight: .regular, design: .serif)

        static let label = Font.system(size: 12, weight: .semibold)
        static let labelTracking: CGFloat = 1.2
        static let tabLabel = Font.system(size: 10, weight: .medium)
        static let button = Font.system(size: 15, weight: .semibold)
        static let buttonTracking: CGFloat = 0.5
        static let body = Font.system(size: 15, weight: .regular)
        static let bodyStrong = Font.system(size: 15, weight: .semibold)
        static let small = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let price = Font.system(size: 14, weight: .semibold)
        static let promo = Font.system(size: 12, weight: .bold, design: .monospaced)
        static let badge = Font.system(size: 10, weight: .bold)
        static let chip = Font.system(size: 14, weight: .medium)
    }

    enum Spacing {
        static let screenMargin: CGFloat = 16
        static let gridGutter: CGFloat = 8
        static let section: CGFloat = 28
        static let itemSpacing: CGFloat = 8
        static let tight: CGFloat = 4
    }

    enum Radius {
        /// radius/pill
        static let chip: CGFloat = 999
        /// radius/sheet
        static let sheet: CGFloat = 12
        /// radius/none — imagery and CTAs are square-cornered in the Figma design.
        static let card: CGFloat = 0
        static let button: CGFloat = 0
        static let tabBar: CGFloat = 32
    }

    enum Sizes {
        static let hairline: CGFloat = 1
        static let ctaHeight: CGFloat = 52
        static let headerRowHeight: CGFloat = 48
        static let tabBarHeight: CGFloat = 64
        static let tabBarBottomPadding: CGFloat = 8
        static let tabBarReserved: CGFloat = 84
        static let navIcon: CGFloat = 22
        static let sizeChipMinWidth: CGFloat = 52
        static let sizeChipHeight: CGFloat = 40
        static let swatch: CGFloat = 14
        static let pdpSwatch: CGFloat = 36
        static let brandLogo: CGFloat = 30
        static let grabberWidth: CGFloat = 40
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// Parses "#RRGGBB" swatch strings from the product fixture.
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        self.init(hex: value)
    }
}

extension View {
    /// Tracked uppercase label used for eyebrows, controls and tab titles.
    func trackedLabel(_ font: Font = Theme.Typography.label, tracking: CGFloat = Theme.Typography.labelTracking) -> some View {
        self.font(font).tracking(tracking).textCase(.uppercase)
    }

    func floatingShadow() -> some View {
        shadow(color: Theme.Colors.shadow, radius: 14, x: 0, y: 6)
    }
}
