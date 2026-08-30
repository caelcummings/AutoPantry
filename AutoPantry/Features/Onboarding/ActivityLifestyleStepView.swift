import SwiftUI

/// Activity level + meals-per-week used for TDEE and planning volume.
struct ActivityLifestyleStepView: View {
    @Binding var bodyProfile: UserBodyProfile
    @Binding var mealsPerWeek: Int

    var body: some View {
        VStack(alignment: .leading, spacing: APTheme.sectionSpacing) {
            activitySection
            mealsSection
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: APTheme.itemSpacing) {
            Text("Exercise habits")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(ActivityLevel.allCases) { level in
                Button {
                    bodyProfile.activityLevel = level
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(level.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(level.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: bodyProfile.activityLevel == level ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(bodyProfile.activityLevel == level ? APTheme.accent : .secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                            .fill(bodyProfile.activityLevel == level ? APTheme.accentMuted : APTheme.cardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals to plan per week")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                Text("\(mealsPerWeek)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("meals")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Stepper(
                "Breakfasts, lunches, dinners — recipes count by servings",
                value: $mealsPerWeek,
                in: 7...35
            )
            .font(.subheadline)

            Text("Snacks you tag in your recipe list don’t count toward this total.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }
}

#Preview {
    ScrollView {
        ActivityLifestyleStepView(
            bodyProfile: .constant(.default),
            mealsPerWeek: .constant(21)
        )
        .padding()
    }
    .background(APTheme.screenBackground)
}
