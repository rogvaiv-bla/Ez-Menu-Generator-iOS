import SwiftUI

struct MenuListItemView: View {
    let menu: Menu
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium Header with Gradient
            VStack(alignment: .leading, spacing: EzSpacing.sm) {
                HStack(alignment: .top, spacing: EzSpacing.md) {
                    VStack(alignment: .leading, spacing: EzSpacing.xs) {
                        Text(menu.name)
                            .font(EzTypography.Headline.font)
                            .foregroundColor(EzColors.Text.primary)
                        
                        HStack(spacing: EzSpacing.sm) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(EzColors.Accent.primary)
                            
                            Text(menu.weekStartDate.formatted(date: .abbreviated, time: .omitted))
                                .font(EzTypography.Label.font)
                                .foregroundColor(EzColors.Text.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Recipe Count Badge
                    VStack(spacing: EzSpacing.xs) {
                        Text("\(recipesCount)")
                            .font(EzTypography.Display.font)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("recipes")
                            .font(EzTypography.Helper.font)
                            .foregroundColor(EzColors.Text.secondary)
                    }
                    .padding(EzSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.Colors.primary.opacity(0.1))
                    )
                }
            }
            .padding(EzSpacing.md)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        EzColors.Background.secondary,
                        EzColors.Background.secondary.opacity(0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Content
            VStack(spacing: EzSpacing.md) {
                // 7-day Progress Indicator
                VStack(alignment: .leading, spacing: EzSpacing.sm) {
                    Text("Weekly Schedule")
                        .font(EzTypography.Label.font)
                        .foregroundColor(EzColors.Text.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(spacing: EzSpacing.sm) {
                        ForEach(0..<7, id: \.self) { day in
                            VStack(spacing: 4) {
                                Text(["L", "M", "M", "J", "V", "S", "D"][day])
                                    .font(EzTypography.Helper.font)
                                    .fontWeight(.semibold)
                                    .foregroundColor(EzColors.Text.secondary)
                                
                                Circle()
                                    .fill(
                                        hasRecipeForDay(day)
                                            ? AppTheme.Colors.primary
                                            : EzColors.Background.tertiary
                                    )
                                    .frame(width: 10, height: 10)
                                    .shadow(
                                        color: hasRecipeForDay(day)
                                            ? AppTheme.Colors.primary.opacity(0.5)
                                            : Color.clear,
                                        radius: hasRecipeForDay(day) ? 4 : 0
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                // Nutrition Summary (Compact)
                NutritionSummaryView(
                    calories: totalCalories,
                    protein: totalProtein,
                    carbs: totalCarbs,
                    fat: totalFat,
                    displayMode: .compact
                )
                
                // Dietary Tags
                dietaryTagsView
                
                // Edit Button
                Button(action: {}) {
                    HStack(spacing: EzSpacing.sm) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Edit Menu")
                            .font(EzTypography.Button.font)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, EzSpacing.md)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(AppTheme.Colors.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(AppTheme.springSnappy, value: isHovered)
            }
            .padding(EzSpacing.md)
        }
        .premiumCard(elevation: .medium)
        .padding(.horizontal, EzSpacing.md)
        .padding(.vertical, EzSpacing.xs)
        .transition(.scale.combined(with: .opacity))
        .animation(AppTheme.springStandard, value: menu.id)
        .onHover { hover in
            isHovered = hover
        }
    }
    
    // MARK: - Computed Properties
    
    private var recipesCount: Int {
        var count = 0
        for meal in menu.meals {
            if meal.breakfast != nil { count += 1 }
            if meal.lunch != nil { count += 1 }
            if meal.dinner != nil { count += 1 }
        }
        return count
    }
    
    private var totalCalories: Int {
        var total = 0
        for meal in menu.meals {
            if let recipe = meal.breakfast {
                total += Int(recipe.nutrition?.caloriesKcal ?? 0)
            }
            if let recipe = meal.lunch {
                total += Int(recipe.nutrition?.caloriesKcal ?? 0)
            }
            if let recipe = meal.dinner {
                total += Int(recipe.nutrition?.caloriesKcal ?? 0)
            }
        }
        return total / max(1, recipesCount)
    }
    
    private var totalProtein: Double {
        var total = 0.0
        for meal in menu.meals {
            if let recipe = meal.breakfast {
                total += recipe.nutrition?.protein ?? 0
            }
            if let recipe = meal.lunch {
                total += recipe.nutrition?.protein ?? 0
            }
            if let recipe = meal.dinner {
                total += recipe.nutrition?.protein ?? 0
            }
        }
        return total / Double(max(1, recipesCount))
    }
    
    private var totalCarbs: Double {
        var total = 0.0
        for meal in menu.meals {
            if let recipe = meal.breakfast {
                total += recipe.nutrition?.carbohydrates ?? 0
            }
            if let recipe = meal.lunch {
                total += recipe.nutrition?.carbohydrates ?? 0
            }
            if let recipe = meal.dinner {
                total += recipe.nutrition?.carbohydrates ?? 0
            }
        }
        return total / Double(max(1, recipesCount))
    }
    
    private var totalFat: Double {
        var total = 0.0
        for meal in menu.meals {
            if let recipe = meal.breakfast {
                total += recipe.nutrition?.fat ?? 0
            }
            if let recipe = meal.lunch {
                total += recipe.nutrition?.fat ?? 0
            }
            if let recipe = meal.dinner {
                total += recipe.nutrition?.fat ?? 0
            }
        }
        return total / Double(max(1, recipesCount))
    }
    
    private var dietaryTagsView: some View {
        VStack(alignment: .leading, spacing: EzSpacing.sm) {
            if !allDietaryRestrictions.isEmpty {
                Text("Dietary Info")
                    .font(EzTypography.Label.font)
                    .foregroundColor(EzColors.Text.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                HStack(spacing: EzSpacing.sm) {
                    ForEach(Array(allDietaryRestrictions.prefix(4)), id: \.self) { dietary in
                        DietaryTagView(dietary: dietary, size: .small)
                    }
                    
                    if allDietaryRestrictions.count > 4 {
                        Text("+\(allDietaryRestrictions.count - 4)")
                            .font(EzTypography.Label.font)
                            .foregroundColor(EzColors.Text.secondary)
                            .padding(.horizontal, EzSpacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                    .fill(EzColors.Background.tertiary)
                            )
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var allDietaryRestrictions: Set<String> {
        var restrictions = Set<String>()
        for meal in menu.meals {
            for recipe in [meal.breakfast, meal.lunch, meal.dinner].compactMap({ $0 }) {
                restrictions.formUnion(recipe.dietaryTags.map { $0.rawValue })
            }
        }
        return restrictions
    }
    
    private func hasRecipeForDay(_ day: Int) -> Bool {
        guard day >= 0 && day < menu.meals.count else { return false }
        let dayMeal = menu.meals[day]
        return dayMeal.breakfast != nil || dayMeal.lunch != nil || dayMeal.dinner != nil
    }
}

#Preview {
    let menu = Menu(name: "Săptămâna 1", weekStartDate: Date())
    
    VStack(spacing: EzSpacing.lg) {
        MenuListItemView(menu: menu)
        Spacer()
    }
    .padding(EzSpacing.lg)
    .background(EzColors.Background.primary.ignoresSafeArea())
}
