import Foundation

/// Persists the onboarding profile, weekly meal plan, and seasoning inventory.
enum LocalProfileStore {
    private static let profileKey = "autopantry.userProfile"
    private static let mealPlanKey = "autopantry.weeklyMealPlan"
    private static let seasoningInventoryKey = "autopantry.seasoningInventory"

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func loadProfile(from defaults: UserDefaults = .standard) -> OnboardingDraft? {
        guard let data = defaults.data(forKey: profileKey) else { return nil }
        return try? decoder.decode(OnboardingDraft.self, from: data)
    }

    static func saveProfile(_ profile: OnboardingDraft?, to defaults: UserDefaults = .standard) {
        guard let profile else {
            defaults.removeObject(forKey: profileKey)
            return
        }
        guard let data = try? encoder.encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }

    static func loadMealPlan(from defaults: UserDefaults = .standard) -> WeeklyMealPlan {
        guard let data = defaults.data(forKey: mealPlanKey),
              let plan = try? decoder.decode(WeeklyMealPlan.self, from: data)
        else {
            return WeeklyMealPlan()
        }
        return plan
    }

    static func saveMealPlan(_ plan: WeeklyMealPlan, to defaults: UserDefaults = .standard) {
        guard let data = try? encoder.encode(plan) else { return }
        defaults.set(data, forKey: mealPlanKey)
    }

    static func loadSeasoningInventory(from defaults: UserDefaults = .standard) -> SeasoningInventory {
        guard let data = defaults.data(forKey: seasoningInventoryKey),
              let inventory = try? decoder.decode(SeasoningInventory.self, from: data)
        else {
            return SeasoningInventory()
        }
        return inventory
    }

    static func saveSeasoningInventory(_ inventory: SeasoningInventory, to defaults: UserDefaults = .standard) {
        guard let data = try? encoder.encode(inventory) else { return }
        defaults.set(data, forKey: seasoningInventoryKey)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: mealPlanKey)
        defaults.removeObject(forKey: seasoningInventoryKey)
    }
}
