import Foundation

/// Biological sex used for BMR estimation (Mifflin–St Jeor).
enum BiologicalSex: String, CaseIterable, Identifiable, Codable {
    case female
    case male
    case preferNotToSay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .female: "Female"
        case .male: "Male"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

/// Self-reported activity used to scale BMR → TDEE.
enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case extraActive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sedentary: "Sedentary"
        case .lightlyActive: "Lightly active"
        case .moderatelyActive: "Moderately active"
        case .veryActive: "Very active"
        case .extraActive: "Extra active"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: "Desk job, little or no exercise"
        case .lightlyActive: "Light exercise 1–3 days / week"
        case .moderatelyActive: "Exercise 3–5 days / week"
        case .veryActive: "Hard exercise 6–7 days / week"
        case .extraActive: "Physical job or 2× daily training"
        }
    }

    /// Standard Harris–Benedict / Mifflin activity multipliers.
    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .lightlyActive: 1.375
        case .moderatelyActive: 1.55
        case .veryActive: 1.725
        case .extraActive: 1.9
        }
    }
}

enum WeightGoalDirection: Equatable {
    case lose
    case maintain
    case gain
}

/// Body metrics used to estimate daily macro needs.
struct UserBodyProfile: Equatable, Codable {
    var sex: BiologicalSex = .female
    var ageYears: Int = 28
    /// Total height in inches (e.g. 66 = 5′6″).
    var heightInches: Int = 66
    var weightPounds: Int = 160
    var desiredWeightPounds: Int = 155
    var activityLevel: ActivityLevel = .moderatelyActive

    static let `default` = UserBodyProfile()

    var isValid: Bool {
        (13...100).contains(ageYears)
            && (48...90).contains(heightInches) // 4′0″…7′6″
            && (80...450).contains(weightPounds)
            && (80...450).contains(desiredWeightPounds)
    }

    var heightFeet: Int { heightInches / 12 }
    var heightRemainingInches: Int { heightInches % 12 }

    var formattedHeight: String {
        "\(heightFeet)′\(heightRemainingInches)″"
    }

    var weightKg: Double { Double(weightPounds) * 0.45359237 }
    var heightCm: Double { Double(heightInches) * 2.54 }

    var weightGoalDirection: WeightGoalDirection {
        let delta = desiredWeightPounds - weightPounds
        if delta <= -3 { return .lose }
        if delta >= 3 { return .gain }
        return .maintain
    }

    var weightGoalSummary: String {
        switch weightGoalDirection {
        case .lose:
            return "Lose \(weightPounds - desiredWeightPounds) lb"
        case .gain:
            return "Gain \(desiredWeightPounds - weightPounds) lb"
        case .maintain:
            return "Maintain weight"
        }
    }

    mutating func setHeight(feet: Int, inches: Int) {
        heightInches = max(48, min(90, feet * 12 + inches))
    }
}
