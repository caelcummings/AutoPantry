import SwiftUI

struct PlanCompleteCelebrationView: View {
    let mealCount: Int
    let totals: WeeklyMacroTotals
    let profile: NutritionProfile
    let onDismiss: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            APTheme.screenBackground.ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        header
                        macroSummaryCard
                        targetComparisonCard
                    }
                    .padding(.horizontal, APTheme.horizontalPadding)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                    .scaleEffect(appear ? 1 : 0.96)
                    .opacity(appear ? 1 : 0.01)
                }

                PrimaryButton(title: "View my week", action: onDismiss)
                    .padding(.horizontal, APTheme.horizontalPadding)
                    .padding(.bottom, 28)
                    .padding(.top, 8)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                appear = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(APTheme.accentMuted)
                    .frame(width: 108, height: 108)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(APTheme.accent)
                    .symbolEffect(.bounce, value: appear)
            }

            VStack(spacing: 8) {
                Text("Week planned!")
                    .font(.largeTitle.bold())
                Text("You hit your meal total for the week. Here’s how the macros added up.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("\(mealCount) meal servings saved")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(APTheme.accent)
            }
        }
    }

    private var macroSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly totals")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                macroStat(title: "Calories", value: totals.calories.formatted(), unit: "cal")
                macroStat(title: "Protein", value: "\(totals.protein)", unit: "g")
                macroStat(title: "Carbs", value: "\(totals.carbs)", unit: "g")
                macroStat(title: "Fat", value: "\(totals.fat)", unit: "g")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private var targetComparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Vs your targets")
                .font(.headline)

            comparisonRow(
                label: "Calories",
                filled: totals.calories,
                targetMin: profile.calories.weeklyMin,
                targetMax: profile.calories.weeklyMax,
                unit: "cal"
            )
            comparisonRow(
                label: "Protein",
                filled: totals.protein,
                targetMin: profile.proteinGrams.weeklyMin,
                targetMax: profile.proteinGrams.weeklyMax,
                unit: "g"
            )
            comparisonRow(
                label: "Carbs",
                filled: totals.carbs,
                targetMin: profile.carbsGrams.weeklyMin,
                targetMax: profile.carbsGrams.weeklyMax,
                unit: "g"
            )
            comparisonRow(
                label: "Fat",
                filled: totals.fat,
                targetMin: profile.fatGrams.weeklyMin,
                targetMax: profile.fatGrams.weeklyMax,
                unit: "g"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private func macroStat(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(APTheme.accentMuted.opacity(0.55))
        )
    }

    private func comparisonRow(label: String, filled: Int, targetMin: Int, targetMax: Int, unit: String) -> some View {
        let inRange = filled >= targetMin && filled <= targetMax
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(filled.formatted()) \(unit)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(inRange ? APTheme.accent : .primary)
                if inRange {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(APTheme.accent)
                }
            }
            Text("Target \(targetMin.formatted())–\(targetMax.formatted()) \(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let fraction = targetMax == 0 ? 0 : Swift.min(Double(filled) / Double(targetMax), 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(inRange ? APTheme.accent : APTheme.accent.opacity(0.45))
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    PlanCompleteCelebrationView(
        mealCount: 14,
        totals: WeeklyMacroTotals(calories: 14_200, protein: 980, carbs: 1_250, fat: 420, mealCount: 14),
        profile: NutritionProfile(),
        onDismiss: {}
    )
}
