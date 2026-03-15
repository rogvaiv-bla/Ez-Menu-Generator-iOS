import SwiftUI

struct MenuListView: View {
    @EnvironmentObject var viewModel: MenuListViewModel
    @State private var showAddMenu = false
    @State private var showSettings = false
    @State private var selectedMenu: Menu? = nil
    @State private var showDeleteMenuConfirmation = false
    @EnvironmentObject private var householdManager: HouseholdManager
    
    // Get the primary/first menu to display
    var primaryMenu: Menu? {
        viewModel.sortedMenus.first
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Custom Navigation Bar (REDESIGN 3.0)
            VStack(spacing: 0) {
                NavigationBarView(
                    title: "Home",
                    showBackButton: false,
                    onUndo: { viewModel.undo() },
                    onRedo: { viewModel.redo() },
                    onSettings: { showSettings = true },
                    canUndo: viewModel.undoRedoManager.canUndo,
                    canRedo: viewModel.undoRedoManager.canRedo
                )

                if primaryMenu != nil {
                    HStack {
                        Spacer()
                        EzButton(
                            "Șterge meniul",
                            icon: "trash",
                            style: .danger,
                            size: .medium
                        ) {
                            showDeleteMenuConfirmation = true
                        }
                        .disabled(viewModel.isGeneratingMenu)
                        Spacer()
                    }
                    .padding(.horizontal, EzSpacing.md)
                    .padding(.top, EzSpacing.sm)
                    .padding(.bottom, EzSpacing.xs)
                    .background(EzColors.Background.primary)
                }
                
                // Main Content
                ZStack {
                    if let primaryMenu = primaryMenu {
                        // Weekly View (REDESIGN 4.0)
                        WeeklyMenuView(menu: primaryMenu) {
                            selectedMenu = primaryMenu
                        }
                    } else {
                        // Empty State - No Menu
                        VStack(spacing: EzSpacing.xl) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 64, weight: .thin))
                                .foregroundColor(EzColors.Text.tertiary)
                            
                            VStack(spacing: EzSpacing.xs) {
                                Text("Niciun meniu planificat")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(EzColors.Text.primary)
                                    .multilineTextAlignment(.center)
                                
                                Text("Începe prin a crea un meniu manual sau generează unul automat.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(EzColors.Text.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, EzSpacing.lg)
                            }
                            
                            VStack(spacing: EzSpacing.md) {
                                EzButton(
                                    "Generează meniu automat",
                                    icon: "wand.and.stars",
                                    style: .primary,
                                    size: .medium
                                ) {
                                    viewModel.generateRandomMenu()
                                }
                                .disabled(viewModel.isGeneratingMenu)
                                
                                EzButton(
                                    "Crează meniu manual",
                                    icon: "pencil",
                                    style: .secondary,
                                    size: .medium
                                ) {
                                    showAddMenu = true
                                }
                            }
                            .padding(.horizontal, EzSpacing.xl)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            
            // Add/Settings Sheets
            .sheet(isPresented: $showAddMenu) {
                AddMenuView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    HouseholdSettingsSheet(isPresented: $showSettings)
                        .environmentObject(householdManager)
                }
            }
            .sheet(item: $selectedMenu) { menu in
                NavigationStack {
                    MenuEditorView(menu: menu)
                }
            }
        }
        .background(EzColors.Background.primary)
        .overlay {
            if showDeleteMenuConfirmation, let menu = primaryMenu {
                DeleteMenuConfirmationOverlay(
                    isPresented: $showDeleteMenuConfirmation,
                    menuName: menu.name,
                    onConfirm: {
                        HapticManager.Context.delete()
                        viewModel.deleteMenu(menu)
                    }
                )
            }
        }
        .onAppear {
            viewModel.fetchMenus()
        }
    }
}

// MARK: - Delete Confirmation Overlay
struct DeleteMenuConfirmationOverlay: View {
    @Binding var isPresented: Bool
    let menuName: String
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack(alignment: .center) {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Confirmation Card (compact, centered)
            VStack(spacing: 0) {
                // Title
                VStack(spacing: 2) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(EzColors.Accent.danger)
                    
                    Text("Șterge meniul?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(EzColors.Text.primary)
                    
                    Text("Va fi șters definitiv.")
                        .font(.system(size: 11))
                        .foregroundColor(EzColors.Text.secondary)
                        .lineLimit(1)
                }
                .padding(6)
                
                Divider()
                    .frame(height: 0.5)
                    .background(EzColors.Background.tertiary)
                
                // Actions
                HStack(spacing: 0) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Anulează")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(EzColors.Text.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    
                    Divider()
                        .background(EzColors.Background.tertiary)
                    
                    Button(action: {
                        onConfirm()
                        isPresented = false
                    }) {
                        Text("Șterge")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(EzColors.Accent.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                }
            }
            .background(EzColors.Background.secondary)
            .cornerRadius(EzSpacing.xs)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .frame(maxWidth: 240, maxHeight: 140)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

#Preview {
    MenuListView()
        .environmentObject(MenuListViewModel())
}
