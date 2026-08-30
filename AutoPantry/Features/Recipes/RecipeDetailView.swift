import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var appState: AppState
    let recipe: RecipeSummary

    private var macros: MacroEstimator.Estimate { recipe.effectiveMacros }
    private var isInWeek: Bool {
        appState.weeklyMealPlan.contains(recipeID: recipe.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: 20) {
                    header
                    metaRow
                    planActionButton
                    ingredientsSection
                    instructionsSection
                }
                .padding(.horizontal, APTheme.horizontalPadding)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(APTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    if recipe.isUserRecipe {
                        NavigationLink {
                            MyRecipeEditorView(recipe: recipe)
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                    FavoriteStarButton(recipeID: recipe.id, size: 20)
                }
            }
        }
    }

    private var heroImage: some View {
        RecipeImageView(recipe: recipe)
    }

    @ViewBuilder
    private var userRecipePlaceholder: some View {
        if recipe.isUserRecipe {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.82, blue: 0.35),
                    Color(red: 0.88, green: 0.68, blue: 0.18),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(red: 0.62, green: 0.45, blue: 0.05).opacity(0.75))
            }
        } else {
            placeholder
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.55))
                }
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [APTheme.accent.opacity(0.85), Color.orange.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if recipe.isUserRecipe {
                    MyRecipeBadge()
                }

                if recipe.isSnack {
                    Text("Snack")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(APTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(APTheme.accentMuted))
                }

                if recipe.isBreakfast {
                    Text("Breakfast")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                }

                if appState.isFavorite(recipeID: recipe.id) {
                    Label("Favorite", systemImage: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.yellow.opacity(0.95))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.yellow.opacity(0.18)))
                }
            }

            Text(recipe.title)
                .font(.title.bold())

            Text(portionLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var portionLine: String {
        if recipe.isSnack {
            let portions = recipe.portionCount == 1 ? "1 portion" : "\(recipe.portionCount) portions"
            return "\(portions) · does not count toward weekly meals"
        }
        let servings = recipe.portionCount == 1 ? "1 serving" : "\(recipe.portionCount) servings"
        return "\(servings) · counts as \(recipe.mealContribution) meal\(recipe.mealContribution == 1 ? "" : "s")"
    }

    private var metaRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let minutes = recipe.cookMinutes {
                    metaChip("\(minutes) min", icon: "clock")
                }
                metaChip("\(recipe.hasMacros ? "" : "~")\(macros.calories) cal", icon: "flame")
                metaChip("\(recipe.hasMacros ? "" : "~")\(macros.proteinGrams)g protein", icon: "bolt.fill")
                metaChip("\(recipe.hasMacros ? "" : "~")\(macros.carbsGrams)g carbs", icon: "leaf.fill")
                metaChip("\(recipe.hasMacros ? "" : "~")\(macros.fatGrams)g fat", icon: "drop.fill")
                if let price = recipe.formattedPrice {
                    metaChip(price, icon: "dollarsign.circle")
                }
            }
        }
    }

    @ViewBuilder
    private var planActionButton: some View {
        if isInWeek {
            Button {
                appState.removeRecipeFromWeeklyPlan(id: recipe.id)
            } label: {
                Label("Remove from this week", systemImage: "minus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.red)
                    .background(
                        RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.35), lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                                    .fill(APTheme.cardBackground)
                            )
                    )
            }
            .buttonStyle(.plain)
        } else {
            let canAdd = recipe.isSnack || !appState.hasCompletedWeeklyMeals
            PrimaryButton(
                title: canAdd ? "Add to this week" : "Meal total is full",
                isEnabled: canAdd
            ) {
                _ = appState.addRecipeToWeeklyPlan(recipe)
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title3.bold())

            if recipe.ingredients.isEmpty {
                Text("No ingredients listed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(APTheme.accent)
                                .padding(.top, 7)

                            Text(ingredient.displayName)
                                .font(.body)

                            Spacer(minLength: 8)

                            if !ingredient.displayAmount.isEmpty {
                                Text(ingredient.displayAmount)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.vertical, 10)

                        if index < recipe.ingredients.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                        .fill(APTheme.cardBackground)
                )
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.title3.bold())

            if recipe.instructions.isEmpty {
                Text("No instructions listed for this recipe yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(APTheme.accent))

                            Text(step)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                        .fill(APTheme.cardBackground)
                )
            }
        }
    }

    private func metaChip(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(APTheme.cardBackground))
    }
}

#Preview {
    NavigationStack {
        if let recipe = RecipeCatalog.feed.first {
            RecipeDetailView(recipe: recipe)
        } else {
            Text("No recipes loaded")
        }
    }
    .environmentObject(AppState(route: .main, userProfile: OnboardingDraft()))
}
