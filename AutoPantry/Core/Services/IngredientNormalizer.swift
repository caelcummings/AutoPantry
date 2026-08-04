import Foundation

/// Canonicalizes ingredient names so near-duplicates merge on the grocery list.
enum IngredientNormalizer {
    /// Stable merge key for grocery aggregation.
    static func groceryKey(for rawName: String) -> String {
        var value = rawName
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else { return value }

        // Drop leading prep words that don't change what you buy.
        let prefixes = [
            "freshly ground ", "freshly ", "fresh ", "large ", "small ", "medium ",
            "extra large ", "chopped ", "minced ", "diced ", "sliced ", "crushed ",
            "grated ", "shredded ", "lean ", "fat free ", "fat-free ", "low fat ",
            "low-fat ", "nonfat ", "skimmed ", "unsalted ", "salted ", "cooked ",
            "uncooked ", "raw ", "whole ", "plain ", "dried ",
        ]
        var changed = true
        while changed {
            changed = false
            for prefix in prefixes where value.hasPrefix(prefix) {
                value = String(value.dropFirst(prefix.count))
                changed = true
            }
        }

        value = singularizePhrase(value)

        if let alias = aliases[value] {
            return alias
        }

        // Singularize again after alias expansion isn't needed; map common heads.
        let words = value.split(separator: " ").map(String.init)
        if let last = words.last, let mapped = headAliases[last] {
            return (words.dropLast() + [mapped]).joined(separator: " ")
        }

        return value
    }

    /// Prefer a clean display name when merging variants.
    static func preferredDisplayName(current: String, candidate: String) -> String {
        let currentKey = groceryKey(for: current)
        let candidateKey = groceryKey(for: candidate)
        guard currentKey == candidateKey else { return current }

        // Prefer plural grocery wording for countable staples ("Eggs"), else shorter/cleaner.
        let currentLower = current.lowercased()
        let candidateLower = candidate.lowercased()

        if preferredPlurals.contains(currentKey) {
            if candidateLower == currentKey + "s" || candidateLower.hasSuffix("es") {
                return candidate.capitalized
            }
            if currentLower == currentKey + "s" {
                return current
            }
        }

        // Prefer the shorter label when one is just a plural/variant.
        if abs(candidate.count - current.count) <= 2 {
            return candidate.count >= current.count ? candidate : current
        }
        return current.count <= candidate.count ? current : candidate
    }

    // MARK: - Private

    private static let preferredPlurals: Set<String> = [
        "egg", "lime", "onion", "tomato", "potato", "carrot", "pepper",
    ]

    private static let aliases: [String: String] = [
        "eggs": "egg",
        "limes": "lime",
        "lemons": "lemon",
        "onions": "onion",
        "tomatoes": "tomato",
        "potatoes": "potato",
        "carrots": "carrot",
        "garlic cloves": "garlic",
        "garlic clove": "garlic",
        "cloves garlic": "garlic",
        "hard boiled egg": "egg",
        "hardboiled egg": "egg",
        "mayo": "mayonnaise",
        "dijon": "dijon mustard",
        "scallion": "green onion",
        "scallions": "green onion",
        "green onions": "green onion",
        "spring onion": "green onion",
        "spring onions": "green onion",
        "cilantro leaves": "cilantro",
        "coriander": "cilantro",
        "bell peppers": "bell pepper",
        "red onions": "red onion",
        "yellow onions": "yellow onion",
        "jalapenos": "jalapeno",
        "chilies": "chili",
        "chiles": "chili",
        "chickpeas": "chickpea",
        "black beans": "black bean",
        "tortillas": "tortilla",
        "buns": "bun",
    ]

    private static let headAliases: [String: String] = [
        "eggs": "egg",
        "limes": "lime",
        "lemons": "lemon",
        "onions": "onion",
        "tomatoes": "tomato",
        "potatoes": "potato",
        "carrots": "carrot",
        "cloves": "clove",
        "peppers": "pepper",
        "chilies": "chili",
        "chiles": "chili",
        "berries": "berry",
        "leaves": "leaf",
    ]

    private static func singularizePhrase(_ phrase: String) -> String {
        phrase
            .split(separator: " ")
            .map { singularize(String($0)) }
            .joined(separator: " ")
    }

    private static func singularize(_ word: String) -> String {
        if let mapped = headAliases[word] { return mapped }
        guard word.count > 3 else { return word }

        // tomatoes, potatoes, heroes
        if word.hasSuffix("oes"), word.count > 4 {
            return String(word.dropLast(2))
        }
        // berries, cherries
        if word.hasSuffix("ies"), word.count > 4 {
            return String(word.dropLast(3)) + "y"
        }
        // leaves
        if word.hasSuffix("ves"), word.count > 4 {
            return String(word.dropLast(3)) + "f"
        }
        // peppers, boxes — avoid turning "cheese" into "chees"
        if word.hasSuffix("sses") { return word }
        if word.hasSuffix("es"),
           let beforeEs = Optional(word.dropLast(2)),
           let last = beforeEs.last,
           "sxz".contains(last) || beforeEs.hasSuffix("ch") || beforeEs.hasSuffix("sh") {
            return String(beforeEs)
        }
        if word.hasSuffix("s"), !word.hasSuffix("ss"), !word.hasSuffix("us"), !word.hasSuffix("is") {
            return String(word.dropLast())
        }
        return word
    }
}
