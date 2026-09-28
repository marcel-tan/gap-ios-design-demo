import SwiftUI

/// Full-screen search. Results use the same listing grid as a PLP.
struct SearchView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.search

    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var submitted = ""
    @FocusState private var focused: Bool

    private let trending = ["Short sleeve tee", "'90s loose jeans", "Hoodie", "Denim jacket", "Linen", "Baby bodysuit"]

    var body: some View {
        CoverStack {
            VStack(spacing: 0) {
                searchField
                Hairline()
                if submitted.isEmpty {
                    suggestions
                } else {
                    ProductListView(scope: .search(submitted), embedded: true)
                        .id(submitted)
                }
            }
            .background(Theme.Colors.surface.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { focused = true }
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("search")
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.Colors.textSecondary)
                TextField("Search Gap", text: $query)
                    .focused($focused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit(submit)
                    .accessibilityIdentifier("search-field")
                if !query.isEmpty {
                    Button { query = ""; submitted = ""; focused = true } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .accessibilityIdentifier("search-clear")
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Theme.Colors.chipFill, in: RoundedRectangle(cornerRadius: 10))
            Button("Cancel") { dismiss() }
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityIdentifier("search-cancel")
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.vertical, 10)
    }

    private var suggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !appState.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recent").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                            Spacer()
                            Button("Clear") { appState.clearRecentSearches() }
                                .font(Theme.Typography.small).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        ForEach(appState.recentSearches, id: \.self) { recent in
                            Button { query = recent; submit() } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath").foregroundStyle(Theme.Colors.textTertiary)
                                    Text(recent).font(Theme.Typography.body).foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                }
                                .frame(height: 36)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Trending").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                    FlowLayout(spacing: 8) {
                        ForEach(trending, id: \.self) { term in
                            Chip(title: term, minWidth: 0) { query = term; submit() }
                                .accessibilityIdentifier("search-trending-\(term.lowercased().replacingOccurrences(of: " ", with: "-"))")
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Departments").trackedLabel().foregroundStyle(Theme.Colors.textSecondary)
                    ForEach(catalog.departments) { department in
                        Button { query = department.name; submit() } label: {
                            HStack {
                                Text(department.name).font(Theme.Typography.body).foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.left").foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .frame(height: 36)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.Spacing.screenMargin)
        }
    }

    private func submit() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        appState.recordSearch(q)
        submitted = q
        focused = false
    }
}
