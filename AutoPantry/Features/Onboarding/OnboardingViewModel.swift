import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case pantryStaples
        case bodyProfile
        case activity
        case nutritionProfile

        static let currentFlowVersion = LocalProfileStore.OnboardingProgress.currentFlowVersion

        var phaseLabel: String {
            switch self {
            case .pantryStaples: "Pantry"
            case .bodyProfile, .activity: "Profile"
            case .nutritionProfile: "Macros"
            }
        }

        var title: String {
            switch self {
            case .pantryStaples: "Your pantry staples"
            case .bodyProfile: "About you"
            case .activity: "Lifestyle"
            case .nutritionProfile: "Your daily macros"
            }
        }

        var subtitle: String {
            switch self {
            case .pantryStaples:
                "Mark spices, oils, and basics you already have — we’ll leave them off your grocery list."
            case .bodyProfile:
                "We’ll use your age, size, and goals to estimate calorie and macro needs."
            case .activity:
                "Exercise and meal count help us set your weekly plan targets."
            case .nutritionProfile:
                "Here’s our estimate — tweak anything to match how you like to eat."
            }
        }
    }

    @Published var draft = OnboardingDraft()
    @Published private(set) var step: Step = .pantryStaples
    /// When false, entering the macros step refreshes estimates from body metrics.
    private var macrosWereCustomized = false

    init(draft: OnboardingDraft = OnboardingDraft(), step: Step = .pantryStaples) {
        self.draft = draft
        self.step = step
        if step == .nutritionProfile {
            macrosWereCustomized = true
        }
    }

    func restore(from progress: LocalProfileStore.OnboardingProgress) {
        draft = progress.draft
        let rawStep = progress.resolvedStepRawValue
        step = Step(rawValue: rawStep) ?? .pantryStaples
        macrosWereCustomized = step == .nutritionProfile
    }

    var progress: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    var stepIndicator: String {
        "Step \(step.rawValue + 1) of \(Step.allCases.count) · \(step.phaseLabel)"
    }

    var canContinue: Bool {
        switch step {
        case .pantryStaples:
            true
        case .bodyProfile:
            draft.bodyProfile.isValid
        case .activity:
            (7...35).contains(draft.nutritionProfile.mealsPerWeek)
        case .nutritionProfile:
            draft.nutritionProfile.isValid
        }
    }

    var isOnFirstStep: Bool { step == Step.allCases.first }
    var isOnLastStep: Bool { step == Step.allCases.last }

    func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        if step == .nutritionProfile {
            // Leaving macros without finishing — allow re-estimate next time unless they finish.
            macrosWereCustomized = false
        }
        step = previous
    }

    /// Returns `true` when onboarding should complete (last step finished).
    func goNext() -> Bool {
        guard canContinue else { return false }

        if step == .activity {
            // Refresh estimate when arriving at macros from lifestyle.
            if !macrosWereCustomized {
                draft.applyEstimatedMacros()
            }
        }

        if step == .nutritionProfile {
            macrosWereCustomized = true
        }

        guard let next = Step(rawValue: step.rawValue + 1) else { return true }
        step = next
        return false
    }

    func markMacrosCustomized() {
        macrosWereCustomized = true
    }
}
