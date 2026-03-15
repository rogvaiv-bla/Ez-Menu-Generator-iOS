import SwiftUI

struct NutritionDetailView: View {
    let nutrition: NutritionInfo
    var title: String = "Valori nutritive"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .headlineStyle()
            
            // Calorii - highlighted
            HStack {
                Label("Calorii", systemImage: "flame.fill")
                    .foregroundColor(EzColors.Accent.warning)
                Spacer()
                Text(String(format: "%.0f kcal", nutrition.caloriesKcal))
                    .font(.headline)
                    .foregroundColor(EzColors.Text.primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(EzColors.Accent.warning.opacity(0.1))
            .cornerRadius(8)
            
            // Macronutrienți în grid
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    MacroCard(label: "Proteina", value: nutrition.protein, unit: "g", color: EzColors.Accent.danger)
                    MacroCard(label: "Carbs", value: nutrition.carbohydrates, unit: "g", color: .blue)
                    MacroCard(label: "Grăsimi", value: nutrition.fat, unit: "g", color: .yellow)
                }
                
                HStack(spacing: 12) {
                    MacroCard(label: "Fibre", value: nutrition.fiber, unit: "g", color: EzColors.Accent.success)
                    MacroCard(label: "Zahăr", value: nutrition.sugars, unit: "g", color: .pink)
                    MacroCard(label: "Sat. Fat", value: nutrition.saturatedFat, unit: "g", color: EzColors.Accent.warning)
                }
            }
            
            // Detalii suplimentare
            VStack(alignment: .leading, spacing: 6) {
                DetailRow(label: "Grăsimi saturate", value: String(format: "%.1f g", nutrition.saturatedFat))
                DetailRow(label: "Zahăr", value: String(format: "%.1f g", nutrition.sugars))
                DetailRow(label: "Fibre", value: String(format: "%.1f g", nutrition.fiber))
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: EzSpacing.Card.cornerRadius)
                .fill(EzColors.Background.secondary)
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: EzSpacing.Card.shadowRadius,
                    x: 0,
                    y: EzSpacing.Card.shadowY
                )
        )
        .padding(.horizontal, EzSpacing.Component.padding)
    }
}

struct MacroCard: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(EzColors.Text.secondary)
            
            Text(String(format: "%.1f", value))
                .font(.headline)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(EzColors.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(EzColors.Text.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(EzColors.Text.primary)
        }
        .font(.caption)
    }
}

#Preview {
    VStack {
        NutritionDetailView(
            nutrition: NutritionInfo(
                caloriesKcal: 500,
                protein: 25,
                carbohydrates: 50,
                fat: 15,
                saturatedFat: 5,
                fiber: 8,
                sugars: 10
            ),
            title: "Valori nutritive per porție"
        )
        Spacer()
    }
    .padding()
}
