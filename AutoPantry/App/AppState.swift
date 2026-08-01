import Combine
import Foundation
import SwiftUI

/// High-level app routing state (onboarding vs main shell).
@MainActor
final class AppState: ObservableObject {
    enum Route {
        case onboarding
        case main
    }

    @Published var route: Route
    @Published private(set) var userProfile: OnboardingDraft?
    @Published var weeklyMealPlan = WeeklyMealPlan()
    @Published var seasoningInventory = SeasoningInventory()
    @Published var showPlanCompleteCelebration = false

    /// When true, profile and meal plan are read/written via `LocalProfileStore`.
    private let persistsLocally: Bool

    /// Production entry: restores a saved profile and skips onboarding when present.
    convenience init() {
        let profile = LocalProfileStore.loadProfile()
        self.init(
            route: profile == nil ? .onboarding : .main,
            userProfile: profile,
            weeklyMealPlan: LocalProfileStore.loadMealPlan(),
            seasoningInventory: LocalProfileStore.loadSeasoningInventory(),
            persistsLocally: true
        )
    }

    /// Previews and tests: in-memory only unless `persistsLocally` is enabled.
    init(
        route: Route = .onboarding,
        userProfile: OnboardingDraft? = nil,
        weeklyMealPlan: WeeklyMealPlan = WeeklyMealPlan(),
        seasoningInventory: SeasoningInventory = SeasoningInventory(),
        persistsLocally: Bool = false
    ) {
        self.route = route
        self.userProfile = userProfile
        self.weeklyMealPlan = weeklyMealPlan
        self.seasoningInventory = seasoningInventory
        self.persistsLocally = persistsLocally
    }

    var nutritionProfile: NutritionProfile {
        userProfile?.nutritionProfile ?? NutritionProfile()
    }

    var weeklyProgress: WeeklyPlanProgress {
        nutritionProfile.progress(for: weeklyMealPlan)
    }

    /// Meal-count target filled (what unlocks the week summary / celebration).
    var hasCompletedWeeklyMeals: Bool {
        weeklyProgress.mealsComplete
    }

    /// Full meal + macro goals met.
    var isWeeklyPlanComplete: Bool {
        nutritionProfile.isPlanComplete(weeklyMealPlan)
    }

    var groceryListItems: [GroceryListItem] {
        GroceryListBuilder.build(from: weeklyMealPlan, excluding: seasoningInventory)
    }

    func completeOnboarding(with draft: OnboardingDraft) {
        userProfile = draft
        weeklyMealPlan = WeeklyMealPlan()
        showPlanCompleteCelebration = false
        route = .main
        persist()
    }

    func resetOnboardingPreview() {
        userProfile = nil
        weeklyMealPlan = WeeklyMealPlan()
        seasoningInventory = SeasoningInventory()
        showPlanCompleteCelebration = false
        route = .onboarding
        if persistsLocally {
            LocalProfileStore.clear()
        }
    }

    /// Liked recipes auto-save to the weekly plan until the meal-count target is met.
    @discardableResult
    func addRecipeToWeeklyPlan(_ recipe: RecipeSummary) -> Bool {
        guard !weeklyMealPlan.contains(recipeID: recipe.id) else { return false }
        guard !hasCompletedWeeklyMeals else { return false }

        weeklyMealPlan.recipes.append(recipe)

        // Celebrate as soon as the week's meal total is reached.
        if nutritionProfile.progress(for: weeklyMealPlan).mealsComplete {
            showPlanCompleteCelebration = true
        }
        persistMealPlan()
        return true
    }

    func removeRecipeFromWeeklyPlan(id: String) {
        weeklyMealPlan.recipes.removeAll { $0.id == id }
        persistMealPlan()
    }

    func dismissPlanCelebration() {
        showPlanCompleteCelebration = false
    }

    func showWeekSummary() {
        guard !weeklyMealPlan.recipes.isEmpty else { return }
        showPlanCompleteCelebration = true
    }

    func resetWeeklyPlan() {
        weeklyMealPlan = WeeklyMealPlan()
        showPlanCompleteCelebration = false
        persistMealPlan()
    }

    func addSeasoning(_ name: String) {
        seasoningInventory.add(name)
        persistSeasoningInventory()
    }

    func removeSeasoning(_ name: String) {
        seasoningInventory.remove(name)
        persistSeasoningInventory()
    }

    private func persist() {
        guard persistsLocally else { return }
        LocalProfileStore.saveProfile(userProfile)
        LocalProfileStore.saveMealPlan(weeklyMealPlan)
        LocalProfileStore.saveSeasoningInventory(seasoningInventory)
    }

    private func persistMealPlan() {
        guard persistsLocally else { return }
        LocalProfileStore.saveMealPlan(weeklyMealPlan)
    }

    private func persistSeasoningInventory() {
        guard persistsLocally else { return }
        LocalProfileStore.saveSeasoningInventory(seasoningInventory)
    }
}
