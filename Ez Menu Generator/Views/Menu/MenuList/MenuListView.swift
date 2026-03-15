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
                if let primaryMenu = primaryMenu {
                    // Weekly View (REDESIGN 4.0)
                    WeeklyMenuView(menu: primaryMenu) {
                        selectedMenu = primaryMenu
                    }
                } else {
                    // Premium Empty State
                    ScrollView {
                        VStack(spacing: 0) {
                            EmptyStateView.noMenus(action: {
                                showAddMenu = true
                            })
                            
                            Spacer()
                                .frame(height: EzSpacing.xxl)
                            
                            // Quick Actions Section
                            VStack(alignment: .leading, spacing: EzSpacing.md) {
                                Text("Quick Actions")
                                    .font(EzTypography.Headline.font)
                                    .foregroundColor(EzColors.Text.primary)
                                    .padding(.horizontal, EzSpacing.lg)
                                
                                VStack(spacing: EzSpacing.md) {
                                    QuickActionButton(
                                        icon: "wand.and.stars",
                                        title: "Auto-Generate Menu",
                                        description: "Create a balanced weekly menu with a single tap",
                                        action: {
                                            viewModel.generateRandomMenu()
                                        },
                                        isLoading: viewModel.isGeneratingMenu
                                    )
                                    
                                    QuickActionButton(
                                        icon: "pencil",
                                        title: "Create Manually",
                                        description: "Build your own custom menu from scratch",
                                        action: {
                                            showAddMenu = true
                                        }
                                    )
                                }
                                .padding(.horizontal, EzSpacing.lg)
                            }
                            .padding(.vertical, EzSpacing.xl)
                        }
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

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    var isLoading: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: EzSpacing.lg) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(AppTheme.Colors.primary.opacity(0.1))
                    )
                
                // Text Content
                VStack(alignment: .leading, spacing: EzSpacing.xs) {
                    Text(title)
                        .font(EzTypography.Headline.font)
                        .foregroundColor(EzColors.Text.primary)
                    
                    Text(description)
                        .font(EzTypography.Body.font)
                        .foregroundColor(EzColors.Text.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron
                if !isLoading {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(EzColors.Text.tertiary)
                } else {
                    ProgressView()
                        .tint(AppTheme.Colors.primary)
                }
            }
            .padding(EzSpacing.lg)
        }
        .disabled(isLoading)
        .premiumCard(elevation: .medium)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.springSnappy, value: isPressed)
        .gesture(
            LongPressGesture(minimumDuration: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

#Preview {
    MenuListView()
        .environmentObject(MenuListViewModel())
}
