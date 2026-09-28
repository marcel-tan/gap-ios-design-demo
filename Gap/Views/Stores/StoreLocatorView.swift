import SwiftUI
import MapKit

struct StoreLocatorView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.storeLocator

    @Environment(StoreLocator.self) private var locator
    @Environment(AppState.self) private var appState
    @State private var brands: Set<Brand> = []
    @State private var selectedStoreID: String?
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 45.515, longitude: -73.65),
                           span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.28))
    )

    private var stores: [Store] { locator.stores(for: brands) }

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $camera, selection: $selectedStoreID) {
                ForEach(stores) { store in
                    Marker(store.name, systemImage: "bag.fill", coordinate: store.coordinate)
                        .tint(store.brandInfo.color)
                        .tag(store.id)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 280)
            .accessibilityIdentifier("store-map")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(title: "All", selected: brands.isEmpty, minWidth: 0) { brands.removeAll() }
                        .accessibilityIdentifier("store-filter-all")
                    ForEach(Brand.allCases) { brand in
                        Chip(title: brand.displayName, selected: brands.contains(brand), minWidth: 0) { brands.toggleMember(brand) }
                            .accessibilityIdentifier("store-filter-\(brand.rawValue)")
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.vertical, 12)
            }
            Hairline()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        Text("\(stores.count) stores near Montréal, QC")
                            .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.Spacing.screenMargin).padding(.vertical, 10)
                            .accessibilityIdentifier("store-count")
                        ForEach(stores) { store in
                            StoreRow(store: store, isSelected: selectedStoreID == store.id, isPreferred: locator.preferredStoreID == store.id) {
                                locator.setPreferred(store)
                                appState.showToast("\(store.name) is now My Store")
                            }
                            .id(store.id)
                            .onTapGesture {
                                selectedStoreID = store.id
                                withAnimation { camera = .region(MKCoordinateRegion(center: store.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))) }
                            }
                            Hairline().padding(.leading, Theme.Spacing.screenMargin)
                        }
                        TabBarSpacer()
                    }
                }
                .onChange(of: selectedStoreID) { _, id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .top) }
                }
            }
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle("Store Locator")
        .inlineNavigationBar()
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("store-locator")
    }
}

struct StoreRow: View {
    let store: Store
    let isSelected: Bool
    let isPreferred: Bool
    let onSetPreferred: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandLogo(brand: store.brandInfo, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(store.name).font(Theme.Typography.bodyStrong)
                    if isPreferred {
                        PillBadge(text: "My Store", fill: Theme.Colors.navy)
                    }
                }
                Text("\(store.address) · \(store.city)").font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                Text(store.hours).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
                if isSelected {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.services.joined(separator: " · ")).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textTertiary)
                        HStack(spacing: 10) {
                            Button(action: onSetPreferred) {
                                Text(isPreferred ? "My Store" : "Set as My Store")
                                    .font(Theme.Typography.small).fontWeight(.semibold)
                                    .padding(.horizontal, 12).frame(height: 32)
                                    .background(isPreferred ? Theme.Colors.canvas : Theme.Colors.ink, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                                    .foregroundStyle(isPreferred ? Theme.Colors.textSecondary : Theme.Colors.onInk)
                            }
                            .buttonStyle(.plain)
                            .disabled(isPreferred)
                            .accessibilityIdentifier("store-set-preferred-\(store.id)")
                            Link(destination: URL(string: "tel:\(store.phone.filter(\.isNumber))")!) {
                                Label(store.phone, systemImage: "phone").font(Theme.Typography.small)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            Spacer()
            Text(store.distanceLabel).font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.screenMargin)
        .background(isSelected ? Theme.Colors.canvas : Theme.Colors.surface)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("store-row-\(store.id)")
    }
}
