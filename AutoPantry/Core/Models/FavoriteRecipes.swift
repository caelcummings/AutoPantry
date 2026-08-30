import Foundation

/// Persisted set of recipe IDs the user has starred as favorites.
struct FavoriteRecipes: Equatable, Codable {
    var recipeIDs: [String]

    init(recipeIDs: [String] = []) {
        self.recipeIDs = recipeIDs
    }

    var idSet: Set<String> { Set(recipeIDs) }

    var isEmpty: Bool { recipeIDs.isEmpty }

    func contains(_ id: String) -> Bool {
        recipeIDs.contains(id)
    }

    mutating func toggle(_ id: String) {
        if let index = recipeIDs.firstIndex(of: id) {
            recipeIDs.remove(at: index)
        } else {
            recipeIDs.append(id)
        }
    }

    mutating func add(_ id: String) {
        guard !contains(id) else { return }
        recipeIDs.append(id)
    }

    mutating func remove(_ id: String) {
        recipeIDs.removeAll { $0 == id }
    }
}
