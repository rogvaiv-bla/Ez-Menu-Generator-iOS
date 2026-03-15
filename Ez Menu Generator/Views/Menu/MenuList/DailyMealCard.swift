import SwiftUI

/// Displays meals for a single day (breakfast, lunch, dinner)
struct DailyMealCard: View {
    let dayIndex: Int // 0 = Monday, 6 = Sunday
    let dayMeals: DayMeals?
    let onTap: () -> Void
    
    var dayName: String {
        let days = ["Luni", "Marți", "Miercuri", "Joi", "Vineri", "Sâmbătă", "Duminică"]
        return dayIndex < days.count ? days[dayIndex] : "Zi"
    }
    
    var mealsCount: Int {
        let count = (dayMeals?.breakfast != nil ? 1 : 0) +
                   (dayMeals?.lunch != nil ? 1 : 0) +
                   (dayMeals?.dinner != nil ? 1 : 0)
        return count
    }
    
    var isComplete: Bool {
        mealsCount == 3
    }
    
    var dayCalories: Int {
        guard let dayMeals = dayMeals else {
            return 0
        }
        var total = 0
        if let breakfast = dayMeals.breakfast {
            total += Int(breakfast.nutrition?.caloriesKcal ?? 0)
        }
        if let lunch = dayMeals.lunch {
            total += Int(lunch.nutrition?.caloriesKcal ?? 0)
        }
        if let dinner = dayMeals.dinner {
            total += Int(dinner.nutrition?.caloriesKcal ?? 0)
        }
        return total
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: EzSpacing.sm) {
            // Header: Day Name + Completion
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayName)
                        .titleStyle()
                    Text("\(mealsCount)/3 mese")
                        .ezLabelStyle()
                        .foregroundColor(EzColors.Text.secondary)
                }
                
                Spacer()
                
                // Completion Badge
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(EzColors.Accent.success)
                } else {
                    Text("\(3 - mealsCount) lipsă")
                        .ezLabelStyle()
                        .foregroundColor(EzColors.Text.secondary)
                }
            }
            
            // Meals List
            VStack(spacing: EzSpacing.xs) {
                MealTypeRow(
                    mealType: "Micul dejun",
                    recipe: dayMeals?.breakfast,
                    icon: "sun.max.fill"
                )
                
                MealTypeRow(
                    mealType: "Prânz",
                    recipe: dayMeals?.lunch,
                    icon: "leaf.fill"
                )
                
                MealTypeRow(
                    mealType: "Cină",
                    recipe: dayMeals?.dinner,
                    icon: "moon.stars.fill"
                )
            }
            
            // Calories Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("\(dayCalories) kcal")
                        .ezLabelStyle()
                }
                .foregroundColor(EzColors.Accent.warning)
                
                Spacer()
                
                Text("Editează")
                    .ezLabelStyle()
                    .foregroundColor(EzColors.Accent.primary)
            }
            .padding(.top, EzSpacing.xs)
        }
        .padding(EzSpacing.md)
        .background(EzColors.Background.secondary)
        .cornerRadius(EzSpacing.Card.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: EzSpacing.Card.cornerRadius)
                .stroke(isComplete ? EzColors.Accent.success.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Meal Type Row
private struct MealTypeRow: View {
    let mealType: String
    let recipe: Recipe?
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(EzColors.Text.secondary)
                    .frame(width: 20)
                
                Text(mealType)
                    .ezLabelStyle()
                    .foregroundColor(EzColors.Text.primary)
                
                if recipe == nil {
                    Text("Gol")
                        .ezLabelStyle()
                        .foregroundColor(EzColors.Text.tertiary)
                }
                
                Spacer()
            }
            
            if let recipe = recipe {
                HStack(spacing: 6) {
                    Circle()
                        .fill(EzColors.Accent.primary)
                        .frame(width: 4)
                    
                    Text(recipe.name)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(EzColors.Text.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.leading, 26)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EzSpacing.sm)
        .background(EzColors.Background.primary)
        .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: EzSpacing.md) {
        DailyMealCard(
            dayIndex: 0,
            dayMeals: nil,
            onTap: {}
        )
        
        DailyMealCard(
            dayIndex: 1,
            dayMeals: nil,
            onTap: {}
        )
    }
    .padding(EzSpacing.md)
    .background(EzColors.Background.primary)
}
