import SwiftUI
import Kingfisher

/// Cached CDN image. Never shows a broken-image state: while loading, offline, or on failure it
/// renders a flat tint derived from `fallbackHex` (the colorway swatch) so grids stay legible.
struct RemoteImage: View {
    let url: URL?
    var fallbackHex: String? = nil
    var contentMode: SwiftUI.ContentMode = .fill

    private var fallback: Color {
        (fallbackHex.flatMap(Color.init(hexString:)) ?? Theme.Colors.chipFill).opacity(0.35)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Theme.Colors.canvas
                fallback
                if let url {
                    KFImage(url)
                        .placeholder { Color.clear }
                        .fade(duration: 0.2)
                        .backgroundDecode()
                        .cacheOriginalImage()
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            }
        }
    }
}

/// Product imagery for a given colorway and shot index.
struct ProductImage: View {
    let product: Product
    var color: ProductColor? = nil
    var index: Int = 0
    var contentMode: SwiftUI.ContentMode = .fill

    private var resolvedColor: ProductColor? { color ?? product.primaryColor }

    private var url: URL? {
        let urls = resolvedColor?.imageURLs ?? []
        guard !urls.isEmpty else { return nil }
        return urls[min(index, urls.count - 1)]
    }

    var body: some View {
        RemoteImage(url: url, fallbackHex: resolvedColor?.hex, contentMode: contentMode)
    }
}
