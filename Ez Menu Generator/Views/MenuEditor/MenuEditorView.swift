import SwiftUI

struct MenuEditorView: View {
    let menu: Menu
    @StateObject private var viewModel: MenuEditorViewModel
    @StateObject private var recipeViewModel = RecipeListViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showShoppingList = false
    
    private let dayNames = ["Luni", "Marți", "Miercuri", "Joi", "Vineri", "Sâmbătă", "Duminică"]
    
    init(menu: Menu) {
        self.menu = menu
        _viewModel = StateObject(wrappedValue: MenuEditorViewModel(menu: menu))
        _recipeViewModel = StateObject(wrappedValue: RecipeListViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Statistics section
                MenuStatsView(menu: menu)
                
                Divider()
                
                // Days section
                ForEach(0..<menu.meals.count, id: \.self) { day in
                    if day < dayNames.count {
                        DayMealSelectorView(
                            dayName: dayNames[day],
                            dayMeals: menu.meals[day],
                            onRecipeSelected: { mealType, recipe in
                                viewModel.assignRecipeToMeal(dayIndex: day, mealType: mealType, recipe: recipe)
                            },
                            onDayRegenerate: {
                                viewModel.regenerateDay(dayIndex: day)
                            }
                        )
                        .environmentObject(recipeViewModel)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(menu.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                MenuValidationView(menu: menu)
                    .environmentObject(MenuListViewModel())
                
                Button(action: {
                    viewModel.generateShoppingList()
                    showShoppingList = true
                }) {
                    Image(systemName: "cart.fill")
                }
            }
        }
        .sheet(isPresented: $showShoppingList) {
            ShoppingListPreviewView(shoppingList: $viewModel.generatedShoppingList)
        }
    }
}

#Preview {
    let menu = Menu(name: "Test", weekStartDate: Date())
    MenuEditorView(menu: menu)
}
