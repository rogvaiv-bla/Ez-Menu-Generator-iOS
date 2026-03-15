import SwiftUI

struct ShoppingItemRowView: View {
    let item: ShoppingItem
    @EnvironmentObject var viewModel: ShoppingListViewModel
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @State private var isCheckedState: Bool = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: EzSpacing.lg) {
                // Animated Checkbox
                Button(action: toggleChecked) {
                    ZStack {
                        Circle()
                            .fill(
                                isCheckedState
                                    ? AppTheme.Colors.success
                                    : EzColors.Background.tertiary
                            )
                            .shadow(
                                color: isCheckedState
                                    ? AppTheme.Colors.success.opacity(0.5)
                                    : Color.clear,
                                radius: isCheckedState ? 6 : 0
                            )
                        
                        if isCheckedState {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(1.0)
                                .animation(AppTheme.springSnappy, value: isCheckedState)
                        } else {
                            Circle()
                                .stroke(EzColors.Text.secondary, lineWidth: 2)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                }
                .accessibilityLabel(isCheckedState ? "Bifat" : "Nebifat")
                .accessibilityHint("Apasă pentru a marca ca \(isCheckedState ? "nebifat" : "bifat")")
                
                // Content
                VStack(alignment: .leading, spacing: EzSpacing.xs) {
                    Text(item.name)
                        .font(EzTypography.Headline.font)
                        .strikethrough(isCheckedState, color: EzColors.Text.secondary)
                        .foregroundColor(
                            isCheckedState
                                ? EzColors.Text.secondary
                                : EzColors.Text.primary
                        )
                    
                    HStack(spacing: EzSpacing.md) {
                        // Quantity & Unit
                        HStack(spacing: EzSpacing.xs) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(EzColors.Text.tertiary)
                            
                            Text("\(Int(item.quantity)) \(item.unit)")
                                .font(EzTypography.Body.font)
                                .foregroundColor(EzColors.Text.secondary)
                        }
                        
                        // Category Badge
                        HStack(spacing: 4) {
                            Text(item.category)
                                .font(EzTypography.Helper.font)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, EzSpacing.sm)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .fill(
                                    EzColors.categoryColors[item.category]
                                        ?? EzColors.Accent.primary
                                )
                        )
                    }
                }
                
                Spacer()
                
                // Action Buttons (More Elegant)
                HStack(spacing: EzSpacing.md) {
                    Button(action: { showEdit = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(EzSpacing.sm)
                            .background(
                                Circle()
                                    .fill(AppTheme.Colors.primary.opacity(0.1))
                            )
                    }
                    .accessibilityLabel("Editează item")
                    .sheet(isPresented: $showEdit) {
                        EditShoppingItemView(item: item)
                            .environmentObject(viewModel)
                    }
                    
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.danger)
                            .padding(EzSpacing.sm)
                            .background(
                                Circle()
                                    .fill(AppTheme.Colors.danger.opacity(0.1))
                            )
                    }
                    .accessibilityLabel("Șterge item")
                    .alert("Șterge item", isPresented: $showDeleteAlert) {
                        Button("Șterge", role: .destructive) {
                            HapticManager.Context.delete()
                            viewModel.undoRedoManager.recordAction(
                                .deleteShoppingItem(ShoppingItemSnapshot.from(item))
                            )
                            viewModel.deleteItem(item)
                        }
                        Button("Anulează", role: .cancel) { }
                    } message: {
                        Text("Ești sigur că vrei să ștergi '\(item.name)'?")
                    }
                }
            }
            .padding(EzSpacing.lg)
            .contentShape(Rectangle())
        }
        .premiumCard(elevation: .small)
        .padding(.horizontal, EzSpacing.md)
        .padding(.vertical, EzSpacing.xs)
        .transition(.scale.combined(with: .opacity))
        .animation(AppTheme.springStandard, value: item.id)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(AppTheme.springSnappy, value: isHovered)
        .onHover { hover in
            isHovered = hover
        }
        .onAppear {
            isCheckedState = item.isChecked
        }
        .onChange(of: item.isChecked) { _, newValue in
            isCheckedState = newValue
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.name), \(Int(item.quantity)) \(item.unit)")
        .accessibilityValue(isCheckedState ? "Bifat" : "Nebifat")
    }
    
    private func toggleChecked() {
        HapticManager.Context.checkbox()
        item.isChecked.toggle()
        isCheckedState = item.isChecked
    }
}

#Preview {
    VStack(spacing: EzSpacing.md) {
        let item1 = ShoppingItem(
            name: "Lapte integral",
            quantity: 2,
            unit: "l",
            category: "Lactate și ouă 🧈🥚"
        )
        
        ShoppingItemRowView(item: item1)
        
        Spacer()
    }
    .padding(EzSpacing.lg)
    .background(EzColors.Background.primary.ignoresSafeArea())
    .environmentObject(ShoppingListViewModel())
}
