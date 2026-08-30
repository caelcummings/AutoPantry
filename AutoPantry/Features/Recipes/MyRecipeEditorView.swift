import PhotosUI
import SwiftUI

struct MyRecipeEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let existingRecipeID: String?

    @State private var title = ""
    @State private var servings = 1
    @State private var cookMinutes = ""
    @State private var isSnack = false
    @State private var isBreakfast = false
    @State private var ingredients: [EditableIngredient] = [EditableIngredient()]
    @State private var instructions: [String] = [""]
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImageData: Data?
    @State private var shouldRemoveImage = false
    @State private var photoLoadTask: Task<Void, Never>?

    private var isEditing: Bool { existingRecipeID != nil }

    init(recipe: RecipeSummary? = nil) {
        existingRecipeID = recipe?.id
        if let recipe {
            _title = State(initialValue: recipe.title)
            _servings = State(initialValue: recipe.portionCount)
            _cookMinutes = State(initialValue: recipe.cookMinutes.map(String.init) ?? "")
            _isSnack = State(initialValue: recipe.isSnack)
            _isBreakfast = State(initialValue: recipe.isBreakfast)
            let mappedIngredients = recipe.ingredients.map {
                EditableIngredient(name: $0.name, amount: $0.amount)
            }
            _ingredients = State(initialValue: mappedIngredients.isEmpty ? [EditableIngredient()] : mappedIngredients)
            _instructions = State(initialValue: recipe.instructions.nonEmptyOrDefault)
            _calories = State(initialValue: recipe.calories.map(String.init) ?? "")
            _protein = State(initialValue: recipe.proteinGrams.map(String.init) ?? "")
            _carbs = State(initialValue: recipe.carbsGrams.map(String.init) ?? "")
            _fat = State(initialValue: recipe.fatGrams.map(String.init) ?? "")
            if UserRecipeImageStore.imageURLIfExists(for: recipe.id) != nil {
                _previewImageData = State(initialValue: UserRecipeImageStore.loadData(for: recipe.id))
            }
        }
    }

    var body: some View {
        Form {
            Section {
                photoSection
            } header: {
                Text("Photo")
            } footer: {
                Text("Optional — choose a picture from your camera roll.")
            }

            Section {
                TextField("Recipe name", text: $title)
                    .textInputAutocapitalization(.words)

                Stepper(value: $servings, in: 1...12) {
                    Text("Servings: \(servings)")
                }

                TextField("Cook time (minutes, optional)", text: $cookMinutes)
                    .keyboardType(.numberPad)
            } header: {
                Text("Basics")
            }

            Section {
                Toggle("Snack", isOn: $isSnack)
                Toggle("Breakfast", isOn: $isBreakfast)
            } footer: {
                Text("Snacks don't count toward your weekly meal total.")
            }

            Section {
                ForEach($ingredients) { $ingredient in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Ingredient", text: $ingredient.name)
                            .textInputAutocapitalization(.words)
                        TextField("Amount (optional)", text: $ingredient.amount)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: deleteIngredients)

                Button {
                    ingredients.append(EditableIngredient())
                } label: {
                    Label("Add ingredient", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Ingredients")
            }

            Section {
                ForEach(instructions.indices, id: \.self) { index in
                    TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
                        .lineLimit(2...6)
                }
                .onDelete(perform: deleteInstructions)

                Button {
                    instructions.append("")
                } label: {
                    Label("Add step", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Instructions")
            }

            Section {
                TextField("Calories per serving", text: $calories)
                    .keyboardType(.numberPad)
                TextField("Protein (g)", text: $protein)
                    .keyboardType(.numberPad)
                TextField("Carbs (g)", text: $carbs)
                    .keyboardType(.numberPad)
                TextField("Fat (g)", text: $fat)
                    .keyboardType(.numberPad)
            } header: {
                Text("Nutrition (optional)")
            } footer: {
                Text("Leave blank to estimate macros from ingredients. Fill all four fields to use your own numbers.")
            }

            if isEditing {
                Section {
                    Button("Delete recipe", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit recipe" : "New recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .confirmationDialog(
            "Delete this recipe?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let existingRecipeID {
                    appState.deleteUserRecipe(id: existingRecipeID)
                }
                dismiss()
            }
        } message: {
            Text("It will be removed from your library, favorites, and weekly plan.")
        }
        .onChange(of: selectedPhoto) { _, item in
            photoLoadTask?.cancel()
            guard let item else { return }
            photoLoadTask = Task { @MainActor in
                guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                guard !Task.isCancelled else { return }
                previewImageData = data
                shouldRemoveImage = false
            }
        }
        .onDisappear {
            photoLoadTask?.cancel()
            photoLoadTask = nil
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if let previewImageData, let uiImage = UIImage(data: previewImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Change photo", systemImage: "photo.on.rectangle.angled")
                }

                Button("Remove", role: .destructive) {
                    self.previewImageData = nil
                    selectedPhoto = nil
                    shouldRemoveImage = true
                }
            }
        } else {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose from camera roll", systemImage: "photo.on.rectangle.angled")
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && ingredients.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func save() {
        let recipeID = existingRecipeID ?? RecipeSummary.makeUserRecipeID()

        if shouldRemoveImage {
            UserRecipeImageStore.delete(for: recipeID)
        } else if let previewImageData {
            UserRecipeImageStore.save(previewImageData, for: recipeID)
        }

        let recipe = buildRecipe(id: recipeID)
        appState.saveUserRecipe(recipe)
        dismiss()
    }

    private func buildRecipe(id: String) -> RecipeSummary {
        let trimmedIngredients = ingredients.compactMap { item -> RecipeIngredient? in
            let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return RecipeIngredient(
                name: name,
                amount: item.amount.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        let trimmedInstructions = instructions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let nutrition = parsedNutrition

        return RecipeSummary(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: UserRecipeImageStore.imageURLIfExists(for: id),
            cookMinutes: Int(cookMinutes.trimmingCharacters(in: .whitespacesAndNewlines)),
            calories: nutrition?.calories,
            proteinGrams: nutrition?.protein,
            carbsGrams: nutrition?.carbs,
            fatGrams: nutrition?.fat,
            servings: servings,
            ingredientCount: trimmedIngredients.count,
            estimatedPrice: nil,
            isSnack: isSnack,
            isBreakfast: isBreakfast,
            ingredients: trimmedIngredients,
            instructions: trimmedInstructions
        )
    }

    private var parsedNutrition: (calories: Int, protein: Int, carbs: Int, fat: Int)? {
        guard
            let caloriesValue = Int(calories.trimmingCharacters(in: .whitespacesAndNewlines)),
            let proteinValue = Int(protein.trimmingCharacters(in: .whitespacesAndNewlines)),
            let carbsValue = Int(carbs.trimmingCharacters(in: .whitespacesAndNewlines)),
            let fatValue = Int(fat.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return nil
        }
        return (caloriesValue, proteinValue, carbsValue, fatValue)
    }

    private func deleteIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        if ingredients.isEmpty {
            ingredients.append(EditableIngredient())
        }
    }

    private func deleteInstructions(at offsets: IndexSet) {
        instructions.remove(atOffsets: offsets)
        if instructions.isEmpty {
            instructions.append("")
        }
    }
}

private struct EditableIngredient: Identifiable {
    let id = UUID()
    var name: String
    var amount: String

    init(name: String = "", amount: String = "") {
        self.name = name
        self.amount = amount
    }
}

private extension Array where Element == String {
    var nonEmptyOrDefault: [String] {
        isEmpty ? [""] : self
    }
}

#Preview("New") {
    NavigationStack {
        MyRecipeEditorView()
            .environmentObject(AppState(route: .main, userProfile: OnboardingDraft()))
    }
}
