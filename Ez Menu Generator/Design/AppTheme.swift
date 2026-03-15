import SwiftUI

/// REDESIGN 2.0 - Main Theme Manager
/// Dark mode first, uses EzColors + EzSpacing + EzTypography
/// Kept for backward compatibility during migration
struct AppTheme {
    
    // MARK: - Animation
    static let animationDuration: Double = 0.3
    static let animationDurationQuick: Double = 0.15
    static let animationDurationSlow: Double = 0.5
    
    // MARK: - NEW SYSTEM: Use EzColors instead
    // Colors are now in Colors.swift (EzColors)
    
    // MARK: - DEPRECATED: Legacy Spacing (use EzSpacing instead)
    /// Deprecated - Use EzSpacing instead
    static let spacing8: CGFloat = 8
    /// Deprecated - Use EzSpacing instead
    static let spacing12: CGFloat = 12
    /// Deprecated - Use EzSpacing instead
    static let spacing16: CGFloat = 16
    /// Deprecated - Use EzSpacing instead
    static let spacing20: CGFloat = 20
    
    // MARK: - DEPRECATED: Legacy Colors (use EzColors instead)
    /// Deprecated - Use EzColors.Accent.primary instead
    static let primary = Color(red: 0.2, green: 0.6, blue: 0.8)  // #3399CC
    /// Deprecated - Use EzColors.Accent.warning instead
    static let secondary = Color(red: 1.0, green: 0.6, blue: 0.2)  // #FF9933
    /// Deprecated - Use EzColors.Accent.success instead
    static let accent = Color(red: 0.2, green: 0.8, blue: 0.4)  // #33CC66
    
    // MARK: - Backward Compatibility Adapters
    /// Use EzColors.Background.primary instead
    static func backgroundColor() -> Color {
        EzColors.Background.primary
    }
    
    /// Use EzColors.Background.secondary instead
    static func cardBackground() -> Color {
        EzColors.Background.secondary
    }
    
    /// Use EzColors.Text.primary instead
    static func textPrimary() -> Color {
        EzColors.Text.primary
    }
    
    /// Use EzColors.Text.secondary instead
    static func textSecondary() -> Color {
        EzColors.Text.secondary
    }
    
    // MARK: - DEPRECATED: Legacy static colors
    /// Deprecated - Use EzColors instead
    static let backgroundLight = Color(red: 0.98, green: 0.98, blue: 0.99)
    /// Deprecated - Use EzColors instead
    static let backgroundDark = Color(red: 0.11, green: 0.11, blue: 0.12)
    /// Deprecated - Use EzColors instead
    static let cardLight = Color.white
    /// Deprecated - Use EzColors instead
    static let cardDark = Color(red: 0.17, green: 0.17, blue: 0.18)
    /// Deprecated - Use EzColors instead
    static let textPrimaryLegacy = Color(red: 0.1, green: 0.1, blue: 0.1)
    /// Deprecated - Use EzColors instead
    static let textSecondaryLegacy = Color(red: 0.6, green: 0.6, blue: 0.6)
    /// Deprecated - Use EzColors instead
    static let textLight = Color.white
    
    // Category Colors - matches SampleDataService categories
    // Kept for backward compatibility
    static let categoryColors: [String: Color] = EzColors.categoryColors
    
}

// MARK: - Text View Modifiers (DEPRECATED - use EzTypography instead)
extension Text {
    /// Deprecated - Use displayStyle(), headlineStyle(), etc. from EzTypography instead
    func themeTitle() -> some View {
        self
            .font(.system(size: 28, weight: .bold, design: .default))
            .foregroundColor(EzColors.Text.primary)
    }
    
    /// Deprecated - Use headlineStyle() from EzTypography instead
    func themeHeadline() -> some View {
        self
            .font(.system(size: 18, weight: .semibold, design: .default))
            .foregroundColor(EzColors.Text.primary)
    }
    
    /// Deprecated - Use bodySecondaryStyle() from EzTypography instead
    func themeSubheadline() -> some View {
        self
            .font(.system(size: 16, weight: .medium, design: .default))
            .foregroundColor(EzColors.Text.secondary)
    }
    
    /// Deprecated - Use labelStyle() from EzTypography instead
    func themeCaption() -> some View {
        self
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundColor(EzColors.Text.secondary)
    }
}

// MARK: - Button Styles (DEPRECATED - use EzColors instead)
extension Button {
    /// Deprecated - Use EzColors.Accent.primary for styling
    func themePrimary() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(EzColors.Accent.primary)
            .cornerRadius(EzSpacing.Card.cornerRadius)
    }
    
    /// Deprecated - Use EzColors.Accent.primary with opacity
    func themeSecondary() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(EzColors.Accent.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(EzColors.Accent.primary.opacity(0.1))
            .cornerRadius(EzSpacing.Card.cornerRadius)
    }
}

// MARK: - View Extensions (DEPRECATED - use cardPadding() instead)
extension View {
    /// Deprecated - Use cardPadding() modifier from EzSpacing instead
    func themeCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: EzSpacing.Card.cornerRadius)
                    .fill(EzColors.Background.secondary)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: EzSpacing.Card.shadowRadius,
                        x: 0,
                        y: EzSpacing.Card.shadowY
                    )
            )
            .padding(.horizontal, EzSpacing.Component.padding)
    }
}
