import SwiftUI

struct RecipeCard: View {
    let recipe: RecipeSummary

    var body: some View {
        GeometryReader { geo in
            let detailsHeight = min(max(geo.size.height * 0.34, 132), 168)
            let imageHeight = max(geo.size.height - detailsHeight, 160)

            VStack(alignment: .leading, spacing: 0) {
                recipeImage
                    .frame(width: geo.size.width, height: imageHeight)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        imageScrim
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    metadataChips

                    if !recipe.ingredients.isEmpty {
                        Text(topIngredientsLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(servingsAndIngredientsLine)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, maxHeight: detailsHeight, alignment: .topLeading)
                .background(APTheme.cardBackground)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: APTheme.cornerRadius + 4, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
        }
    }

    private var topIngredientsLine: String {
        recipe.ingredients.prefix(4).map(\.name).joined(separator: ", ")
    }

    private var servingsAndIngredientsLine: String {
        if recipe.isSnack {
            let portionLabel = recipe.portionCount == 1 ? "1 portion" : "\(recipe.portionCount) portions"
            return "Snack · \(portionLabel) · \(recipe.ingredientCount) ingredients"
        }
        let servingLabel = recipe.portionCount == 1 ? "1 serving" : "\(recipe.portionCount) servings"
        return "\(servingLabel) · \(recipe.ingredientCount) ingredients"
    }

    private var imageScrim: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.18)],
            startPoint: .center,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var metadataChips: some View {
        let chips = metadataItems
        if chips.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                        metaChip(chip.text, icon: chip.icon, emphasized: chip.emphasized)
                    }
                }
            }
        }
    }

    private var metadataItems: [(text: String, icon: String, emphasized: Bool)] {
        let macros = recipe.effectiveMacros
        let prefix = recipe.hasMacros ? "" : "~"
        var items: [(String, String, Bool)] = []
        if recipe.isSnack {
            items.append(("Snack", "carrot.fill", true))
        }
        if let cookMinutes = recipe.cookMinutes {
            items.append(("\(cookMinutes)m", "clock", false))
        }
        items.append(("\(prefix)\(macros.calories) cal", "flame", false))
        items.append(("\(prefix)\(macros.proteinGrams)g P", "bolt.fill", false))
        if let price = recipe.formattedPrice {
            items.append((price, "dollarsign.circle", false))
        }
        return items
    }

    @ViewBuilder
    private var recipeImage: some View {
        if let imageURL = recipe.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    imagePlaceholder
                case .empty:
                    ZStack {
                        imagePlaceholder
                        ProgressView().tint(.white)
                    }
                @unknown default:
                    imagePlaceholder
                }
            }
        } else {
            imagePlaceholder
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
        }
    }

    private var imagePlaceholder: some View {
        LinearGradient(
            colors: [APTheme.accent.opacity(0.85), Color.orange.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func metaChip(_ text: String, icon: String, emphasized: Bool = false) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(emphasized ? APTheme.accent : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(emphasized ? APTheme.accentMuted : Color.primary.opacity(0.06)))
            .lineLimit(1)
    }
}

#Preview {
    RecipeCard(recipe: RecipeCatalog.feed[0])
        .padding()
        .frame(height: 520)
}
