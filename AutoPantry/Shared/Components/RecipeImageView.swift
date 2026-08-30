import SwiftUI

struct RecipeImageView: View {
    let recipe: RecipeSummary

    var body: some View {
        Group {
            if let localImage {
                localImage
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = recipe.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack {
                            placeholder
                            ProgressView()
                                .tint(.white)
                        }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var localImage: Image? {
        guard let data = UserRecipeImageStore.loadData(for: recipe.id),
              let uiImage = UIImage(data: data)
        else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    @ViewBuilder
    private var placeholder: some View {
        if recipe.isUserRecipe {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.82, blue: 0.35),
                    Color(red: 0.88, green: 0.68, blue: 0.18),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color(red: 0.62, green: 0.45, blue: 0.05).opacity(0.75))
            }
        } else {
            LinearGradient(
                colors: [APTheme.accent.opacity(0.85), Color.orange.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}
