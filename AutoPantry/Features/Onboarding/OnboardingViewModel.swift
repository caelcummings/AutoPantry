import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case nutritionProfile
        case budget
        case skill
        case household

        var phaseLabel: String {
            switch self {
            case .nutritionProfile: "Profile"
            case .budget, .skill, .household: "Preferences"
            }
        }

        var title: String {
            switch self {
            case .nutritionProfile: "Build your nutrition profile"
            case .budget: "Budget"
            case .skill: "Cooking skill"
            case .household: "Household size"
            }
        }

        var subtitle: String {
            switch self {
            case .nutritionProfile:
                "Set your ideal daily macro ranges — we'll plan recipes to hit your weekly targets."
            case .budget:
                "We'll prioritize recipes in your range."
            case .skill:
                "We'll match recipe difficulty to you."
            case .household:
                "We'll scale servings and grocery lists."
            }
        }
    }

    @Published var draft = OnboardingDraft()
    @Published private(set) var step: Step = .nutritionProfile

    var progress: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    var stepIndicator: String {
        "Step \(step.rawValue + 1) of \(Step.allCases.count) · \(step.phaseLabel)"
    }

    var canContinue: Bool {
        switch step {
        case .nutritionProfile:
            draft.nutritionProfile.isValid
        case .budget, .skill, .household:
            true
        }
    }

    var isOnFirstStep: Bool { step == Step.allCases.first }
    var isOnLastStep: Bool { step == Step.allCases.last }

    func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    func goNext() -> Bool {
        guard canContinue else { return false }
        guard let next = Step(rawValue: step.rawValue + 1) else { return true }
        step = next
        return false
    }
}
