import Foundation

/// Backward-compatible access — recipes load from `Resources/recipes.json`.
enum MockRecipes {
    static var feed: [RecipeSummary] { RecipeCatalog.feed }

    static func deck(
        excluding plannedIDs: Set<String>,
        profile: NutritionProfile,
        plan: WeeklyMealPlan,
        isPlanComplete: Bool
    ) -> [RecipeSummary] {
        RecipeCatalog.deck(
            excluding: plannedIDs,
            profile: profile,
            plan: plan,
            isPlanComplete: isPlanComplete
        )
    }
}
