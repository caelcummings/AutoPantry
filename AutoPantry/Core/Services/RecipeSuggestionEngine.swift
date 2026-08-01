import Foundation

/// Ranks discover-feed recipes to help fill weekly macro and meal goals.
enum RecipeSuggestionEngine {
    struct MacroNeeds: Equatable {
        var calories: Int
        var protein: Int
        var carbs: Int
        var fat: Int
        var mealsRemaining: Int
    }

    /// Build a discover deck: smart-ranked with light randomness, or shuffled when the week is complete.
    static func buildDeck(
        from candidates: [RecipeSummary],
        profile: NutritionProfile,
        plan: WeeklyMealPlan,
        isPlanComplete: Bool
    ) -> [RecipeSummary] {
        guard !candidates.isEmpty else { return [] }

        if isPlanComplete {
            return candidates.shuffled()
        }

        let needs = macroNeeds(profile: profile, plan: plan)
        let scored = candidates.map { recipe -> (RecipeSummary, Double) in
            (recipe, score(recipe: recipe, needs: needs, profile: profile, plan: plan))
        }

        let sorted = scored.sorted { $0.1 > $1.1 }.map(\.0)

        // Keep top smart picks first, but shuffle within tiers so the feed feels fresh.
        let tierSize = max(8, sorted.count / 5)
        var deck: [RecipeSummary] = []
        var index = 0
        while index < sorted.count {
            let end = min(index + tierSize, sorted.count)
            deck.append(contentsOf: sorted[index..<end].shuffled())
            index = end
        }
        return deck
    }

    static func macroNeeds(profile: NutritionProfile, plan: WeeklyMealPlan) -> MacroNeeds {
        let totals = plan.totalsUsingEstimates
        let mealsRemaining = max(1, profile.mealsPerWeek - totals.mealCount)

        return MacroNeeds(
            calories: max(0, profile.calories.weeklyMin - totals.calories),
            protein: max(0, profile.proteinGrams.weeklyMin - totals.protein),
            carbs: max(0, profile.carbsGrams.weeklyMin - totals.carbs),
            fat: max(0, profile.fatGrams.weeklyMin - totals.fat),
            mealsRemaining: mealsRemaining
        )
    }

    private static func score(
        recipe: RecipeSummary,
        needs: MacroNeeds,
        profile: NutritionProfile,
        plan: WeeklyMealPlan
    ) -> Double {
        let macros = recipe.effectiveMacros
        let servings = recipe.mealContribution
        let totals = plan.totalsUsingEstimates

        let addedCalories = macros.calories * servings
        let addedProtein = macros.proteinGrams * servings
        let addedCarbs = macros.carbsGrams * servings
        let addedFat = macros.fatGrams * servings

        let newCalories = totals.calories + addedCalories
        let newProtein = totals.protein + addedProtein
        let newCarbs = totals.carbs + addedCarbs
        let newFat = totals.fat + addedFat
        let newMeals = totals.mealCount + servings

        var score = 0.0

        // Prefer recipes whose serving count fits remaining meal slots.
        if newMeals <= profile.mealsPerWeek {
            score += 12
            if servings <= needs.mealsRemaining {
                score += min(20, Double(servings) * 3)
            }
        } else {
            score -= Double(newMeals - profile.mealsPerWeek) * 8
        }

        // Strong penalty if this meal would blow past weekly max.
        if newCalories > profile.calories.weeklyMax { score -= 80 }
        if newProtein > profile.proteinGrams.weeklyMax { score -= 50 }
        if newCarbs > profile.carbsGrams.weeklyMax { score -= 40 }
        if newFat > profile.fatGrams.weeklyMax { score -= 40 }

        // Reward filling what's still missing (weighted by user ranges).
        if needs.calories > 0 {
            score += min(40, Double(addedCalories) / Double(needs.calories / needs.mealsRemaining + 1) * 12)
        }
        if needs.protein > 0 {
            score += min(35, Double(addedProtein) / Double(needs.protein / needs.mealsRemaining + 1) * 14)
        }
        if needs.carbs > 0 {
            score += min(20, Double(addedCarbs) / Double(needs.carbs / needs.mealsRemaining + 1) * 8)
        }
        if needs.fat > 0 {
            score += min(15, Double(addedFat) / Double(needs.fat / needs.mealsRemaining + 1) * 8)
        }

        // Prefer meals that land near per-meal targets when many meals remain.
        let targetCalPerMeal = profile.calories.midpoint
        let targetProteinPerMeal = profile.proteinGrams.midpoint
        let calDelta = abs(macros.calories - targetCalPerMeal)
        let proteinDelta = abs(macros.proteinGrams - targetProteinPerMeal)
        score += max(0, 25 - Double(calDelta) / 25)
        score += max(0, 20 - Double(proteinDelta) / 3)

        // Light randomness so suggestions rotate between good options.
        score += Double.random(in: 0...4)

        return score
    }
}

extension WeeklyMealPlan {
    var totalsUsingEstimates: WeeklyMacroTotals {
        recipes.reduce(into: WeeklyMacroTotals()) { totals, recipe in
            let macros = recipe.effectiveMacros
            let servings = recipe.mealContribution
            // Macros on recipes are per serving; scale by servings toward the week.
            totals.calories += macros.calories * servings
            totals.protein += macros.proteinGrams * servings
            totals.carbs += macros.carbsGrams * servings
            totals.fat += macros.fatGrams * servings
            totals.mealCount += servings
        }
    }
}
