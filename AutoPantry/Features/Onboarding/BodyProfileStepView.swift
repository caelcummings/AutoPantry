import SwiftUI

/// Collects age, height, weight, goal weight, and sex for macro estimation.
struct BodyProfileStepView: View {
    @Binding var bodyProfile: UserBodyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: APTheme.sectionSpacing) {
            sexSection
            ageSection
            heightSection
            weightSection
            goalWeightSection
        }
    }

    private var sexSection: some View {
        VStack(alignment: .leading, spacing: APTheme.itemSpacing) {
            sectionLabel("Sex")
            VStack(spacing: APTheme.itemSpacing) {
                ForEach(BiologicalSex.allCases) { sex in
                    selectionRow(
                        title: sex.title,
                        isSelected: bodyProfile.sex == sex
                    ) {
                        bodyProfile.sex = sex
                    }
                }
            }
        }
    }

    private var ageSection: some View {
        card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    sectionLabel("Age")
                    Text("\(bodyProfile.ageYears) years")
                        .font(.title2.bold())
                }
                Spacer()
                Stepper(
                    "",
                    value: $bodyProfile.ageYears,
                    in: 13...100
                )
                .labelsHidden()
            }
        }
    }

    private var heightSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Height")
                Text(bodyProfile.formattedHeight)
                    .font(.title2.bold())

                HStack(spacing: 20) {
                    Stepper(
                        "\(bodyProfile.heightFeet) ft",
                        value: Binding(
                            get: { bodyProfile.heightFeet },
                            set: { bodyProfile.setHeight(feet: $0, inches: bodyProfile.heightRemainingInches) }
                        ),
                        in: 4...7
                    )
                    Stepper(
                        "\(bodyProfile.heightRemainingInches) in",
                        value: Binding(
                            get: { bodyProfile.heightRemainingInches },
                            set: { bodyProfile.setHeight(feet: bodyProfile.heightFeet, inches: $0) }
                        ),
                        in: 0...11
                    )
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var weightSection: some View {
        card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    sectionLabel("Current weight")
                    Text("\(bodyProfile.weightPounds) lb")
                        .font(.title2.bold())
                }
                Spacer()
                Stepper(
                    "",
                    value: $bodyProfile.weightPounds,
                    in: 80...450,
                    step: 1
                )
                .labelsHidden()
            }
        }
    }

    private var goalWeightSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        sectionLabel("Goal weight")
                        Text("\(bodyProfile.desiredWeightPounds) lb")
                            .font(.title2.bold())
                    }
                    Spacer()
                    Stepper(
                        "",
                        value: $bodyProfile.desiredWeightPounds,
                        in: 80...450,
                        step: 1
                    )
                    .labelsHidden()
                }

                Text(bodyProfile.weightGoalSummary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(APTheme.accent)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                    .fill(APTheme.cardBackground)
            )
    }

    private func selectionRow(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? APTheme.accent : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                    .fill(isSelected ? APTheme.accentMuted : APTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        BodyProfileStepView(bodyProfile: .constant(.default))
            .padding()
    }
    .background(APTheme.screenBackground)
}
