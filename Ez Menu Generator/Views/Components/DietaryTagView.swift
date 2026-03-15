import SwiftUI

/// Beautiful dietary tag badge for the 16 dietary restrictions
/// Uses semantic colors and modern design
struct DietaryTagView: View {
    let dietary: String
    var size: TagSize = .medium
    var isSelectable: Bool = false
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    enum TagSize {
        case small
        case medium
        case large
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium:
                return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .large:
                return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 12
            case .large: return 14
            }
        }
    }
    
    var tagColor: Color {
        switch dietary.lowercased() {
        case let d where d.contains("vegan"):
            return AppTheme.DietaryColors.vegan
        case let d where d.contains("vegetarian"):
            return AppTheme.DietaryColors.vegetarian
        case let d where d.contains("gluten"):
            return AppTheme.DietaryColors.glutenFree
        case let d where d.contains("dairy"):
            return AppTheme.DietaryColors.dairyFree
        case let d where d.contains("nut"):
            return AppTheme.DietaryColors.nutFree
        case let d where d.contains("keto"):
            return AppTheme.DietaryColors.keto
        case let d where d.contains("carb"):
            return AppTheme.DietaryColors.lowCarb
        case let d where d.contains("organic"):
            return AppTheme.DietaryColors.organic
        case let d where d.contains("kosher"):
            return AppTheme.DietaryColors.kosher
        case let d where d.contains("halal"):
            return AppTheme.DietaryColors.halal
        case let d where d.contains("paleo"):
            return AppTheme.DietaryColors.paleo
        case let d where d.contains("raw"):
            return AppTheme.DietaryColors.rawFood
        case let d where d.contains("fat"):
            return AppTheme.DietaryColors.lowFat
        case let d where d.contains("sodium"):
            return AppTheme.DietaryColors.lowSodium
        case let d where d.contains("protein"):
            return AppTheme.DietaryColors.highProtein
        case let d where d.contains("sugar"):
            return AppTheme.DietaryColors.sugarFree
        default:
            return AppTheme.DietaryColors.glutenFree
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Icon based on dietary type
            Image(systemName: dietaryIcon)
                .font(.system(size: size.fontSize - 2, weight: .medium))
            
            Text(dietary)
                .font(.system(size: size.fontSize, weight: .medium, design: .default))
        }
        .padding(size.padding)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(tagColor.opacity(isSelected ? 1.0 : 0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .stroke(
                    isSelected ? tagColor : Color.clear,
                    lineWidth: isSelected ? 2 : 0
                )
        )
        .if(isSelectable) { view in
            view.onTapGesture(perform: onTap ?? {})
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    private var dietaryIcon: String {
        switch dietary.lowercased() {
        case let d where d.contains("vegan"):
            return "leaf.fill"
        case let d where d.contains("vegetarian"):
            return "leaf.circle.fill"
        case let d where d.contains("gluten"):
            return "checkmark.shield.fill"
        case let d where d.contains("dairy"):
            return "cup.and.saucer.fill"
        case let d where d.contains("nut"):
            return "hand.raised.fill"
        case let d where d.contains("keto"):
            return "flame.fill"
        case let d where d.contains("carb"):
            return "bolt.fill"
        case let d where d.contains("organic"):
            return "leaf"
        case let d where d.contains("kosher"):
            return "star.fill"
        case let d where d.contains("halal"):
            return "star.circle.fill"
        case let d where d.contains("paleo"):
            return "fork.knife"
        case let d where d.contains("raw"):
            return "apple.fill"
        case let d where d.contains("fat"):
            return "heart.fill"
        case let d where d.contains("sodium"):
            return "drop.fill"
        case let d where d.contains("protein"):
            return "bolt.badge.fill"
        case let d where d.contains("sugar"):
            return "candy.fill"
        default:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: EzSpacing.lg) {
        Text("Dietary Tags - All Sizes")
            .font(EzTypography.Display.font)
            .foregroundColor(EzColors.Text.primary)
            .padding(.horizontal, EzSpacing.lg)
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Small")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
            
            HStack(spacing: EzSpacing.sm) {
                DietaryTagView(dietary: "Vegan", size: .small)
                DietaryTagView(dietary: "Gluten Free", size: .small)
                DietaryTagView(dietary: "Organic", size: .small)
                Spacer()
            }
        }
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Medium (Default)")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
            
            HStack(spacing: EzSpacing.sm) {
                DietaryTagView(dietary: "Vegetarian", size: .medium)
                DietaryTagView(dietary: "Dairy Free", size: .medium)
                DietaryTagView(dietary: "Keto", size: .medium)
                Spacer()
            }
        }
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Large")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
            
            HStack(spacing: EzSpacing.md) {
                DietaryTagView(dietary: "High Protein", size: .large)
                DietaryTagView(dietary: "Low Sodium", size: .large)
                Spacer()
            }
        }
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("All 16 Dietary Types")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
            
            VStack(alignment: .leading, spacing: EzSpacing.sm) {
                HStack(spacing: EzSpacing.sm) {
                    DietaryTagView(dietary: "Vegan", size: .small)
                    DietaryTagView(dietary: "Vegetarian", size: .small)
                    DietaryTagView(dietary: "Gluten Free", size: .small)
                    DietaryTagView(dietary: "Dairy Free", size: .small)
                }
                
                HStack(spacing: EzSpacing.sm) {
                    DietaryTagView(dietary: "Nut Free", size: .small)
                    DietaryTagView(dietary: "Keto", size: .small)
                    DietaryTagView(dietary: "Low Carb", size: .small)
                    DietaryTagView(dietary: "Organic", size: .small)
                }
                
                HStack(spacing: EzSpacing.sm) {
                    DietaryTagView(dietary: "Kosher", size: .small)
                    DietaryTagView(dietary: "Halal", size: .small)
                    DietaryTagView(dietary: "Paleo", size: .small)
                    DietaryTagView(dietary: "Raw Food", size: .small)
                }
                
                HStack(spacing: EzSpacing.sm) {
                    DietaryTagView(dietary: "Low Fat", size: .small)
                    DietaryTagView(dietary: "Low Sodium", size: .small)
                    DietaryTagView(dietary: "High Protein", size: .small)
                    DietaryTagView(dietary: "Sugar Free", size: .small)
                }
            }
        }
        
        Spacer()
    }
    .padding(EzSpacing.lg)
    .background(EzColors.Background.primary.ignoresSafeArea())
}
