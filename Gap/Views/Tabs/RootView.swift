import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .task {
            let quick = ProcessInfo.processInfo.arguments.contains("-uiTesting")
            try? await Task.sleep(for: .milliseconds(quick ? 150 : 1100))
            withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.Colors.navy.ignoresSafeArea()
            GapWordmark(height: 120, color: Theme.Colors.onNavy)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("splash")
    }
}
