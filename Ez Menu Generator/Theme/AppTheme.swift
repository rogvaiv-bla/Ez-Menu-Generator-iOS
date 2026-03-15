import SwiftUI

/// REDESIGN 2.0 - Premium Main Theme Manager (Apple 2025 Style)
/// Centralized design system with animations, spacing, colors, typography, shadows
struct AppTheme {
    
    // MARK: - Animation Curves (Premium feel)
    static let springStandard = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let springSnappy = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.8, dampingFraction: 0.6)
    
    static let animationDuration: Double = 0.3
    static let animationDurationQuick: Double = 0.15
    static let animationDurationSlow: Double = 0.5
    
    // MARK: - Corner Radius (Apple 2025 design)
    struct CornerRadius {
        /// Small buttons, tight components: 8px
        static let small: CGFloat = 8
        /// Standard cards, components: 12px
        static let medium: CGFloat = 12
        /// Large cards, major containers: 16px
        static let large: CGFloat = 16
        /// Extra large, full-width containers: 20px
        static let extraLarge: CGFloat = 20
    }
    
    // MARK: - Shadow Design (Material 3 style)
    struct Shadows {
        /// No elevation
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        
        /// Elevation 1: Subtle cards
        static let sm = Shadow(
            color: Color.black.opacity(0.08),
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// Elevation 2: Medium cards
        static let md = Shadow(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// Elevation 3: Premium cards, modals
        static let lg = Shadow(
            color: Color.black.opacity(0.16),
            radius: 16,
            x: 0,
            y: 8
        )
        
        /// Elevation 4: Bottom sheets, floating
        static let xl = Shadow(
            color: Color.black.opacity(0.20),
            radius: 24,
            x: 0,
            y: 12
        )
    }
    
    // MARK: - Semantic Colors
    struct Colors {
        // Primary actions
        static let primary = EzColors.Accent.primary
        static let primaryHover = Color(red: 0.65, green: 0.45, blue: 1.0) // Lighter
        
        // Success state
        static let success = EzColors.Accent.success
        static let successHover = Color(red: 0.1, green: 0.95, blue: 0.55)
        
        // Warning state
        static let warning = EzColors.Accent.warning
        static let warningHover = Color(red: 1.0, green: 0.8, blue: 0.4)
        
        // Danger/destructive
        static let danger = EzColors.Accent.danger
        static let dangerHover = Color(red: 1.0, green: 0.52, blue: 0.52)
        
        // Backgrounds
        static let bgPrimary = EzColors.Background.primary
        static let bgSecondary = EzColors.Background.secondary
        static let bgTertiary = EzColors.Background.tertiary
        static let bgSurface = EzColors.Background.surface
        
        // Text
        static let textPrimary = EzColors.Text.primary
        static let textSecondary = EzColors.Text.secondary
        static let textTertiary = EzColors.Text.tertiary
        static let textInverse = Color(red: 0.0, green: 0.0, blue: 0.0)
    }
    
    // MARK: - Dietary Tags Colors
    struct DietaryColors {
        static let vegan = Color(red: 0.14, green: 0.82, blue: 0.42)        // Vibrant Green
        static let vegetarian = Color(red: 0.2, green: 0.85, blue: 0.4)     // Light Green
        static let glutenFree = Color(red: 0.0, green: 0.72, blue: 0.82)    // Cyan
        static let dairyFree = Color(red: 0.95, green: 0.45, blue: 0.2)     // Orange
        static let nutFree = Color(red: 1.0, green: 0.6, blue: 0.2)         // Warm Orange
        static let keto = Color(red: 0.8, green: 0.2, blue: 0.8)            // Magenta
        static let lowCarb = Color(red: 0.9, green: 0.4, blue: 0.1)         // Deep Orange
        static let organic = Color(red: 0.1, green: 0.8, blue: 0.4)         // Fresh Green
        static let kosher = Color(red: 0.4, green: 0.6, blue: 0.95)         // Blue
        static let halal = Color(red: 0.2, green: 0.7, blue: 0.95)          // Sky Blue
        static let paleo = Color(red: 0.9, green: 0.5, blue: 0.2)           // Burnt Orange
        static let rawFood = Color(red: 0.2, green: 0.9, blue: 0.6)         // Turquoise
        static let lowFat = Color(red: 0.95, green: 0.6, blue: 0.1)         // Gold
        static let lowSodium = Color(red: 0.6, green: 0.8, blue: 0.3)       // Lime
        static let highProtein = Color(red: 1.0, green: 0.3, blue: 0.3)     // Coral Red
        static let sugarFree = Color(red: 0.95, green: 0.7, blue: 0.1)      // Bright Gold
    }
    
    // MARK: - Backward Compatibility
    static let categoryColors: [String: Color] = EzColors.categoryColors
    
    static func backgroundColor() -> Color { EzColors.Background.primary }
    static func cardBackground() -> Color { EzColors.Background.secondary }
    static func textPrimary() -> Color { EzColors.Text.primary }
    static func textSecondary() -> Color { EzColors.Text.secondary }
    
}


