import SwiftUI

struct EditShoppingItemView: View {
    let item: ShoppingItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ShoppingListViewModel
    @State private var quantity: Int = 1
    @State private var unit: String = "buc"
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Articol")) {
                    Text(item.name)
                        .bodySecondaryStyle()
                }
                
                Section(header: Text("Cantitate")) {
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
            .navigationTitle("Editare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anulează") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvează") {
                        item.quantity = Double(quantity)
                        item.unit = unit
                        item.notes = notes.isEmpty ? nil : notes
                        viewModel.updateItem(item)
                        dismiss()
                    }
                }
            }
            .onAppear {
                quantity = Int(item.quantity)
                unit = item.unit
                notes = item.notes ?? ""
            }
        }
    }
}

#Preview {
    let item = ShoppingItem(name: "Brânză", quantity: 200, unit: "g", category: "Lactate")
    EditShoppingItemView(item: item)
}
