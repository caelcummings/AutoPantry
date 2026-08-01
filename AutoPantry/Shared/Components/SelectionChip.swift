import SwiftUI

struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: APTheme.chipCornerRadius, style: .continuous)
                        .fill(isSelected ? APTheme.accent : APTheme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: APTheme.chipCornerRadius, style: .continuous)
                        .strokeBorder(isSelected ? .clear : Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
