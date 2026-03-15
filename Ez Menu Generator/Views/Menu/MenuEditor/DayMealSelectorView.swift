import SwiftUI

struct DayMealSelectorView: View {
    let dayName: String
    var dayMeals: DayMeals
    let onRecipeSelected: (String, Recipe) -> Void
    var onDayRegenerate: (() -> Void)?
    
    @EnvironmentObject var recipeViewModel: RecipeListViewModel
    
    @State private var showBreakfastPicker = false
    @State private var showLunchPicker = false
    @State private var showDinnerPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            HStack {
                Text(dayName)
                    .headlineStyle()
                Spacer()
                Button(action: { onDayRegenerate?() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .padding(EzSpacing.xs)
                        .background(EzColors.Accent.primary.opacity(0.1))
                        .foregroundColor(EzColors.Accent.primary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
                .help("Regenerează ziua")
            }
            
            // Breakfast
            Button(action: { showBreakfastPicker = true }) {
                HStack {
                    Image(systemName: "sunrise.fill")
                        .foregroundColor(EzColors.Accent.primary)
                    VStack(alignment: .leading, spacing: EzSpacing.xs) {
                        Text("Mic dejun")
                            .font(.caption)
                            .foregroundColor(EzColors.Text.secondary)
                        Text(dayMeals.breakfast?.name ?? "Selectează...")
                            .bodySecondaryStyle()
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(EzColors.Text.secondary)
                }
                .padding(EzSpacing.md)
                .background(EzColors.Background.secondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .sheet(isPresented: $showBreakfastPicker) {
                RecipePickerView(onRecipeSelected: { recipe in
                    onRecipeSelected("breakfast", recipe)
                    showBreakfastPicker = false
                }, mealType: "breakfast")
                .environmentObject(recipeViewModel)
            }
            
            // Lunch
            Button(action: { showLunchPicker = true }) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(EzColors.Accent.warning)
                    VStack(alignment: .leading, spacing: EzSpacing.xs) {
                        Text("Prânz")
                            .font(.caption)
                            .foregroundColor(EzColors.Text.secondary)
                        Text(dayMeals.lunch?.name ?? "Selectează...")
                            .bodySecondaryStyle()
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(EzColors.Text.secondary)
                }
                .padding(EzSpacing.md)
                .background(EzColors.Background.secondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .sheet(isPresented: $showLunchPicker) {
                RecipePickerView(onRecipeSelected: { recipe in
                    onRecipeSelected("lunch", recipe)
                    showLunchPicker = false
                }, mealType: "lunch")
                .environmentObject(recipeViewModel)
            }
            
            // Dinner
            Button(action: { showDinnerPicker = true }) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(EzColors.Accent.success)
                    VStack(alignment: .leading, spacing: EzSpacing.xs) {
                        Text("Cină")
                            .font(.caption)
                            .foregroundColor(EzColors.Text.secondary)
                        Text(dayMeals.dinner?.name ?? "Selectează...")
                            .bodySecondaryStyle()
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(EzColors.Text.secondary)
                }
                .padding(EzSpacing.md)
                .background(EzColors.Background.secondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .sheet(isPresented: $showDinnerPicker) {
                RecipePickerView(onRecipeSelected: { recipe in
                    onRecipeSelected("dinner", recipe)
                    showDinnerPicker = false
                }, mealType: "dinner")
                .environmentObject(recipeViewModel)
            }
        }
        .padding(EzSpacing.md)
        .background(EzColors.Background.primary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

#Preview {
    let dayMeal = DayMeals()
    DayMealSelectorView(dayName: "Luni", dayMeals: dayMeal, onRecipeSelected: { _, _ in })
}
