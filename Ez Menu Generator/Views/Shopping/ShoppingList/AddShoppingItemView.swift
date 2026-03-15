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
            ScrollView {
                VStack(spacing: EzSpacing.lg) {
                    // MARK: - Categorie Section
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Categorie")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.secondary)
                            .tracking(0.5)
                        
                        Picker("Categorie", selection: $selectedCategory) {
                            ForEach(availableCategories, id: \.self) { cat in
                                Text(CategoryManager.displayName(for: cat)).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedCategory) { _, _ in
                            if !itemsForCategory.isEmpty {
                                selectedItem = itemsForCategory[0]
                            } else {
                                selectedItem = nil
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Articol Section
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Articol")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.secondary)
                            .tracking(0.5)
                        
                        if !itemsForCategory.isEmpty {
                            Picker("Selectează", selection: $selectedItem) {
                                ForEach(itemsForCategory, id: \.self) { item in
                                    Text(item).tag(Optional(item))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(EzSpacing.sm)
                            .background(EzColors.Background.tertiary)
                            .cornerRadius(AppTheme.CornerRadius.small)
                            
                            Divider()
                                .padding(.vertical, EzSpacing.sm)
                            
                            HStack(spacing: EzSpacing.sm) {
                                Image(systemName: "pencil.circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.primary)
                                
                                Text("Articol personalizat")
                                    .font(EzTypography.Body.font)
                                    .foregroundColor(EzColors.Text.primary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $useCustom)
                                    .tint(AppTheme.Colors.primary)
                            }
                            .padding(EzSpacing.sm)
                            .background(EzColors.Background.tertiary.opacity(0.5))
                            .cornerRadius(AppTheme.CornerRadius.small)
                            
                            if useCustom {
                                TextField("Introdu articol custom...", text: $customItem)
                                    .textFieldStyle(.plain)
                                    .padding(EzSpacing.sm)
                                    .background(EzColors.Background.tertiary)
                                    .cornerRadius(AppTheme.CornerRadius.small)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        } else {
                            TextField("Introdu articol...", text: $customItem)
                                .textFieldStyle(.plain)
                                .padding(EzSpacing.sm)
                                .background(EzColors.Background.tertiary)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Detalii Section
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Detalii")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.secondary)
                            .tracking(0.5)
                        
                        VStack(alignment: .leading, spacing: EzSpacing.sm) {
                            HStack {
                                Text("Cantitate")
                                    .font(EzTypography.Body.font)
                                    .foregroundColor(EzColors.Text.secondary)
                                Spacer()
                                Text("\(quantity)")
                                    .font(EzTypography.Headline.font)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                            
                            Stepper("", value: $quantity, in: 1...1000, step: 1)
                                .tint(AppTheme.Colors.primary)
                        }
                        .padding(EzSpacing.sm)
                        .background(EzColors.Background.tertiary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        
                        VStack(alignment: .leading, spacing: EzSpacing.sm) {
                            Text("Unitate")
                                .font(EzTypography.Label.font)
                                .foregroundColor(EzColors.Text.secondary)
                            
                            Picker("Unitate", selection: $unit) {
                                ForEach(["buc", "g", "kg", "l"], id: \.self) { u in
                                    Text(u).tag(u)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(EzSpacing.sm)
                        .background(EzColors.Background.tertiary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Note Section
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Note (opțional)")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.secondary)
                            .tracking(0.5)
                        
                        TextField("Adaugă o notă...", text: $notes)
                            .textFieldStyle(.plain)
                            .padding(EzSpacing.sm)
                            .background(EzColors.Background.tertiary)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Action Buttons
                    VStack(spacing: EzSpacing.md) {
                        Button(action: addItem) {
                            HStack(spacing: EzSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Adaugă articol")
                                    .font(EzTypography.Button.font)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, EzSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .fill(AppTheme.Colors.primary)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.6)
                        
                        Button(action: { dismiss() }) {
                            Text("Anulează")
                                .font(EzTypography.Button.font)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, EzSpacing.md)
                                .foregroundColor(EzColors.Text.primary)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                        .stroke(EzColors.Background.tertiary, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, EzSpacing.lg)
                    
                    Spacer()
                        .frame(height: EzSpacing.xl)
                }
                .padding(EzSpacing.lg)
            }
            .background(EzColors.Background.primary)
            .scrollIndicators(.hidden)
            .navigationTitle("Adaugă articol")
            .navigationBarTitleDisplayMode(.inline)
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
