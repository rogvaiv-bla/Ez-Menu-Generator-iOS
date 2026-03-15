import SwiftUI

/// REDESIGN 2.0 - Typography System
/// Font: Inter (open source, modern)
/// Fallback: System SF Pro
struct EzTypography {
    
    // MARK: - Font Definitions
    
    /// Display: 24px, weight 700, line-height 32px
    /// Usage: Page titles, major headings
    struct Display {
        static let font = Font.system(size: 24, weight: .bold, design: .default)
        static let lineHeight: CGFloat = 32
    }
    
    /// Headline: 18px, weight 600, line-height 24px
    /// Usage: Section headers, card titles
    struct Headline {
        static let font = Font.system(size: 18, weight: .semibold, design: .default)
        static let lineHeight: CGFloat = 24
    }
    
    /// Title: 16px, weight 600, line-height 22px
    /// Usage: Card titles, tab labels, important text
    struct Title {
        static let font = Font.system(size: 16, weight: .semibold, design: .default)
        static let lineHeight: CGFloat = 22
    }
    
    /// Body: 14px, weight 400, line-height 20px
    /// Usage: Main content, descriptions, body text
    struct Body {
        static let font = Font.system(size: 14, weight: .regular, design: .default)
        static let lineHeight: CGFloat = 20
    }
    
    /// Label: 12px, weight 500, line-height 16px
    /// Usage: Tags, captions, small UI text
    struct Label {
        static let font = Font.system(size: 12, weight: .medium, design: .default)
        static let lineHeight: CGFloat = 16
    }
    
    /// Helper: 11px, weight 400, line-height 16px
    /// Usage: Timestamps, hints, secondary captions
    struct Helper {
        static let font = Font.system(size: 11, weight: .regular, design: .default)
        static let lineHeight: CGFloat = 16
    }
    
    // MARK: - Semantic Typography
    
    /// Button text: 16px, weight 600
    struct Button {
        static let font = Font.system(size: 16, weight: .semibold, design: .default)
    }
    
    /// TextField placeholder text: 14px, weight 400
    struct Placeholder {
        static let font = Font.system(size: 14, weight: .regular, design: .default)
    }
    
    /// Badge/chip text: 12px, weight 500
    struct Badge {
        static let font = Font.system(size: 12, weight: .medium, design: .default)
    }
    
    /// Score numeric: 18px, weight 700
    struct Score {
        static let font = Font.system(size: 18, weight: .bold, design: .default)
    }
}

// MARK: - Text View Modifiers

extension Text {
    /// Page titles and major headings
    func displayStyle() -> some View {
        self
            .font(EzTypography.Display.font)
            .lineSpacing(EzTypography.Display.lineHeight - 24)
            .foregroundColor(EzColors.Text.primary)
    }
    
    /// Section headers
    func headlineStyle() -> some View {
        self
            .font(EzTypography.Headline.font)
            .lineSpacing(EzTypography.Headline.lineHeight - 18)
            .foregroundColor(EzColors.Text.primary)
    }
    
    /// Card titles, tab labels
    func titleStyle() -> some View {
        self
            .font(EzTypography.Title.font)
            .lineSpacing(EzTypography.Title.lineHeight - 16)
            .foregroundColor(EzColors.Text.primary)
    }
    
    /// Main content
    func bodyStyle() -> some View {
        self
            .font(EzTypography.Body.font)
            .lineSpacing(EzTypography.Body.lineHeight - 14)
            .foregroundColor(EzColors.Text.primary)
    }
    
    /// Secondary text, captions
    func bodySecondaryStyle() -> some View {
        self
            .font(EzTypography.Body.font)
            .lineSpacing(EzTypography.Body.lineHeight - 14)
            .foregroundColor(EzColors.Text.secondary)
    }
    
    /// Tags, labels, small UI
    func ezLabelStyle() -> some View {
        self
            .font(EzTypography.Label.font)
            .lineSpacing(EzTypography.Label.lineHeight - 12)
            .foregroundColor(EzColors.Text.secondary)
    }
    
    /// Timestamps, hints
    func helperStyle() -> some View {
        self
            .font(EzTypography.Helper.font)
            .lineSpacing(EzTypography.Helper.lineHeight - 11)
            .foregroundColor(EzColors.Text.tertiary)
    }
    
    /// Score numbers
    func scoreStyle() -> some View {
        self
            .font(EzTypography.Score.font)
            .foregroundColor(EzColors.Text.primary)
    }
    
    /// Disabled/hint text
    func disabledStyle() -> some View {
        self
            .font(EzTypography.Body.font)
            .foregroundColor(EzColors.Text.tertiary)
    }
}

// MARK: - TextField Modifiers

extension TextField {
    /// Apply consistent styling to text fields
    func ezTextFieldStyle() -> some View {
        self
            .font(EzTypography.Body.font)
            .foregroundColor(EzColors.Text.primary)
    }
}

// MARK: - Button Text Modifiers

extension Button {
    /// Apply consistent styling to button text
    func ezButtonTextStyle() -> some View {
        self
            .font(EzTypography.Button.font)
            .foregroundColor(.white)
    }
    
    /// Secondary button text
    func ezSecondaryButtonTextStyle() -> some View {
        self
            .font(EzTypography.Button.font)
            .foregroundColor(EzColors.Accent.primary)
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Apply accessibility-friendly line height for body text
    func accessibleLineHeight() -> some View {
        self.lineSpacing(4) // Add 4pt for better readability
    }
}

// MARK: - Font Scaling (for future Dynamic Type support)

struct ScaledTypography {
    /// Get font scaled to preferred size category
    static func scaledFont(_ fontStyle: Font) -> Font {
        // Future: can be enhanced with @Environment(\.sizeCategory)
        return fontStyle
    }
}
