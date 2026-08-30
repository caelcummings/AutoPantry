import SwiftUI

struct PlanCompleteCelebrationView: View {
    @EnvironmentObject private var appState: AppState
    let onDismiss: () -> Void
    var onRedoWeek: (() -> Void)? = nil

    @State private var appear = false
    @State private var bannerMessage: String?
    @State private var flashClearAction = DeferredUIAction()

    private var profile: NutritionProfile { appState.nutritionProfile }
    private var totals: WeeklyMacroTotals { appState.weeklyMealPlan.totals }
    private var mealCount: Int { totals.mealCount }
    private var gaps: MacroGaps { profile.macroGaps(for: totals) }
    private var snackSuggestions: [RecipeSummary] {
        SnackSuggestionEngine.suggestions(
            profile: profile,
            plan: appState.weeklyMealPlan,
            userRecipes: appState.userRecipeList
        )
    }

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
                        if gaps.hasAnyGap {
                            dailySupplementCard
                            snackTopUpSection
                        }
                    }
                    .padding(.horizontal, APTheme.horizontalPadding)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                    .scaleEffect(appear ? 1 : 0.96)
                    .opacity(appear ? 1 : 0.01)
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "View my week", action: onDismiss)

                    if let onRedoWeek {
                        Button(action: onRedoWeek) {
                            Text("Redo my week")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(.red)
                                .background(
                                    RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                                        .strokeBorder(Color.red.opacity(0.35), lineWidth: 1.5)
                                        .background(
                                            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                                                .fill(APTheme.cardBackground)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
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
        .onDisappear { flashClearAction.cancel() }
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
                Text(headerSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("\(mealCount) meal servings saved")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(APTheme.accent)
            }
        }
    }

    private var headerSubtitle: String {
        if gaps.hasAnyGap {
            if let phrase = gaps.dailySupplementPhrase {
                return "You hit your meal total. To close the remaining gap, aim for \(phrase) — or add snacks below."
            }
            return "You hit your meal total. Add snacks below to close any macro gaps."
        }
        return "You hit your meal total for the week. Here’s how the macros added up."
    }

    private var dailySupplementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Daily supplement guide", systemImage: "calendar")
                .font(.headline)
                .foregroundStyle(APTheme.accent)

            if let phrase = gaps.dailySupplementPhrase {
                Text("You’re short \(gaps.summaryLines.joined(separator: " · ")) for the week. Spread that across the week and aim for \(phrase).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                if gaps.dailyCalories > 0 {
                    dailySupplementRow(label: "Calories", amount: "+\(gaps.dailyCalories.formatted()) cal / day")
                }
                if gaps.dailyProtein > 0 {
                    dailySupplementRow(label: "Protein", amount: "+\(gaps.dailyProtein.formatted())g / day")
                }
                if gaps.dailyCarbs > 0 {
                    dailySupplementRow(label: "Carbs", amount: "+\(gaps.dailyCarbs.formatted())g / day")
                }
                if gaps.dailyFat > 0 {
                    dailySupplementRow(label: "Fat", amount: "+\(gaps.dailyFat.formatted())g / day")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private func dailySupplementRow(label: String, amount: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(amount)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(APTheme.accent)
        }
    }

    private var snackTopUpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Top up with snacks", systemImage: "carrot.fill")
                .font(.headline)
                .foregroundStyle(APTheme.accent)

            Text("Still short: \(gaps.summaryLines.joined(separator: " · "))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let bannerMessage {
                Text(bannerMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(APTheme.accent)
            }

            if snackSuggestions.isEmpty {
                Text("No snack suggestions left — browse the Recipes tab to add more.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(snackSuggestions) { snack in
                        snackRow(snack)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.accentMuted.opacity(0.45))
        )
    }

    private func snackRow(_ snack: RecipeSummary) -> some View {
        HStack(spacing: 12) {
            snackThumbnail(snack)

            VStack(alignment: .leading, spacing: 4) {
                Text(snack.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("\(snack.effectiveMacros.calories) cal · \(snack.effectiveMacros.proteinGrams)g protein")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                addSnack(snack)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(APTheme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(snack.title) to this week")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private func addSnack(_ snack: RecipeSummary) {
        if appState.addRecipeToWeeklyPlan(snack) {
            flash("Added \(snack.title)")
        } else {
            flash("Already in your week")
        }
    }

    private func flash(_ message: String) {
        withAnimation { bannerMessage = message }
        flashClearAction.schedule(after: .seconds(1.5)) {
            withAnimation {
                if bannerMessage == message { bannerMessage = nil }
            }
        }
    }

    @ViewBuilder
    private func snackThumbnail(_ snack: RecipeSummary) -> some View {
        AsyncImage(url: snack.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                LinearGradient(
                    colors: [APTheme.accent.opacity(0.7), Color.orange.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    PlanCompleteCelebrationView(onDismiss: {}, onRedoWeek: {})
        .environmentObject(
            AppState(
                route: .main,
                userProfile: OnboardingDraft(),
                weeklyMealPlan: WeeklyMealPlan(recipes: RecipeCatalog.feed.prefix(8).map { $0 })
            )
        )
}
