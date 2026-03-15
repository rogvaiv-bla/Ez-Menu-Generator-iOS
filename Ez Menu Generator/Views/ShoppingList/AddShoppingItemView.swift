import SwiftUI

struct AddShoppingItemView: View {
    @EnvironmentObject var viewModel: ShoppingListViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory = "Legume / Fructe"
    @State private var selectedItem: String? = nil
    @State private var customItem = ""
    @State private var quantity = 1
    @State private var unit = "buc"
    @State private var notes = ""
    @State private var useCustom = false
    
    var itemsForCategory: [String] {
        SampleDataService.shoppingItems[selectedCategory] ?? []
    }
    
    var availableCategories: [String] {
        CategoryManager.orderedCategories.map { $0.name }
    }
    
    var itemName: String {
        if itemsForCategory.isEmpty || useCustom {
            // No predefined items OR custom toggle enabled - use custom field
            return customItem.trimmingCharacters(in: .whitespaces)
        } else {
            // Use selected item from predefined list
            return selectedItem?.trimmingCharacters(in: .whitespaces) ?? ""
        }
    }
    
    var isValid: Bool {
        !itemName.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Categorie")) {
                    Picker("Categorie", selection: $selectedCategory) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Text(CategoryManager.displayName(for: cat)).tag(cat)
                        }
                    }
                    .onChange(of: selectedCategory) { _, _ in
                        // Reset selection when category changes
                        if !itemsForCategory.isEmpty {
                            selectedItem = itemsForCategory[0]
                        } else {
                            selectedItem = nil
                        }
                    }
                }
                
                Section(header: Text("Articol")) {
                    if !itemsForCategory.isEmpty {
                        Picker("Selectează", selection: $selectedItem) {
                            ForEach(itemsForCategory, id: \.self) { item in
                                Text(item).tag(Optional(item))
                            }
                        }
                        .onChange(of: selectedItem) { _, _ in
                            // Validation updates automatically
                        }
                        
                        Divider()
                        
                        Toggle("Articol personalizat", isOn: $useCustom)
                        
                        if useCustom {
                            TextField("Introdu articol...", text: $customItem)
                        }
                    } else {
                        // No predefined items - show text field directly
                        TextField("Introdu articol...", text: $customItem)
                    }
                }
                
                Section(header: Text("Detalii")) {
                    Stepper("Cantitate: \(quantity)", value: $quantity, in: 1...1000, step: 1)
                    
                    Picker("Unitate", selection: $unit) {
                        ForEach(["buc", "g", "kg", "l"], id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                }
                
                Section(header: Text("Note (opțional)")) {
                    TextField("Note", text: $notes)
                }
            }
            .navigationTitle("Adaugă articol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anulează") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adaugă") {
                        addItem()
                    }
                    .disabled(!isValid)
                }
            }
            .scrollContentBackground(.hidden)
            .background(EzColors.Background.primary)
            .onAppear {
                if !itemsForCategory.isEmpty && selectedItem == nil {
                    selectedItem = itemsForCategory[0]
                }
            }
        }
    }
    
    private func addItem() {
        guard isValid else { return }
        
        let item = ShoppingItem(
            name: itemName,
            quantity: Double(quantity),
            unit: unit,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes
        )
        
        viewModel.addItem(item)
        viewModel.undoRedoManager.recordAction(.addShoppingItem(ShoppingItemSnapshot.from(item)))
        dismiss()
    }
}

#Preview {
    AddShoppingItemView()
        .environmentObject(ShoppingListViewModel())
}
