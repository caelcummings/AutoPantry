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
    @Published var favoriteRecipes = FavoriteRecipes()
    @Published var userRecipes = UserRecipes()
    @Published var extraGroceryItems = ExtraGroceryItems()
    @Published var showPlanCompleteCelebration = false
    /// In-progress onboarding to restore when the app relaunches mid-flow.
    @Published private(set) var onboardingProgress: LocalProfileStore.OnboardingProgress?

    /// When true, profile and meal plan are read/written via `LocalProfileStore`.
    private let persistsLocally: Bool

    /// Production entry: restores a saved profile and skips onboarding when present.
    convenience init() {
        let profile = LocalProfileStore.loadProfile()
        let hasCompleted = LocalProfileStore.hasCompletedOnboarding()
        let shouldSkipOnboarding = profile?.isComplete == true

        if shouldSkipOnboarding {
            LocalProfileStore.markOnboardingCompleted()
        } else if hasCompleted {
            // Completion flag without a readable profile — reset stale onboarding state.
            LocalProfileStore.clearProfileAndOnboarding()
        }

        self.init(
            route: shouldSkipOnboarding ? .main : .onboarding,
            userProfile: shouldSkipOnboarding ? profile : nil,
            weeklyMealPlan: LocalProfileStore.loadMealPlan(),
            seasoningInventory: LocalProfileStore.loadSeasoningInventory(),
            favoriteRecipes: LocalProfileStore.loadFavorites(),
            userRecipes: LocalProfileStore.loadUserRecipes(),
            extraGroceryItems: LocalProfileStore.loadExtraGroceryItems(),
            onboardingProgress: shouldSkipOnboarding ? nil : LocalProfileStore.loadOnboardingProgress(),
            persistsLocally: true
        )
    }

    /// Previews and tests: in-memory only unless `persistsLocally` is enabled.
    init(
        route: Route = .onboarding,
        userProfile: OnboardingDraft? = nil,
        weeklyMealPlan: WeeklyMealPlan = WeeklyMealPlan(),
        seasoningInventory: SeasoningInventory = SeasoningInventory(),
        favoriteRecipes: FavoriteRecipes = FavoriteRecipes(),
        userRecipes: UserRecipes = UserRecipes(),
        extraGroceryItems: ExtraGroceryItems = ExtraGroceryItems(),
        onboardingProgress: LocalProfileStore.OnboardingProgress? = nil,
        persistsLocally: Bool = false
    ) {
        self.route = route
        self.userProfile = userProfile
        self.weeklyMealPlan = weeklyMealPlan
        self.seasoningInventory = seasoningInventory
        self.favoriteRecipes = favoriteRecipes
        self.userRecipes = userRecipes
        self.extraGroceryItems = extraGroceryItems
        self.onboardingProgress = onboardingProgress
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
        GroceryListBuilder.build(
            from: weeklyMealPlan,
            excluding: seasoningInventory,
            extras: extraGroceryItems
        )
    }

    var userRecipeList: [RecipeSummary] {
        userRecipes.sortedRecipes
    }

    func recipe(withID id: String) -> RecipeSummary? {
        RecipeCatalog.recipe(withID: id, userRecipes: userRecipeList)
    }

    func discoverDeck(isPlanComplete: Bool) -> [RecipeSummary] {
        let plannedIDs = Set(weeklyMealPlan.recipes.map(\.id))
        return RecipeCatalog.deck(
            excluding: plannedIDs,
            profile: nutritionProfile,
            plan: weeklyMealPlan,
            isPlanComplete: isPlanComplete,
            userRecipes: userRecipeList
        )
    }

    @discardableResult
    func saveUserRecipe(_ recipe: RecipeSummary) -> Bool {
        guard recipe.isUserRecipe else { return false }

        if let index = userRecipes.recipes.firstIndex(where: { $0.id == recipe.id }) {
            userRecipes.recipes[index] = recipe
        } else {
            userRecipes.recipes.append(recipe)
        }

        for index in weeklyMealPlan.recipes.indices where weeklyMealPlan.recipes[index].id == recipe.id {
            weeklyMealPlan.recipes[index] = recipe
        }

        persistUserRecipes()
        persistMealPlan()
        return true
    }

    func deleteUserRecipe(id: String) {
        userRecipes.recipes.removeAll { $0.id == id }
        UserRecipeImageStore.delete(for: id)
        removeRecipeFromWeeklyPlan(id: id)
        if favoriteRecipes.contains(id) {
            favoriteRecipes.toggle(id)
            persistFavorites()
        }
        persistUserRecipes()
    }

    func completeOnboarding(with draft: OnboardingDraft) {
        guard draft.isComplete else { return }
        userProfile = draft
        weeklyMealPlan = WeeklyMealPlan()
        showPlanCompleteCelebration = false
        onboardingProgress = nil
        persistCompletedProfile()
        route = .main
    }

    /// Saves in-progress onboarding so a relaunch can resume the same step.
    func saveOnboardingProgress(draft: OnboardingDraft, step: OnboardingViewModel.Step) {
        let progress = LocalProfileStore.OnboardingProgress(
            draft: draft,
            stepRawValue: step.rawValue,
            flowVersion: LocalProfileStore.OnboardingProgress.currentFlowVersion
        )
        onboardingProgress = progress
        guard persistsLocally else { return }
        LocalProfileStore.saveOnboardingProgress(progress)
        persistSeasoningInventory()
    }

    func clearOnboardingProgressRestore() {
        onboardingProgress = nil
    }

    /// Updates the saved profile (body metrics and/or macros) from the Profile tab.
    func updateUserProfile(_ draft: OnboardingDraft) {
        userProfile = draft
        persistProfile()
    }

    func resetOnboardingPreview() {
        userProfile = nil
        weeklyMealPlan = WeeklyMealPlan()
        seasoningInventory = SeasoningInventory()
        favoriteRecipes = FavoriteRecipes()
        userRecipes = UserRecipes()
        extraGroceryItems = ExtraGroceryItems()
        showPlanCompleteCelebration = false
        onboardingProgress = nil
        route = .onboarding
        if persistsLocally {
            LocalProfileStore.clear()
        }
    }

    /// Flushes profile-related data when the app backgrounds.
    func persistSessionState() {
        guard persistsLocally else { return }
        if let userProfile, userProfile.isComplete {
            LocalProfileStore.saveProfile(userProfile)
            LocalProfileStore.markOnboardingCompleted()
        }
        LocalProfileStore.saveMealPlan(weeklyMealPlan)
        LocalProfileStore.saveSeasoningInventory(seasoningInventory)
        LocalProfileStore.saveFavorites(favoriteRecipes)
        LocalProfileStore.saveUserRecipes(userRecipes)
        LocalProfileStore.saveExtraGroceryItems(extraGroceryItems)
    }

    func isFavorite(recipeID: String) -> Bool {
        favoriteRecipes.contains(recipeID)
    }

    func toggleFavorite(recipeID: String) {
        favoriteRecipes.toggle(recipeID)
        persistFavorites()
    }

    /// Liked recipes auto-save to the weekly plan. Meals stop once the meal target
    /// is met; snacks (tagged in the recipe catalog) can still be added afterward.
    @discardableResult
    func addRecipeToWeeklyPlan(_ recipe: RecipeSummary) -> Bool {
        guard !weeklyMealPlan.contains(recipeID: recipe.id) else { return false }
        if !recipe.isSnack {
            guard !hasCompletedWeeklyMeals else { return false }
        }

        let mealsWereComplete = hasCompletedWeeklyMeals
        weeklyMealPlan.recipes.append(recipe)

        // Celebrate when the week's meal total is first reached (meals only, not snacks).
        if !mealsWereComplete, nutritionProfile.progress(for: weeklyMealPlan).mealsComplete {
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
        // Pantry staples are intentionally kept — they persist independently of the weekly plan.
    }

    func addSeasoning(_ name: String) {
        seasoningInventory.add(name)
        persistSeasoningInventory()
    }

    func removeSeasoning(_ name: String) {
        seasoningInventory.remove(name)
        persistSeasoningInventory()
    }

    func addExtraGroceryItem(_ name: String) {
        extraGroceryItems.add(name)
        persistExtraGroceryItems()
    }

    func removeExtraGroceryItem(_ name: String) {
        extraGroceryItems.remove(name)
        persistExtraGroceryItems()
    }

    private func persistCompletedProfile() {
        guard persistsLocally else { return }
        LocalProfileStore.saveProfile(userProfile)
        LocalProfileStore.markOnboardingCompleted()
        LocalProfileStore.saveOnboardingProgress(nil)
        LocalProfileStore.saveMealPlan(weeklyMealPlan)
        LocalProfileStore.saveSeasoningInventory(seasoningInventory)
        LocalProfileStore.saveFavorites(favoriteRecipes)
        LocalProfileStore.saveUserRecipes(userRecipes)
        LocalProfileStore.saveExtraGroceryItems(extraGroceryItems)
    }

    private func persistProfile() {
        guard persistsLocally else { return }
        LocalProfileStore.saveProfile(userProfile)
        LocalProfileStore.markOnboardingCompleted()
    }

    private func persistUserRecipes() {
        guard persistsLocally else { return }
        LocalProfileStore.saveUserRecipes(userRecipes)
    }

    private func persistMealPlan() {
        guard persistsLocally else { return }
        LocalProfileStore.saveMealPlan(weeklyMealPlan)
    }

    private func persistSeasoningInventory() {
        guard persistsLocally else { return }
        LocalProfileStore.saveSeasoningInventory(seasoningInventory)
    }

    private func persistFavorites() {
        guard persistsLocally else { return }
        LocalProfileStore.saveFavorites(favoriteRecipes)
    }

    private func persistExtraGroceryItems() {
        guard persistsLocally else { return }
        LocalProfileStore.saveExtraGroceryItems(extraGroceryItems)
    }
}
