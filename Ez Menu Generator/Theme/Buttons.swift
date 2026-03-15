import SwiftUI

/// REDESIGN 3.0 - Button System
/// Consistent button styles following Apple HIG
/// Three variants: Primary, Secondary, Tertiary
/// Three sizes: Large, Medium, Small

// MARK: - Button Style Enum

enum EzButtonStyle {
    case primary        // Filled with accent color
    case secondary      // Outlined with accent color
    case tertiary       // Ghost/text only
    case danger         // Filled with danger color
    case success        // Filled with success color
}

enum EzButtonSize {
    case large          // 48pt height - CTA, forms
    case medium         // 40pt height - modal actions
    case small          // 32pt height - inline actions
    
    var height: CGFloat {
        switch self {
        case .large: return 48
        case .medium: return 40
        case .small: return 32
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .large: return 24
        case .medium: return 20
        case .small: return 16
        }
    }
    
    var font: Font {
        switch self {
        case .large: return .system(size: 16, weight: .semibold)
        case .medium: return .system(size: 15, weight: .semibold)
        case .small: return .system(size: 14, weight: .medium)
        }
    }
}

private struct EzPressFeedbackStyle: ButtonStyle {
    let pressedScale: CGFloat
    let pressedOpacity: Double
    let animation: Animation

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}

// MARK: - EzButton Component

struct EzButton: View {
    let title: String
    let icon: String?
    let style: EzButtonStyle
    let size: EzButtonSize
    let action: () -> Void
    let fullWidth: Bool
    
    init(
        _ title: String,
        icon: String? = nil,
        style: EzButtonStyle = .primary,
        size: EzButtonSize = .large,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                Text(title)
                    .font(size.font)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(12)
        }
        .buttonStyle(
            EzPressFeedbackStyle(
                pressedScale: 0.96,
                pressedOpacity: 0.8,
                animation: .easeInOut(duration: 0.1)
            )
        )
    }
    
    // MARK: - Style Computation
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return EzColors.Accent.primary
        case .secondary:
            return Color.clear
        case .tertiary:
            return Color.clear
        case .danger:
            return EzColors.Accent.danger
        case .success:
            return EzColors.Accent.success
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .danger, .success:
            return EzColors.Text.primary
        case .secondary:
            return EzColors.Accent.primary
        case .tertiary:
            return EzColors.Text.secondary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .danger, .success:
            return Color.clear
        case .secondary:
            return EzColors.Accent.primary
        case .tertiary:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        style == .secondary ? 1.5 : 0
    }
}

// MARK: - Icon-Only Button (for toolbars)

struct EzIconButton: View {
    let icon: String
    let style: EzButtonStyle
    let size: CGFloat
    let action: () -> Void
    
    init(
        icon: String,
        style: EzButtonStyle = .tertiary,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .cornerRadius(size / 4)
        }
        .buttonStyle(
            EzPressFeedbackStyle(
                pressedScale: 0.9,
                pressedOpacity: 1.0,
                animation: .easeInOut(duration: 0.1)
            )
        )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return EzColors.Accent.primary
        case .secondary:
            return EzColors.Background.tertiary
        case .tertiary:
            return Color.clear
        case .danger:
            return EzColors.Accent.danger.opacity(0.1)
        case .success:
            return EzColors.Accent.success.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return EzColors.Text.primary
        case .secondary:
            return EzColors.Accent.primary
        case .tertiary:
            return EzColors.Text.secondary
        case .danger:
            return EzColors.Accent.danger
        case .success:
            return EzColors.Accent.success
        }
    }
}

// MARK: - Floating Action Button

struct EzFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(EzColors.Text.primary)
                .frame(width: 56, height: 56)
                .background(EzColors.Accent.primary)
                .clipShape(Circle())
                .ezShadow(EzShadows.floating)
        }
        .buttonStyle(
            EzPressFeedbackStyle(
                pressedScale: 0.92,
                pressedOpacity: 1.0,
                animation: .spring(response: 0.3, dampingFraction: 0.6)
            )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        EzButton("Save Recipe", icon: "checkmark.circle.fill", style: .primary, size: .large, fullWidth: true, action: {})
        EzButton("Cancel", style: .secondary, size: .large, fullWidth: true, action: {})
        EzButton("Delete", icon: "trash", style: .danger, size: .medium, action: {})
        EzButton("Add to Favorites", icon: "heart", style: .success, size: .small, action: {})
        
        HStack(spacing: 16) {
            EzIconButton(icon: "pencil", style: .secondary, action: {})
            EzIconButton(icon: "trash", style: .danger, action: {})
            EzIconButton(icon: "heart.fill", style: .success, action: {})
        }
        
        EzFloatingActionButton(icon: "plus", action: {})
    }
    .padding()
    .background(EzColors.Background.primary)
    .preferredColorScheme(.dark)
}
