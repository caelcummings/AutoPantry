import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var checkedIDs: Set<String> = []
    @State private var showSeasoningInventory = false

    private var items: [GroceryListItem] {
        appState.groceryListItems
    }

    private var groupedItems: [(aisle: String, items: [GroceryListItem])] {
        Dictionary(grouping: items, by: \.aisle)
            .map { (aisle: $0.key, items: $0.value) }
            .sorted { lhs, rhs in
                if lhs.aisle == "Pantry staples" { return false }
                if rhs.aisle == "Pantry staples" { return true }
                return lhs.aisle < rhs.aisle
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appState.weeklyMealPlan.recipes.isEmpty {
                    emptyPlanState
                } else if items.isEmpty {
                    emptyFilteredState
                } else {
                    listContent
                }
            }
            .background(APTheme.screenBackground.ignoresSafeArea())
            .navigationTitle("Grocery List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
                Section(group.aisle) {
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
                    }
                }
            }
        }
    }

    private var emptyPlanState: some View {
        ContentUnavailableView {
            Label("No recipes saved yet", systemImage: "cart")
        } description: {
            Text("Like recipes in Discover to build this week's grocery list.")
        } actions: {
            Button("Manage pantry") {
                showSeasoningInventory = true
            }
            .buttonStyle(.borderedProminent)
            .tint(APTheme.accent)
        }
    }

    private var emptyFilteredState: some View {
        ContentUnavailableView {
            Label("List is empty", systemImage: "checkmark.circle")
        } description: {
            Text("Every ingredient from this week's recipes is already covered by your pantry—or recipes have no ingredients listed.")
        } actions: {
            Button("Edit pantry") {
                showSeasoningInventory = true
            }
            .buttonStyle(.borderedProminent)
            .tint(APTheme.accent)
        }
    }

    private func binding(for item: GroceryListItem) -> Binding<Bool> {
        Binding(
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
