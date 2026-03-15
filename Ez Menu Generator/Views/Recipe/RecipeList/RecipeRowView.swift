import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: EzSpacing.lg) {
                // Category Icon - Large & Visual
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(
                            (EzColors.categoryColors[recipe.category] ?? EzColors.Accent.primary)
                                .opacity(0.15)
                        )
                    
                    VStack {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(
                                EzColors.categoryColors[recipe.category] ?? EzColors.Accent.primary
                            )
                    }
                }
                .frame(width: 60, height: 60)
                
                // Recipe Info
                VStack(alignment: .leading, spacing: EzSpacing.sm) {
                    // Recipe Name
                    Text(recipe.name)
                        .font(EzTypography.Headline.font)
                        .foregroundColor(EzColors.Text.primary)
                        .lineLimit(2)
                    
                    // Category Badge
                    Text(recipe.category)
                        .font(EzTypography.Helper.font)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, EzSpacing.sm)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .fill(EzColors.categoryColors[recipe.category] ?? EzColors.Accent.primary)
                        )
                    
                    // Meal Type Tags
                    if recipe.hasMealType {
                        HStack(spacing: EzSpacing.xs) {
                            if recipe.isBreakfast {
                                MealTypeTag(label: "Mic dejun", color: EzColors.Accent.warning)
                            }
                            if recipe.isLunch {
                                MealTypeTag(label: "Prânz", color: EzColors.NutritionScore.fair)
                            }
                            if recipe.isDinner {
                                MealTypeTag(label: "Cină", color: EzColors.Accent.primary)
                            }
                            if recipe.isDessert {
                                MealTypeTag(label: "Desert", color: EzColors.Accent.danger)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Right Info Stack
                VStack(alignment: .center, spacing: EzSpacing.sm) {
                    // Time Badge
                    HStack(spacing: EzSpacing.xs) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text("\(recipe.prepTimeMinutes + recipe.cookTimeMinutes)'")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(EzSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.Colors.primary.opacity(0.1))
                    )
                    
                    // Servings
                    HStack(spacing: EzSpacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text("\(recipe.servings)")
                            .font(EzTypography.Label.font)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(EzColors.Accent.success)
                    .padding(EzSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(EzColors.Accent.success.opacity(0.1))
                    )
                    
                    Spacer()
                }
                .frame(maxWidth: 70)
            }
            .padding(EzSpacing.lg)
        }
        .premiumCard(elevation: .medium)
        .padding(.horizontal, EzSpacing.md)
        .padding(.vertical, EzSpacing.sm)
        .transition(.scale.combined(with: .opacity))
        .animation(AppTheme.springStandard, value: recipe.id)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(AppTheme.springSnappy, value: isHovered)
        .onHover { hover in
            isHovered = hover
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name)")
        .accessibilityValue("\(recipe.category), \(recipe.prepTimeMinutes + recipe.cookTimeMinutes) minute, \(recipe.servings) porții")
        .accessibilityHint("Apasă pentru a vedea detaliile rețetei")
    }
    
    private var categoryIcon: String {
        switch recipe.category.lowercased() {
        case let c where c.contains("salată"):
            return "leaf.circle.fill"
        case let c where c.contains("supă"):
            return "drop.circle.fill"
        case let c where c.contains("carne"):
            return "flame.circle.fill"
        case let c where c.contains("pește"):
            return "fish.fill"
        case let c where c.contains("paste"):
            return "fork.knife.circle.fill"
        case let c where c.contains("sos"):
            return "drops.fill"
        case let c where c.contains("desert"):
            return "cake.fill"
        case let c where c.contains("băutură"):
            return "cup.and.saucer.fill"
        case let c where c.contains("mic dejun"):
            return "sun.max.fill"
        default:
            return "fork.knife.circle.fill"
        }
    }
}

// MARK: - Supporting Views

struct MealTypeTag: View {
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(EzTypography.Helper.font)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, EzSpacing.xs)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(color.opacity(0.15))
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: EzSpacing.lg) {
            let recipe = SampleDataService.sampleRecipes.first
            
            if let recipe = recipe {
                RecipeRowView(recipe: recipe)
                RecipeRowView(recipe: recipe)
            }
            
            Spacer()
        }
        .padding(EzSpacing.lg)
    }
    .background(EzColors.Background.primary.ignoresSafeArea())
}
