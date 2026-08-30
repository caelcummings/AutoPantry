import SwiftUI

struct RecipesLibraryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var showSnacksOnly = false
    @State private var showFavoritesOnly = false
    @State private var bannerMessage: String?
    @State private var flashClearAction = DeferredUIAction()

    private var allMyRecipes: [RecipeSummary] {
        filtered(appState.userRecipeList)
    }

    private var myRecipesList: [RecipeSummary] {
        let favoriteIDs = appState.favoriteRecipes.idSet
        let plannedIDs = Set(appState.weeklyMealPlan.recipes.map(\.id))
        return allMyRecipes.filter {
            !favoriteIDs.contains($0.id) && !plannedIDs.contains($0.id)
        }
    }

    private var favoriteRecipesList: [RecipeSummary] {
        let ids = appState.favoriteRecipes.idSet
        let plannedIDs = Set(appState.weeklyMealPlan.recipes.map(\.id))
        let recipes = ids.compactMap { appState.recipe(withID: $0) }
            .filter { !plannedIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        return filtered(recipes)
    }

    private var plannedRecipes: [RecipeSummary] {
        filtered(appState.weeklyMealPlan.recipes)
    }

    private var otherRecipes: [RecipeSummary] {
        let plannedIDs = Set(appState.weeklyMealPlan.recipes.map(\.id))
        let favoriteIDs = appState.favoriteRecipes.idSet
        let userIDs = Set(appState.userRecipeList.map(\.id))
        let catalog = RecipeCatalog.feed
            .filter { !plannedIDs.contains($0.id) && !favoriteIDs.contains($0.id) && !userIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        return filtered(catalog)
    }

    private var totalVisibleCount: Int {
        if showFavoritesOnly {
            return favoriteRecipesList.count
        }
        return myRecipesList.count + favoriteRecipesList.count + plannedRecipes.count + otherRecipes.count + (showFavoritesOnly ? 0 : 1)
    }

    var body: some View {
        NavigationStack {
            Group {
                if totalVisibleCount == 0 {
                    ContentUnavailableView {
                        Label(
                            emptyTitle,
                            systemImage: emptySystemImage
                        )
                    } description: {
                        Text(emptyDescription)
                    }
                } else {
                    List {
                        Section {
                            WeeklyPlanProgressView(progress: appState.weeklyProgress, style: .compact)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }

                        if let bannerMessage {
                            Section {
                                Text(bannerMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(APTheme.accent)
                            }
                        }

                        if !showFavoritesOnly, !plannedRecipes.isEmpty {
                            Section {
                                ForEach(plannedRecipes) { recipe in
                                    HStack(spacing: 8) {
                                        NavigationLink {
                                            RecipeDetailView(recipe: recipe)
                                        } label: {
                                            recipeRow(recipe, isThisWeek: true, showsInlineActions: false)
                                        }

                                        FavoriteStarButton(recipeID: recipe.id, size: 20)

                                        Button {
                                            removeFromWeek(recipe)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.red.opacity(0.85))
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Remove from this week")
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            removeFromWeek(recipe)
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        favoriteSwipe(recipe)
                                    }
                                }
                                .onDelete(perform: deletePlanned)
                            } header: {
                                Text("This week")
                            } footer: {
                                Text("Swipe left or tap − to remove. Macros update automatically.")
                            }
                        }

                        if !showFavoritesOnly {
                            Section {
                                if myRecipesList.isEmpty {
                                    myRecipesEmptyRow
                                } else {
                                    ForEach(myRecipesList) { recipe in
                                        myRecipeRow(recipe)
                                    }
                                }
                            } header: {
                                Text("My Recipes")
                            } footer: {
                                if appState.userRecipes.isEmpty {
                                    Text("Tap to create a recipe, or use + in the toolbar.")
                                } else if myRecipesList.isEmpty {
                                    Text("Your custom recipes also appear under This week or Favorites when saved there.")
                                } else {
                                    Text("Tap ★ to favorite, or + to add to your week. Edit from the recipe page.")
                                }
                            }
                        }

                        if !favoriteRecipesList.isEmpty {
                            Section {
                                ForEach(favoriteRecipesList) { recipe in
                                    favoriteRow(recipe)
                                }
                            } header: {
                                Label("Favorites", systemImage: "star.fill")
                            } footer: {
                                Text("Tap the star to remove a favorite.")
                            }
                        }

                        if !showFavoritesOnly, !otherRecipes.isEmpty {
                            Section {
                                ForEach(otherRecipes) { recipe in
                                    HStack(spacing: 8) {
                                        NavigationLink {
                                            RecipeDetailView(recipe: recipe)
                                        } label: {
                                            recipeRow(recipe, isThisWeek: false, showsInlineActions: false)
                                        }

                                        FavoriteStarButton(recipeID: recipe.id, size: 20)

                                        Button {
                                            addToWeek(recipe)
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    canAdd(recipe) ? APTheme.accent : Color.secondary.opacity(0.35)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(!canAdd(recipe))
                                        .accessibilityLabel("Add to this week")
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            addToWeek(recipe)
                                        } label: {
                                            Label("Add", systemImage: "plus")
                                        }
                                        .tint(APTheme.accent)
                                        .disabled(!canAdd(recipe))
                                    }
                                    .swipeActions(edge: .leading) {
                                        favoriteSwipe(recipe)
                                    }
                                }
                            } header: {
                                Text(plannedRecipes.isEmpty ? "All recipes" : "More recipes")
                            } footer: {
                                Text("Tap ★ to favorite, or + to add to your week.")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(APTheme.screenBackground.ignoresSafeArea())
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes or ingredients")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MyRecipeEditorView()
                    } label: {
                        Label("Add recipe", systemImage: "plus.circle.fill")
                    }
                    .tint(APTheme.accent)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                        if showFavoritesOnly { showSnacksOnly = false }
                    } label: {
                        Label(
                            showFavoritesOnly ? "All recipes" : "Favorites only",
                            systemImage: showFavoritesOnly ? "star.fill" : "star"
                        )
                    }
                    .tint(showFavoritesOnly ? .yellow : nil)

                    Button {
                        showSnacksOnly.toggle()
                        if showSnacksOnly { showFavoritesOnly = false }
                    } label: {
                        Label(
                            showSnacksOnly ? "All recipes" : "Snacks only",
                            systemImage: showSnacksOnly ? "fork.knife" : "carrot.fill"
                        )
                    }
                }
            }
            .onDisappear { flashClearAction.cancel() }
        }
    }

    private var emptyTitle: String {
        if showFavoritesOnly { return "No Favorites" }
        if searchText.isEmpty { return "No Recipes" }
        return "No Results"
    }

    private var emptySystemImage: String {
        if showFavoritesOnly { return "star" }
        if searchText.isEmpty { return "book" }
        return "magnifyingglass"
    }

    private var emptyDescription: String {
        if showFavoritesOnly {
            return "Tap the star on a recipe to save it here."
        }
        if searchText.isEmpty {
            return appState.userRecipes.isEmpty
                ? "Your recipe catalog is empty. Tap + to add your own recipe."
                : "No catalog recipes match your filters."
        }
        return "Try a different name or ingredient."
    }

    private var myRecipesEmptyRow: some View {
        NavigationLink {
            MyRecipeEditorView()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(APTheme.accentMuted)
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(APTheme.accent)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Add your own recipe")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Ingredients, instructions, and an optional photo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func myRecipeRow(_ recipe: RecipeSummary) -> some View {
        let inWeek = appState.weeklyMealPlan.contains(recipeID: recipe.id)
        HStack(spacing: 8) {
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                recipeRow(
                    recipe,
                    isThisWeek: inWeek,
                    showsInlineActions: false,
                    showsMyRecipeBadge: false
                )
            }

            FavoriteStarButton(recipeID: recipe.id, size: 20)

            if inWeek {
                Button {
                    removeFromWeek(recipe)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove from this week")
            } else {
                Button {
                    addToWeek(recipe)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            canAdd(recipe) ? APTheme.accent : Color.secondary.opacity(0.35)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canAdd(recipe))
                .accessibilityLabel("Add to this week")
            }
        }
        .swipeActions(edge: .leading) {
            favoriteSwipe(recipe)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                appState.deleteUserRecipe(id: recipe.id)
                flash("Deleted \(recipe.title)")
            } label: {
                Label("Delete", systemImage: "trash")
            }

            if !inWeek {
                Button {
                    addToWeek(recipe)
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .tint(APTheme.accent)
                .disabled(!canAdd(recipe))
            }
        }
    }

    @ViewBuilder
    private func favoriteRow(_ recipe: RecipeSummary) -> some View {
        let inWeek = appState.weeklyMealPlan.contains(recipeID: recipe.id)
        HStack(spacing: 8) {
            NavigationLink {
                RecipeDetailView(recipe: recipe)
            } label: {
                recipeRow(
                    recipe,
                    isThisWeek: inWeek,
                    showsInlineActions: false
                )
            }

            FavoriteStarButton(recipeID: recipe.id, size: 20)

            if inWeek {
                Button {
                    removeFromWeek(recipe)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove from this week")
            } else {
                Button {
                    addToWeek(recipe)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            canAdd(recipe) ? APTheme.accent : Color.secondary.opacity(0.35)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canAdd(recipe))
                .accessibilityLabel("Add to this week")
            }
        }
        .swipeActions(edge: .leading) {
            favoriteSwipe(recipe)
        }
        .swipeActions(edge: .trailing) {
            if inWeek {
                Button(role: .destructive) {
                    removeFromWeek(recipe)
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            } else {
                Button {
                    addToWeek(recipe)
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .tint(APTheme.accent)
                .disabled(!canAdd(recipe))
            }
        }
    }

    private func favoriteSwipe(_ recipe: RecipeSummary) -> some View {
        Button {
            appState.toggleFavorite(recipeID: recipe.id)
            flash(
                appState.isFavorite(recipeID: recipe.id)
                    ? "Added \(recipe.title) to favorites"
                    : "Removed from favorites"
            )
        } label: {
            Label(
                appState.isFavorite(recipeID: recipe.id) ? "Unfavorite" : "Favorite",
                systemImage: appState.isFavorite(recipeID: recipe.id) ? "star.slash" : "star.fill"
            )
        }
        .tint(.yellow)
    }

    private func filtered(_ recipes: [RecipeSummary]) -> [RecipeSummary] {
        recipes.filter { recipe in
            if showFavoritesOnly && !appState.isFavorite(recipeID: recipe.id) { return false }
            if showSnacksOnly && !recipe.isSnack { return false }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return true }
            if recipe.title.localizedCaseInsensitiveContains(query) { return true }
            return recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(query) }
        }
    }

    private func canAdd(_ recipe: RecipeSummary) -> Bool {
        if appState.weeklyMealPlan.contains(recipeID: recipe.id) { return false }
        if recipe.isSnack { return true }
        return !appState.hasCompletedWeeklyMeals
    }

    private func addToWeek(_ recipe: RecipeSummary) {
        if appState.addRecipeToWeeklyPlan(recipe) {
            flash("Added \(recipe.title) to this week")
        } else if appState.hasCompletedWeeklyMeals && !recipe.isSnack {
            flash("Meal total is full — remove a meal or add a snack")
        } else {
            flash("Already in your week")
        }
    }

    private func removeFromWeek(_ recipe: RecipeSummary) {
        appState.removeRecipeFromWeeklyPlan(id: recipe.id)
        flash("Removed \(recipe.title) from this week")
    }

    private func deletePlanned(at offsets: IndexSet) {
        let ids = offsets.map { plannedRecipes[$0].id }
        ids.forEach { appState.removeRecipeFromWeeklyPlan(id: $0) }
        flash("Removed from this week")
    }

    private func flash(_ message: String) {
        withAnimation { bannerMessage = message }
        flashClearAction.schedule(after: .seconds(1.6)) {
            withAnimation {
                if bannerMessage == message { bannerMessage = nil }
            }
        }
    }

    private func recipeRow(
        _ recipe: RecipeSummary,
        isThisWeek: Bool,
        showsInlineActions: Bool = true,
        showsMyRecipeBadge: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            recipeThumbnail(recipe)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if appState.isFavorite(recipeID: recipe.id) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .accessibilityHidden(true)
                    }

                    if showsMyRecipeBadge, recipe.isUserRecipe {
                        MyRecipeBadge()
                    }

                    if isThisWeek {
                        Text("Saved")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(APTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(APTheme.accentMuted))
                    }

                    if recipe.isSnack {
                        Text("Snack")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(APTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(APTheme.accentMuted))
                    }

                    if recipe.isBreakfast {
                        Text("Breakfast")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }

                Text(subtitle(for: recipe))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showsInlineActions, isThisWeek {
                Spacer(minLength: 0)
                FavoriteStarButton(recipeID: recipe.id, size: 20)
                Button {
                    removeFromWeek(recipe)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove from this week")
            }
        }
        .padding(.vertical, 4)
    }

    private func subtitle(for recipe: RecipeSummary) -> String {
        let macros = recipe.effectiveMacros
        var parts: [String] = []
        if let minutes = recipe.cookMinutes {
            parts.append("\(minutes) min")
        }
        parts.append("\(recipe.hasMacros ? "" : "~")\(macros.calories) cal")
        parts.append("\(recipe.ingredients.count) ingredients")
        if recipe.isSnack {
            parts.append("snack")
        } else {
            parts.append(recipe.portionCount == 1 ? "1 serving" : "\(recipe.portionCount) servings")
        }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func recipeThumbnail(_ recipe: RecipeSummary) -> some View {
        RecipeImageView(recipe: recipe)
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    RecipesLibraryView()
        .environmentObject(AppState(route: .main, userProfile: OnboardingDraft()))
}
