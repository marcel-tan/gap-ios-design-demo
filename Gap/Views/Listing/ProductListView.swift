import SwiftUI

/// Product listing page for a scope (category, department, sale, search …).
struct ProductListView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.productListing

    let scope: ListingScope
    var embedded = false

    @Environment(Catalog.self) private var catalog
    @Environment(AppState.self) private var appState
    @Environment(TabRouter.self) private var router
    @State private var filter = ProductFilter()
    @State private var showFilters = false

    private var scopeProducts: [Product] { catalog.products(in: scope) }
    private var items: [ListingItem] { catalog.listingItems(in: scope, filter: filter) }

    var body: some View {
        content
            .background(Theme.Colors.surface.ignoresSafeArea())
            .navigationTitle(embedded ? "" : catalog.title(for: scope))
            .inlineNavigationBar()
            .toolbar {
                if !embedded {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { appState.isSearchPresented = true } label: { Image(systemName: "magnifyingglass") }
                            .accessibilityIdentifier("plp-search")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(products: scopeProducts, filter: $filter)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .accessibilityElement(children: .contain)
            .figmaNode(Self.figmaNode)
            .accessibilityIdentifier("plp-\(scope.identifier)")
    }

    @ViewBuilder
    private var content: some View {
        let items = items
        VStack(spacing: 0) {
            toolbar(count: items.count)
            Hairline()
            if items.isEmpty {
                EmptyState(symbol: "tshirt", title: "No items match",
                           message: filter.hasActiveFilters ? "Try clearing a filter or two." : "Nothing here yet — check back soon.",
                           actionTitle: filter.hasActiveFilters ? "Clear filters" : nil) { filter.clear() }
            } else {
                ScrollView {
                    ProductGrid(items: items) { item in
                        router.push(.product(item.product, item.color), on: appState.selectedTab)
                    }
                    .padding(.top, 12)
                    if !embedded { TabBarSpacer() }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("plp-grid")
            }
        }
    }

    private func toolbar(count: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(count) \(count == 1 ? "item" : "items")")
                .font(Theme.Typography.small)
                .foregroundStyle(Theme.Colors.textSecondary)
                .accessibilityIdentifier("plp-count")
            Spacer()
            Menu {
                Picker("Sort", selection: $filter.sort) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                pillLabel(filter.sort == .featured ? "Sort" : filter.sort.rawValue, symbol: "arrow.up.arrow.down")
            }
            .accessibilityIdentifier("plp-sort")
            Button { showFilters = true } label: {
                pillLabel(filter.hasActiveFilters ? "Filter (\(filter.activeCount))" : "Filter", symbol: "line.3.horizontal.decrease",
                          active: filter.hasActiveFilters)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("plp-filter")
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .frame(height: 44)
    }

    private func pillLabel(_ title: String, symbol: String, active: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
            Text(title).font(Theme.Typography.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(active ? Theme.Colors.ink : Theme.Colors.chipFill, in: Capsule())
        .foregroundStyle(active ? Theme.Colors.onInk : Theme.Colors.textPrimary)
    }
}

struct FilterSheet: View {
    let products: [Product]
    @Binding var filter: ProductFilter
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProductFilter

    init(products: [Product], filter: Binding<ProductFilter>) {
        self.products = products
        _filter = filter
        _draft = State(initialValue: filter.wrappedValue)
    }

    private var matchCount: Int {
        products.filter(draft.matches).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("Sort") {
                        VStack(spacing: 0) {
                            ForEach(SortOption.allCases) { option in
                                Button { draft.sort = option } label: {
                                    HStack {
                                        Text(option.rawValue).font(Theme.Typography.body).foregroundStyle(Theme.Colors.textPrimary)
                                        Spacer()
                                        Image(systemName: draft.sort == option ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(draft.sort == option ? Theme.Colors.navy : Theme.Colors.chipBorder)
                                    }
                                    .frame(height: 40)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("sort-\(option.identifier)")
                            }
                        }
                    }
                    let colors = ProductFilter.colorOptions(products)
                    if !colors.isEmpty {
                        section("Color") {
                            wrap(colors) { family in
                                Chip(title: family, selected: draft.colors.contains(family), minWidth: 0) { draft.colors.toggleMember(family) }
                                    .accessibilityIdentifier("filter-color-\(family.lowercased())")
                            }
                        }
                    }
                    let sizes = ProductFilter.sizeOptions(products)
                    if !sizes.isEmpty {
                        section("Size") {
                            wrap(sizes) { size in
                                Chip(title: size, selected: draft.sizes.contains(size)) { draft.sizes.toggleMember(size) }
                                    .accessibilityIdentifier("filter-size-\(size)")
                            }
                        }
                    }
                    section("Price") {
                        wrap(ProductFilter.priceBands) { band in
                            let selected = draft.minPrice == band.min && draft.maxPrice == band.max && (band.min != nil || band.max != nil)
                            Chip(title: band.label, selected: selected, minWidth: 0) {
                                if selected {
                                    draft.minPrice = nil; draft.maxPrice = nil
                                } else {
                                    draft.minPrice = band.min; draft.maxPrice = band.max
                                }
                            }
                            .accessibilityIdentifier("filter-price-\(band.id)")
                        }
                    }
                    Toggle(isOn: $draft.onSaleOnly) {
                        Text("Sale items only").font(Theme.Typography.bodyStrong)
                    }
                    .tint(Theme.Colors.navy)
                    .accessibilityIdentifier("filter-sale")
                    Color.clear.frame(height: 80)
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    OutlineButton(title: "Clear") { draft.clear() }
                        .accessibilityIdentifier("filter-clear")
                    PrimaryButton(title: "Show \(matchCount) \(matchCount == 1 ? "style" : "styles")") {
                        filter = draft
                        dismiss()
                    }
                    .accessibilityIdentifier("filter-apply")
                }
                .padding(Theme.Spacing.screenMargin)
                .background(Theme.Colors.surface)
            }
            .navigationTitle("Filter & Sort")
            .inlineNavigationBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("filter-sheet")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
            content()
        }
    }

    private func wrap<T: Hashable, Content: View>(_ items: [T], @ViewBuilder content: @escaping (T) -> Content) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { content($0) }
        }
    }
}

/// Left-to-right wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
