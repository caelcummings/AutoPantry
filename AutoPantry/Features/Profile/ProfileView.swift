import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showResetOnboardingConfirmation = false

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
                        LabeledContent("Sex", value: profile.bodyProfile.sex.title)
                        LabeledContent("Age", value: "\(profile.bodyProfile.ageYears)")
                        LabeledContent("Height", value: profile.bodyProfile.formattedHeight)
                        LabeledContent("Weight", value: "\(profile.bodyProfile.weightPounds) lb")
                        LabeledContent("Goal weight", value: "\(profile.bodyProfile.desiredWeightPounds) lb")
                        LabeledContent("Activity", value: profile.bodyProfile.activityLevel.title)
                        LabeledContent("Meals / week", value: "\(profile.nutritionProfile.mealsPerWeek)")

                        NavigationLink {
                            EditBodyProfileView(profile: profile)
                        } label: {
                            Label("Edit profile", systemImage: "person.crop.circle")
                        }
                    } header: {
                        Text("Your profile")
                    } footer: {
                        Text(profile.bodyProfile.weightGoalSummary)
                    }

                    Section {
                        Label(profile.macroSummaryLine, systemImage: "chart.bar.fill")
                            .foregroundStyle(APTheme.accent)
                        macroDetailRow("Calories / day", profile.nutritionProfile.calories)
                        macroDetailRow("Protein / day", profile.nutritionProfile.proteinGrams, unit: "g")
                        macroDetailRow("Carbs / day", profile.nutritionProfile.carbsGrams, unit: "g")
                        macroDetailRow("Fat / day", profile.nutritionProfile.fatGrams, unit: "g")

                        NavigationLink {
                            EditMacrosView(profile: profile)
                        } label: {
                            Label("Edit macros", systemImage: "slider.horizontal.3")
                        }
                    } header: {
                        Text("Nutrition targets")
                    } footer: {
                        Text("Targets were estimated from your profile. Adjust anytime to match how you eat.")
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
                        Text("Complete onboarding to set your profile and macro targets.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    NavigationLink {
                        LegalDocumentView(title: "Support", sections: LegalDocuments.support)
                    } label: {
                        Label("Support", systemImage: "questionmark.circle")
                    }

                    NavigationLink {
                        LegalDocumentView(title: "Privacy Policy", sections: LegalDocuments.privacyPolicy)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "mailto:\(AppLegalLinks.supportEmail)")!) {
                        Label("Email support", systemImage: "envelope")
                    }
                } header: {
                    Text("Help & legal")
                } footer: {
                    Text("Your data stays on this device. See Privacy Policy for details.")
                }

                Section {
                    if !plan.recipes.isEmpty {
                        Button("Clear weekly plan", role: .destructive) {
                            appState.resetWeeklyPlan()
                        }
                    }
                    Button("Reset profile & redo onboarding", role: .destructive) {
                        showResetOnboardingConfirmation = true
                    }
                } footer: {
                    Text("Resetting clears your profile, weekly plan, pantry list, and favorites.")
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog(
                "Reset profile & redo onboarding?",
                isPresented: $showResetOnboardingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive) {
                    appState.resetOnboardingPreview()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your profile, weekly plan, pantry list, and favorites. You can’t undo this.")
            }
        }
    }

    @ViewBuilder
    private func recipeThumbnail(_ recipe: RecipeSummary) -> some View {
        RecipeImageView(recipe: recipe)
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
        var parts: [String] = []
        if recipe.isSnack {
            parts.append("Snack")
        } else if recipe.isBreakfast {
            parts.append("Breakfast")
        }
        if recipe.isSnack {
            parts.append(recipe.portionCount == 1 ? "1 portion" : "\(recipe.portionCount) portions")
        } else {
            parts.append(recipe.portionCount == 1 ? "1 serving" : "\(recipe.portionCount) servings")
        }
        parts.append("\(recipe.ingredientCount) ingredients")
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
