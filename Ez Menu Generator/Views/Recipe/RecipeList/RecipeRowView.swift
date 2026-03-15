import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Thumbnail image
                LazyImage(
                    image: recipe.image,
                    recipeId: recipe.id,
                    displayType: .thumbnail,
                    supabaseImagePath: recipe.supabaseImagePath
                )
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.name)
                        .headlineStyle()
                    
                    // Meal Type Tags - More Visible
                    if recipe.hasMealType {
                        HStack(spacing: 6) {
                            if recipe.isBreakfast {
                                Text("🌅 Mic dejun")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background(EzColors.Accent.warning.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            if recipe.isLunch {
                                Text("☀️ Prânz")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background(EzColors.NutritionScore.fair.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            if recipe.isDinner {
                                Text("🌙 Cină")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background(EzColors.Accent.primary.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            if recipe.isDessert {
                                Text("✨ Desert")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background(EzColors.Accent.danger.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(recipe.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(EzColors.Text.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(EzColors.categoryColors[recipe.category] ?? EzColors.Text.tertiary)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.category)")
        .accessibilityValue("\(recipe.difficulty.rawValue), \(recipe.prepTimeMinutes + recipe.cookTimeMinutes) minute")
        .accessibilityHint("Apasă pentru a vedea detaliile rețetei")
    }
}

#Preview {
    // Safe preview with fallback recipe
    let recipe = SampleDataService.sampleRecipes.first ?? Recipe(
        id: UUID(),
        name: "Sample Recipe",
        description: "Preview description",  // init parameter is 'description' not 'recipeDescription'
        category: "Main Course",
        servings: 4,
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
        ingredients: [],
        instructions: "Preview instructions",
        difficulty: .medium,
        createdAt: Date()
    )
    RecipeRowView(recipe: recipe)
        .preferredColorScheme(.dark)
}
