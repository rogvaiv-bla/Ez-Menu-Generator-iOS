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
            ScrollView {
                VStack(spacing: EzSpacing.lg) {
                    // MARK: - Item Name Card
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Articol")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.secondary)
                            .tracking(0.5)
                        
                        Text(item.name)
                            .font(EzTypography.Headline.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.primary)
                            .padding(EzSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .fill(AppTheme.Colors.primary.opacity(0.1))
                            )
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Quantity Section
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Cantitate")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.secondary)
                            .tracking(0.5)
                        
                        VStack(alignment: .leading, spacing: EzSpacing.sm) {
                            HStack {
                                Text("Valoare")
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
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Unit Section
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Unitate măsură")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.secondary)
                            .tracking(0.5)
                        
                        Picker("Unitate", selection: $unit) {
                            ForEach(["buc", "g", "kg", "l"], id: \.self) { u in
                                Text(u).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Notes Section
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
                        Button(action: {
                            item.quantity = Double(quantity)
                            item.unit = unit
                            item.notes = notes.isEmpty ? nil : notes
                            viewModel.updateItem(item)
                            dismiss()
                        }) {
                            HStack(spacing: EzSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Salvează")
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
            .navigationTitle("Editare")
            .navigationBarTitleDisplayMode(.inline)
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
