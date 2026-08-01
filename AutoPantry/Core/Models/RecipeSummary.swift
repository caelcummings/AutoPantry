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
    var cuisines: [String]
    var ingredients: [RecipeIngredient]
    var instructions: [String]

    /// At least 1 serving so progress never stalls on bad data.
    var mealContribution: Int { max(servings, 1) }

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

    enum CodingKeys: String, CodingKey {
        case id, title, imageURL, cookMinutes, calories, proteinGrams, carbsGrams, fatGrams
        case servings, ingredientCount, estimatedPrice, cuisines, ingredients, instructions
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
        cuisines = try container.decodeIfPresent([String].self, forKey: .cuisines) ?? []
        ingredients = try container.decodeIfPresent([RecipeIngredient].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
    }
}

struct RecipeIngredient: Equatable, Codable {
    let name: String
    let amount: String
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
        isPlanComplete: Bool
    ) -> [RecipeSummary] {
        let candidates = feed.filter { !plannedIDs.contains($0.id) }
        return RecipeSuggestionEngine.buildDeck(
            from: candidates,
            profile: profile,
            plan: plan,
            isPlanComplete: isPlanComplete
        )
    }

    private static func loadRecipes() -> [RecipeSummary] {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            assertionFailure("recipes.json missing from app bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(RecipeCatalogFile.self, from: data)
            return catalog.recipes
        } catch {
            assertionFailure("Failed to decode recipes.json: \(error)")
            return []
        }
    }
}
