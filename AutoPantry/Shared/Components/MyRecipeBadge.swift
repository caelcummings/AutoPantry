import SwiftUI

struct MyRecipeBadge: View {
    var body: some View {
        Text("My Recipe")
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color(red: 0.62, green: 0.45, blue: 0.05))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.88, blue: 0.45),
                            Color(red: 0.93, green: 0.76, blue: 0.28),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay {
                Capsule().strokeBorder(Color(red: 0.78, green: 0.58, blue: 0.12).opacity(0.45), lineWidth: 0.5)
            }
    }
}

#Preview {
    MyRecipeBadge()
        .padding()
}
