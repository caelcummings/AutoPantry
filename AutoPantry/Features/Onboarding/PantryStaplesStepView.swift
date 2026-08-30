import SwiftUI

/// Onboarding step: mark pantry staples the user already owns.
struct PantryStaplesStepView: View {
    @EnvironmentObject private var appState: AppState
    @FocusState.Binding var searchFocused: Bool
    @State private var customItem = ""

    init(searchFocused: FocusState<Bool>.Binding) {
        _searchFocused = searchFocused
    }

    private var ownedKeys: Set<String> {
        Set(appState.seasoningInventory.items.map(SeasoningMatcher.normalize))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: APTheme.sectionSpacing) {
            summaryCard

            customAddCard

            ForEach(PantryCategory.allCases) { category in
                categoryCard(category)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if appState.seasoningInventory.isEmpty {
                Text("Optional — tap what you already keep on hand. You can always update this later in Profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Label(
                    "\(appState.seasoningInventory.items.count) staple\(appState.seasoningInventory.items.count == 1 ? "" : "s") selected",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(APTheme.accent)

                Text("These stay off your grocery list. You can edit anytime in Profile.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private var customAddCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add custom")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                TextField("e.g. Everything bagel seasoning", text: $customItem)
                    .textInputAutocapitalization(.words)
                    .focused($searchFocused)
                    .submitLabel(.done)
                    .onSubmit(addCustomItem)

                Button("Add", action: addCustomItem)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(APTheme.accent)
                    .disabled(customItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private func categoryCard(_ category: PantryCategory) -> some View {
        let items = SeasoningMatcher.items(in: category)
        let ownedCount = items.filter { ownedKeys.contains(SeasoningMatcher.normalize($0)) }.count

        return DisclosureGroup {
            VStack(spacing: 0) {
                ForEach(items, id: \.self) { name in
                    stapleRow(name)
                    if name != items.last {
                        Divider()
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text(category.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if ownedCount > 0 {
                    Text("\(ownedCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(APTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(APTheme.accentMuted))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: APTheme.cornerRadius, style: .continuous)
                .fill(APTheme.cardBackground)
        )
    }

    private func stapleRow(_ name: String) -> some View {
        let isOwned = ownedKeys.contains(SeasoningMatcher.normalize(name))
        return Button {
            if isOwned {
                appState.removeSeasoning(name)
            } else {
                appState.addSeasoning(name)
            }
        } label: {
            HStack {
                Text(name)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isOwned ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOwned ? APTheme.accent : .secondary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func addCustomItem() {
        let trimmed = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appState.addSeasoning(trimmed)
        customItem = ""
        searchFocused = false
    }
}

#Preview {
    struct PreviewWrapper: View {
        @FocusState private var searchFocused: Bool

        var body: some View {
            ScrollView {
                PantryStaplesStepView(searchFocused: $searchFocused)
                    .padding()
            }
            .environmentObject(AppState(route: .onboarding))
        }
    }

    return PreviewWrapper()
}
