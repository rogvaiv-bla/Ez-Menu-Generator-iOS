import SwiftUI

/// REDESIGN 3.0 - Shadow System
/// Consistent elevation and depth for UI elements
/// All shadows optimized for dark mode (#0A0E27 background)
struct EzShadows {
    
    // MARK: - Elevation Levels
    
    /// Level 0: No shadow (flat elements)
    static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
    
    /// Level 1: Subtle elevation for cards
    /// Usage: Recipe cards, shopping items, list rows
    static let card = Shadow(
        color: Color.black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 2
    )
    
    /// Level 2: Medium elevation for floating elements
    /// Usage: Modal sheets, dropdowns, popovers
    static let elevated = Shadow(
        color: Color.black.opacity(0.20),
        radius: 16,
        x: 0,
        y: 4
    )
    
    /// Level 3: High elevation for FABs
    /// Usage: Floating Action Buttons, key interactive elements
    static let floating = Shadow(
        color: EzColors.Accent.primary.opacity(0.4),
        radius: 8,
        x: 0,
        y: 4
    )
    
    /// Level 4: Maximum elevation for alerts/modals
    /// Usage: Critical alerts, overlays requiring attention
    static let modal = Shadow(
        color: Color.black.opacity(0.30),
        radius: 24,
        x: 0,
        y: 8
    )
    
    // MARK: - Context-Specific Shadows
    
    /// Accent-colored shadow for primary actions
    static let accentGlow = Shadow(
        color: EzColors.Accent.primary.opacity(0.4),
        radius: 12,
        x: 0,
        y: 4
    )
    
    /// Success-colored shadow for confirmation actions
    static let successGlow = Shadow(
        color: EzColors.Accent.success.opacity(0.4),
        radius: 12,
        x: 0,
        y: 4
    )
    
    /// Danger-colored shadow for destructive actions
    static let dangerGlow = Shadow(
        color: EzColors.Accent.danger.opacity(0.4),
        radius: 12,
        x: 0,
        y: 4
    )
    
    // MARK: - Inner Shadows (using overlays)
    
    /// Inset shadow effect (implement with overlay)
    static let inset = Shadow(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )
}

// MARK: - Shadow Model

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extension for Easy Application

extension View {
    /// Apply a shadow from the EzShadows system
    func ezShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply card shadow (most common)
    func cardShadow() -> some View {
        self.ezShadow(EzShadows.card)
    }
    
    /// Apply elevated shadow
    func elevatedShadow() -> some View {
        self.ezShadow(EzShadows.elevated)
    }
    
    /// Apply floating shadow (for FABs)
    func floatingShadow() -> some View {
        self.ezShadow(EzShadows.floating)
    }
}
