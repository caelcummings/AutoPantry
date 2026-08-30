import Foundation

/// Min–max range for a single macro (daily). Weekly totals multiply by 7.
struct MacroRange: Equatable, Codable {
    var min: Int
    var max: Int

    var midpoint: Int { (min + max) / 2 }
    var weeklyMin: Int { min * 7 }
    var weeklyMax: Int { max * 7 }

    var isValid: Bool { min > 0 && max >= min }

    static func defaultCalories() -> MacroRange { MacroRange(min: 1_800, max: 2_200) }
    static func defaultProtein() -> MacroRange { MacroRange(min: 120, max: 160) }
    static func defaultCarbs() -> MacroRange { MacroRange(min: 150, max: 200) }
    static func defaultFat() -> MacroRange { MacroRange(min: 50, max: 70) }
}

/// Daily macro targets collected during profile onboarding.
struct NutritionProfile: Equatable, Codable {
    var calories: MacroRange = .defaultCalories()
    var proteinGrams: MacroRange = .defaultProtein()
    var carbsGrams: MacroRange = .defaultCarbs()
    var fatGrams: MacroRange = .defaultFat()
    var mealsPerWeek: Int = 21

    var isValid: Bool {
        calories.isValid && proteinGrams.isValid && carbsGrams.isValid && fatGrams.isValid
            && mealsPerWeek >= 7 && mealsPerWeek <= 35
    }

    /// Average macros per planned meal (used when building weekly recipe lists).
    var caloriesPerMeal: Int {
        max((calories.midpoint * 7) / max(mealsPerWeek, 1), 1)
    }

    var proteinPerMeal: Int {
        max((proteinGrams.midpoint * 7) / max(mealsPerWeek, 1), 1)
    }
}

enum MacroPreset: String, CaseIterable, Identifiable {
    case balanced
    case highProtein
    case lowCarb
    case keto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: "Balanced"
        case .highProtein: "High protein"
        case .lowCarb: "Low carb"
        case .keto: "Keto"
        }
    }

    var subtitle: String {
        switch self {
        case .balanced: "Flexible everyday targets"
        case .highProtein: "Muscle-forward, higher protein"
        case .lowCarb: "Moderate carbs, steady energy"
        case .keto: "Low carb, higher fat"
        }
    }

    func apply(to profile: inout NutritionProfile) {
        switch self {
        case .balanced:
            profile.calories = MacroRange(min: 1_800, max: 2_200)
            profile.proteinGrams = MacroRange(min: 110, max: 150)
            profile.carbsGrams = MacroRange(min: 180, max: 230)
            profile.fatGrams = MacroRange(min: 55, max: 75)
        case .highProtein:
            profile.calories = MacroRange(min: 1_900, max: 2_400)
            profile.proteinGrams = MacroRange(min: 150, max: 200)
            profile.carbsGrams = MacroRange(min: 120, max: 180)
            profile.fatGrams = MacroRange(min: 50, max: 70)
        case .lowCarb:
            profile.calories = MacroRange(min: 1_700, max: 2_100)
            profile.proteinGrams = MacroRange(min: 120, max: 160)
            profile.carbsGrams = MacroRange(min: 80, max: 130)
            profile.fatGrams = MacroRange(min: 65, max: 90)
        case .keto:
            profile.calories = MacroRange(min: 1_600, max: 2_000)
            profile.proteinGrams = MacroRange(min: 100, max: 140)
            profile.carbsGrams = MacroRange(min: 20, max: 50)
            profile.fatGrams = MacroRange(min: 120, max: 150)
        }
    }
}
