import SwiftUI

struct MenuValidationView: View {
    let menu: Menu
    @EnvironmentObject var menuListViewModel: MenuListViewModel
    @State private var showValidation = false
    
    var violations: [String] {
        menuListViewModel.getMenuValidationIssues(menu: menu)
    }
    
    var isValid: Bool {
        violations.isEmpty
    }
    
    var body: some View {
        Button(action: { showValidation.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isValid ? EzColors.Accent.success : EzColors.Accent.warning)
                    .font(.system(size: 20))
                if !isValid {
                    Text("\(violations.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(EzColors.Accent.warning)
                }
            }
        }
        .sheet(isPresented: $showValidation) {
            ValidationDetailView(violations: violations, isValid: isValid)
        }
    }
}

struct ValidationDetailView: View {
    let violations: [String]
    let isValid: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: EzSpacing.lg) {
                    if isValid {
                        // Success State
                        VStack(spacing: EzSpacing.lg) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64, weight: .regular))
                                .foregroundColor(EzColors.Accent.success)
                            
                            VStack(spacing: EzSpacing.sm) {
                                Text("Meniu Valid!")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(EzColors.Text.primary)
                                
                                Text("Toate constrângerile sunt respectate")
                                    .font(.system(size: 15))
                                    .foregroundColor(EzColors.Text.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(EzSpacing.xl)
                    } else {
                        // Problems State
                        VStack(alignment: .leading, spacing: EzSpacing.md) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(EzColors.Accent.warning)
                                
                                Text("Probleme detectate")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(EzColors.Text.primary)
                                
                                Spacer()
                                
                                Text("\(Set(violations).count)")
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, EzSpacing.sm)
                                    .padding(.vertical, EzSpacing.xs)
                                    .background(EzColors.Accent.warning.opacity(0.2))
                                    .foregroundColor(EzColors.Accent.warning)
                                    .cornerRadius(EzSpacing.xs)
                            }
                            
                            VStack(alignment: .leading, spacing: EzSpacing.sm) {
                                ForEach(Array(Set(violations)), id: \.self) { violation in
                                    HStack(alignment: .top, spacing: EzSpacing.sm) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(EzColors.Accent.warning)
                                            .padding(.top, EzSpacing.xs)
                                        
                                        Text(violation)
                                            .font(.system(size: 14))
                                            .foregroundColor(EzColors.Text.primary)
                                            .lineSpacing(2)
                                    }
                                    .padding(EzSpacing.sm)
                                    .background(EzColors.Background.tertiary)
                                    .cornerRadius(EzSpacing.xs)
                                }
                            }
                        }
                        .padding(EzSpacing.md)
                        .background(EzColors.Background.secondary)
                        .cornerRadius(EzSpacing.sm)
                    }
                    
                    Spacer()
                        .frame(height: EzSpacing.md)
                }
                .padding(EzSpacing.md)
            }
            .background(EzColors.Background.primary)
            .navigationTitle("Validare Meniu")
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
    MenuValidationView(menu: Menu(name: "Test", weekStartDate: Date()))
        .environmentObject(MenuListViewModel())
}
