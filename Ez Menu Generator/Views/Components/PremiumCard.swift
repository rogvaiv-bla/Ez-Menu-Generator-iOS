import SwiftUI

/// Premium card component with elevation, shadow, and material design
/// Styled for Apple 2025 aesthetic
struct PremiumCard<Content: View>: View {
    let content: Content
    var elevation: Elevation = .medium
    var backgroundColor: Color = EzColors.Background.secondary
    var padding: CGFloat = EzSpacing.md
    var onTap: (() -> Void)? = nil
    
    // MARK: - Elevation Levels
    enum Elevation {
        case none
        case small
        case medium
        case large
        
        var shadow: (color: Color, radius: CGFloat, y: CGFloat) {
            switch self {
            case .none:
                return (Color.clear, 0, 0)
            case .small:
                return (Color.black.opacity(0.08), 2, 1)
            case .medium:
                return (Color.black.opacity(0.12), 8, 4)
            case .large:
                return (Color.black.opacity(0.16), 16, 8)
            }
        }
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(backgroundColor)
            )
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: 0,
                y: elevation.shadow.y
            )
            .if(onTap != nil) { view in
                view.onTapGesture(perform: onTap ?? {})
            }
    }
}

/// Inline card modifier for easy usage
extension View {
    func premiumCard(
        elevation: PremiumCard<EmptyView>.Elevation = .medium,
        backgroundColor: Color = EzColors.Background.secondary,
        padding: CGFloat = EzSpacing.md,
        onTap: (() -> Void)? = nil
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(backgroundColor)
            )
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: 0,
                y: elevation.shadow.y
            )
            .if(onTap != nil) { view in
                view.onTapGesture(perform: onTap ?? {})
            }
    }
}

/// Conditional modifier helper
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    VStack(spacing: EzSpacing.lg) {
        // Small elevation
        VStack(alignment: .leading, spacing: EzSpacing.sm) {
            Text("Small Elevation Card")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.primary)
            Text("Subtle shadow for secondary content")
                .font(EzTypography.Body.font)
                .foregroundColor(EzColors.Text.secondary)
        }
        .premiumCard(elevation: .small)
        
        // Medium elevation (default)
        VStack(alignment: .leading, spacing: EzSpacing.sm) {
            Text("Medium Elevation Card")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.primary)
            Text("Standard card for main content")
                .font(EzTypography.Body.font)
                .foregroundColor(EzColors.Text.secondary)
        }
        .premiumCard()
        
        // Large elevation
        VStack(alignment: .leading, spacing: EzSpacing.sm) {
            Text("Large Elevation Card")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.primary)
            Text("Deep shadow for premium feel")
                .font(EzTypography.Body.font)
                .foregroundColor(EzColors.Text.secondary)
        }
        .premiumCard(elevation: .large)
        
        Spacer()
    }
    .padding(EzSpacing.lg)
    .background(EzColors.Background.primary.ignoresSafeArea())
}
