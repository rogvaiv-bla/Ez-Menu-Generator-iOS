import SwiftUI

/// Displays weekly nutrition statistics summary
struct WeeklyStatsWidget: View {
    let menu: Menu?
    
    var averageCalories: Int {
        guard let menu = menu, !menu.meals.isEmpty else { return 0 }
        var totalCalories = 0
        for day in menu.meals {
            if let breakfast = day.breakfast {
                totalCalories += Int(breakfast.nutrition?.caloriesKcal ?? 0)
            }
            if let lunch = day.lunch {
                totalCalories += Int(lunch.nutrition?.caloriesKcal ?? 0)
            }
            if let dinner = day.dinner {
                totalCalories += Int(dinner.nutrition?.caloriesKcal ?? 0)
            }
        }
        return totalCalories / (menu.meals.count > 0 ? menu.meals.count : 1)
    }
    
    var averageProtein: Double {
        guard let menu = menu, !menu.meals.isEmpty else { return 0 }
        var totalProtein: Double = 0
        for day in menu.meals {
            if let breakfast = day.breakfast {
                totalProtein += breakfast.nutrition?.protein ?? 0
            }
            if let lunch = day.lunch {
                totalProtein += lunch.nutrition?.protein ?? 0
            }
            if let dinner = day.dinner {
                totalProtein += dinner.nutrition?.protein ?? 0
            }
        }
        return totalProtein / Double(menu.meals.count > 0 ? menu.meals.count : 1)
    }
    
    var body: some View {
        VStack(spacing: EzSpacing.md) {
            // Header
            HStack {
                Text("Sumar săptămândal")
                    .titleStyle()
                Spacer()
                if let menu = menu {
                    Text(weekRangeString(from: menu.weekStartDate))
                        .ezLabelStyle()
                        .foregroundColor(EzColors.Text.secondary)
                }
            }
            
            // Stats Grid
            HStack(spacing: EzSpacing.md) {
                // Calories
                StatsCard(
                    icon: "flame.fill",
                    label: "Cal. zilnice",
                    value: "\(averageCalories)",
                    unit: "kcal",
                    color: EzColors.Accent.warning
                )
                
                // Protein
                StatsCard(
                    icon: "bolt.fill",
                    label: "Proteine",
                    value: String(format: "%.0f", averageProtein),
                    unit: "g",
                    color: EzColors.Accent.primary
                )
                
                // Meals Count
                StatsCard(
                    icon: "checkmark.circle.fill",
                    label: "Mese plan.",
                    value: "\(totalMealsPlanned)",
                    unit: "/ 21",
                    color: EzColors.Accent.success
                )
            }
        }
        .padding(EzSpacing.md)
        .background(EzColors.Background.secondary)
        .cornerRadius(EzSpacing.Card.cornerRadius)
    }
    
    var totalMealsPlanned: Int {
        guard let menu = menu else { return 0 }
        var count = 0
        for day in menu.meals {
            if day.breakfast != nil { count += 1 }
            if day.lunch != nil { count += 1 }
            if day.dinner != nil { count += 1 }
        }
        return count
    }
    
    private func weekRangeString(from date: Date) -> String {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 6, to: date) ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: date)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Stat Card Component
private struct StatsCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: EzSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .headlineStyle()
                .lineLimit(1)
            
            HStack(spacing: 2) {
                Text(unit)
                    .ezLabelStyle()
                    .foregroundColor(EzColors.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EzSpacing.sm)
        .background(EzColors.Background.primary)
        .cornerRadius(8)
    }
}

#Preview {
    WeeklyStatsWidget(menu: nil)
        .background(EzColors.Background.primary)
        .padding(EzSpacing.lg)
}
