import SwiftUI

/// Shop tab root: department list for the selected brand plus quick links.
struct ShopView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.shop

    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(TabRouter.self) private var router

    private var brand: Brand { appState.selectedBrand }

    var body: some View {
        VStack(spacing: 0) {
            StoreHeader(title: "Shop")
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        BrandLogo(brand: brand, size: 22)
                        Text("Shopping \(brand.displayName)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                        Spacer()
                        Button("Change") { appState.isBrandSwitcherPresented = true }
                            .font(Theme.Typography.small)
                            .foregroundStyle(Theme.Colors.navy)
                            .accessibilityIdentifier("shop-change-brand")
                    }
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.vertical, 12)

                    if brand == .gap, let edit = catalog.fallEdit {
                        fallEditTile(edit)
                    }

                    ForEach(catalog.departments(for: brand)) { department in
                        row(title: department.name, symbol: department.symbol, identifier: "shop-dept-\(department.id)") {
                            router.push(.department(brand, department.id), on: .shop)
                        }
                    }

                    Text("Featured").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                        .padding(.top, 28)
                        .padding(.bottom, 8)
                    row(title: "New Arrivals", symbol: "sparkles", identifier: "shop-new") {
                        router.push(.listing(.newArrivals(brand: brand)), on: .shop)
                    }
                    row(title: "Sale", symbol: "tag", identifier: "shop-sale", tint: Theme.Colors.sale) {
                        router.push(.listing(.sale(brand: brand)), on: .shop)
                    }
                    row(title: "Shop All \(brand.displayName)", symbol: "square.grid.3x3", identifier: "shop-all") {
                        router.push(.listing(.all(brand: brand)), on: .shop)
                    }
                    row(title: "Find a Store", symbol: "mappin.and.ellipse", identifier: "shop-stores") {
                        router.push(.storeLocator, on: .shop)
                    }
                    TabBarSpacer()
                }
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("shop")
    }

    /// Figma: S04 Shop › Fall Edit feature card — full-bleed image, eyebrow, serif title and CTA.
    private func fallEditTile(_ edit: Collection) -> some View {
        let hero = catalog.product(id: "gap-797118") ?? catalog.products(in: edit).first
        return Button { router.push(.listing(.collection(edit.id)), on: .shop) } label: {
            ZStack(alignment: .bottomLeading) {
                if let hero { ProductImage(product: hero, index: 1) } else { Theme.Colors.canvas }
                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 4) {
                    Text(edit.eyebrow).trackedLabel().foregroundStyle(.white)
                    Text(edit.title).font(Theme.Typography.editorial).foregroundStyle(.white)
                    Text("Shop the \(edit.name) →").font(Theme.Typography.small).fontWeight(.semibold).foregroundStyle(.white)
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .frame(height: 200)
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.bottom, 16)
        .accessibilityIdentifier("shop-fall-edit")
    }

    private func row(title: String, symbol: String, identifier: String, tint: Color = Theme.Colors.textPrimary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(tint).frame(width: 26)
                    Text(title).font(Theme.Typography.bodyStrong).foregroundStyle(tint)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .frame(height: 56)
                Hairline().padding(.leading, Theme.Spacing.screenMargin)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

/// Category list under one department (e.g. Women → Short Sleeve Tees, Jeans, …).
struct DepartmentView: View {
    let brand: Brand
    let departmentID: String
    @Environment(Catalog.self) private var catalog
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var router

    private var department: Department? { catalog.department(id: departmentID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let products = catalog.products(in: .department(brand: brand, department: departmentID))
                if let first = products.first {
                    Button { push(.listing(.department(brand: brand, department: departmentID))) } label: {
                        ZStack(alignment: .bottomLeading) {
                            ProductImage(product: first, index: 1)
                            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(department?.name ?? departmentID.capitalized).font(Theme.Typography.heroTitle).foregroundStyle(.white)
                                Text("Shop all \(products.count) styles").font(Theme.Typography.bodyStrong).foregroundStyle(.white).underline()
                            }
                            .padding(Theme.Spacing.screenMargin)
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    }
                    .buttonStyle(.plain)
                    .padding(Theme.Spacing.screenMargin)
                    .accessibilityIdentifier("dept-hero")
                }

                Text("Categories").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.bottom, 8)
                ForEach(catalog.categories(for: brand, department: departmentID)) { category in
                    let count = catalog.products(in: .category(brand: brand, department: departmentID, category: category.id)).count
                    Button { push(.listing(.category(brand: brand, department: departmentID, category: category.id))) } label: {
                        VStack(spacing: 0) {
                            HStack {
                                Text(category.name).font(Theme.Typography.bodyStrong).foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Text("\(count)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textTertiary)
                                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                            .frame(height: 54)
                            Hairline().padding(.leading, Theme.Spacing.screenMargin)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("category-\(departmentID)-\(category.id)")
                }
                TabBarSpacer()
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle(department?.name ?? departmentID.capitalized)
        .inlineNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { appState.isSearchPresented = true } label: { Image(systemName: "magnifyingglass") }
                    .accessibilityIdentifier("dept-search")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("department-\(departmentID)")
    }

    private func push(_ route: Route) {
        router.push(route, on: appState.selectedTab)
    }
}
