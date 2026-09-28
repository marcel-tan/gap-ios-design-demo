import SwiftUI

struct OnboardingView: View, FigmaTraced {
    static let figmaNode = FigmaScreens.onboarding

    @Environment(AppState.self) private var appState
    @Environment(Catalog.self) private var catalog
    @State private var page = 0

    private struct Page {
        let title: String
        let body: String
        let productID: String
    }

    private let pages = [
        Page(title: "Shop Gap, Athleta, Old Navy & Banana Republic in one place.",
             body: "Switch brands from the top of the app and keep one bag across all four.",
             productID: "815642"),
        Page(title: "Earn Encore points on every order.",
             body: "1 point per dollar. Premier members get free shipping and early access to drops.",
             productID: "795346"),
        Page(title: "Find your store in Montréal.",
             body: "Buy online, pick up in store, and see what's on the rack before you go.",
             productID: "886601"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index]).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.Colors.navy : Theme.Colors.hairline)
                        .frame(width: index == page ? 20 : 6, height: 6)
                }
            }
            .animation(.easeInOut, value: page)
            .padding(.vertical, 20)

            VStack(spacing: 12) {
                PrimaryButton(title: page == pages.count - 1 ? "Start Shopping" : "Continue") {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        finish()
                    }
                }
                .accessibilityIdentifier("onboarding-continue")
                Button("Skip") { finish() }
                    .font(Theme.Typography.small)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .accessibilityIdentifier("onboarding-skip")
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .figmaNode(Self.figmaNode)
        .accessibilityIdentifier("onboarding")
    }

    private func onboardingPage(_ item: Page) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let product = catalog.product(id: item.productID) {
                    ProductImage(product: product)
                } else {
                    Theme.Colors.navy
                }
                GapLogoTile(size: 48)
                    .padding(Theme.Spacing.screenMargin)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 440)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(Theme.Typography.greeting)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.body)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.top, 24)
            Spacer(minLength: 0)
        }
    }

    private func finish() {
        appState.hasCompletedOnboarding = true
    }
}
