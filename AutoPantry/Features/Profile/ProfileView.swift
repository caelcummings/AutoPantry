import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    private var profile: OnboardingDraft? { appState.userProfile }
    private var plan: WeeklyMealPlan { appState.weeklyMealPlan }

    var body: some View {
        NavigationStack {
            List {
                if !plan.recipes.isEmpty {
                    Section {
                        WeeklyPlanProgressView(progress: appState.weeklyProgress)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)

                        ForEach(plan.recipes) { recipe in
                            HStack(spacing: 12) {
                                recipeThumbnail(recipe)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.title)
                                        .font(.headline)
                                    Text(recipeDetailLine(recipe))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteRecipes)
                    } header: {
                        Text("Saved recipes this week")
                    } footer: {
                        if appState.hasCompletedWeeklyMeals {
                            Text("Meal target met for the week.")
                        } else {
                            Text("Like recipes in Discover to fill your plan.")
                        }
                    }
                }

                if appState.hasCompletedWeeklyMeals {
                    Section {
                        Button {
                            appState.showWeekSummary()
                        } label: {
                            Label("View week summary", systemImage: "party.popper.fill")
                        }
                        .foregroundStyle(APTheme.accent)
                    }
                }

                if let profile {
                    Section {
                        Label(profile.macroSummaryLine, systemImage: "chart.bar.fill")
                            .foregroundStyle(APTheme.accent)
                        macroDetailRow("Calories / day", profile.nutritionProfile.calories)
                        macroDetailRow("Protein / day", profile.nutritionProfile.proteinGrams, unit: "g")
                        macroDetailRow("Carbs / day", profile.nutritionProfile.carbsGrams, unit: "g")
                        macroDetailRow("Fat / day", profile.nutritionProfile.fatGrams, unit: "g")
                        LabeledContent("Meals per week", value: "\(profile.nutritionProfile.mealsPerWeek)")
                    } header: {
                        Text("Nutrition profile")
                    }

                    Section("Preferences") {
                        LabeledContent("Budget", value: profile.budgetRange.title)
                        LabeledContent("Cooking skill", value: profile.cookingSkill.title)
                        LabeledContent("Household", value: "\(profile.householdSize)")
                    }

                    Section {
                        NavigationLink {
                            SeasoningInventoryView()
                        } label: {
                            HStack {
                                Label("Pantry staples", systemImage: "cabinet.fill")
                                Spacer()
                                Text(
                                    appState.seasoningInventory.isEmpty
                                        ? "None"
                                        : "\(appState.seasoningInventory.items.count)"
                                )
                                .foregroundStyle(.secondary)
                            }
                        }
                    } footer: {
                        Text("Owned spices, condiments, and basics are left off your grocery list.")
                    }
                } else {
                    Section {
                        Text("Complete onboarding to set your macro targets.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if !plan.recipes.isEmpty {
                        Button("Clear weekly plan", role: .destructive) {
                            appState.resetWeeklyPlan()
                        }
                    }
                    Button("Replay onboarding (preview)") {
                        appState.resetOnboardingPreview()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    @ViewBuilder
    private func recipeThumbnail(_ recipe: RecipeSummary) -> some View {
        AsyncImage(url: recipe.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Color.gray.opacity(0.2)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func deleteRecipes(at offsets: IndexSet) {
        let ids = offsets.map { appState.weeklyMealPlan.recipes[$0].id }
        ids.forEach { appState.removeRecipeFromWeeklyPlan(id: $0) }
    }

    private func macroDetailRow(_ label: String, _ range: MacroRange, unit: String = "cal") -> some View {
        LabeledContent(label) {
            Text("\(range.min)–\(range.max) \(unit)")
                .monospacedDigit()
        }
    }

    private func recipeDetailLine(_ recipe: RecipeSummary) -> String {
        let servingLabel = recipe.mealContribution == 1 ? "1 serving" : "\(recipe.mealContribution) servings"
        var parts = [servingLabel, "\(recipe.ingredientCount) ingredients"]
        if let calories = recipe.calories, let protein = recipe.proteinGrams {
            parts.append("\(calories) cal")
            parts.append("\(protein)g protein")
        }
        if let price = recipe.formattedPrice {
            parts.append(price)
        }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    ProfileView()
        .environmentObject(
            AppState(route: .main, userProfile: OnboardingDraft())
        )
}
