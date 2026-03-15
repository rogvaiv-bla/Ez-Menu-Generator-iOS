import SwiftUI

struct NutritionDashboardView: View {
    let nutrition: NutritionInfo?
    let servings: Int
    
    var body: some View {
        guard let nutrition = nutrition else {
            return AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(EzColors.Text.tertiary)
                        Text("Nicio informație nutritivă disponibilă")
                            .foregroundColor(EzColors.Text.tertiary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(EzColors.Background.tertiary.opacity(0.3))
                    .cornerRadius(8)
                }
            )
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Macro circles
                HStack(spacing: 12) {
                    MacroCircleView(
                        label: "Proteine",
                        value: nutrition.protein,
                        unit: "g",
                        color: EzColors.Accent.danger,
                        percentage: macroPercentage(nutrition.proteinCalories, total: nutrition.caloriesKcal)
                    )
                    
                    MacroCircleView(
                        label: "Glucide",
                        value: nutrition.carbohydrates,
                        unit: "g",
                        color: EzColors.Accent.warning,
                        percentage: macroPercentage(nutrition.carbsCalories, total: nutrition.caloriesKcal)
                    )
                    
                    MacroCircleView(
                        label: "Grăsimi",
                        value: nutrition.fat,
                        unit: "g",
                        color: EzColors.NutritionScore.fair,
                        percentage: macroPercentage(nutrition.fatCalories, total: nutrition.caloriesKcal)
                    )
                    
                    MacroCircleView(
                        label: "Fibre",
                        value: nutrition.fiber,
                        unit: "g",
                        color: EzColors.Accent.success,
                        percentage: macroPercentage(nutrition.fiberCalories, total: nutrition.caloriesKcal)
                    )
                }
                
                // Calorie breakdown
                VStack(alignment: .leading, spacing: 10) {
                    Text("Distribuția caloriilor per 100g")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(EzColors.Text.tertiary)
                    
                    CalorieBarView(
                        label: "Proteine",
                        calories: nutrition.proteinCalories,
                        total: nutrition.caloriesKcal,
                        color: EzColors.Accent.danger
                    )
                    
                    CalorieBarView(
                        label: "Glucide",
                        calories: nutrition.carbsCalories,
                        total: nutrition.caloriesKcal,
                        color: EzColors.Accent.warning
                    )
                    
                    CalorieBarView(
                        label: "Grăsimi",
                        calories: nutrition.fatCalories,
                        total: nutrition.caloriesKcal,
                        color: EzColors.NutritionScore.fair
                    )
                    
                    if nutrition.fiber > 0 {
                        CalorieBarView(
                            label: "Fibre",
                            calories: nutrition.fiberCalories,
                            total: nutrition.caloriesKcal,
                            color: EzColors.Accent.success
                        )
                    }
                }
                .padding()
                .background(EzColors.Background.secondary)
                .cornerRadius(8)
                
                // Per serving info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pe porție (\(servings) porții)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(EzColors.Text.tertiary)
                    
                    HStack(spacing: 16) {
                        NutritionStatView(
                            label: "Kcal",
                            value: String(format: "%.0f", nutrition.caloriesKcal),
                            color: EzColors.Accent.primary
                        )
                        
                        NutritionStatView(
                            label: "P",
                            value: String(format: "%.1f", nutrition.protein),
                            unit: "g",
                            color: EzColors.Accent.danger
                        )
                        
                        NutritionStatView(
                            label: "C",
                            value: String(format: "%.1f", nutrition.carbohydrates),
                            unit: "g",
                            color: EzColors.Accent.warning
                        )
                        
                        NutritionStatView(
                            label: "G",
                            value: String(format: "%.1f", nutrition.fat),
                            unit: "g",
                            color: EzColors.NutritionScore.fair
                        )
                    }
                }
                
                // Additional nutrients
                if nutrition.fiber > 0 || nutrition.alcohol > 0 || nutrition.saturatedFat > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Informații suplimentare")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(EzColors.Text.tertiary)
                        
                        Divider()
                        
                        if nutrition.fiber > 0 {
                            HStack {
                                Text("Fibre")
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", nutrition.fiber))g")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if nutrition.alcohol > 0 {
                            HStack {
                                Label("Alcool", systemImage: "wineglass.fill")
                                    .font(.caption)
                                    .foregroundColor(EzColors.Accent.danger)
                                Spacer()
                                Text("\(String(format: "%.1f", nutrition.alcohol))g")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if nutrition.saturatedFat > 0 {
                            HStack {
                                Text("Grăsimi saturate")
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", nutrition.saturatedFat))g")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if nutrition.sugars > 0 {
                            HStack {
                                Text("Zaharuri")
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", nutrition.sugars))g")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(EzColors.Background.secondary)
                    .cornerRadius(8)
                }
            }
        )
    }
    
    private func macroPercentage(_ macroCalories: Double, total: Double) -> Double {
        guard total > 0 else { return 0 }
        return (macroCalories / total) * 100
    }
}

// MARK: - Macro Circle Component
struct MacroCircleView: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(EzColors.Background.surface.opacity(0.5), lineWidth: 3)
                    .frame(width: 52, height: 52)
                
                Circle()
                    .trim(from: 0, to: percentage / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: percentage)
                
                VStack(spacing: 2) {
                    Text("\(String(format: "%.0f", percentage))%")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(String(format: "%.1f", value))
                        .font(.caption2)
                }
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(EzColors.Text.tertiary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(EzColors.Text.tertiary)
        }
    }
}

// MARK: - Calorie Bar Component
struct CalorieBarView: View {
    let label: String
    let calories: Double
    let total: Double
    let color: Color
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return (calories / total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(String(format: "%.0f", calories)) kcal (\(String(format: "%.0f", percentage))%)")
                    .font(.caption2)
                    .foregroundColor(EzColors.Text.tertiary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(EzColors.Background.tertiary.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Stat Component
struct NutritionStatView: View {
    let label: String
    let value: String
    var unit: String = ""
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(EzColors.Text.tertiary)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(EzColors.Text.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: 20) {
        NutritionDashboardView(
            nutrition: NutritionInfo(
                caloriesKcal: 250,
                protein: 28,
                carbohydrates: 12,
                fat: 8,
                saturatedFat: 2,
                fiber: 3,
                sugars: 2,
                alcohol: 0
            ),
            servings: 4
        )
        .padding()
    }
    .background(EzColors.Background.primary)
}
