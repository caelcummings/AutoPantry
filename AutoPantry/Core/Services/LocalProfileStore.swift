import Foundation

/// Persists the onboarding profile, weekly meal plan, seasoning inventory, and favorites.
enum LocalProfileStore {
    private static let profileKey = "autopantry.userProfile"
    private static let onboardingCompletedKey = "autopantry.onboardingCompleted"
    private static let onboardingProgressKey = "autopantry.onboardingProgress"
    private static let mealPlanKey = "autopantry.weeklyMealPlan"
    private static let seasoningInventoryKey = "autopantry.seasoningInventory"
    private static let favoritesKey = "autopantry.favoriteRecipes"
    private static let userRecipesKey = "autopantry.userRecipes"
    private static let extraGroceryItemsKey = "autopantry.extraGroceryItems"

    private static let profileFileName = "userProfile.json"
    private static let onboardingCompletedFileName = "onboardingCompleted.json"
    private static let onboardingProgressFileName = "onboardingProgress.json"

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    struct OnboardingProgress: Codable {
        static let currentFlowVersion = 2

        var draft: OnboardingDraft
        var stepRawValue: Int
        var flowVersion: Int = currentFlowVersion

        /// Maps saved step indices from older onboarding flows.
        var resolvedStepRawValue: Int {
            guard flowVersion < Self.currentFlowVersion else { return stepRawValue }
            // Before pantry step existed: 0=body, 1=activity, 2=macros
            return min(stepRawValue + 1, 3)
        }
    }

    private struct OnboardingCompletedFile: Codable {
        var completed: Bool
    }

    // MARK: - Onboarding completion

    static func hasCompletedOnboarding(from defaults: UserDefaults = .standard) -> Bool {
        if let fileValue = loadOnboardingCompletedFromFile() {
            return fileValue
        }
        return defaults.bool(forKey: onboardingCompletedKey)
    }

    static func markOnboardingCompleted(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: onboardingCompletedKey)
        saveOnboardingCompletedToFile(true)
    }

    // MARK: - Profile

    static func loadProfile(from defaults: UserDefaults = .standard) -> OnboardingDraft? {
        if let profile = loadProfileFromFile() {
            return profile
        }
        guard let data = defaults.data(forKey: profileKey) else { return nil }
        guard let profile = try? decoder.decode(OnboardingDraft.self, from: data) else { return nil }
        // Migrate older UserDefaults-only saves into Application Support.
        saveProfile(profile, to: defaults)
        return profile
    }

    static func saveProfile(_ profile: OnboardingDraft?, to defaults: UserDefaults = .standard) {
        guard let profile else {
            defaults.removeObject(forKey: profileKey)
            removeFile(named: profileFileName)
            return
        }
        guard let data = try? encoder.encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
        writeFile(data, named: profileFileName)
    }

    // MARK: - In-progress onboarding

    static func loadOnboardingProgress(from defaults: UserDefaults = .standard) -> OnboardingProgress? {
        if let progress = loadOnboardingProgressFromFile() {
            return progress
        }
        guard let data = defaults.data(forKey: onboardingProgressKey) else { return nil }
        guard let progress = try? decoder.decode(OnboardingProgress.self, from: data) else { return nil }
        saveOnboardingProgress(progress, to: defaults)
        return progress
    }

    static func saveOnboardingProgress(_ progress: OnboardingProgress?, to defaults: UserDefaults = .standard) {
        guard let progress else {
            defaults.removeObject(forKey: onboardingProgressKey)
            removeFile(named: onboardingProgressFileName)
            return
        }
        guard let data = try? encoder.encode(progress) else { return }
        defaults.set(data, forKey: onboardingProgressKey)
        writeFile(data, named: onboardingProgressFileName)
    }

    // MARK: - Other persisted state

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

    static func loadFavorites(from defaults: UserDefaults = .standard) -> FavoriteRecipes {
        guard let data = defaults.data(forKey: favoritesKey),
              let favorites = try? decoder.decode(FavoriteRecipes.self, from: data)
        else {
            return FavoriteRecipes()
        }
        return favorites
    }

    static func saveFavorites(_ favorites: FavoriteRecipes, to defaults: UserDefaults = .standard) {
        guard let data = try? encoder.encode(favorites) else { return }
        defaults.set(data, forKey: favoritesKey)
    }

    static func loadUserRecipes(from defaults: UserDefaults = .standard) -> UserRecipes {
        guard let data = defaults.data(forKey: userRecipesKey),
              let recipes = try? decoder.decode(UserRecipes.self, from: data)
        else {
            return UserRecipes()
        }
        return recipes
    }

    static func saveUserRecipes(_ recipes: UserRecipes, to defaults: UserDefaults = .standard) {
        guard let data = try? encoder.encode(recipes) else { return }
        defaults.set(data, forKey: userRecipesKey)
    }

    static func loadExtraGroceryItems(from defaults: UserDefaults = .standard) -> ExtraGroceryItems {
        guard let data = defaults.data(forKey: extraGroceryItemsKey),
              let items = try? decoder.decode(ExtraGroceryItems.self, from: data)
        else {
            return ExtraGroceryItems()
        }
        return items
    }

    static func saveExtraGroceryItems(_ items: ExtraGroceryItems, to defaults: UserDefaults = .standard) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: extraGroceryItemsKey)
    }

    static func clearProfileAndOnboarding(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: onboardingCompletedKey)
        defaults.removeObject(forKey: onboardingProgressKey)
        removeFile(named: profileFileName)
        removeFile(named: onboardingCompletedFileName)
        removeFile(named: onboardingProgressFileName)
    }

    static func clear(defaults: UserDefaults = .standard) {
        clearProfileAndOnboarding(from: defaults)
        defaults.removeObject(forKey: mealPlanKey)
        defaults.removeObject(forKey: seasoningInventoryKey)
        defaults.removeObject(forKey: favoritesKey)
        defaults.removeObject(forKey: userRecipesKey)
        defaults.removeObject(forKey: extraGroceryItemsKey)
    }

    // MARK: - File helpers

    private static var storageDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AutoPantry", isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }

    private static func fileURL(named name: String) -> URL {
        storageDirectory.appendingPathComponent(name)
    }

    private static func writeFile(_ data: Data, named name: String) {
        let url = fileURL(named: name)
        try? data.write(to: url, options: .atomic)
    }

    private static func readFile(named name: String) -> Data? {
        let url = fileURL(named: name)
        return try? Data(contentsOf: url)
    }

    private static func removeFile(named name: String) {
        let url = fileURL(named: name)
        try? FileManager.default.removeItem(at: url)
    }

    private static func loadProfileFromFile() -> OnboardingDraft? {
        guard let data = readFile(named: profileFileName) else { return nil }
        return try? decoder.decode(OnboardingDraft.self, from: data)
    }

    private static func loadOnboardingCompletedFromFile() -> Bool? {
        guard let data = readFile(named: onboardingCompletedFileName),
              let payload = try? decoder.decode(OnboardingCompletedFile.self, from: data)
        else {
            return nil
        }
        return payload.completed
    }

    private static func saveOnboardingCompletedToFile(_ completed: Bool) {
        guard let data = try? encoder.encode(OnboardingCompletedFile(completed: completed)) else { return }
        writeFile(data, named: onboardingCompletedFileName)
    }

    private static func loadOnboardingProgressFromFile() -> OnboardingProgress? {
        guard let data = readFile(named: onboardingProgressFileName) else { return nil }
        return try? decoder.decode(OnboardingProgress.self, from: data)
    }
}
