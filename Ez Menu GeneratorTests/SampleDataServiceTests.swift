import Testing
import SwiftData
@testable import Ez_Menu_Generator

@Suite("SampleDataService")
struct SampleDataServiceTests {
    
    @Test("Sample recipes are properly seeded")
    func sampleRecipesSeeded() {
        let recipes = SampleDataService.sampleRecipes
        
        #expect(recipes.count == 15)
        #expect(!recipes.isEmpty)
        
        // Check first recipe (safely)
        guard let firstRecipe = recipes.first else {
            Issue.record("Sample recipes array is empty")
            return
        }
        #expect(firstRecipe.name == "Pui copt cu cartofi la cuptor și legume")
        #expect(firstRecipe.servings == 4)
        #expect(!firstRecipe.ingredients.isEmpty)
    }
    
    @Test("Sample recipes have nutrition data")
    func recipesHaveNutrition() {
        let recipes = SampleDataService.sampleRecipes
        
        for recipe in recipes {
            #expect(!recipe.ingredients.isEmpty, "Recipe \(recipe.name) has no ingredients")
            
            // At least some ingredients should have nutrition
            let withNutrition = recipe.ingredients.filter { $0.nutritionPer100g != nil }
            #expect(!withNutrition.isEmpty, "Recipe \(recipe.name) has no ingredients with nutrition")
        }
    }
    
    @Test("Shopping items are properly categorized")
    func shoppingItemsCategorized() {
        let items = SampleDataService.shoppingItems
        let categories = SampleDataService.shoppingCategories
        
        #expect(!categories.isEmpty)
        #expect(!items.isEmpty)
        
        // All shopping item categories should be in categories list
        for (category, _) in items {
            #expect(categories.contains(category), "Category '\(category)' not in categories list")
        }
    }
    
    @Test("In-memory data seeding works correctly")
    func inMemorySeeding() async throws {
        let config = ModelConfiguration(schema: Schema([Recipe.self, Ingredient.self, ShoppingItem.self]), isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema([Recipe.self, Ingredient.self, ShoppingItem.self]), configurations: [config])
        
        let context = ModelContext(container)
        
        // Seed data
        SampleDataService.seedDataIfNeeded(context: context)
        
        // Verify recipes were inserted
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recipesCount = try context.fetchCount(recipeDescriptor)
        
        #expect(recipesCount == 15, "Expected 15 recipes, got \(recipesCount)")
        
        // Verify shopping items were inserted
        let shoppingDescriptor = FetchDescriptor<ShoppingItem>()
        let shoppingCount = try context.fetchCount(shoppingDescriptor)
        
        #expect(shoppingCount > 0, "Expected shopping items to be seeded")
    }
    
    @Test("Duplicate seeding doesn't create duplicates")
    func noDuplicateSeeding() async throws {
        let config = ModelConfiguration(schema: Schema([Recipe.self, Ingredient.self, ShoppingItem.self]), isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema([Recipe.self, Ingredient.self, ShoppingItem.self]), configurations: [config])
        
        let context = ModelContext(container)
        
        // Seed twice
        SampleDataService.seedDataIfNeeded(context: context)
        SampleDataService.seedDataIfNeeded(context: context)
        
        // Verify only 15 recipes exist
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recipesCount = try context.fetchCount(recipeDescriptor)
        
        #expect(recipesCount == 15, "Expected 15 recipes after duplicate seeding, got \(recipesCount)")
    }
}
