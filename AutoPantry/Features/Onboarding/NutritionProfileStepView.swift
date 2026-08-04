import SwiftUI

/// Profile-building step: daily macro ranges + weekly meal-plan context.
struct NutritionProfileStepView: View {
    @Binding var profile: NutritionProfile
    @State private var selectedPreset: MacroPreset?

    var body: some View {
        VStack(alignment: .leading, spacing: APTheme.sectionSpacing) {
            presetSection
            macroEditors
            mealsPerWeekSection
            weeklySummaryCard
        }
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
            preset.apply(to: &profile)
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

    private var mealsPerWeekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals to plan per week")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                Text("\(profile.mealsPerWeek)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("meals")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Stepper("Breakfasts, lunches, dinners — recipes count by servings", value: $profile.mealsPerWeek, in: 7...35)
                .font(.subheadline)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your weekly targets", systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(APTheme.accent)

            Text("Recipes fill this total by servings (a 4-serving recipe counts as 4 meals). Snacks under 300 cal/serving don’t count toward the meal total.")
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
}

#Preview {
    ScrollView {
        NutritionProfileStepView(profile: .constant(NutritionProfile()))
            .padding()
    }
    .background(APTheme.screenBackground)
}
