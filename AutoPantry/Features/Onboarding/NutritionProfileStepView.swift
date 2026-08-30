import SwiftUI

/// Macro ranges step: starts from body-based estimate; user can refine.
struct NutritionProfileStepView: View {
    @Binding var profile: NutritionProfile
    var bodyProfile: UserBodyProfile?
    var showsEstimateActions: Bool = true
    @State private var selectedPreset: MacroPreset?

    var body: some View {
        VStack(alignment: .leading, spacing: APTheme.sectionSpacing) {
            if showsEstimateActions, bodyProfile != nil {
                estimateBanner
            }
            presetSection
            macroEditors
            weeklySummaryCard
        }
    }

    private var estimateBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Estimated from your profile", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(APTheme.accent)

            if let bodyProfile {
                Text(estimateCaption(for: bodyProfile))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                recalculate()
            } label: {
                Label("Recalculate from profile", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(APTheme.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.accentMuted)
        )
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: APTheme.itemSpacing) {
            Text("Quick presets")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: APTheme.itemSpacing) {
                    ForEach(MacroPreset.allCases) { preset in
                        presetChip(preset)
                    }
                }
            }
        }
    }

    private func presetChip(_ preset: MacroPreset) -> some View {
        let isSelected = selectedPreset == preset
        return Button {
            selectedPreset = preset
            let meals = profile.mealsPerWeek
            preset.apply(to: &profile)
            profile.mealsPerWeek = meals
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.title)
                    .font(.subheadline.weight(.semibold))
                Text(preset.subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(width: 140, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                    .fill(isSelected ? APTheme.accent : APTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private var macroEditors: some View {
        VStack(spacing: APTheme.itemSpacing) {
            MacroRangeEditor(
                title: "Calories",
                unit: "cal",
                icon: "flame.fill",
                tint: .orange,
                range: $profile.calories,
                bounds: 1_200...3_500,
                step: 50
            )
            MacroRangeEditor(
                title: "Protein",
                unit: "g",
                icon: "bolt.fill",
                tint: APTheme.accent,
                range: $profile.proteinGrams,
                bounds: 50...250,
                step: 5
            )
            MacroRangeEditor(
                title: "Carbs",
                unit: "g",
                icon: "leaf.fill",
                tint: .green,
                range: $profile.carbsGrams,
                bounds: 20...350,
                step: 5
            )
            MacroRangeEditor(
                title: "Fat",
                unit: "g",
                icon: "drop.fill",
                tint: .yellow,
                range: $profile.fatGrams,
                bounds: 20...200,
                step: 5
            )
        }
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your weekly targets", systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(APTheme.accent)

            Text("Recipes fill this total by servings (a 4-serving recipe counts as 4 meals). Recipes tagged as snacks don’t count toward the meal total.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Macro targets below are weekly totals across those \(profile.mealsPerWeek) meals.")
                .font(.caption)
                .foregroundStyle(.secondary)

            weeklyRow("Calories", min: profile.calories.weeklyMin, max: profile.calories.weeklyMax, unit: "cal")
            weeklyRow("Protein", min: profile.proteinGrams.weeklyMin, max: profile.proteinGrams.weeklyMax, unit: "g")
            weeklyRow("Carbs", min: profile.carbsGrams.weeklyMin, max: profile.carbsGrams.weeklyMax, unit: "g")
            weeklyRow("Fat", min: profile.fatGrams.weeklyMin, max: profile.fatGrams.weeklyMax, unit: "g")

            Divider()

            HStack {
                Text("Avg per meal")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("~\(profile.caloriesPerMeal) cal · ~\(profile.proteinPerMeal)g protein")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.accentMuted)
        )
    }

    private func weeklyRow(_ label: String, min: Int, max: Int, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(min.formatted())–\(max.formatted()) \(unit)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }

    private func estimateCaption(for body: UserBodyProfile) -> String {
        let bmr = MacroCalculator.basalMetabolicRate(for: body)
        let maintenance = MacroCalculator.maintenanceCalories(for: body)
        let target = MacroCalculator.targetCalories(for: body)
        return "BMR ~\(bmr) · maintenance ~\(maintenance) · target ~\(target) cal/day · \(body.weightGoalSummary)"
    }

    private func recalculate() {
        guard let bodyProfile else { return }
        selectedPreset = nil
        profile = MacroCalculator.estimate(
            body: bodyProfile,
            mealsPerWeek: profile.mealsPerWeek
        )
    }
}

#Preview {
    ScrollView {
        NutritionProfileStepView(
            profile: .constant(NutritionProfile()),
            bodyProfile: .default
        )
        .padding()
    }
    .background(APTheme.screenBackground)
}
