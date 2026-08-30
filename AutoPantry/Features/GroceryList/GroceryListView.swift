import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var checkedIDs: Set<String> = []
    @State private var showSeasoningInventory = false
    @State private var showAddItem = false
    @State private var newItemName = ""

    private var items: [GroceryListItem] {
        appState.groceryListItems
    }

    private var groupedItems: [(aisle: String, items: [GroceryListItem])] {
        Dictionary(grouping: items, by: \.aisle)
            .map { (aisle: $0.key, items: $0.value) }
            .sorted { lhs, rhs in
                if lhs.aisle == GroceryListBuilder.addedAisle { return true }
                if rhs.aisle == GroceryListBuilder.addedAisle { return false }
                if lhs.aisle == GroceryListBuilder.pantryStaplesAisle { return false }
                if rhs.aisle == GroceryListBuilder.pantryStaplesAisle { return true }
                return lhs.aisle < rhs.aisle
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    if appState.weeklyMealPlan.recipes.isEmpty {
                        emptyPlanState
                    } else {
                        emptyFilteredState
                    }
                } else {
                    listContent
                }
            }
            .background(APTheme.screenBackground.ignoresSafeArea())
            .navigationTitle("Grocery List")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        newItemName = ""
                        showAddItem = true
                    } label: {
                        Label("Add item", systemImage: "plus")
                    }
                    .accessibilityLabel("Add grocery item")

                    Button {
                        showSeasoningInventory = true
                    } label: {
                        Label("Pantry", systemImage: "cabinet.fill")
                    }
                }
            }
            .navigationDestination(isPresented: $showSeasoningInventory) {
                SeasoningInventoryView()
            }
            .alert("Add item", isPresented: $showAddItem) {
                TextField("e.g. Paper towels", text: $newItemName)
                    .textInputAutocapitalization(.words)
                Button("Add") {
                    addCustomItem()
                }
                .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) {
                    newItemName = ""
                }
            } message: {
                Text("Type a name and tap Add.")
            }
            .onChange(of: items.map(\.id)) { _, newIDs in
                checkedIDs = checkedIDs.intersection(Set(newIDs))
            }
        }
    }

    private var listContent: some View {
        List {
            if !appState.seasoningInventory.isEmpty {
                Section {
                    Label(
                        "\(appState.seasoningInventory.items.count) pantry staple\(appState.seasoningInventory.items.count == 1 ? "" : "s") hidden",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(APTheme.accent)
                }
            }

            ForEach(groupedItems, id: \.aisle) { group in
                Section {
                    ForEach(group.items) { item in
                        Toggle(isOn: binding(for: item)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                if let detail = item.detailLine {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tint(APTheme.accent)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if item.isCustom {
                                Button(role: .destructive) {
                                    appState.removeExtraGroceryItem(item.name)
                                    checkedIDs.remove(item.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text(group.aisle)
                } footer: {
                    if group.aisle == GroceryListBuilder.pantryStaplesAisle {
                        Text("Checked staples are saved to your pantry and stay off future lists.")
                    } else if group.aisle == GroceryListBuilder.addedAisle {
                        Text("Swipe left to remove an item you added.")
                    }
                }
            }
        }
    }

    private var emptyPlanState: some View {
        ContentUnavailableView {
            Label("No recipes saved yet", systemImage: "cart")
        } description: {
            Text("Like recipes in Discover to build this week's grocery list — or tap + to add something now.")
        } actions: {
            Button("Add item") {
                newItemName = ""
                showAddItem = true
            }
            .buttonStyle(.borderedProminent)
            .tint(APTheme.accent)

            Button("Manage pantry") {
                showSeasoningInventory = true
            }
            .buttonStyle(.bordered)
        }
    }

    private var emptyFilteredState: some View {
        ContentUnavailableView {
            Label("List is empty", systemImage: "checkmark.circle")
        } description: {
            Text("Every ingredient from this week's recipes is already covered by your pantry—or recipes have no ingredients listed.")
        } actions: {
            Button("Add item") {
                newItemName = ""
                showAddItem = true
            }
            .buttonStyle(.borderedProminent)
            .tint(APTheme.accent)

            Button("Edit pantry") {
                showSeasoningInventory = true
            }
            .buttonStyle(.bordered)
        }
    }

    private func addCustomItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appState.addExtraGroceryItem(trimmed)
        newItemName = ""
    }

    private func isPersistentPantryItem(_ item: GroceryListItem) -> Bool {
        item.aisle == GroceryListBuilder.pantryStaplesAisle
            || SeasoningMatcher.isPantryStaple(item.name)
    }

    private func binding(for item: GroceryListItem) -> Binding<Bool> {
        if isPersistentPantryItem(item) {
            return Binding(
                get: { appState.seasoningInventory.containsIngredient(item.name) },
                set: { isChecked in
                    if isChecked {
                        appState.addSeasoning(item.name)
                    } else {
                        appState.removeSeasoning(item.name)
                    }
                }
            )
        }

        return Binding(
            get: { checkedIDs.contains(item.id) },
            set: { isChecked in
                if isChecked {
                    checkedIDs.insert(item.id)
                } else {
                    checkedIDs.remove(item.id)
                }
            }
        )
    }
}

#Preview {
    GroceryListView()
        .environmentObject(
            AppState(route: .main, userProfile: OnboardingDraft())
        )
}
