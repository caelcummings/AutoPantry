import SwiftUI

/// Root router: onboarding first, then the main tab shell.
struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.route {
            case .onboarding:
                OnboardingFlowView()
            case .main:
                MainTabView()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: appState.route)
    }
}

#Preview("Onboarding") {
    RootView()
        .environmentObject(AppState(route: .onboarding))
}

#Preview("Main") {
    RootView()
        .environmentObject(
            AppState(route: .main, userProfile: OnboardingDraft())
        )
}
