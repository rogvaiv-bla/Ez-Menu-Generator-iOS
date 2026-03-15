import Testing
@testable import Ez_Menu_Generator

@Suite("NutritionCalculator")
struct NutritionCalculatorTests {
    
    // MARK: - convertToGrams Tests
    
    @Test("Converts grams to grams (identity)")
    func gramsToGrams() {
        #expect(NutritionCalculator.convertToGrams(100, unit: "g") == 100)
        #expect(NutritionCalculator.convertToGrams(500, unit: "grame") == 500)
    }
    
    @Test("Converts kilograms to grams")
    func kilogramsToGrams() {
        #expect(NutritionCalculator.convertToGrams(1, unit: "kg") == 1000)
        #expect(NutritionCalculator.convertToGrams(0.5, unit: "kg") == 500)
    }
    
    @Test("Converts liters to grams")
    func litersToGrams() {
        #expect(NutritionCalculator.convertToGrams(1, unit: "l") == 1000)
        #expect(NutritionCalculator.convertToGrams(2, unit: "litru") == 2000)
    }
    
    @Test("Converts tablespoons to grams")
    func tableSpoonToGrams() {
        #expect(NutritionCalculator.convertToGrams(1, unit: "linguri") == 15)
        #expect(NutritionCalculator.convertToGrams(2, unit: "linguri") == 30)
        #expect(NutritionCalculator.convertToGrams(4, unit: "tbsp") == 60)
    }
    
    @Test("Converts teaspoons to grams")
    func teaSpoonToGrams() {
        #expect(NutritionCalculator.convertToGrams(1, unit: "ceai") == 5)
        #expect(NutritionCalculator.convertToGrams(3, unit: "ceai") == 15)
        #expect(NutritionCalculator.convertToGrams(2, unit: "tsp") == 10)
    }
    
    @Test("Converts garlic cloves to grams")
    func garlicClovesToGrams() {
        #expect(NutritionCalculator.convertToGrams(1, unit: "cati") == 100)
        #expect(NutritionCalculator.convertToGrams(3, unit: "cati") == 300)
    }
    
    @Test("Converts cups to grams")
    func cupsToGrams() {
        #expect(NutritionCalculator.convertToGrams(1, unit: "cana") == 240)
        #expect(NutritionCalculator.convertToGrams(2, unit: "cup") == 480)
    }
    
    @Test("Converts pieces to grams (default)")
    func piecesToGrams() {
        #expect(NutritionCalculator.convertToGrams(1, unit: "buc") == 100)
        #expect(NutritionCalculator.convertToGrams(2, unit: "bucata") == 200)
    }
    
    // MARK: - ingredientNutrition Tests
    
    @Test("Calculates nutrition for ingredient with standard units")
    func ingredientNutritionStandard() {
        let ingredient = Ingredient(
            name: "Somon",
            quantity: 200,
            unit: "g",
            category: "Pește",
            nutritionPer100g: .init(caloriesKcal: 208, protein: 20, carbohydrates: 0, fat: 13, saturatedFat: 2.9, fiber: 0, sugars: 0)
        )
        
        let nutrition = NutritionCalculator.ingredientNutrition(ingredient)
        
        #expect(nutrition?.caloriesKcal == 416) // 208 * 2
        #expect(nutrition?.protein == 40) // 20 * 2
        #expect(nutrition?.fat == 26) // 13 * 2
    }
    
    @Test("Calculates nutrition for ingredient without nutrition data")
    func ingredientNutritionNil() {
        let ingredient = Ingredient(
            name: "Unknown",
            quantity: 100,
            unit: "g",
            category: "Test",
            nutritionPer100g: nil
        )
        
        let nutrition = NutritionCalculator.ingredientNutrition(ingredient)
        
        #expect(nutrition == nil)
    }
    
    // MARK: - recipeNutritionPerServing Tests
    
    @Test("Calculates recipe nutrition per serving correctly")
    func recipeNutritionPerServing() {
        let recipe = Recipe(
            name: "Test Recipe",
            description: "Test",
            category: "Test",
            servings: 2,
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            ingredients: [
                Ingredient(
                    name: "Somon",
                    quantity: 200,
                    unit: "g",
                    category: "Pește",
                    nutritionPer100g: .init(caloriesKcal: 208, protein: 20, carbohydrates: 0, fat: 13, saturatedFat: 2.9, fiber: 0, sugars: 0)
                )
            ],
            instructions: "Test",
            difficulty: .easy
        )
        
        let perServing = NutritionCalculator.recipeNutritionPerServing(recipe)
        
        #expect(perServing.caloriesKcal == 208) // (208 * 2) / 2 = 208
        #expect(perServing.protein == 20) // (20 * 2) / 2 = 20
        #expect(perServing.fat == 13) // (13 * 2) / 2 = 13
    }
    
    @Test("Recipe with multiple ingredients sums correctly")
    func recipeMultipleIngredients() {
        let recipe = Recipe(
            name: "Mixed Recipe",
            description: "Test",
            category: "Test",
            servings: 4,
            prepTimeMinutes: 15,
            cookTimeMinutes: 30,
            ingredients: [
                Ingredient(
                    name: "Pui",
                    quantity: 200,
                    unit: "g",
                    category: "Carne",
                    nutritionPer100g: NutritionInfo(caloriesKcal: 165, protein: 31, carbohydrates: 0, fat: 3.6, saturatedFat: 1.1, fiber: 0, sugars: 0)
                ),
                Ingredient(
                    name: "Orez",
                    quantity: 100,
                    unit: "g",
                    category: "Cărămizi",
                    nutritionPer100g: NutritionInfo(caloriesKcal: 130, protein: 2.7, carbohydrates: 28, fat: 0.3, saturatedFat: 0.08, fiber: 0.4, sugars: 0.1)
                )
            ],
            instructions: "Test",
            difficulty: .medium
        )
        
        let total = NutritionCalculator.recipeNutrition(recipe)
        let perServing = NutritionCalculator.recipeNutritionPerServing(recipe)
        
        // Total: Pui (200g): 330 kcal, Orez (100g): 130 kcal = 460 kcal
        #expect(total.caloriesKcal == 460)
        
        // Per serving: 460 / 4 = 115 kcal
        #expect(perServing.caloriesKcal == 115)
        
        // Protein: (31*2 + 2.7) / 4 = 65.7/4 ≈ 16.425
        #expect(abs(perServing.protein - 16.425) < 0.1)
    }
    
    @Test("Recipe with zero servings handles gracefully")
    func recipeZeroServings() {
        let recipe = Recipe(
            name: "Invalid Recipe",
            description: "Test",
            category: "Test",
            servings: 0,
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            ingredients: [
                Ingredient(
                    name: "Pui",
                    quantity: 100,
                    unit: "g",
                    category: "Carne",
                    nutritionPer100g: .chicken
                )
            ],
            instructions: "Test",
            difficulty: .easy
        )
        
        let perServing = NutritionCalculator.recipeNutritionPerServing(recipe)
        
        // Should use max(servings, 1) = 1
        #expect(perServing.caloriesKcal == 165) // 165 * 1 / 1
    }
}
