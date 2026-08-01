import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, APTheme.horizontalPadding)
                    .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: APTheme.sectionSpacing) {
                        header
                        stepContent
                    }
                    .padding(.horizontal, APTheme.horizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
            .background(APTheme.screenBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                footer
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.isOnFirstStep {
                        Button("Back", action: viewModel.goBack)
                    }
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(APTheme.accent)
                    .frame(width: geo.size.width * viewModel.progress)
            }
        }
        .frame(height: 6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.stepIndicator)
                .font(.caption.weight(.semibold))
                .foregroundStyle(APTheme.accent)
            Text(viewModel.step.title)
                .font(.largeTitle.bold())
            Text(viewModel.step.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .nutritionProfile:
            NutritionProfileStepView(profile: $viewModel.draft.nutritionProfile)

        case .budget:
            VStack(spacing: APTheme.itemSpacing) {
                ForEach(BudgetRange.allCases) { range in
                    selectionRow(
                        title: range.title,
                        subtitle: range.subtitle,
                        isSelected: viewModel.draft.budgetRange == range
                    ) {
                        viewModel.draft.budgetRange = range
                    }
                }
            }

        case .skill:
            VStack(spacing: APTheme.itemSpacing) {
                ForEach(CookingSkill.allCases) { skill in
                    selectionRow(
                        title: skill.title,
                        subtitle: nil,
                        isSelected: viewModel.draft.cookingSkill == skill
                    ) {
                        viewModel.draft.cookingSkill = skill
                    }
                }
            }

        case .household:
            VStack(spacing: APTheme.sectionSpacing) {
                Text("\(viewModel.draft.householdSize)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)

                Stepper(
                    "People at home",
                    value: $viewModel.draft.householdSize,
                    in: 1...8
                )
                .font(.headline)
            }
            .padding(.top, 8)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: viewModel.isOnLastStep ? "Start discovering" : "Continue",
                isEnabled: viewModel.canContinue
            ) {
                if viewModel.goNext() {
                    appState.completeOnboarding(with: viewModel.draft)
                }
            }
        }
        .padding(.horizontal, APTheme.horizontalPadding)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private func selectionRow(
        title: String,
        subtitle: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? APTheme.accent : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                    .fill(isSelected ? APTheme.accentMuted : APTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppState(route: .onboarding))
}
