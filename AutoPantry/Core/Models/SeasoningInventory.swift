import Foundation

/// Pantry staples the user already owns — excluded from grocery generation.
struct SeasoningInventory: Equatable, Codable {
    /// Display names as entered / selected by the user.
    var items: [String] = []

    var isEmpty: Bool { items.isEmpty }

    var sortedItems: [String] {
        items.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    mutating func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = SeasoningMatcher.normalize(trimmed)
        guard !items.contains(where: { SeasoningMatcher.normalize($0) == key }) else { return }
        items.append(trimmed)
    }

    mutating func remove(_ name: String) {
        let key = SeasoningMatcher.normalize(name)
        items.removeAll { SeasoningMatcher.normalize($0) == key }
    }

    func containsIngredient(_ ingredientName: String) -> Bool {
        SeasoningMatcher.isOwned(ingredientName, inventory: items)
    }
}

enum PantryCategory: String, CaseIterable, Identifiable {
    case seasonings
    case oilsAndVinegars
    case condiments
    case bakingAndSweeteners
    case cookingBasics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .seasonings: "Seasonings & spices"
        case .oilsAndVinegars: "Oils & vinegars"
        case .condiments: "Condiments & sauces"
        case .bakingAndSweeteners: "Baking & sweeteners"
        case .cookingBasics: "Cooking basics"
        }
    }
}

/// Shared pantry vocabulary + matching for inventory and grocery filtering.
enum SeasoningMatcher {
    struct CatalogItem: Hashable {
        let name: String
        let category: PantryCategory
    }

    /// Curated staples shown in the inventory picker, grouped by category.
    static let catalog: [CatalogItem] = {
        let pairs: [(String, PantryCategory)] = [
            // Seasonings & spices
            ("Salt", .seasonings),
            ("Black pepper", .seasonings),
            ("White pepper", .seasonings),
            ("Garlic powder", .seasonings),
            ("Onion powder", .seasonings),
            ("Paprika", .seasonings),
            ("Smoked paprika", .seasonings),
            ("Cumin", .seasonings),
            ("Chili powder", .seasonings),
            ("Cayenne", .seasonings),
            ("Red pepper flakes", .seasonings),
            ("Oregano", .seasonings),
            ("Basil", .seasonings),
            ("Thyme", .seasonings),
            ("Rosemary", .seasonings),
            ("Dill", .seasonings),
            ("Parsley", .seasonings),
            ("Bay leaves", .seasonings),
            ("Cinnamon", .seasonings),
            ("Nutmeg", .seasonings),
            ("Ginger", .seasonings),
            ("Turmeric", .seasonings),
            ("Coriander", .seasonings),
            ("Allspice", .seasonings),
            ("Cloves", .seasonings),
            ("Curry powder", .seasonings),
            ("Italian seasoning", .seasonings),
            ("Taco seasoning", .seasonings),
            ("Dry mustard", .seasonings),
            ("Garlic salt", .seasonings),
            ("Seasoning salt", .seasonings),
            ("Everything bagel seasoning", .seasonings),

            // Oils & vinegars
            ("Olive oil", .oilsAndVinegars),
            ("Vegetable oil", .oilsAndVinegars),
            ("Canola oil", .oilsAndVinegars),
            ("Sesame oil", .oilsAndVinegars),
            ("Coconut oil", .oilsAndVinegars),
            ("Cooking spray", .oilsAndVinegars),
            ("White vinegar", .oilsAndVinegars),
            ("Apple cider vinegar", .oilsAndVinegars),
            ("Balsamic vinegar", .oilsAndVinegars),
            ("Rice vinegar", .oilsAndVinegars),
            ("Red wine vinegar", .oilsAndVinegars),

            // Condiments & sauces
            ("Ketchup", .condiments),
            ("Mustard", .condiments),
            ("Dijon mustard", .condiments),
            ("Mayonnaise", .condiments),
            ("Soy sauce", .condiments),
            ("Hot sauce", .condiments),
            ("Sriracha", .condiments),
            ("Worcestershire sauce", .condiments),
            ("BBQ sauce", .condiments),
            ("Teriyaki sauce", .condiments),
            ("Fish sauce", .condiments),
            ("Hot honey", .condiments),
            ("Ranch dressing", .condiments),
            ("Salsa", .condiments),
            ("Tomato paste", .condiments),
            ("Peanut butter", .condiments),
            ("Jam", .condiments),
            ("Relish", .condiments),
            ("Tahini", .condiments),
            ("Hoisin sauce", .condiments),

            // Baking & sweeteners
            ("Sugar", .bakingAndSweeteners),
            ("Brown sugar", .bakingAndSweeteners),
            ("Powdered sugar", .bakingAndSweeteners),
            ("Honey", .bakingAndSweeteners),
            ("Maple syrup", .bakingAndSweeteners),
            ("Vanilla extract", .bakingAndSweeteners),
            ("Flour", .bakingAndSweeteners),
            ("Baking powder", .bakingAndSweeteners),
            ("Baking soda", .bakingAndSweeteners),
            ("Cornstarch", .bakingAndSweeteners),
            ("Cocoa powder", .bakingAndSweeteners),
            ("Yeast", .bakingAndSweeteners),

            // Cooking basics
            ("Butter", .cookingBasics),
            ("Garlic", .cookingBasics),
            ("Onion", .cookingBasics),
            ("Lemon juice", .cookingBasics),
            ("Lime juice", .cookingBasics),
            ("Chicken broth", .cookingBasics),
            ("Vegetable broth", .cookingBasics),
            ("Beef broth", .cookingBasics),
            ("Bouillon", .cookingBasics),
            ("Breadcrumbs", .cookingBasics),
            ("Rice", .cookingBasics),
            ("Pasta", .cookingBasics),
            ("Soy milk", .cookingBasics),
            ("Oats", .cookingBasics),
        ]
        return pairs.map { CatalogItem(name: $0.0, category: $0.1) }
    }()

    static func items(in category: PantryCategory) -> [String] {
        catalog.filter { $0.category == category }.map(\.name)
    }

    /// All picker names (for roots / matching).
    static var commonSeasonings: [String] { catalog.map(\.name) }

    private static let stapleRoots: Set<String> = Set(
        catalog.map { normalize($0.name) } + [
            // Seasoning variants
            "kosher salt", "sea salt", "coarse salt", "pepper", "peppercorns",
            "ground pepper", "cayenne pepper", "pepper flakes", "herbs",
            "seasoning", "mustard powder", "ground cumin", "ground cinnamon",
            "ground nutmeg", "ground ginger", "ground cloves", "dried oregano",
            "dried basil", "dried thyme", "bay leaf",
            // Condiment / oil variants
            "extra virgin olive oil", "evoo", "mayo", "catsup", "yellow mustard",
            "dijon", "light soy sauce", "low sodium soy sauce", "tamari",
            "tabasco", "chili sauce", "barbecue sauce", "bbq",
            "apple cider", "balsamic", "rice wine vinegar",
            "all-purpose flour", "ap flour", "granulated sugar", "white sugar",
            "confectioners sugar", "icing sugar", "corn starch", "corn flour",
            "stock", "chicken stock", "vegetable stock", "beef stock",
            "chicken bouillon", "vegetable bouillon", "beef bouillon",
            "panko", "panko breadcrumbs", "almond extract",
            "canola", "neutral oil", "avocado oil",
        ]
    )

    private static let produceExclusions: Set<String> = [
        "bell pepper", "bell peppers", "green pepper", "green peppers",
        "red pepper", "red peppers", "yellow pepper", "yellow peppers",
        "jalapeno pepper", "jalapeño pepper", "peppers", "green chilies", "chilies",
    ]

    static func normalize(_ name: String) -> String {
        var value = name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        let prefixes = [
            "freshly ground ", "freshly ", "ground ", "dried ", "fresh ",
            "pure ", "chopped ", "minced ", "extra virgin ", "low sodium ",
            "unsalted ", "salted ",
        ]
        for prefix in prefixes where value.hasPrefix(prefix) {
            value = String(value.dropFirst(prefix.count))
        }
        return value
    }

    /// Whether this ingredient is a pantry staple (spice, condiment, oil, etc.).
    static func isPantryStaple(_ ingredientName: String) -> Bool {
        let name = normalize(ingredientName)
        guard !name.isEmpty else { return false }
        if produceExclusions.contains(name) { return false }
        if stapleRoots.contains(name) { return true }

        if name.contains("seasoning") { return true }
        if name.hasSuffix(" extract") { return true }
        if name.hasSuffix(" flakes") && name.contains("pepper") { return true }
        if name.hasSuffix(" vinegar") { return true }
        if name.hasSuffix(" oil") { return true }
        if name.hasSuffix(" sauce") { return true }
        if name.hasSuffix(" syrup") { return true }
        if name.hasSuffix(" broth") || name.hasSuffix(" stock") { return true }
        if name.contains("bouillon") { return true }
        if name.hasSuffix(" powder") { return true }
        if name == "salt" || name.hasSuffix(" salt") { return true }
        if name == "pepper" || name.hasSuffix(" pepper") {
            return !produceExclusions.contains(name)
        }
        if name == "mayo" || name == "mayonnaise" { return true }
        if name == "ketchup" || name == "catsup" { return true }
        if name == "mustard" || name.hasSuffix(" mustard") { return true }
        if name == "flour" || name.hasSuffix(" flour") { return true }
        if name == "sugar" || name.hasSuffix(" sugar") { return true }
        if name == "butter" { return true }
        if name == "honey" { return true }
        if name == "rice" || name.hasSuffix(" rice") { return true }
        if name == "pasta" || name.hasSuffix(" pasta") { return true }
        if name.contains("breadcrumb") || name == "panko" { return true }
        return false
    }

    /// Backward-compatible alias used by grocery aisle grouping.
    static func isSeasoning(_ ingredientName: String) -> Bool {
        isPantryStaple(ingredientName)
    }

    /// True when the ingredient should be skipped because the user already owns it.
    static func isOwned(_ ingredientName: String, inventory: [String]) -> Bool {
        guard isPantryStaple(ingredientName) else { return false }
        let ingredient = normalize(ingredientName)
        let owned = inventory.map(normalize).filter { !$0.isEmpty }
        guard !owned.isEmpty else { return false }

        for item in owned {
            if ingredient == item { return true }
            if ingredient.hasSuffix(" \(item)") || ingredient.hasPrefix("\(item) ") {
                return true
            }

            if matchesAlias(ingredient: ingredient, owned: item) {
                return true
            }
        }
        return false
    }

    private static func matchesAlias(ingredient: String, owned: String) -> Bool {
        switch owned {
        case "salt":
            return ingredient == "salt" || ingredient.hasSuffix(" salt")
        case "pepper", "black pepper":
            return [
                "pepper", "black pepper", "ground pepper", "peppercorns",
            ].contains(ingredient)
        case "olive oil":
            return ingredient.contains("olive oil") || ingredient == "evoo"
        case "vegetable oil", "canola oil":
            return ingredient == "vegetable oil"
                || ingredient == "canola oil"
                || ingredient == "neutral oil"
        case "mayonnaise", "mayo":
            return ingredient == "mayonnaise" || ingredient == "mayo"
        case "ketchup":
            return ingredient == "ketchup" || ingredient == "catsup"
        case "mustard":
            return ingredient == "mustard"
                || ingredient == "yellow mustard"
                || ingredient == "dijon mustard"
                || ingredient == "dijon"
        case "soy sauce":
            return ingredient.contains("soy sauce") || ingredient == "tamari"
        case "hot sauce":
            return ingredient == "hot sauce"
                || ingredient == "sriracha"
                || ingredient == "tabasco"
                || ingredient == "chili sauce"
        case "bbq sauce", "barbecue sauce":
            return ingredient.contains("bbq") || ingredient.contains("barbecue")
        case "flour":
            return ingredient == "flour"
                || ingredient == "all-purpose flour"
                || ingredient == "ap flour"
        case "sugar":
            return ingredient == "sugar"
                || ingredient == "white sugar"
                || ingredient == "granulated sugar"
        case "powdered sugar":
            return ingredient == "powdered sugar"
                || ingredient == "confectioners sugar"
                || ingredient == "icing sugar"
        case "cornstarch":
            return ingredient == "cornstarch"
                || ingredient == "corn starch"
                || ingredient == "corn flour"
        case "chicken broth":
            return ingredient == "chicken broth" || ingredient == "chicken stock"
        case "vegetable broth":
            return ingredient == "vegetable broth" || ingredient == "vegetable stock"
        case "beef broth":
            return ingredient == "beef broth" || ingredient == "beef stock"
        case "bouillon":
            return ingredient.contains("bouillon")
        case "breadcrumbs":
            return ingredient.contains("breadcrumb") || ingredient == "panko"
        case "garlic":
            return ingredient == "garlic"
                || ingredient == "garlic clove"
                || ingredient == "garlic cloves"
        case "onion":
            return ingredient == "onion" || ingredient == "onions"
        case "vanilla extract":
            return ingredient == "vanilla" || ingredient == "vanilla extract"
        case "rice":
            return ingredient == "rice" || ingredient.hasSuffix(" rice")
        case "pasta":
            return ingredient == "pasta" || ingredient.hasSuffix(" pasta")
        default:
            return false
        }
    }
}
