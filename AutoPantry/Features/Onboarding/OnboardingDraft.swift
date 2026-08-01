import Foundation

/// Draft collected during onboarding; persisted locally (and later mapped to Firestore).
struct OnboardingDraft: Equatable, Codable {
    var nutritionProfile: NutritionProfile = NutritionProfile()
    var budgetRange: BudgetRange = .medium
    var cookingSkill: CookingSkill = .intermediate
    var householdSize: Int = 2

    /// Human-readable macro summary for profile UI.
    var macroSummaryLine: String {
        let p = nutritionProfile.proteinGrams
        let c = nutritionProfile.calories
        return "\(p.min)–\(p.max)g protein · \(c.min)–\(c.max) cal/day"
    }
}

enum BudgetRange: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high
    case dontCare

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Budget"
        case .medium: "Balanced"
        case .high: "Premium"
        case .dontCare: "Don't care"
        }
    }

    var subtitle: String {
        switch self {
        case .low: "~$4–7 / meal"
        case .medium: "~$7–12 / meal"
        case .high: "$12+ / meal"
        case .dontCare: "Show recipes at any price"
        }
    }
}

enum CookingSkill: String, CaseIterable, Identifiable, Codable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Comfortable"
        case .advanced: "Pro"
        }
    }
}
