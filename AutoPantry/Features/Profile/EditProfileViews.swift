import SwiftUI

/// Edit body metrics + activity + meal count from the Profile tab.
struct EditBodyProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft: OnboardingDraft
    @State private var recalculateMacros = true

    init(profile: OnboardingDraft) {
        _draft = State(initialValue: profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: APTheme.sectionSpacing) {
                BodyProfileStepView(bodyProfile: $draft.bodyProfile)

                ActivityLifestyleStepView(
                    bodyProfile: $draft.bodyProfile,
                    mealsPerWeek: $draft.nutritionProfile.mealsPerWeek
                )

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Recalculate macros from this profile", isOn: $recalculateMacros)
                        .font(.subheadline.weight(.semibold))

                    Text(
                        recalculateMacros
                            ? "Saving will refresh your calorie and macro ranges from these stats. You can still fine-tune them afterward."
                            : "Your current macro targets will be kept. Change them anytime under Edit macros."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                        .fill(APTheme.cardBackground)
                )
            }
            .padding(.horizontal, APTheme.horizontalPadding)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
        .background(APTheme.screenBackground.ignoresSafeArea())
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!draft.bodyProfile.isValid || !draft.nutritionProfile.isValid)
            }
        }
    }

    private func save() {
        if recalculateMacros {
            draft.applyEstimatedMacros()
        }
        appState.updateUserProfile(draft)
        dismiss()
    }
}

/// Edit daily macro ranges from the Profile tab.
struct EditMacrosView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draft: OnboardingDraft

    init(profile: OnboardingDraft) {
        _draft = State(initialValue: profile)
    }

    var body: some View {
        ScrollView {
            NutritionProfileStepView(
                profile: $draft.nutritionProfile,
                bodyProfile: draft.bodyProfile
            )
            .padding(.horizontal, APTheme.horizontalPadding)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
        .background(APTheme.screenBackground.ignoresSafeArea())
        .navigationTitle("Edit macros")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    appState.updateUserProfile(draft)
                    dismiss()
                }
                .disabled(!draft.nutritionProfile.isValid)
            }
        }
    }
}
