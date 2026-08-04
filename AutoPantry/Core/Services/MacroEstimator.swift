import Foundation

/// Rough per-serving macro estimates from ingredient names (used when JSON has no nutrition).
enum MacroEstimator {
    struct Estimate: Equatable {
        let calories: Int
        let proteinGrams: Int
        let carbsGrams: Int
        let fatGrams: Int
    }

    static func estimate(for recipe: RecipeSummary) -> Estimate {
        if recipe.hasMacros,
           let calories = recipe.calories,
           let protein = recipe.proteinGrams,
           let carbs = recipe.carbsGrams,
           let fat = recipe.fatGrams {
            return Estimate(calories: calories, proteinGrams: protein, carbsGrams: carbs, fatGrams: fat)
        }

        let names = recipe.ingredients.map { $0.name.lowercased() }
        var proteinScore = 0
        var carbScore = 0
        var fatScore = 0

        for name in names {
            if matches(name, proteinKeywords) { proteinScore += 1 }
            if matches(name, carbKeywords) { carbScore += 1 }
            if matches(name, fatKeywords) { fatScore += 1 }
        }

        let protein = min(75, 12 + proteinScore * 14)
        let carbs = min(110, 18 + carbScore * 16)
        let fat = min(55, 10 + fatScore * 9)
        let calories = min(1_100, max(420, 280 + recipe.ingredientCount * 35 + protein * 4 + carbs * 3))

        return Estimate(calories: calories, proteinGrams: protein, carbsGrams: carbs, fatGrams: fat)
    }

    private static let proteinKeywords = [
        "chicken", "beef", "pork", "turkey", "fish", "salmon", "shrimp", "tuna", "cod",
        "egg", "tofu", "beans", "lentils", "chickpea", "protein", "bacon", "ham", "sausage",
    ]

    private static let carbKeywords = [
        "rice", "pasta", "noodle", "bread", "tortilla", "potato", "oats", "flour", "sugar",
        "quinoa", "corn", "bean", "lentil", "pepper", "tomato",
    ]

    private static let fatKeywords = [
        "oil", "butter", "cheese", "cream", "avocado", "nuts", "almond", "peanut", "coconut",
        "mayonnaise", "bacon",
    ]

    private static func matches(_ name: String, _ keywords: [String]) -> Bool {
        keywords.contains { name.contains($0) }
    }
}

extension RecipeSummary {
    var effectiveMacros: MacroEstimator.Estimate {
        MacroEstimator.estimate(for: self)
    }

    /// Recipes under 300 calories per serving are snacks (not meals).
    var isSnack: Bool {
        effectiveMacros.calories < 300
    }

    /// Portions used for grocery/macro scaling (always at least 1).
    var portionCount: Int { max(servings, 1) }

    /// Meal slots filled toward the weekly meal target (snacks contribute 0).
    var mealContribution: Int { isSnack ? 0 : portionCount }
}
