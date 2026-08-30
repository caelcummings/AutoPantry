import Foundation

/// Ranks discover-feed recipes to help fill weekly macro and meal goals,
/// while preferring dishes that reuse ingredients already on the weekly list
/// so grocery carts stay smaller.
enum RecipeSuggestionEngine {
    struct MacroNeeds: Equatable {
        var calories: Int
        var protein: Int
        var carbs: Int
        var fat: Int
        var mealsRemaining: Int
    }

    /// At or above this weekly meal target, Discover ranks for macros / meal fit.
    /// Below it, the feed is fully random.
    private static let smartRankingMealThreshold = 21

    /// Noise added on top of the smart score so equally-good recipes rotate week to week.
    /// Kept below hard macro penalties (~40–80) so unfit meals stay buried.
    private static let rankingJitter: ClosedRange<Double> = 0...26

    /// Build a discover deck: smart-ranked when aiming for 21+ meals/week, otherwise fully random.
    static func buildDeck(
        from candidates: [RecipeSummary],
        profile: NutritionProfile,
        plan: WeeklyMealPlan,
        isPlanComplete: Bool
    ) -> [RecipeSummary] {
        guard !candidates.isEmpty else { return [] }

        // Fewer than 21 meals/week → no goal-oriented ranking.
        if profile.mealsPerWeek < smartRankingMealThreshold {
            return candidates.shuffled()
        }

        let plannedKeys = shoppableIngredientKeys(from: plan.recipes)

        if isPlanComplete {
            // Meal slots are full; still surface ingredient-overlapping snacks first.
            guard !plannedKeys.isEmpty else { return candidates.shuffled() }
            let scored = candidates.map { recipe -> (RecipeSummary, Double) in
                (
                    recipe,
                    ingredientOverlapScore(recipe: recipe, plannedKeys: plannedKeys)
                        + Double.random(in: rankingJitter)
                )
            }
            return tieredShuffle(scored.sorted { $0.1 > $1.1 }.map(\.0))
        }

        let needs = macroNeeds(profile: profile, plan: plan)
        let scored = candidates.map { recipe -> (RecipeSummary, Double) in
            (
                recipe,
                score(
                    recipe: recipe,
                    needs: needs,
                    profile: profile,
                    plan: plan,
                    plannedKeys: plannedKeys
                )
            )
        }

        return tieredShuffle(scored.sorted { $0.1 > $1.1 }.map(\.0))
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

    /// Keep stronger macro fits toward the front, but shuffle within wide bands
    /// so the same handful of recipes isn't always first.
    private static func tieredShuffle(_ sorted: [RecipeSummary]) -> [RecipeSummary] {
        guard sorted.count > 1 else { return sorted }

        // Wider front band as the catalog grows (~1/3 of recipes compete for early slots).
        let frontBand = max(15, (sorted.count + 2) / 3)
        var deck: [RecipeSummary] = []
        var index = 0
        var bandSize = frontBand

        while index < sorted.count {
            let end = min(index + bandSize, sorted.count)
            deck.append(contentsOf: sorted[index..<end].shuffled())
            index = end
            // Later bands stay mixed but get a bit smaller so weak fits stay farther back.
            bandSize = max(10, bandSize * 2 / 3)
        }
        return deck
    }

    private static func score(
        recipe: RecipeSummary,
        needs: MacroNeeds,
        profile: NutritionProfile,
        plan: WeeklyMealPlan,
        plannedKeys: Set<String>
    ) -> Double {
        let macros = recipe.effectiveMacros
        let portions = recipe.portionCount
        let mealSlots = recipe.mealContribution
        let totals = plan.totalsUsingEstimates

        let addedCalories = macros.calories * portions
        let addedProtein = macros.proteinGrams * portions
        let addedCarbs = macros.carbsGrams * portions
        let addedFat = macros.fatGrams * portions

        let newCalories = totals.calories + addedCalories
        let newProtein = totals.protein + addedProtein
        let newCarbs = totals.carbs + addedCarbs
        let newFat = totals.fat + addedFat
        let newMeals = totals.mealCount + mealSlots

        var score = 0.0

        if recipe.isSnack {
            // Snacks don't fill meal slots; lightly prefer them when macros still need topping up.
            score += 6
        } else if newMeals <= profile.mealsPerWeek {
            // Prefer recipes whose serving count fits remaining meal slots.
            score += 12
            if mealSlots <= needs.mealsRemaining {
                score += min(20, Double(mealSlots) * 3)
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
        if !recipe.isSnack {
            let targetCalPerMeal = profile.calories.midpoint
            let targetProteinPerMeal = profile.proteinGrams.midpoint
            let calDelta = abs(macros.calories - targetCalPerMeal)
            let proteinDelta = abs(macros.proteinGrams - targetProteinPerMeal)
            score += max(0, 25 - Double(calDelta) / 25)
            score += max(0, 20 - Double(proteinDelta) / 3)
        }

        // Prefer recipes that reuse shoppable ingredients already in the week.
        score += ingredientOverlapScore(recipe: recipe, plannedKeys: plannedKeys)

        // Enough jitter to reorder similar macro fits without promoting bad fits.
        score += Double.random(in: rankingJitter)

        return score
    }

    /// Reward shared grocery items; soft-penalize recipes that add many brand-new ones.
    private static func ingredientOverlapScore(
        recipe: RecipeSummary,
        plannedKeys: Set<String>
    ) -> Double {
        guard !plannedKeys.isEmpty else { return 0 }

        let recipeKeys = shoppableIngredientKeys(from: [recipe])
        guard !recipeKeys.isEmpty else { return 0 }

        let sharedCount = recipeKeys.intersection(plannedKeys).count
        let newCount = recipeKeys.subtracting(plannedKeys).count
        let overlapRatio = Double(sharedCount) / Double(recipeKeys.count)

        var bonus = 0.0
        // Each reused item (chicken, eggs, tortillas…) meaningfully shrinks the list.
        bonus += Double(sharedCount) * 9
        // Prefer recipes where most of their shoppable ingredients are already planned.
        bonus += overlapRatio * 28
        // Soft cost for introducing many brand-new shoppables.
        if newCount > 2 {
            bonus -= Double(newCount - 2) * 2.5
        }

        // Cap so macros and meal fit still matter.
        return min(48, max(-12, bonus))
    }

    /// Keys for ingredients that drive grocery list size (skip pantry staples like salt/oil).
    private static func shoppableIngredientKeys(from recipes: [RecipeSummary]) -> Set<String> {
        var keys = Set<String>()
        for recipe in recipes {
            for ingredient in recipe.ingredients {
                let key = IngredientNormalizer.groceryKey(for: ingredient.name)
                guard !key.isEmpty else { continue }
                guard !SeasoningMatcher.isPantryStaple(ingredient.name) else { continue }
                keys.insert(key)
            }
        }
        return keys
    }
}

extension WeeklyMealPlan {
    var totalsUsingEstimates: WeeklyMacroTotals {
        recipes.reduce(into: WeeklyMacroTotals()) { totals, recipe in
            let macros = recipe.effectiveMacros
            let portions = recipe.portionCount
            // Macros on recipes are per serving; scale by portions toward the week.
            totals.calories += macros.calories * portions
            totals.protein += macros.proteinGrams * portions
            totals.carbs += macros.carbsGrams * portions
            totals.fat += macros.fatGrams * portions
            // Snacks (catalog-tagged) do not fill meal slots.
            totals.mealCount += recipe.mealContribution
        }
    }
}
