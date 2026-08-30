import Foundation

/// Extra grocery items the user adds by hand (not from recipes).
struct ExtraGroceryItems: Equatable, Codable {
    var items: [String] = []

    var isEmpty: Bool { items.isEmpty }

    var sortedItems: [String] {
        items.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    mutating func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = IngredientNormalizer.groceryKey(for: trimmed)
        guard !key.isEmpty else { return }
        guard !items.contains(where: { IngredientNormalizer.groceryKey(for: $0) == key }) else { return }
        items.append(trimmed)
    }

    mutating func remove(_ name: String) {
        let key = IngredientNormalizer.groceryKey(for: name)
        items.removeAll { IngredientNormalizer.groceryKey(for: $0) == key }
    }

    func contains(_ name: String) -> Bool {
        let key = IngredientNormalizer.groceryKey(for: name)
        return items.contains { IngredientNormalizer.groceryKey(for: $0) == key }
    }
}
