import Foundation

struct GroceryListItem: Identifiable, Equatable {
    var id: String { normalizedName }
    let name: String
    let normalizedName: String
    let aisle: String
    let amounts: [String]
    let recipeCount: Int

    var detailLine: String? {
        let cleaned = amounts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if cleaned.isEmpty {
            return recipeCount > 1 ? "Used in \(recipeCount) recipes" : nil
        }
        var seen = Set<String>()
        let unique = cleaned.filter { seen.insert($0).inserted }
        let amountText = unique.joined(separator: " + ")
        if recipeCount > 1 {
            return "\(amountText) · \(recipeCount) recipes"
        }
        return amountText
    }
}

enum GroceryListBuilder {
    private static let seasoningAisle = "Pantry staples"
    private static let otherAisle = "Other"

    static func build(
        from plan: WeeklyMealPlan,
        excluding inventory: SeasoningInventory
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
                let rawName = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !rawName.isEmpty else { continue }

                if inventory.containsIngredient(rawName) {
                    continue
                }

                let key = SeasoningMatcher.normalize(rawName)
                guard !key.isEmpty else { continue }

                var entry = aggregates[key] ?? Aggregate(
                    displayName: rawName,
                    isSeasoning: SeasoningMatcher.isSeasoning(rawName)
                )
                // Prefer longer / more specific spelling when merging duplicates.
                if rawName.count > entry.displayName.count {
                    entry.displayName = rawName
                }
                if !ingredient.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    entry.amounts.append(ingredient.amount)
                }
                entry.recipeIDs.insert(recipe.id)
                aggregates[key] = entry
            }
        }

        return aggregates.map { key, value in
            GroceryListItem(
                name: value.displayName,
                normalizedName: key,
                aisle: value.isSeasoning ? seasoningAisle : otherAisle,
                amounts: value.amounts,
                recipeCount: value.recipeIDs.count
            )
        }
        .sorted {
            if $0.aisle != $1.aisle {
                // Pantry staples last so fresh food shows first.
                if $0.aisle == seasoningAisle { return false }
                if $1.aisle == seasoningAisle { return true }
                return $0.aisle < $1.aisle
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
