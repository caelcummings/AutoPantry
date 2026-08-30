import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Tab = .discover

    enum Tab: Hashable {
        case discover
        case recipes
        case list
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeFeedView()
                .tabItem { Label("Discover", systemImage: "sparkles") }
                .tag(Tab.discover)

            RecipesLibraryView()
                .tabItem { Label("Recipes", systemImage: "book") }
                .tag(Tab.recipes)

            GroceryListView()
                .tabItem { Label("List", systemImage: "cart") }
                .tag(Tab.list)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .fullScreenCover(isPresented: $appState.showPlanCompleteCelebration) {
            PlanCompleteCelebrationView(
                onDismiss: {
                    appState.dismissPlanCelebration()
                    selectedTab = .profile
                },
                onRedoWeek: {
                    appState.resetWeeklyPlan()
                    selectedTab = .discover
                }
            )
            .environmentObject(appState)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(
            AppState(route: .main, userProfile: OnboardingDraft())
        )
}
