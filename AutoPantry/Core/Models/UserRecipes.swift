import Foundation

/// User-created recipes persisted on device.
struct UserRecipes: Equatable, Codable {
    var recipes: [RecipeSummary] = []

    var isEmpty: Bool { recipes.isEmpty }

    var sortedRecipes: [RecipeSummary] {
        recipes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

extension RecipeSummary {
    static let userRecipeIDPrefix = "user-"

    var isUserRecipe: Bool {
        id.hasPrefix(Self.userRecipeIDPrefix)
    }

    static func makeUserRecipeID() -> String {
        userRecipeIDPrefix + UUID().uuidString.lowercased()
    }
}
