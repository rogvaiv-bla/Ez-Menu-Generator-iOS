import SwiftUI

/// Custom navigation bar for redesigned UI
/// Structure: [<] [Context] [Search] [↶ Undo] [↷ Redo] [Settings]
struct NavigationBarView: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    let onSearch: (() -> Void)?
    let onPrimaryAction: (() -> Void)?
    let primaryActionIcon: String
    let onUndo: (() -> Void)?
    let onRedo: (() -> Void)?
    let onSettings: (() -> Void)?
    let settingsIcon: String
    let canUndo: Bool
    let canRedo: Bool
    
    init(
        title: String,
        showBackButton: Bool = false,
        onBack: (() -> Void)? = nil,
        onSearch: (() -> Void)? = nil,
        onPrimaryAction: (() -> Void)? = nil,
        primaryActionIcon: String = "plus",
        onUndo: (() -> Void)? = nil,
        onRedo: (() -> Void)? = nil,
        onSettings: (() -> Void)? = nil,
        settingsIcon: String = "gear",
        canUndo: Bool = false,
        canRedo: Bool = false
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.onSearch = onSearch
        self.onPrimaryAction = onPrimaryAction
        self.primaryActionIcon = primaryActionIcon
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onSettings = onSettings
        self.settingsIcon = settingsIcon
        self.canUndo = canUndo
        self.canRedo = canRedo
    }
    
    var body: some View {
        HStack(spacing: EzSpacing.sm) {
            // [<] Back Button
            if showBackButton {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(EzColors.Text.primary)
                }
                .frame(width: 32, height: 32)
            }
            
            // [Context] Title
            Text(title)
                .titleStyle()
                .lineLimit(1)
            
            Spacer()
            
            // [🔍] Search Button
            if let onSearch = onSearch {
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(EzColors.Text.primary)
                }
                .frame(width: 32, height: 32)
            }

            // [＋] Primary Action Button
            if let onPrimaryAction = onPrimaryAction {
                Button(action: onPrimaryAction) {
                    Image(systemName: primaryActionIcon)
                        .font(.system(size: 16))
                        .foregroundColor(EzColors.Text.primary)
                }
                .frame(width: 32, height: 32)
            }
            
            // [↶] Undo Button (shown only when available)
            if let onUndo = onUndo, canUndo {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16))
                        .foregroundColor(EzColors.Accent.primary)
                }
                .frame(width: 32, height: 32)
                .accessibilityLabel("Undo")
                .accessibilityHint("Undo the last action")
            }
            
            // [↷] Redo Button (shown only when available)
            if let onRedo = onRedo, canRedo {
                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16))
                        .foregroundColor(EzColors.Accent.primary)
                }
                .frame(width: 32, height: 32)
                .accessibilityLabel("Redo")
                .accessibilityHint("Redo the last undone action")
            }
            
            // [⚙️] Settings Button
            if let onSettings = onSettings {
                Button(action: onSettings) {
                    Image(systemName: settingsIcon)
                        .font(.system(size: 16))
                        .foregroundColor(EzColors.Text.primary)
                }
                .frame(width: 32, height: 32)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, EzSpacing.md)
        .background(EzColors.Background.secondary)
        .overlay(alignment: .bottom) {
            Divider()
                .foregroundColor(EzColors.Background.tertiary.opacity(0.5))
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        // Without back button
        NavigationBarView(
            title: "Home",
            showBackButton: false,
            onSearch: {},
            onSettings: {}
        )
        
        Spacer()
        
        // With back button
        NavigationBarView(
            title: "Recipe Details",
            showBackButton: true,
            onBack: {},
            onSearch: {},
            onSettings: {}
        )
        
        Spacer()
    }
    .background(EzColors.Background.primary)
}
