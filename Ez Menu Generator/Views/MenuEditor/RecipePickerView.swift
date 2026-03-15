import SwiftUI

struct RecipePickerView: View {
    let onRecipeSelected: (Recipe) -> Void
    let mealType: String? // "breakfast", "lunch", "dinner", "dessert"
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RecipeListViewModel
    @State private var searchText = ""
    
    var filteredRecipes: [Recipe] {
        var recipes = viewModel.recipes
        
        // Filter by search text
        if !searchText.isEmpty {
            recipes = recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by meal type
        if let mealType = mealType {
            recipes = recipes.filter { recipe in
                switch mealType {
                case "breakfast":
                    return recipe.isBreakfast
                case "lunch":
                    return recipe.isLunch
                case "dinner":
                    return recipe.isDinner
                case "dessert":
                    return recipe.isDessert
                default:
                    return true
                }
            }
        }

        // Defensive deduplication by normalized display name
        var uniqueByName: [String: Recipe] = [:]
        for recipe in recipes {
            let key = recipe.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            if uniqueByName[key] == nil {
                uniqueByName[key] = recipe
            }
        }
        recipes = Array(uniqueByName.values)
        
        return recipes.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // Helper to get meal type label
    func mealTypeLabel(for recipe: Recipe) -> String {
        var types: [String] = []
        if recipe.isBreakfast { types.append("Mic dejun") }
        if recipe.isLunch { types.append("Prânz") }
        if recipe.isDinner { types.append("Cină") }
        if recipe.isDessert { types.append("Desert") }
        return types.isEmpty ? "Neprecizat" : types.joined(separator: ", ")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredRecipes.isEmpty {
                    VStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 48))
                            .foregroundColor(EzColors.Accent.primary.opacity(0.3))
                        Text("Nicio rețetă")
                            .headlineStyle()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(EzColors.Background.primary)
                } else {
                    List(filteredRecipes, id: \.id) { recipe in
                        Button(action: {
                            onRecipeSelected(recipe)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(recipe.name)
                                        .bodySecondaryStyle()
                                        .foregroundColor(EzColors.Text.primary)
                                    Text(mealTypeLabel(for: recipe))
                                        .helperStyle()
                                        .foregroundColor(EzColors.Text.secondary)
                                }
                                Spacer()
                                Text(recipe.category)
                                    .font(.caption)
                                    .foregroundColor(EzColors.Accent.primary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Selectează rețetă")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Caută...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Anulează")
                    }
                }
            }
        }
        .onAppear {
            // Force fresh fetch to ensure no duplicates and latest data
            viewModel.fetchRecipes(force: true)
        }
    }
}

#Preview {
    RecipePickerView(onRecipeSelected: { _ in }, mealType: nil)
        .environmentObject(RecipeListViewModel())
}
