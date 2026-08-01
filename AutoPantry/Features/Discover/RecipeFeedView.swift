import SwiftUI

struct RecipeFeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var deck: [RecipeSummary] = []
    @State private var currentIndex = 0
    @State private var lastActionMessage: String?

    private var isFinished: Bool { deck.isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if appState.hasCompletedWeeklyMeals && isFinished {
                    planCompleteState
                } else if isFinished {
                    emptyDeckState
                } else {
                    WeeklyPlanProgressView(progress: appState.weeklyProgress, style: .compact)
                        .padding(.horizontal, APTheme.horizontalPadding)
                        .padding(.top, 2)
                        .padding(.bottom, 8)

                    GeometryReader { geo in
                        TabView(selection: $currentIndex) {
                            ForEach(Array(deck.enumerated()), id: \.element.id) { offset, recipe in
                                RecipeCard(recipe: recipe)
                                    .frame(width: geo.size.width - (APTheme.horizontalPadding * 2), height: geo.size.height)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .tag(offset)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: deck.count)

                    bottomChrome
                }
            }
            .background(APTheme.screenBackground.ignoresSafeArea())
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !appState.weeklyMealPlan.recipes.isEmpty {
                        Text("\(appState.weeklyMealPlan.recipes.count) saved")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(APTheme.accent)
                    } else {
                        Label("Smart picks", systemImage: "sparkles")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(APTheme.accent)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .onAppear { refreshDeck() }
            .onChange(of: appState.weeklyMealPlan) { _, _ in refreshDeck() }
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: 6) {
            if let lastActionMessage {
                Text(lastActionMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .transition(.opacity)
            }

            if !appState.hasCompletedWeeklyMeals {
                actionButtons
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var actionButtons: some View {
        HStack(spacing: 32) {
            circleButton(systemName: "xmark", tint: .secondary) {
                passCurrentRecipe()
            }
            circleButton(systemName: "heart.fill", tint: APTheme.accent) {
                likeCurrentRecipe()
            }
        }
    }

    private var emptyDeckState: some View {
        ContentUnavailableView {
            Label("No more recipes to swipe", systemImage: "tray")
        } description: {
            Text("You've seen everything for now. Check your weekly plan on Profile.")
        } actions: {
            Button("Reload feed") { refreshDeck(force: true) }
                .buttonStyle(.borderedProminent)
                .tint(APTheme.accent)
        }
        .frame(maxHeight: .infinity)
    }

    private var planCompleteState: some View {
        ContentUnavailableView {
            Label("Week planned!", systemImage: "checkmark.seal.fill")
        } description: {
            Text("You saved enough meals for the week. Open your summary to see macros.")
        } actions: {
            Button("View week summary") {
                appState.showWeekSummary()
            }
            .buttonStyle(.borderedProminent)
            .tint(APTheme.accent)
        }
        .frame(maxHeight: .infinity)
    }

    private func passCurrentRecipe() {
        guard let recipe = recipe(at: currentIndex) else { return }
        flashMessage("Passed on \(recipe.title)")
        removeRecipe(at: currentIndex)
        haptic(.light)
    }

    private func likeCurrentRecipe() {
        guard let recipe = recipe(at: currentIndex) else { return }

        if appState.hasCompletedWeeklyMeals {
            flashMessage("Weekly meal total already met!")
            haptic(.light)
            return
        }

        if appState.addRecipeToWeeklyPlan(recipe) {
            flashMessage("Saved \(recipe.title) to your week")
        } else {
            flashMessage("Already in your week")
        }

        removeRecipe(at: currentIndex)
        haptic(.medium)
    }

    private func recipe(at index: Int) -> RecipeSummary? {
        guard deck.indices.contains(index) else { return nil }
        return deck[index]
    }

    private func removeRecipe(at index: Int) {
        guard deck.indices.contains(index) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            deck.remove(at: index)
            if deck.isEmpty {
                currentIndex = 0
            } else if currentIndex >= deck.count {
                currentIndex = deck.count - 1
            }
        }
    }

    private func refreshDeck(force: Bool = false) {
        let plannedIDs = Set(appState.weeklyMealPlan.recipes.map(\.id))
        let profile = appState.userProfile?.nutritionProfile ?? NutritionProfile()
        let available = RecipeCatalog.deck(
            excluding: plannedIDs,
            profile: profile,
            plan: appState.weeklyMealPlan,
            isPlanComplete: appState.hasCompletedWeeklyMeals
        )
        if force || deck.isEmpty {
            deck = available
            currentIndex = 0
        } else {
            deck = available
            if currentIndex >= deck.count {
                currentIndex = max(0, deck.count - 1)
            }
        }
    }

    private func flashMessage(_ message: String) {
        withAnimation { lastActionMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                withAnimation {
                    if lastActionMessage == message { lastActionMessage = nil }
                }
            }
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func circleButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 54, height: 54)
                .background(Circle().fill(APTheme.cardBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecipeFeedView()
        .environmentObject(
            AppState(route: .main, userProfile: OnboardingDraft())
        )
}
