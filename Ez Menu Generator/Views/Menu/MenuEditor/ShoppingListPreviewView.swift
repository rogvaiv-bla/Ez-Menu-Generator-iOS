import SwiftUI

struct ShoppingListPreviewView: View {
    @Binding var shoppingList: [ShoppingItem]
    @Environment(\.dismiss) var dismiss
    @State private var showAddToCart = false
    
    var groupedByCategory: [String: [ShoppingItem]] {
        Dictionary(grouping: shoppingList) { $0.category }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if shoppingList.isEmpty {
                    EmptyStateView.noShoppingItems {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(EzColors.Background.primary)
                } else {
                    List {
                        ForEach(groupedByCategory.sorted { $0.key < $1.key }, id: \.key) { category, items in
                            Section(header: Text(category).headlineStyle()) {
                                ForEach(items) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .bodySecondaryStyle()
                                            Text("\(String(format: "%.1f", item.quantity)) \(item.unit)")
                                                .helperStyle()
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Lista de cumpărături")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Înapoi")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddToCart = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var items = SampleDataService.sampleRecipes.flatMap { $0.ingredients }.map { 
        ShoppingItem(name: $0.name, quantity: $0.quantity, unit: $0.unit, category: $0.category)
    }
    ShoppingListPreviewView(shoppingList: $items)
}
