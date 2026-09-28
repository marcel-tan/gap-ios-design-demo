import SwiftUI

/// Figma: S02 Home (17:730). Greeting + Encore tier, search bar, "Fall Layers" editorial hero,
/// "Build your fall outfit" rail (the golden-path products), new arrivals and the store card.
struct HomeView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.home

    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(TabRouter.self) private var router
    @Environment(EncoreAccount.self) private var account
    @Environment(WishlistStore.self) private var wishlist

    private var brand: Brand { appState.selectedBrand }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: 14) {
                    greetingHeader
                    searchBar
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                if brand == .gap, let edit = catalog.fallEdit {
                    heroBanner(edit)
                    outfitRail(edit)
                } else {
                    brandHero
                }
                ProductRail(title: "New arrivals",
                            products: catalog.rail(brand: brand, department: brand == .gap ? "women" : nil),
                            seeAll: { open(.listing(.newArrivals(brand: brand))) },
                            onSelect: { open(.product($0, nil)) })
                let sale = catalog.rail(brand: brand, onSale: true)
                if !sale.isEmpty {
                    ProductRail(title: "Sale", products: sale,
                                seeAll: { open(.listing(.sale(brand: brand))) },
                                onSelect: { open(.product($0, nil)) })
                }
                storeCard
                TabBarSpacer()
            }
            .padding(.top, 8)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("home")
    }

    private func open(_ route: Route) {
        router.push(route, on: .home)
    }

    // MARK: Sections

    /// Figma: Home › greeting row. Tapping the name opens Account; the brand mark opens the switcher.
    private var greetingHeader: some View {
        HStack(alignment: .top) {
            Button { appState.selectedTab = .account } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Greeting.text()), \(account.firstName)")
                        .font(Theme.Typography.sectionTitle)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    HStack(spacing: 6) {
                        Text("encore").font(Theme.Typography.encoreWordmark).foregroundStyle(Theme.Colors.encoreGold)
                        Text("\(account.tier.replacingOccurrences(of: " Member", with: "")) · \(account.pointsLabel) pts")
                            .font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home-encore")
            Spacer()
            HStack(spacing: 10) {
                Button { appState.isBrandSwitcherPresented = true } label: {
                    HStack(spacing: 4) {
                        Wordmark(brand: brand)
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("brand-switcher")
                IconButton(symbol: wishlist.isEmpty ? "heart" : "heart.fill", identifier: "header-wishlist", badge: wishlist.count) { appState.isWishlistPresented = true }
            }
        }
        .frame(minHeight: Theme.Sizes.headerRowHeight)
    }

    /// Figma component: Search bar (15:150).
    private var searchBar: some View {
        Button { appState.isSearchPresented = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .medium))
                Text("Search \(brand.displayName)").font(Theme.Typography.body)
                Spacer()
                Image(systemName: "barcode.viewfinder").font(.system(size: 18))
            }
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .overlay(Rectangle().stroke(Theme.Colors.ink, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("header-search")
    }

    /// Figma: Hero / Fall Layers — editorial serif headline over a lifestyle photo.
    private func heroBanner(_ edit: Collection) -> some View {
        let hero = catalog.product(id: "gap-815642") ?? catalog.products(in: edit).first
        return Button { open(.listing(.collection(edit.id))) } label: {
            ZStack(alignment: .bottomLeading) {
                if let hero {
                    ProductImage(product: hero, index: 1)
                } else {
                    brand.color
                }
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .init(x: 0.5, y: 0.4), endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    Text(edit.eyebrow).trackedLabel().foregroundStyle(.white)
                    Text(edit.title)
                        .font(Theme.Typography.heroTitle)
                        .foregroundStyle(.white)
                    Text("Shop the edit")
                        .font(Theme.Typography.small).fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.ink)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.Colors.surface)
                        .padding(.top, 4)
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .frame(height: 380)
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .accessibilityIdentifier("home-hero")
    }

    /// Non-Gap brands keep a simple new-season hero.
    private var brandHero: some View {
        let hero = catalog.rail(brand: brand, limit: 1).first
        return Button { open(.listing(.newArrivals(brand: brand))) } label: {
            ZStack(alignment: .bottomLeading) {
                if let hero { ProductImage(product: hero, index: 1) } else { brand.color }
                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    Text(brand.tagline).trackedLabel().foregroundStyle(.white.opacity(0.85))
                    Text("New Season, New \(brand.displayName)").font(Theme.Typography.heroTitle).foregroundStyle(.white)
                    Text("Shop new arrivals").font(Theme.Typography.bodyStrong).foregroundStyle(.white).underline()
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .frame(height: 380)
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .accessibilityIdentifier("home-hero")
    }

    /// Figma: "Build your fall outfit" — three 113 pt tiles for the golden-path products.
    private func outfitRail(_ edit: Collection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Build your fall outfit", action: { open(.listing(.collection(edit.id))) })
            HStack(alignment: .top, spacing: 10) {
                ForEach(catalog.products(in: edit).prefix(3)) { product in
                    Button { open(.product(product, nil)) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            ProductImage(product: product)
                                .aspectRatio(113 / 150, contentMode: .fit)
                                .clipped()
                            Text(product.name)
                                .font(Theme.Typography.caption).fontWeight(.medium)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .lineLimit(2, reservesSpace: true)
                                .multilineTextAlignment(.leading)
                            PriceLabel(product: product)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home-outfit-\(product.id)")
                }
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-outfit")
    }

    private var storeCard: some View {
        Button { open(.storeLocator) } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse").font(.system(size: 22)).foregroundStyle(Theme.Colors.navy)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stores near Montréal").font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textPrimary)
                    Text("Check availability and pick up in store").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(14)
            .background(Rectangle().stroke(Theme.Colors.hairline))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .accessibilityIdentifier("home-stores")
    }
}

/// Figma: S03 Brand switcher (17:822) — sheet listing the four Gap Inc. brands.
struct BrandSwitcherView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.brandSwitcher

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shop our family of brands").font(Theme.Typography.screenTitle).padding(.horizontal, Theme.Spacing.screenMargin).padding(.top, 20)
            Text("One account, one bag, one Encore balance across all four brands.")
                .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.screenMargin)
            VStack(spacing: 0) {
                ForEach(Brand.allCases) { brand in
                    Button {
                        appState.selectedBrand = brand
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            BrandLogo(brand: brand, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(brand.displayName).font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textPrimary)
                                Text(brand.tagline).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                            }
                            Spacer()
                            if brand == appState.selectedBrand {
                                Image(systemName: "checkmark").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.navy)
                            } else {
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("brand-\(brand.rawValue)")
                    if brand != Brand.allCases.last { Hairline().padding(.leading, 70) }
                }
            }
            .padding(.top, 8)
            Spacer()
        }
        .background(Theme.Colors.surface)
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("brand-switcher-sheet")
    }
}
