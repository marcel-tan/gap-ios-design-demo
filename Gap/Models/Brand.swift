import SwiftUI

/// Gap Inc. brands available in the brand switcher.
enum Brand: String, CaseIterable, Identifiable, Codable {
    case gap
    case athleta
    case oldnavy
    case bananarepublic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gap: return "Gap"
        case .athleta: return "Athleta"
        case .oldnavy: return "Old Navy"
        case .bananarepublic: return "Banana Republic"
        }
    }

    /// Short mark drawn inside the circular logo badge (Gap uses its wordmark asset instead).
    var monogram: String {
        switch self {
        case .gap: return "GAP"
        case .athleta: return "A"
        case .oldnavy: return "ON"
        case .bananarepublic: return "BR"
        }
    }

    var color: Color {
        switch self {
        case .gap: return Theme.Colors.navy
        case .athleta: return Color(hex: 0x1F1F1F)
        case .oldnavy: return Color(hex: 0x00347A)
        case .bananarepublic: return Color(hex: 0x2B2B2B)
        }
    }

    var tagline: String {
        switch self {
        case .gap: return "Modern American optimism"
        case .athleta: return "Power of she"
        case .oldnavy: return "Fun, fashion & value for the whole family"
        case .bananarepublic: return "Imagined worldwide"
        }
    }

    var memberProgram: String {
        switch self {
        case .gap: return "Gap Encore"
        case .athleta: return "Athleta Rewards"
        case .oldnavy: return "Navyist Rewards"
        case .bananarepublic: return "BR Rewards"
        }
    }
}

/// The Gap wordmark, rendered from the vector `GapWordmark` asset and tinted with `color`.
struct GapWordmark: View {
    var height: CGFloat
    var color: Color = Theme.Colors.navy

    var body: some View {
        Image("GapWordmark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .foregroundStyle(color)
            .accessibilityLabel("GAP")
    }
}

/// The Gap logo as it appears in the App Store: white wordmark on a navy square.
struct GapLogoTile: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Theme.Colors.navy
            GapWordmark(height: size * 0.5, color: Theme.Colors.onNavy)
        }
        .frame(width: size, height: size)
    }
}

/// Circular brand badge (the Gap tab icon and brand switcher rows).
struct BrandLogo: View {
    let brand: Brand
    var size: CGFloat = Theme.Sizes.brandLogo
    var isMuted = false

    var body: some View {
        ZStack {
            Circle().fill(isMuted ? Theme.Colors.textTertiary : brand.color)
            if brand == .gap {
                GapWordmark(height: size * 0.42, color: Theme.Colors.onNavy)
            } else {
                Text(brand.monogram)
                    .font(.system(size: size * 0.4, weight: .bold, design: .serif))
                    .tracking(-0.5)
                    .foregroundStyle(Theme.Colors.onNavy)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(brand.displayName)
    }
}
