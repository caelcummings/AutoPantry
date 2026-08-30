import SwiftUI

struct RecipeCard: View {
    @EnvironmentObject private var appState: AppState
    let recipe: RecipeSummary
    @State private var showingAllIngredients = false

    var body: some View {
        GeometryReader { geo in
            let detailsHeight = showingAllIngredients
                ? min(max(geo.size.height * 0.58, 220), geo.size.height * 0.72)
                : min(max(geo.size.height * 0.36, 132), 172)
            let imageHeight = max(geo.size.height - detailsHeight, 80)

            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(width: geo.size.width, height: imageHeight)
                    .overlay {
                        recipeImage
                    }
                    .clipped()
                    .overlay(alignment: .bottom) {
                        imageScrim
                    }
                    .overlay(alignment: .topTrailing) {
                        FavoriteStarButton(recipeID: recipe.id, size: 18, style: .onImage)
                            .padding(12)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(recipe.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Spacer(minLength: 0)

                        if appState.isFavorite(recipeID: recipe.id) {
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.yellow)
                                .accessibilityHidden(true)
                        }
                    }

                    metadataChips

                    if !recipe.ingredients.isEmpty {
                        ingredientsPreview
                    }

                    Text(servingsAndIngredientsLine)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(width: geo.size.width, height: detailsHeight, alignment: .topLeading)
                .background(APTheme.cardBackground)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: APTheme.cornerRadius + 4, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var topIngredientsLine: String {
        recipe.ingredients.prefix(4).map(\.displayName).filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private var canShowMoreIngredients: Bool {
        recipe.ingredients.count > 4 || showingAllIngredients
    }

    @ViewBuilder
    private var ingredientsPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showingAllIngredients {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Text(ingredient.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.primary)

                                Spacer(minLength: 8)

                                if !ingredient.displayAmount.isEmpty {
                                    Text(ingredient.displayAmount)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
            } else {
                Text(topIngredientsLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if canShowMoreIngredients {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        showingAllIngredients.toggle()
                    }
                } label: {
                    Text(showingAllIngredients ? "Less" : "More")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(APTheme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showingAllIngredients ? "Hide full ingredient list" : "Show all ingredients")
            }
        }
        .frame(maxHeight: showingAllIngredients ? .infinity : nil, alignment: .top)
    }

    private var servingsAndIngredientsLine: String {
        if recipe.isSnack {
            let portionLabel = recipe.portionCount == 1 ? "1 portion" : "\(recipe.portionCount) portions"
            return "Snack · \(portionLabel) · \(recipe.ingredientCount) ingredients"
        }
        let servingLabel = recipe.portionCount == 1 ? "1 serving" : "\(recipe.portionCount) servings"
        return "\(servingLabel) · \(recipe.ingredientCount) ingredients"
    }

    private var imageScrim: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.18)],
            startPoint: .center,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var metadataChips: some View {
        let chips = metadataItems
        if chips.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                        metaChip(chip.text, icon: chip.icon, emphasized: chip.emphasized)
                    }
                }
            }
        }
    }

    private var metadataItems: [(text: String, icon: String, emphasized: Bool)] {
        let macros = recipe.effectiveMacros
        let prefix = recipe.hasMacros ? "" : "~"
        var items: [(String, String, Bool)] = []
        if recipe.isUserRecipe {
            items.append(("My Recipe", "star.circle.fill", true))
        }
        if recipe.isSnack {
            items.append(("Snack", "carrot.fill", true))
        }
        if recipe.isBreakfast {
            items.append(("Breakfast", "sunrise.fill", true))
        }
        if let cookMinutes = recipe.cookMinutes {
            items.append(("\(cookMinutes)m", "clock", false))
        }
        items.append(("\(prefix)\(macros.calories) cal", "flame", false))
        items.append(("\(prefix)\(macros.proteinGrams)g P", "bolt.fill", false))
        if let price = recipe.formattedPrice {
            items.append((price, "dollarsign.circle", false))
        }
        return items
    }

    @ViewBuilder
    private var recipeImage: some View {
        RecipeImageView(recipe: recipe)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var imagePlaceholder: some View {
        LinearGradient(
            colors: [APTheme.accent.opacity(0.85), Color.orange.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func metaChip(_ text: String, icon: String, emphasized: Bool = false) -> some View {
        Group {
            if text == "My Recipe" {
                MyRecipeBadge()
            } else {
                Label(text, systemImage: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(emphasized ? APTheme.accent : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(emphasized ? APTheme.accentMuted : Color.primary.opacity(0.06)))
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    RecipeCard(recipe: RecipeCatalog.feed[0])
        .padding()
        .frame(height: 520)
        .environmentObject(AppState(route: .main, userProfile: OnboardingDraft()))
}
