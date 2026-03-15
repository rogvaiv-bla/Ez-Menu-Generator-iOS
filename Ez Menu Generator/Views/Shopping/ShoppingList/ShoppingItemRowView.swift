import SwiftUI

struct ShoppingItemRowView: View {
    let item: ShoppingItem
    @EnvironmentObject var viewModel: ShoppingListViewModel
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Large Checkbox
                Button(action: {
                    HapticManager.Context.checkbox()
                    item.isChecked.toggle()
                }) {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "o.circle")
                        .foregroundColor(item.isChecked ? EzColors.Accent.success : EzColors.Text.secondary)
                        .font(.system(size: 32))
                }
                .accessibilityLabel(item.isChecked ? "Bifat" : "Nebifat")
                .accessibilityHint("Apasă pentru a marca ca \(item.isChecked ? "nebifat" : "bifat")")
                .accessibilityAddTraits(.isButton)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .strikethrough(item.isChecked)
                        .foregroundColor(item.isChecked ? EzColors.Text.secondary : EzColors.Text.primary)
                    
                    HStack(spacing: 10) {
                        Text("\(Int(item.quantity)) \(item.unit)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(EzColors.Text.secondary)
                        
                        Text(item.category)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(EzColors.categoryColors[item.category] ?? EzColors.Accent.primary)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 8) {
                    Button(action: { showEdit = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(EzColors.Accent.primary)
                            .font(.system(size: 24))
                    }
                    .accessibilityLabel("Editează")
                    .sheet(isPresented: $showEdit) {
                        EditShoppingItemView(item: item)
                            .environmentObject(viewModel)
                    }
                    
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(EzColors.Accent.danger)
                            .font(.system(size: 24))
                    }
                    .accessibilityLabel("Șterge")
                    .alert("Șterge item", isPresented: $showDeleteAlert) {
                        Button("Șterge", role: .destructive) {
                            HapticManager.Context.delete()
                            viewModel.undoRedoManager.recordAction(.deleteShoppingItem(ShoppingItemSnapshot.from(item)))
                            viewModel.deleteItem(item)
                        }
                        Button("Anulează", role: .cancel) { }
                    } message: {
                        Text("Ești sigur că vrei să ștergi '\(item.name)'?")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.Context.checkbox()
                item.isChecked.toggle()
            }
            .opacity(item.isChecked ? 0.65 : 1)
            
            Divider()
                .padding(.leading, 72)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.name), \(Int(item.quantity)) \(item.unit)")
        .accessibilityValue(item.isChecked ? "Bifat" : "Nebifat")
    }
}

#Preview {
    let item = ShoppingItem(name: "Lapte", quantity: 2, unit: "l", category: "Lactate și ouă")
    ShoppingItemRowView(item: item)
}
