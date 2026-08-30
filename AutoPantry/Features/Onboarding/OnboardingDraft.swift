import Foundation

/// User profile collected during onboarding and editable later in Profile.
struct OnboardingDraft: Equatable, Codable {
    var bodyProfile: UserBodyProfile = .default
    var nutritionProfile: NutritionProfile = NutritionProfile()

    /// Human-readable macro summary for profile UI.
    var macroSummaryLine: String {
        let p = nutritionProfile.proteinGrams
        let c = nutritionProfile.calories
        return "\(p.min)–\(p.max)g protein · \(c.min)–\(c.max) cal/day"
    }

    /// True when the user finished onboarding with a usable body + macro profile.
    var isComplete: Bool {
        bodyProfile.isValid && nutritionProfile.isValid
    }

    /// Re-estimate macros from body metrics while keeping meal count.
    mutating func applyEstimatedMacros() {
        nutritionProfile = MacroCalculator.estimate(
            body: bodyProfile,
            mealsPerWeek: nutritionProfile.mealsPerWeek
        )
    }

    // Backward-compatible decode for profiles saved before body metrics existed.
    enum CodingKeys: String, CodingKey {
        case bodyProfile, nutritionProfile
        case budgetRange, cookingSkill, householdSize // legacy ignored
    }

    init(
        bodyProfile: UserBodyProfile = .default,
        nutritionProfile: NutritionProfile = NutritionProfile()
    ) {
        self.bodyProfile = bodyProfile
        self.nutritionProfile = nutritionProfile
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bodyProfile = try container.decodeIfPresent(UserBodyProfile.self, forKey: .bodyProfile) ?? .default
        nutritionProfile = try container.decodeIfPresent(NutritionProfile.self, forKey: .nutritionProfile)
            ?? NutritionProfile()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bodyProfile, forKey: .bodyProfile)
        try container.encode(nutritionProfile, forKey: .nutritionProfile)
    }
}
