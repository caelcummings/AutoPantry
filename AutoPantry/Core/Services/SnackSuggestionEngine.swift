import Foundation

/// Shortfalls vs weekly macro minimums — used to suggest snacks on the celebration screen.
struct MacroGaps: Equatable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int

    var hasAnyGap: Bool {
        calories > 0 || protein > 0 || carbs > 0 || fat > 0
    }

    /// Human-readable lines for the celebration UI.
    var summaryLines: [String] {
        var lines: [String] = []
        if calories > 0 { lines.append("~\((calories).formatted()) cal") }
        if protein > 0 { lines.append("~\((protein).formatted())g protein") }
        if carbs > 0 { lines.append("~\((carbs).formatted())g carbs") }
        if fat > 0 { lines.append("~\((fat).formatted())g fat") }
        return lines
    }

    /// Weekly shortfall spread across 7 days (rounded up so the week still closes).
    var dailyCalories: Int { dailyAmount(for: calories) }
    var dailyProtein: Int { dailyAmount(for: protein) }
    var dailyCarbs: Int { dailyAmount(for: carbs) }
    var dailyFat: Int { dailyAmount(for: fat) }

    /// e.g. "an extra ~20g protein and ~200 cal per day"
    var dailySupplementPhrase: String? {
        var parts: [String] = []
        if dailyCalories > 0 { parts.append("~\(dailyCalories.formatted()) cal") }
        if dailyProtein > 0 { parts.append("~\(dailyProtein.formatted())g protein") }
        if dailyCarbs > 0 { parts.append("~\(dailyCarbs.formatted())g carbs") }
        if dailyFat > 0 { parts.append("~\(dailyFat.formatted())g fat") }
        guard !parts.isEmpty else { return nil }

        let joined: String
        switch parts.count {
        case 1:
            joined = parts[0]
        case 2:
            joined = "\(parts[0]) and \(parts[1])"
        default:
            joined = parts.dropLast().joined(separator: ", ") + ", and \(parts.last!)"
        }
        return "an extra \(joined) per day"
    }

    private func dailyAmount(for weeklyGap: Int) -> Int {
        guard weeklyGap > 0 else { return 0 }
        return max(1, Int(ceil(Double(weeklyGap) / 7.0)))
    }
}

extension NutritionProfile {
    func macroGaps(for totals: WeeklyMacroTotals) -> MacroGaps {
        MacroGaps(
            calories: max(0, calories.weeklyMin - totals.calories),
            protein: max(0, proteinGrams.weeklyMin - totals.protein),
            carbs: max(0, carbsGrams.weeklyMin - totals.carbs),
            fat: max(0, fatGrams.weeklyMin - totals.fat)
        )
    }
}

/// Picks catalog snacks that best close remaining macro gaps without blowing past weekly maxes.
enum SnackSuggestionEngine {
    static func suggestions(
        profile: NutritionProfile,
        plan: WeeklyMealPlan,
        userRecipes: [RecipeSummary] = [],
        limit: Int = 6
    ) -> [RecipeSummary] {
        let gaps = profile.macroGaps(for: plan.totals)
        guard gaps.hasAnyGap else { return [] }

        let plannedIDs = Set(plan.recipes.map(\.id))
        let candidates = (RecipeCatalog.feed + userRecipes).filter { $0.isSnack && !plannedIDs.contains($0.id) }
        guard !candidates.isEmpty else { return [] }

        let scored = candidates.map { snack -> (RecipeSummary, Double) in
            (snack, score(snack: snack, gaps: gaps, profile: profile, totals: plan.totals))
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    private static func score(
        snack: RecipeSummary,
        gaps: MacroGaps,
        profile: NutritionProfile,
        totals: WeeklyMacroTotals
    ) -> Double {
        let macros = snack.effectiveMacros
        let portions = snack.portionCount
        let addCal = macros.calories * portions
        let addProtein = macros.proteinGrams * portions
        let addCarbs = macros.carbsGrams * portions
        let addFat = macros.fatGrams * portions

        var score = 0.0

        if gaps.calories > 0 {
            score += min(Double(addCal), Double(gaps.calories)) * 0.06
        }
        if gaps.protein > 0 {
            score += min(Double(addProtein), Double(gaps.protein)) * 0.18
        }
        if gaps.carbs > 0 {
            score += min(Double(addCarbs), Double(gaps.carbs)) * 0.04
        }
        if gaps.fat > 0 {
            score += min(Double(addFat), Double(gaps.fat)) * 0.04
        }

        // Prefer snacks that actually move the needle when a gap exists.
        if gaps.calories > 0 && addCal == 0 { score -= 20 }
        if gaps.protein > 0 && addProtein == 0 { score -= 25 }

        // Soft penalty for pushing far past weekly max.
        if totals.calories + addCal > profile.calories.weeklyMax {
            score -= Double(totals.calories + addCal - profile.calories.weeklyMax) * 0.04
        }
        if totals.protein + addProtein > profile.proteinGrams.weeklyMax {
            score -= Double(totals.protein + addProtein - profile.proteinGrams.weeklyMax) * 0.08
        }

        return score
    }
}
