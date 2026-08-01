import SwiftUI

struct MacroRangeEditor: View {
    let title: String
    let unit: String
    let icon: String
    let tint: Color
    @Binding var range: MacroRange
    let bounds: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                Spacer()
                Text("\(range.min)–\(range.max) \(unit)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Minimum")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: minBinding,
                    in: Double(bounds.lowerBound)...Double(range.max),
                    step: Double(step)
                )
                .tint(tint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Maximum")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: maxBinding,
                    in: Double(range.min)...Double(bounds.upperBound),
                    step: Double(step)
                )
                .tint(tint)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private var minBinding: Binding<Double> {
        Binding(
            get: { Double(range.min) },
            set: { range.min = Int($0.rounded()) }
        )
    }

    private var maxBinding: Binding<Double> {
        Binding(
            get: { Double(range.max) },
            set: { range.max = Int($0.rounded()) }
        )
    }
}
