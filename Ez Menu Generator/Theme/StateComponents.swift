import SwiftUI

/// REDESIGN 3.0 - Reusable State Components
/// Consistent empty, loading, and error states across all views
/// Following Apple HIG for feedback and communication

// MARK: - Empty State Component

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: EzSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(EzColors.Text.tertiary)
            
            VStack(spacing: EzSpacing.xs) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(EzColors.Text.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(EzColors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, EzSpacing.lg)
            }
            
            if let actionTitle = actionTitle, let action = action {
                EzButton(
                    actionTitle,
                    icon: "plus.circle.fill",
                    style: .primary,
                    size: .medium,
                    action: action
                )
                .padding(.top, EzSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message).")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Loading State Component

struct LoadingStateView: View {
    let message: String
    
    init(message: String = "Se încarcă...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: EzSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: EzColors.Accent.primary))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(EzColors.Text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Error State Component

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryTitle: String
    let retryAction: () -> Void
    
    init(
        title: String = "A apărut o eroare",
        message: String,
        retryTitle: String = "Încearcă din nou",
        retryAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: EzSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(EzColors.Accent.warning)
            
            VStack(spacing: EzSpacing.xs) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(EzColors.Text.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(EzColors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, EzSpacing.lg)
            }
            
            EzButton(
                retryTitle,
                icon: "arrow.clockwise",
                style: .secondary,
                size: .medium,
                action: retryAction
            )
            .padding(.top, EzSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message).")
        .accessibilityHint("Apasă pentru a încerca din nou.")
    }
}

// MARK: - Network Offline Banner

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: EzSpacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))
            
            Text("Offline - modificările vor fi sincronizate automat")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(EzColors.Text.primary)
        .padding(.horizontal, EzSpacing.md)
        .padding(.vertical, EzSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(EzColors.Accent.warning)
        .cornerRadius(8)
        .padding(.horizontal, EzSpacing.md)
        .padding(.top, EzSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline. Modificările vor fi sincronizate automat când revii online.")
    }
}

// MARK: - Success Toast (temporary overlay)

struct SuccessToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: EzSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(EzColors.Accent.success)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(EzColors.Text.primary)
        }
        .padding(.horizontal, EzSpacing.md)
        .padding(.vertical, EzSpacing.sm)
        .background(EzColors.Background.surface)
        .cornerRadius(12)
        .ezShadow(EzShadows.elevated)
    }
}

// MARK: - Common Empty States (pre-configured)

extension EmptyStateView {
    /// Empty state for recipes list
    static func noRecipes(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "fork.knife",
            title: "Nicio rețetă încă",
            message: "Începe prin a adăuga prima ta rețetă sau caută produse pentru inspirație.",
            actionTitle: "Adaugă rețetă",
            action: action
        )
    }
    
    /// Empty state for menus list
    static func noMenus(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "calendar",
            title: "Niciun meniu planificat",
            message: "Creează primul tău meniu săptămânal pentru a organiza mesele.",
            actionTitle: "Creează meniu",
            action: action
        )
    }
    
    /// Empty state for shopping list
    static func noShoppingItems(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "cart",
            title: "Lista de cumpărături este goală",
            message: "Adaugă produse manual sau generează automat din meniul săptămânal.",
            actionTitle: "Adaugă produs",
            action: action
        )
    }
    
    /// Empty state for search results
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "Niciun rezultat",
            message: "Încearcă să folosești alte cuvinte cheie sau verifică ortografia.",
            actionTitle: nil,
            action: nil
        )
    }
}

// MARK: - Common Error States

extension ErrorStateView {
    /// Network error state
    static func networkError(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Eroare de conexiune",
            message: "Nu s-a putut conecta la server. Verifică conexiunea la internet și încearcă din nou.",
            retryAction: retryAction
        )
    }
    
    /// Generic error state
    static func genericError(message: String, retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "A apărut o eroare",
            message: message,
            retryAction: retryAction
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        EmptyStateView.noRecipes(action: {})
            .frame(height: 300)
        
        LoadingStateView()
            .frame(height: 200)
        
        ErrorStateView.networkError(retryAction: {})
            .frame(height: 300)
        
        OfflineBannerView()
        
        SuccessToast(message: "Rețetă salvată")
    }
    .padding()
    .background(EzColors.Background.primary)
    .preferredColorScheme(.dark)
}
