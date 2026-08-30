import Foundation

/// Estimates daily macro ranges from body metrics (Mifflin–St Jeor + activity + goal).
enum MacroCalculator {
    /// Builds a full nutrition profile, preserving `mealsPerWeek`.
    static func estimate(
        body: UserBodyProfile,
        mealsPerWeek: Int = 21
    ) -> NutritionProfile {
        let calories = targetCalories(for: body)
        let split = macroSplit(calories: calories, body: body)

        var profile = NutritionProfile()
        profile.mealsPerWeek = min(35, max(7, mealsPerWeek))
        profile.calories = range(around: calories, spread: 100, step: 50, clamp: 1_200...3_500)
        profile.proteinGrams = range(around: split.protein, spread: 15, step: 5, clamp: 50...250)
        profile.carbsGrams = range(around: split.carbs, spread: 20, step: 5, clamp: 20...350)
        profile.fatGrams = range(around: split.fat, spread: 10, step: 5, clamp: 20...200)
        return profile
    }

    /// Basal metabolic rate via Mifflin–St Jeor (kcal / day).
    static func basalMetabolicRate(for body: UserBodyProfile) -> Int {
        let base = 10 * body.weightKg + 6.25 * body.heightCm - 5 * Double(body.ageYears)
        let adjusted: Double
        switch body.sex {
        case .male:
            adjusted = base + 5
        case .female:
            adjusted = base - 161
        case .preferNotToSay:
            // Midpoint between male (+5) and female (−161) offsets.
            adjusted = base - 78
        }
        return max(Int(adjusted.rounded()), 1_000)
    }

    /// Maintenance calories (TDEE) before goal adjustment.
    static func maintenanceCalories(for body: UserBodyProfile) -> Int {
        let tdee = Double(basalMetabolicRate(for: body)) * body.activityLevel.multiplier
        return max(Int(tdee.rounded()), 1_200)
    }

    /// Daily calorie target after applying weight-goal surplus/deficit.
    static func targetCalories(for body: UserBodyProfile) -> Int {
        let maintenance = maintenanceCalories(for: body)
        let deltaPounds = abs(body.desiredWeightPounds - body.weightPounds)

        let adjustment: Int
        switch body.weightGoalDirection {
        case .maintain:
            adjustment = 0
        case .lose:
            // ~0.5–1 lb/week: 250–500 kcal deficit, scaled by how far the goal is.
            adjustment = -min(750, max(250, 200 + deltaPounds * 15))
        case .gain:
            adjustment = min(500, max(200, 150 + deltaPounds * 10))
        }

        return min(3_500, max(1_200, maintenance + adjustment))
    }

    // MARK: - Private

    private struct MacroSplit {
        var protein: Int
        var carbs: Int
        var fat: Int
    }

    private static func macroSplit(calories: Int, body: UserBodyProfile) -> MacroSplit {
        let kg = body.weightKg

        let proteinPerKg: Double
        switch body.weightGoalDirection {
        case .lose: proteinPerKg = 2.0
        case .gain: proteinPerKg = 1.8
        case .maintain: proteinPerKg = 1.6
        }

        var protein = Int((kg * proteinPerKg).rounded())
        protein = min(220, max(80, protein))

        // ~25–30% of calories from fat, floored by bodyweight.
        let fatFromPercent = Int((Double(calories) * 0.28 / 9.0).rounded())
        let fatFromWeight = Int((kg * 0.8).rounded())
        var fat = max(fatFromPercent, fatFromWeight)
        fat = min(150, max(40, fat))

        let caloriesFromProtein = protein * 4
        let caloriesFromFat = fat * 9
        let remaining = max(calories - caloriesFromProtein - caloriesFromFat, 80)
        var carbs = Int((Double(remaining) / 4.0).rounded())
        carbs = min(350, max(20, carbs))

        return MacroSplit(protein: protein, carbs: carbs, fat: fat)
    }

    private static func range(
        around midpoint: Int,
        spread: Int,
        step: Int,
        clamp: ClosedRange<Int>
    ) -> MacroRange {
        let stepped: (Int) -> Int = { value in
            let rounded = Int((Double(value) / Double(step)).rounded()) * step
            return min(clamp.upperBound, max(clamp.lowerBound, rounded))
        }
        var minValue = stepped(midpoint - spread)
        var maxValue = stepped(midpoint + spread)
        if maxValue < minValue { swap(&minValue, &maxValue) }
        if minValue == maxValue {
            maxValue = min(clamp.upperBound, minValue + step)
        }
        return MacroRange(min: minValue, max: maxValue)
    }
}
