import SwiftUI

struct SeasoningInventoryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var customItem = ""
    @FocusState private var isCustomFieldFocused: Bool

    private var ownedKeys: Set<String> {
        Set(appState.seasoningInventory.items.map(SeasoningMatcher.normalize))
    }

    var body: some View {
        List {
            Section {
                Text("Mark staples you already have — spices, condiments, oils, and basics stay off the grocery list when recipes call for them.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            if !appState.seasoningInventory.isEmpty {
                Section("Your pantry") {
                    ForEach(appState.seasoningInventory.sortedItems, id: \.self) { name in
                        HStack {
                            Text(name)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(APTheme.accent)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.removeSeasoning(name)
                        }
                    }
                    .onDelete(perform: deleteOwned)
                }
            }

            Section {
                HStack {
                    TextField("Add a custom item", text: $customItem)
                        .textInputAutocapitalization(.words)
                        .focused($isCustomFieldFocused)
                        .onSubmit(addCustomItem)

                    Button("Add") {
                        addCustomItem()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(APTheme.accent)
                    .disabled(customItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Custom")
            }

            ForEach(PantryCategory.allCases) { category in
                Section(category.title) {
                    ForEach(SeasoningMatcher.items(in: category), id: \.self) { name in
                        let isOwned = ownedKeys.contains(SeasoningMatcher.normalize(name))
                        Button {
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
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Pantry staples")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addCustomItem() {
        let trimmed = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appState.addSeasoning(trimmed)
        customItem = ""
        isCustomFieldFocused = false
    }

    private func deleteOwned(at offsets: IndexSet) {
        let items = appState.seasoningInventory.sortedItems
        for index in offsets {
            appState.removeSeasoning(items[index])
        }
    }
}

#Preview {
    NavigationStack {
        SeasoningInventoryView()
            .environmentObject(AppState(route: .main, userProfile: OnboardingDraft()))
    }
}
