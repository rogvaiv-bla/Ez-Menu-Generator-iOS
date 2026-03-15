import SwiftUI

struct MenuStatsView: View {
    let menu: Menu
    
    var stats: MenuStats {
        calculateStats()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: EzSpacing.lg) {
            Text("Statistici săptămână")
                .headlineStyle()
            
            VStack(spacing: EzSpacing.md) {
                StatRow(label: "🥩 Carne roșie", value: "\(stats.redMeatDays)/1", color: stats.redMeatDays > 1 ? EzColors.Accent.danger : EzColors.Accent.success)
                StatRow(label: "🍗 Carne de pasăre", value: "\(stats.poultryDays)/2", color: stats.poultryDays > 2 ? EzColors.Accent.warning : EzColors.Accent.success)
                StatRow(label: "🐟 Pește", value: "\(stats.fishDays)/2", color: stats.fishDays > 2 ? EzColors.Accent.warning : EzColors.Accent.success)
                StatRow(label: "🥚 Ouă totale", value: "\(stats.totalEggs)/5", color: stats.totalEggs > 5 ? EzColors.Accent.danger : EzColors.Accent.success)
                StatRow(label: "🥓 Mezeluri", value: "\(stats.processedMeatDays)/2", color: stats.processedMeatDays > 2 ? EzColors.Accent.warning : EzColors.Accent.success)
                StatRow(label: "🫘 Legume uscate", value: "\(stats.legumesDays)/2", color: stats.legumesDays > 2 ? EzColors.Accent.warning : EzColors.Accent.success)
                StatRow(label: "🍎 Zile cu fructe", value: "\(stats.fruitDays)/5", color: stats.fruitDays >= 5 ? EzColors.Accent.success : EzColors.Accent.warning)
                StatRow(label: "🧀 Brânză (max 20g/zi)", value: "✓", color: EzColors.Accent.success)
                StatRow(label: "🥜 Nuci (max 20g/zi)", value: "✓", color: EzColors.Accent.success)
            }
            .padding(EzSpacing.md)
            .background(EzColors.Background.secondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            
            // Legend
            VStack(alignment: .leading, spacing: EzSpacing.sm) {
                HStack(spacing: 8) {
                    Circle().fill(EzColors.Accent.success).frame(width: 8, height: 8)
                    Text("Conform restricțiilor").font(.caption)
                }
                HStack(spacing: 8) {
                    Circle().fill(EzColors.Accent.warning).frame(width: 8, height: 8)
                    Text("Apropiat de limită").font(.caption)
                }
                HStack(spacing: 8) {
                    Circle().fill(EzColors.Accent.danger).frame(width: 8, height: 8)
                    Text("Depășit").font(.caption)
                }
            }
            .padding(.top, EzSpacing.sm)
            .foregroundColor(EzColors.Text.tertiary)
        }
        .padding(EzSpacing.md)
        .background(EzColors.Background.secondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private func calculateStats() -> MenuStats {
        var redMeatCount = 0
        var poultryCount = 0
        var fishCount = 0
        var eggsCount = 0
        var processedMeatCount = 0
        var legumesCount = 0
        let _ = 0  // fruitDaysCount not used, just for clarity
        
        var redMeatDays = Set<Int>()
        var poultryDays = Set<Int>()
        var fishDays = Set<Int>()
        var processedMeatDays = Set<Int>()
        var legumesDays = Set<Int>()
        var fruitDaysSet = Set<Int>()
        
        for (dayIndex, dayMeals) in menu.meals.enumerated() {
            let meals = [dayMeals.breakfast, dayMeals.lunch, dayMeals.dinner].compactMap { $0 }
            
            for meal in meals {
                // Count tags
                for tag in meal.dietaryTags {
                    switch tag {
                    case .redMeat:
                        redMeatCount += 1
                        redMeatDays.insert(dayIndex)
                    case .poultry:
                        poultryCount += 1
                        poultryDays.insert(dayIndex)
                    case .fish:
                        fishCount += 1
                        fishDays.insert(dayIndex)
                    case .eggs:
                        eggsCount += 1
                    case .processedMeats:
                        processedMeatCount += 1
                        processedMeatDays.insert(dayIndex)
                    case .legumes:
                        legumesCount += 1
                        legumesDays.insert(dayIndex)
                    case .fruit:
                        fruitDaysSet.insert(dayIndex)
                    default:
                        break
                    }
                }
            }
        }
        
        return MenuStats(
            redMeatDays: redMeatDays.count,
            poultryDays: poultryDays.count,
            fishDays: fishDays.count,
            totalEggs: eggsCount,
            processedMeatDays: processedMeatDays.count,
            legumesDays: legumesDays.count,
            fruitDays: fruitDaysSet.count
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                Text(value)
                    .fontWeight(.bold)
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
            }
        }
        .font(.subheadline)
    }
}

struct MenuStats {
    let redMeatDays: Int
    let poultryDays: Int
    let fishDays: Int
    let totalEggs: Int
    let processedMeatDays: Int
    let legumesDays: Int
    let fruitDays: Int
}

#Preview {
    let menu = Menu(name: "Test", weekStartDate: Date())
    MenuStatsView(menu: menu)
}
