import SwiftUI

struct AddMenuView: View {
    @EnvironmentObject var viewModel: MenuListViewModel
    @Environment(\.dismiss) var dismiss
    @State private var menuName = ""
    @State private var weekStartDate = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: EzSpacing.lg) {
                    // Menu Details Card
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Detalii meniu")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(EzColors.Text.secondary)
                        
                        VStack(spacing: EzSpacing.md) {
                            // Menu Name
                            VStack(alignment: .leading, spacing: EzSpacing.xs) {
                                Text("Nume meniu")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(EzColors.Text.secondary)
                                
                                TextField("ex: Meniu săptămânal", text: $menuName)
                                    .textFieldStyle(.plain)
                                    .padding(EzSpacing.sm)
                                    .background(EzColors.Background.tertiary)
                                    .cornerRadius(EzSpacing.xs)
                                    .foregroundColor(EzColors.Text.primary)
                            }
                            
                            // Start Date
                            VStack(alignment: .leading, spacing: EzSpacing.xs) {
                                Text("Data de început")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(EzColors.Text.secondary)
                                
                                DatePicker(
                                    "",
                                    selection: $weekStartDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(EzColors.Accent.primary)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(EzSpacing.sm)
                    
                    // Action Buttons
                    VStack(spacing: EzSpacing.md) {
                        EzButton(
                            "Creează meniu",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            size: .medium,
                            fullWidth: true
                        ) {
                            let finalName = menuName.isEmpty ? "Săptămâna \(weekStartDate.formatted(date: .abbreviated, time: .omitted))" : menuName
                            viewModel.createNewMenu(name: finalName, startDate: weekStartDate)
                            HapticManager.success()
                            dismiss()
                        }
                        
                        EzButton(
                            "Anulează",
                            style: .secondary,
                            size: .medium,
                            fullWidth: true
                        ) {
                            dismiss()
                        }
                    }
                }
                .padding(EzSpacing.md)
            }
            .background(EzColors.Background.primary)
            .navigationTitle("Meniu nou")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(EzColors.Accent.primary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
}

#Preview {
    AddMenuView()
        .environmentObject(MenuListViewModel())
}
