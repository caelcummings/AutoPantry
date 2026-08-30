import SwiftUI

enum AppLegalLinks {
    /// Update after hosting `docs/privacy-policy.html` (GitHub Pages, etc.).
    static let privacyPolicyURL = URL(string: "https://caelcummings.github.io/AutoPantry/privacy-policy.html")

    /// Update after hosting `docs/support.html`, or use your support email page.
    static let supportURL = URL(string: "https://caelcummings.github.io/AutoPantry/support.html")

    static let supportEmail = "caelcummings@gmail.com"
}

struct LegalDocumentView: View {
    let title: String
    let sections: [LegalSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(APTheme.horizontalPadding)
            .padding(.vertical, 20)
        }
        .background(APTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

enum LegalDocuments {
    static let privacyPolicy = [
        LegalSection(
            title: "Overview",
            body: "AutoPantry helps you plan weekly meals, estimate macros, and build grocery lists. This policy describes what data the app stores and how it is used."
        ),
        LegalSection(
            title: "Data we store on your device",
            body: """
            • Body profile (age, sex, height, weight, activity) to estimate calorie and macro targets
            • Your nutrition targets and meals-per-week preference
            • Weekly meal plan, favorites, pantry staples, and custom grocery items
            • Custom recipes you create, including optional photos from your camera roll
            """
        ),
        LegalSection(
            title: "What we do not do",
            body: """
            • No account is required
            • We do not sell your data
            • We do not use your data for advertising or cross-app tracking
            • We do not upload your profile or recipes to our servers
            """
        ),
        LegalSection(
            title: "Photos",
            body: "If you add a photo to a custom recipe, the image is saved locally on your device. AutoPantry only accesses your photo library when you choose a picture."
        ),
        LegalSection(
            title: "Recipe images",
            body: "Built-in recipe photos may load from the internet when you are online. No personal data is sent with those requests."
        ),
        LegalSection(
            title: "Deleting your data",
            body: "Open Profile → Reset profile & redo onboarding to erase your profile, weekly plan, pantry list, favorites, and custom recipes from this device."
        ),
        LegalSection(
            title: "Contact",
            body: "Questions about privacy? Email \(AppLegalLinks.supportEmail)."
        ),
        LegalSection(
            title: "Last updated",
            body: "August 29, 2026"
        ),
    ]

    static let support = [
        LegalSection(
            title: "Get help",
            body: "AutoPantry is a local meal-planning app. Most issues can be resolved by restarting the app or resetting your profile from the Profile tab."
        ),
        LegalSection(
            title: "Common questions",
            body: """
            • Grocery list empty? Save recipes in Discover or add items with + on the List tab.
            • Macros look off? Edit your profile or macro targets in Profile.
            • Custom recipe photo? Allow photo library access when prompted.
            • Start over? Profile → Reset profile & redo onboarding.
            """
        ),
        LegalSection(
            title: "Email support",
            body: "For bugs or feedback, contact \(AppLegalLinks.supportEmail). Please include your iOS version and a short description of the issue."
        ),
    ]
}

#Preview {
    NavigationStack {
        LegalDocumentView(title: "Privacy Policy", sections: LegalDocuments.privacyPolicy)
    }
}
