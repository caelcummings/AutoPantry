import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Tab = .discover

    enum Tab: Hashable {
        case discover
        case list
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeFeedView()
                .tabItem { Label("Discover", systemImage: "sparkles") }
                .tag(Tab.discover)

            GroceryListView()
                .tabItem { Label("List", systemImage: "cart") }
                .tag(Tab.list)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .fullScreenCover(isPresented: $appState.showPlanCompleteCelebration) {
            PlanCompleteCelebrationView(
                mealCount: appState.weeklyMealPlan.totals.mealCount,
                totals: appState.weeklyMealPlan.totals,
                profile: appState.nutritionProfile,
                onDismiss: {
                    appState.dismissPlanCelebration()
                    selectedTab = .profile
                }
            )
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(
            AppState(route: .main, userProfile: OnboardingDraft())
        )
}
