import Foundation

struct RecipeSummary: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let imageURL: URL?
    let cookMinutes: Int?
    let calories: Int?
    let proteinGrams: Int?
    let carbsGrams: Int?
    let fatGrams: Int?
    /// How many meal slots this recipe fills toward the weekly meal target.
    let servings: Int
    let ingredientCount: Int
    let estimatedPrice: Double?
    /// Explicit snack tag from the recipe catalog (not calorie-based).
    let isSnack: Bool
    /// Explicit breakfast tag from the recipe catalog.
    let isBreakfast: Bool
    var cuisines: [String]
    var ingredients: [RecipeIngredient]
    var instructions: [String]

    var hasMacros: Bool {
        calories != nil && proteinGrams != nil && carbsGrams != nil && fatGrams != nil
    }

    var formattedPrice: String? {
        guard let estimatedPrice else { return nil }
        return estimatedPrice.formatted(.currency(code: "USD"))
    }

    /// Values used by weekly macro totals (actual or estimated from ingredients).
    var caloriesValue: Int { effectiveMacros.calories }
    var proteinValue: Int { effectiveMacros.proteinGrams }
    var carbsValue: Int { effectiveMacros.carbsGrams }
    var fatValue: Int { effectiveMacros.fatGrams }

    /// Portions used for grocery/macro scaling (always at least 1).
    var portionCount: Int { max(servings, 1) }

    /// Meal slots filled toward the weekly meal target (snacks contribute 0).
    var mealContribution: Int { isSnack ? 0 : portionCount }

    enum CodingKeys: String, CodingKey {
        case id, title, imageURL, cookMinutes, calories, proteinGrams, carbsGrams, fatGrams
        case servings, ingredientCount, estimatedPrice, isSnack, isBreakfast, cuisines, ingredients, instructions
    }

    init(
        id: String,
        title: String,
        imageURL: URL?,
        cookMinutes: Int?,
        calories: Int?,
        proteinGrams: Int?,
        carbsGrams: Int?,
        fatGrams: Int?,
        servings: Int = 1,
        ingredientCount: Int,
        estimatedPrice: Double?,
        isSnack: Bool = false,
        isBreakfast: Bool = false,
        cuisines: [String] = [],
        ingredients: [RecipeIngredient] = [],
        instructions: [String] = []
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.cookMinutes = cookMinutes
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.servings = max(servings, 1)
        self.ingredientCount = ingredientCount
        self.estimatedPrice = estimatedPrice
        self.isSnack = isSnack
        self.isBreakfast = isBreakfast
        self.cuisines = cuisines
        self.ingredients = ingredients
        self.instructions = instructions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        cookMinutes = try container.decodeIfPresent(Int.self, forKey: .cookMinutes)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        proteinGrams = try container.decodeIfPresent(Int.self, forKey: .proteinGrams)
        carbsGrams = try container.decodeIfPresent(Int.self, forKey: .carbsGrams)
        fatGrams = try container.decodeIfPresent(Int.self, forKey: .fatGrams)
        servings = max(try container.decodeIfPresent(Int.self, forKey: .servings) ?? 1, 1)
        ingredientCount = try container.decode(Int.self, forKey: .ingredientCount)
        estimatedPrice = try container.decodeIfPresent(Double.self, forKey: .estimatedPrice)
        isSnack = try container.decodeIfPresent(Bool.self, forKey: .isSnack) ?? false
        isBreakfast = try container.decodeIfPresent(Bool.self, forKey: .isBreakfast) ?? false
        cuisines = try container.decodeIfPresent([String].self, forKey: .cuisines) ?? []
        ingredients = try container.decodeIfPresent([RecipeIngredient].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(cookMinutes, forKey: .cookMinutes)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encodeIfPresent(proteinGrams, forKey: .proteinGrams)
        try container.encodeIfPresent(carbsGrams, forKey: .carbsGrams)
        try container.encodeIfPresent(fatGrams, forKey: .fatGrams)
        try container.encode(servings, forKey: .servings)
        try container.encode(ingredientCount, forKey: .ingredientCount)
        try container.encodeIfPresent(estimatedPrice, forKey: .estimatedPrice)
        try container.encode(isSnack, forKey: .isSnack)
        try container.encode(isBreakfast, forKey: .isBreakfast)
        try container.encode(cuisines, forKey: .cuisines)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(instructions, forKey: .instructions)
    }
}

struct RecipeIngredient: Equatable, Codable {
    let name: String
    let amount: String

    /// Name without parenthetical notes or metric slash-alternates.
    var displayName: String {
        IngredientNormalizer.stripParentheticals(
            from: IngredientNormalizer.dropMetricAlternates(from: name)
        )
    }

    /// US customary amount only (`1 cup / 120g` → `1 cup`).
    var displayAmount: String {
        let fromAmount = IngredientNormalizer.dropMetricAlternates(from: amount)
        if !fromAmount.isEmpty { return fromAmount }
        return IngredientNormalizer.usAmount(fromName: name)
    }
}

private struct RecipeCatalogFile: Decodable {
    let version: Int
    let recipes: [RecipeSummary]
}

enum RecipeCatalog {
    static let feed: [RecipeSummary] = loadRecipes()
    static let hasNutritionData: Bool = feed.contains { $0.hasMacros }

    static func deck(
        excluding plannedIDs: Set<String>,
        profile: NutritionProfile,
        plan: WeeklyMealPlan,
        isPlanComplete: Bool,
        userRecipes: [RecipeSummary] = []
    ) -> [RecipeSummary] {
        let candidates = (feed + userRecipes).filter { !plannedIDs.contains($0.id) }
        return RecipeSuggestionEngine.buildDeck(
            from: candidates,
            profile: profile,
            plan: plan,
            isPlanComplete: isPlanComplete
        )
    }

    static func recipe(withID id: String, userRecipes: [RecipeSummary] = []) -> RecipeSummary? {
        userRecipes.first { $0.id == id } ?? feed.first { $0.id == id }
    }

    private static func loadRecipes() -> [RecipeSummary] {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            #if DEBUG
            assertionFailure("recipes.json missing from app bundle")
            #endif
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(RecipeCatalogFile.self, from: data)
            return catalog.recipes
        } catch {
            #if DEBUG
            assertionFailure("Failed to decode recipes.json: \(error)")
            #endif
            return []
        }
    }
}
