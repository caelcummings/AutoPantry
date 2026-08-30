import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var didRestoreProgress = false
    @FocusState private var pantrySearchFocused: Bool

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
                .scrollDismissesKeyboard(.interactively)
            }
            .background(APTheme.screenBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if showsFooterButton {
                    footer
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.isOnFirstStep {
                        Button("Back", action: viewModel.goBack)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.step == .pantryStaples, appState.seasoningInventory.isEmpty {
                        Button("Skip for now", action: advanceOnboarding)
                            .font(.subheadline)
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    if viewModel.step == .pantryStaples {
                        Spacer()
                        Button("Done") {
                            pantrySearchFocused = false
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .onAppear(perform: restoreProgressIfNeeded)
        }
    }

    private var showsFooterButton: Bool {
        !(viewModel.step == .pantryStaples && pantrySearchFocused)
    }

    private func advanceOnboarding() {
        pantrySearchFocused = false
        if viewModel.goNext() {
            appState.completeOnboarding(with: viewModel.draft)
        } else {
            appState.saveOnboardingProgress(draft: viewModel.draft, step: viewModel.step)
        }
    }

    private func restoreProgressIfNeeded() {
        guard !didRestoreProgress, let progress = appState.onboardingProgress else { return }
        viewModel.restore(from: progress)
        didRestoreProgress = true
        appState.clearOnboardingProgressRestore()
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
        case .pantryStaples:
            PantryStaplesStepView(searchFocused: $pantrySearchFocused)

        case .bodyProfile:
            BodyProfileStepView(bodyProfile: $viewModel.draft.bodyProfile)

        case .activity:
            ActivityLifestyleStepView(
                bodyProfile: $viewModel.draft.bodyProfile,
                mealsPerWeek: $viewModel.draft.nutritionProfile.mealsPerWeek
            )

        case .nutritionProfile:
            NutritionProfileStepView(
                profile: $viewModel.draft.nutritionProfile,
                bodyProfile: viewModel.draft.bodyProfile
            )
            .onChange(of: viewModel.draft.nutritionProfile) { _, _ in
                viewModel.markMacrosCustomized()
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: viewModel.isOnLastStep ? "Start discovering" : "Continue",
                isEnabled: viewModel.canContinue,
                action: advanceOnboarding
            )
        }
        .padding(.horizontal, APTheme.horizontalPadding)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppState(route: .onboarding))
}
