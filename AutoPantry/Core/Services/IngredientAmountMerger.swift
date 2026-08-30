import Foundation

/// Parses and merges grocery amounts across recipes, converting compatible units when possible
/// (e.g. `24 oz` + `4 cups` → `56 oz`).
enum IngredientAmountMerger {
    /// Combine raw amount strings into as few display lines as possible.
    static func combine(_ rawAmounts: [String]) -> [String] {
        let cleaned = rawAmounts
            .map { IngredientNormalizer.dropMetricAlternates(from: $0) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return [] }
        if cleaned.count == 1 { return cleaned }

        var volumeML: Double = 0
        var weightG: Double = 0
        var ozAsWritten: Double = 0 // weight oz and fl oz treated interchangeably for merging
        var hasVolume = false
        var hasWeight = false
        var hasExplicitOz = false
        var hasNonOunceWeightUnit = false
        var volumeUnitHint: Unit = .cup
        var weightUnitHint: Unit = .ounce
        var countTotals: [String: Double] = [:] // unit label → count
        var leftovers: [String] = []

        for raw in cleaned {
            guard let parsed = parse(raw) else {
                leftovers.append(raw)
                continue
            }

            switch parsed.unit.family {
            case .volume:
                hasVolume = true
                volumeML += parsed.quantity * parsed.unit.toMilliliters
                if parsed.unit.rank >= volumeUnitHint.rank {
                    volumeUnitHint = parsed.unit
                }
                // Track fluid ounces so cups/tbsp can fold into an oz total.
                ozAsWritten += parsed.quantity * parsed.unit.toFluidOunces
                if parsed.unit == .fluidOunce {
                    hasExplicitOz = true
                }

            case .weight:
                hasWeight = true
                weightG += parsed.quantity * parsed.unit.toGrams
                if parsed.unit.rank >= weightUnitHint.rank {
                    weightUnitHint = parsed.unit
                }
                if parsed.unit == .ounce {
                    ozAsWritten += parsed.quantity
                    hasExplicitOz = true
                } else {
                    hasNonOunceWeightUnit = true
                }

            case .count:
                let label = parsed.unit.displayPlural
                countTotals[label, default: 0] += parsed.quantity
            }
        }

        var merged: [String] = []

        // Prefer a single oz total when recipes mix cups/tbsp with oz (e.g. 24 oz + 4 cups).
        let canMergeVolumeIntoOz = hasVolume && hasExplicitOz && !hasNonOunceWeightUnit
        if canMergeVolumeIntoOz, ozAsWritten > 0 {
            merged.append(format(quantity: ozAsWritten, unit: .ounce))
        } else {
            if hasVolume, volumeML > 0 {
                let unit = preferredVolumeUnit(totalML: volumeML, hint: volumeUnitHint)
                merged.append(format(quantity: volumeML / unit.toMilliliters, unit: unit))
            }
            if hasWeight, weightG > 0 {
                let unit = preferredWeightUnit(totalG: weightG, hint: weightUnitHint)
                merged.append(format(quantity: weightG / unit.toGrams, unit: unit))
            }
        }

        for (label, total) in countTotals.sorted(by: { $0.key < $1.key }) where total > 0 {
            merged.append(formatCount(total, label: label))
        }

        // De-dupe leftover strings while preserving order.
        var seen = Set<String>()
        for leftover in leftovers where seen.insert(leftover.lowercased()).inserted {
            merged.append(leftover)
        }

        return merged.isEmpty ? cleaned : merged
    }

    // MARK: - Parsing

    private struct ParsedAmount {
        var quantity: Double
        var unit: Unit
    }

    private enum UnitFamily {
        case volume
        case weight
        case count
    }

    private enum Unit: Equatable {
        case teaspoon, tablespoon, fluidOunce, cup, pint, quart, milliliter, liter
        case ounce, pound, gram, kilogram
        case piece, clove, can, bunch, package

        var family: UnitFamily {
            switch self {
            case .teaspoon, .tablespoon, .fluidOunce, .cup, .pint, .quart, .milliliter, .liter:
                return .volume
            case .ounce, .pound, .gram, .kilogram:
                return .weight
            case .piece, .clove, .can, .bunch, .package:
                return .count
            }
        }

        /// Preference rank when choosing a display unit (higher = coarser).
        var rank: Int {
            switch self {
            case .teaspoon: return 1
            case .tablespoon: return 2
            case .fluidOunce, .ounce: return 3
            case .cup: return 4
            case .pint: return 5
            case .quart: return 6
            case .milliliter: return 2
            case .liter: return 6
            case .gram: return 2
            case .kilogram: return 5
            case .pound: return 4
            case .piece, .clove, .can, .bunch, .package: return 1
            }
        }

        var toMilliliters: Double {
            switch self {
            case .teaspoon: return 4.92892
            case .tablespoon: return 14.7868
            case .fluidOunce: return 29.5735
            case .cup: return 236.588
            case .pint: return 473.176
            case .quart: return 946.353
            case .milliliter: return 1
            case .liter: return 1_000
            default: return 0
            }
        }

        var toFluidOunces: Double {
            guard toMilliliters > 0 else { return 0 }
            return toMilliliters / 29.5735
        }

        var toGrams: Double {
            switch self {
            case .ounce: return 28.3495
            case .pound: return 453.592
            case .gram: return 1
            case .kilogram: return 1_000
            default: return 0
            }
        }

        var displaySingular: String {
            switch self {
            case .teaspoon: return "tsp"
            case .tablespoon: return "tbsp"
            case .fluidOunce, .ounce: return "oz"
            case .cup: return "cup"
            case .pint: return "pint"
            case .quart: return "quart"
            case .milliliter: return "ml"
            case .liter: return "L"
            case .pound: return "lb"
            case .gram: return "g"
            case .kilogram: return "kg"
            case .piece: return "piece"
            case .clove: return "clove"
            case .can: return "can"
            case .bunch: return "bunch"
            case .package: return "package"
            }
        }

        var displayPlural: String {
            switch self {
            case .teaspoon: return "tsp"
            case .tablespoon: return "tbsp"
            case .fluidOunce, .ounce: return "oz"
            case .cup: return "cups"
            case .pint: return "pints"
            case .quart: return "quarts"
            case .milliliter: return "ml"
            case .liter: return "L"
            case .pound: return "lb"
            case .gram: return "g"
            case .kilogram: return "kg"
            case .piece: return "pieces"
            case .clove: return "cloves"
            case .can: return "cans"
            case .bunch: return "bunches"
            case .package: return "packages"
            }
        }

        static func match(from raw: String) -> Unit? {
            let normalized = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

            // Prefer the longest known unit at the start ("fl oz", then "oz", etc.).
            let aliases: [(String, Unit)] = [
                ("fluid ounces", .fluidOunce),
                ("fluid ounce", .fluidOunce),
                ("fl oz", .fluidOunce),
                ("teaspoons", .teaspoon),
                ("teaspoon", .teaspoon),
                ("tablespoons", .tablespoon),
                ("tablespoon", .tablespoon),
                ("milliliters", .milliliter),
                ("millilitres", .milliliter),
                ("milliliter", .milliliter),
                ("millilitre", .milliliter),
                ("kilograms", .kilogram),
                ("kilogram", .kilogram),
                ("packages", .package),
                ("package", .package),
                ("ounces", .ounce),
                ("ounce", .ounce),
                ("pounds", .pound),
                ("pound", .pound),
                ("quarts", .quart),
                ("quart", .quart),
                ("pints", .pint),
                ("pint", .pint),
                ("cups", .cup),
                ("cup", .cup),
                ("cloves", .clove),
                ("clove", .clove),
                ("pieces", .piece),
                ("piece", .piece),
                ("bunches", .bunch),
                ("bunch", .bunch),
                ("cans", .can),
                ("can", .can),
                ("grams", .gram),
                ("gram", .gram),
                ("liters", .liter),
                ("litres", .liter),
                ("liter", .liter),
                ("litre", .liter),
                ("tbsp", .tablespoon),
                ("tbsps", .tablespoon),
                ("tbs", .tablespoon),
                ("tsp", .teaspoon),
                ("tsps", .teaspoon),
                ("floz", .fluidOunce),
                ("pkgs", .package),
                ("pkg", .package),
                ("pcs", .piece),
                ("pc", .piece),
                ("oz", .ounce),
                ("lbs", .pound),
                ("lb", .pound),
                ("kg", .kilogram),
                ("ml", .milliliter),
                ("qt", .quart),
                ("pt", .pint),
                ("g", .gram),
                ("l", .liter),
                ("c", .cup),
            ]

            for (alias, unit) in aliases {
                if normalized == alias { return unit }
                if normalized.hasPrefix(alias + " ") { return unit }
            }
            return nil
        }
    }

    private static func parse(_ raw: String) -> ParsedAmount? {
        var text = raw
            .lowercased()
            .replacingOccurrences(of: "½", with: "1/2")
            .replacingOccurrences(of: "⅓", with: "1/3")
            .replacingOccurrences(of: "⅔", with: "2/3")
            .replacingOccurrences(of: "¼", with: "1/4")
            .replacingOccurrences(of: "¾", with: "3/4")
            .replacingOccurrences(of: "⅛", with: "1/8")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // "fl. oz" / "fl oz" → single token for matching
        text = text
            .replacingOccurrences(of: "fl. oz", with: "fl oz")
            .replacingOccurrences(of: "fluid ounces", with: "fl oz")
            .replacingOccurrences(of: "fluid ounce", with: "fl oz")

        // quantity then unit — supports "1 1/2 cups", "1/2 cup", "2.5 oz", "16oz"
        let pattern = #"^(\d+\s+\d+/\d+|\d+/\d+|\d+\.\d+|\d+)\s*([a-zA-Z][a-zA-Z.\s]*?)$"#
        guard let match = text.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        let matched = String(text[match])
        guard let unitRange = matched.range(of: #"([a-zA-Z][a-zA-Z.\s]*)$"#, options: .regularExpression) else {
            return nil
        }
        let unitText = matched[unitRange]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
        let qtyText = matched[..<unitRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let quantity = parseNumber(String(qtyText)),
              let unit = Unit.match(from: unitText)
        else {
            return nil
        }
        return ParsedAmount(quantity: quantity, unit: unit)
    }

    private static func parseNumber(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(" ") {
            let parts = trimmed.split(separator: " ")
            guard parts.count == 2,
                  let whole = Double(parts[0]),
                  let frac = parseFraction(String(parts[1]))
            else { return nil }
            return whole + frac
        }
        if trimmed.contains("/") {
            return parseFraction(trimmed)
        }
        return Double(trimmed)
    }

    private static func parseFraction(_ text: String) -> Double? {
        let parts = text.split(separator: "/")
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0
        else { return nil }
        return numerator / denominator
    }

    // MARK: - Formatting

    private static func preferredVolumeUnit(totalML: Double, hint: Unit) -> Unit {
        let cups = totalML / Unit.cup.toMilliliters
        if cups >= 0.25 && cups < 16 { return .cup }
        if totalML >= 1_000 { return .liter }
        if hint == .tablespoon || hint == .teaspoon {
            let tbsp = totalML / Unit.tablespoon.toMilliliters
            if tbsp < 4 { return hint == .teaspoon && tbsp < 1 ? .teaspoon : .tablespoon }
        }
        let floz = totalML / Unit.fluidOunce.toMilliliters
        if floz >= 1 { return .fluidOunce }
        return hint.family == .volume ? hint : .cup
    }

    private static func preferredWeightUnit(totalG: Double, hint: Unit) -> Unit {
        let pounds = totalG / Unit.pound.toGrams
        if pounds >= 1 { return .pound }
        let ounces = totalG / Unit.ounce.toGrams
        if ounces >= 1 || hint == .ounce { return .ounce }
        if totalG >= 1000 { return .kilogram }
        return .gram
    }

    private static func format(quantity: Double, unit: Unit) -> String {
        let rounded = roundDisplay(quantity)
        let label: String
        if abs(rounded - 1) < 0.05 {
            label = unit.displaySingular
        } else {
            label = unit.displayPlural
        }
        return "\(formatNumber(rounded)) \(label)"
    }

    private static func formatCount(_ quantity: Double, label: String) -> String {
        let rounded = roundDisplay(quantity)
        // Singularize common plurals when exactly 1.
        var unit = label
        if abs(rounded - 1) < 0.05 {
            if label.hasSuffix("es") {
                unit = String(label.dropLast(2))
            } else if label.hasSuffix("s") {
                unit = String(label.dropLast())
            }
        }
        return "\(formatNumber(rounded)) \(unit)"
    }

    private static func roundDisplay(_ value: Double) -> Double {
        // Prefer friendly culinary fractions-ish decimals.
        let candidates: [Double] = [
            value.rounded(),
            (value * 2).rounded() / 2,
            (value * 4).rounded() / 4,
        ]
        for candidate in candidates {
            if abs(candidate - value) <= 0.08 {
                return candidate
            }
        }
        return (value * 10).rounded() / 10
    }

    private static func formatNumber(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.05 {
            return String(Int(value.rounded()))
        }
        if abs(value * 2 - (value * 2).rounded()) < 0.05 {
            let halves = (value * 2).rounded() / 2
            if abs(halves - halves.rounded()) < 0.05 {
                return String(Int(halves.rounded()))
            }
            return String(format: "%.1f", halves)
        }
        let tenths = (value * 10).rounded() / 10
        return String(format: "%.1f", tenths)
    }
}
