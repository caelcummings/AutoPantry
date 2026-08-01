import SwiftUI

/// Shared visual tokens for a consistent, polished MVP UI.
enum APTheme {
    static let cornerRadius: CGFloat = 16
    static let chipCornerRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12

    static let accent = Color(red: 0.18, green: 0.72, blue: 0.52)
    static let accentMuted = Color(red: 0.18, green: 0.72, blue: 0.52).opacity(0.15)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let screenBackground = Color(.systemGroupedBackground)
}
