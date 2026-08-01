import Foundation

struct WeeklyMacroTotals: Equatable {
    var calories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var mealCount: Int = 0
}

struct WeeklyMealPlan: Equatable, Codable {
    var recipes: [RecipeSummary] = []

    var totals: WeeklyMacroTotals {
        totalsUsingEstimates
    }

    var recipesWithMacros: [RecipeSummary] {
        recipes.filter(\.hasMacros)
    }

    func contains(recipeID: String) -> Bool {
        recipes.contains { $0.id == recipeID }
    }
}

struct WeeklyPlanProgress: Equatable {
    var mealsFilled: Int
    var mealsTarget: Int
    var caloriesFilled: Int
    var caloriesMin: Int
    var caloriesMax: Int
    var proteinFilled: Int
    var proteinMin: Int
    var proteinMax: Int

    var mealsComplete: Bool { mealsFilled >= mealsTarget }
    var caloriesComplete: Bool { caloriesFilled >= caloriesMin && caloriesFilled <= caloriesMax }
    var proteinComplete: Bool { proteinFilled >= proteinMin && proteinFilled <= proteinMax }

    var isComplete: Bool { mealsComplete && caloriesComplete && proteinComplete }

    var mealsProgress: Double {
        guard mealsTarget > 0 else { return 0 }
        return min(Double(mealsFilled) / Double(mealsTarget), 1)
    }

    var caloriesProgress: Double {
        guard caloriesMax > 0 else { return 0 }
        return min(Double(caloriesFilled) / Double(caloriesMax), 1)
    }
}

extension NutritionProfile {
    func progress(for plan: WeeklyMealPlan) -> WeeklyPlanProgress {
        let totals = plan.totals
        return WeeklyPlanProgress(
            mealsFilled: totals.mealCount,
            mealsTarget: mealsPerWeek,
            caloriesFilled: totals.calories,
            caloriesMin: calories.weeklyMin,
            caloriesMax: calories.weeklyMax,
            proteinFilled: totals.protein,
            proteinMin: proteinGrams.weeklyMin,
            proteinMax: proteinGrams.weeklyMax
        )
    }

    func isPlanComplete(_ plan: WeeklyMealPlan) -> Bool {
        let progress = progress(for: plan)
        guard progress.mealsComplete else { return false }

        return progress.isComplete
            && plan.totals.carbs >= carbsGrams.weeklyMin
            && plan.totals.carbs <= carbsGrams.weeklyMax
            && plan.totals.fat >= fatGrams.weeklyMin
            && plan.totals.fat <= fatGrams.weeklyMax
    }
}
