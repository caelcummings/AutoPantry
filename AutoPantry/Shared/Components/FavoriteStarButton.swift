import SwiftUI

/// Toggles favorite state for a recipe; filled star when favorited.
struct FavoriteStarButton: View {
    @EnvironmentObject private var appState: AppState
    let recipeID: String
    var size: CGFloat = 22
    var style: Style = .plain

    enum Style {
        case plain
        case onImage
    }

    private var isFavorite: Bool {
        appState.isFavorite(recipeID: recipeID)
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                appState.toggleFavorite(recipeID: recipeID)
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(isFavorite ? Color.yellow : starIdleColor)
                .symbolEffect(.bounce, value: isFavorite)
                .padding(style == .onImage ? 8 : 0)
                .background {
                    if style == .onImage {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    private var starIdleColor: Color {
        switch style {
        case .plain:
            return .secondary
        case .onImage:
            return .white
        }
    }
}
