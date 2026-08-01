import SwiftUI

struct WeeklyPlanProgressView: View {
    let progress: WeeklyPlanProgress
    var style: Style = .detailed

    enum Style {
        case detailed
        case compact
    }

    var body: some View {
        switch style {
        case .detailed:
            detailedBody
        case .compact:
            compactBody
        }
    }

    private var detailedBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week's plan")
                .font(.subheadline.weight(.semibold))

            progressRow(
                label: "Meals",
                value: "\(progress.mealsFilled)/\(progress.mealsTarget)",
                fraction: progress.mealsProgress,
                isComplete: progress.mealsComplete
            )

            progressRow(
                label: "Calories (est.)",
                value: "\(progress.caloriesFilled.formatted()) / \(progress.caloriesMax.formatted())",
                fraction: progress.caloriesProgress,
                isComplete: progress.caloriesComplete
            )

            progressRow(
                label: "Protein (est.)",
                value: "\(progress.proteinFilled)g / \(progress.proteinMax.formatted())g",
                fraction: min(Double(progress.proteinFilled) / Double(max(progress.proteinMax, 1)), 1),
                isComplete: progress.proteinComplete
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private var compactBody: some View {
        HStack(spacing: 10) {
            Image(systemName: progress.isComplete ? "checkmark.circle.fill" : "chart.bar.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(APTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(progress.mealsFilled)/\(progress.mealsTarget) meals")
                        .font(.caption.weight(.semibold))
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(progress.caloriesFilled.formatted()) cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(progress.proteinFilled)g P")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08))
                        Capsule()
                            .fill(APTheme.accent.opacity(progress.isComplete ? 1 : 0.65))
                            .frame(width: geo.size.width * overallFraction)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(APTheme.cardBackground.opacity(0.92))
        )
    }

    private var overallFraction: Double {
        let meals = progress.mealsProgress
        let calories = progress.caloriesProgress
        let protein = min(Double(progress.proteinFilled) / Double(max(progress.proteinMax, 1)), 1)
        return min((meals + calories + protein) / 3, 1)
    }

    private func progressRow(label: String, value: String, fraction: Double, isComplete: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(value)
                    .font(.caption)
                    .foregroundStyle(isComplete ? APTheme.accent : .secondary)
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(APTheme.accent)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(isComplete ? APTheme.accent : APTheme.accent.opacity(0.55))
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
    }
}
