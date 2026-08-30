import Foundation

struct GroceryListItem: Identifiable, Equatable {
    var id: String { normalizedName }
    let name: String
    let normalizedName: String
    let aisle: String
    let amounts: [String]
    let recipeCount: Int
    /// True when the user added this item manually (not from a recipe).
    let isCustom: Bool

    init(
        name: String,
        normalizedName: String,
        aisle: String,
        amounts: [String],
        recipeCount: Int,
        isCustom: Bool = false
    ) {
        self.name = name
        self.normalizedName = normalizedName
        self.aisle = aisle
        self.amounts = amounts
        self.recipeCount = recipeCount
        self.isCustom = isCustom
    }

    var detailLine: String? {
        let cleaned = amounts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if cleaned.isEmpty {
            return recipeCount > 1 ? "Used in \(recipeCount) recipes" : nil
        }
        let amountText = cleaned.joined(separator: " + ")
        if recipeCount > 1 {
            return "\(amountText) · \(recipeCount) recipes"
        }
        return amountText
    }
}

enum GroceryListBuilder {
    static let pantryStaplesAisle = "Pantry staples"
    static let addedAisle = "Added"
    private static let otherAisle = "Other"

    static func build(
        from plan: WeeklyMealPlan,
        excluding inventory: SeasoningInventory,
        extras: ExtraGroceryItems = ExtraGroceryItems()
    ) -> [GroceryListItem] {
        struct Aggregate {
            var displayName: String
            var amounts: [String] = []
            var recipeIDs: Set<String> = []
            var isSeasoning: Bool
        }

        var aggregates: [String: Aggregate] = [:]

        for recipe in plan.recipes {
            for ingredient in recipe.ingredients {
                let rawName = ingredient.displayName
                guard !rawName.isEmpty else { continue }

                if inventory.containsIngredient(rawName) {
                    continue
                }

                let key = IngredientNormalizer.groceryKey(for: rawName)
                guard !key.isEmpty else { continue }

                var entry = aggregates[key] ?? Aggregate(
                    displayName: rawName,
                    isSeasoning: SeasoningMatcher.isPantryStaple(rawName)
                )
                entry.displayName = IngredientNormalizer.preferredDisplayName(
                    current: entry.displayName,
                    candidate: rawName
                )
                if !ingredient.displayAmount.isEmpty {
                    entry.amounts.append(ingredient.displayAmount)
                }
                entry.recipeIDs.insert(recipe.id)
                // If any variant looks like a staple, keep it in that aisle.
                if SeasoningMatcher.isPantryStaple(rawName) {
                    entry.isSeasoning = true
                }
                aggregates[key] = entry
            }
        }

        var items = aggregates.map { key, value in
            GroceryListItem(
                name: prettyName(value.displayName),
                normalizedName: key,
                aisle: value.isSeasoning ? pantryStaplesAisle : otherAisle,
                amounts: IngredientAmountMerger.combine(value.amounts),
                recipeCount: value.recipeIDs.count
            )
        }

        let existingKeys = Set(items.map(\.normalizedName))
        for rawName in extras.sortedItems {
            let key = IngredientNormalizer.groceryKey(for: rawName)
            guard !key.isEmpty, !existingKeys.contains(key) else { continue }
            items.append(
                GroceryListItem(
                    name: prettyName(rawName),
                    normalizedName: key,
                    aisle: addedAisle,
                    amounts: [],
                    recipeCount: 0,
                    isCustom: true
                )
            )
        }

        return items.sorted {
            if $0.aisle != $1.aisle {
                if $0.aisle == addedAisle { return true }
                if $1.aisle == addedAisle { return false }
                if $0.aisle == pantryStaplesAisle { return false }
                if $1.aisle == pantryStaplesAisle { return true }
                return $0.aisle < $1.aisle
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Title-cases lowercase names without mangling acronyms like BBQ.
    private static func prettyName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        if trimmed != trimmed.lowercased() { return trimmed }
        return trimmed.split(separator: " ").map { word in
            guard let first = word.first else { return String(word) }
            return String(first).uppercased() + word.dropFirst()
        }.joined(separator: " ")
    }
}
