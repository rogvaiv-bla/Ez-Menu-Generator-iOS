import SwiftUI
import SwiftData

struct ProductDetailView: View {
    let product: FoodProduct
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text(product.category)
                                .font(.caption)
                                .foregroundColor(EzColors.Text.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(EzColors.Accent.primary.opacity(0.1))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            if let barcode = product.barcode {
                                Text("📊 \(barcode)")
                                    .font(.caption2)
                                    .foregroundColor(EzColors.Accent.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Calories Card
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(EzColors.Accent.warning)
                            Text("Energie (per 100g)")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("\(Int(product.nutrition.caloriesKcal)) kcal")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(EzColors.Accent.warning)
                    }
                    .padding()
                    .background(EzColors.Accent.warning.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Macronutrients
                    VStack(spacing: 12) {
                        Text("Macronutrienți (per 100g)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            MacroDetailCard(label: "Proteine", value: product.nutrition.protein, unit: "g", color: EzColors.Accent.danger, icon: "💪")
                            MacroDetailCard(label: "Carbohidrați", value: product.nutrition.carbohydrates, unit: "g", color: EzColors.Accent.primary, icon: "⚡")
                            MacroDetailCard(label: "Grăsimi", value: product.nutrition.fat, unit: "g", color: EzColors.NutritionScore.fair, icon: "🧈")
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            MacroDetailCard(label: "Fibre", value: product.nutrition.fiber, unit: "g", color: EzColors.Accent.success, icon: "🌾")
                            MacroDetailCard(label: "Zahăr", value: product.nutrition.sugars, unit: "g", color: EzColors.Accent.danger, icon: "🍬")
                            MacroDetailCard(label: "Grăsimi saturate", value: product.nutrition.saturatedFat, unit: "g", color: EzColors.Accent.warning, icon: "⚠️")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Nutritional Facts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Informații nutriționale complete (per 100g)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        NutritionFactsRow(label: "Calorii", value: "\(Int(product.nutrition.caloriesKcal)) kcal")
                        NutritionFactsRow(label: "Proteine", value: String(format: "%.1f g", product.nutrition.protein))
                        NutritionFactsRow(label: "Carbohidrați", value: String(format: "%.1f g", product.nutrition.carbohydrates))
                        NutritionFactsRow(label: "Grăsimi totale", value: String(format: "%.1f g", product.nutrition.fat))
                        NutritionFactsRow(label: "Grăsimi saturate", value: String(format: "%.1f g", product.nutrition.saturatedFat))
                        NutritionFactsRow(label: "Fibre", value: String(format: "%.1f g", product.nutrition.fiber))
                        NutritionFactsRow(label: "Zahăr", value: String(format: "%.1f g", product.nutrition.sugars))
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { addToShoppingList() }) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Adaugă la Cumpărături")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(EzColors.Accent.primary)
                            .foregroundColor(EzColors.Text.primary)
                            .cornerRadius(8)
                        }
                        
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("Închide")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(EzColors.Background.tertiary)
                            .foregroundColor(EzColors.Text.primary)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func addToShoppingList() {
        let shoppingItem = ShoppingItem(name: product.name, category: product.category, isChecked: false)
        modelContext.insert(shoppingItem)
        try? modelContext.save()
        dismiss()
    }
}

struct MacroDetailCard: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(icon)
                    .font(.system(size: 20))
                Spacer()
            }
            
            Text(String(format: "%.1f", value))
                .font(.system(size: 20, weight: .bold))
            
            Text(unit)
                .font(.caption)
                .foregroundColor(EzColors.Text.secondary)
            
            Text(label)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NutritionFactsRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(EzColors.Text.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(EzColors.Background.secondary)
        .cornerRadius(6)
    }
}

#Preview {
    ProductDetailView(product: FoodProduct(name: "Somon", category: "Pește", nutrition: NutritionInfo(caloriesKcal: 208, protein: 20, carbohydrates: 0, fat: 13, saturatedFat: 2.9, fiber: 0, sugars: 0)))
}
