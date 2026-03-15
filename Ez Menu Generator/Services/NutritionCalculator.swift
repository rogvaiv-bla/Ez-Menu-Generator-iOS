import Foundation

// Service pentru calcularea valorilor nutritive pe baza ingredientelor
class NutritionCalculator {
    
    // Converteste grame in unitatea data (pentru ingrediente cu unitati diferite)
    static func convertToGrams(_ quantity: Double, unit: String) -> Double {
        switch unit.lowercased() {
        case "g", "grame":
            return quantity
        case "kg":
            return quantity * 1000
        case "ml", "mililitri":
            return quantity  // Aproximare: 1ml ≈ 1g pentru lichide
        case "l", "litru":
            return quantity * 1000
        case "buc", "bucata", "piece", "unit":
            return quantity * 100  // Default: 1 bucata ≈ 100g
        case "lingura", "tbsp", "tablespoon":
            return quantity * 15  // 1 lingura ≈ 15g
        case "ceai", "tsp", "teaspoon":
            return quantity * 5   // 1 ceai ≈ 5g
        case "cana", "cup":
            return quantity * 240  // 1 cana ≈ 240g
        default:
            return quantity * 100  // Default
        }
    }
    
    // Calculeaza nutritia pentru un ingredient specific
    static func ingredientNutrition(_ ingredient: Ingredient) -> NutritionInfo? {
        guard let nutrition = ingredient.nutritionPer100g else { return nil }
        
        let grams = convertToGrams(ingredient.quantity, unit: ingredient.unit)
        let multiplier = grams / 100.0
        
        return NutritionInfo(
            caloriesKcal: nutrition.caloriesKcal * multiplier,
            protein: nutrition.protein * multiplier,
            carbohydrates: nutrition.carbohydrates * multiplier,
            fat: nutrition.fat * multiplier,
            saturatedFat: nutrition.saturatedFat * multiplier,
            fiber: nutrition.fiber * multiplier,
            sugars: nutrition.sugars * multiplier
        )
    }
    
    // Calculeaza nutritia totala pentru o reteta
    static func recipeNutrition(_ recipe: Recipe) -> NutritionInfo {
        var totalNutrition = NutritionInfo()
        
        for ingredient in recipe.ingredients {
            if let ingredientNutrition = ingredientNutrition(ingredient) {
                totalNutrition.caloriesKcal += ingredientNutrition.caloriesKcal
                totalNutrition.protein += ingredientNutrition.protein
                totalNutrition.carbohydrates += ingredientNutrition.carbohydrates
                totalNutrition.fat += ingredientNutrition.fat
                totalNutrition.saturatedFat += ingredientNutrition.saturatedFat
                totalNutrition.fiber += ingredientNutrition.fiber
                totalNutrition.sugars += ingredientNutrition.sugars
            }
        }
        
        return totalNutrition
    }
    
    // Calculeaza nutritia per portie (scoate din reteta totala)
    static func recipeNutritionPerServing(_ recipe: Recipe) -> NutritionInfo {
        let totalNutrition = recipeNutrition(recipe)
        let servings = Double(max(recipe.servings, 1))
        
        return NutritionInfo(
            caloriesKcal: totalNutrition.caloriesKcal / servings,
            protein: totalNutrition.protein / servings,
            carbohydrates: totalNutrition.carbohydrates / servings,
            fat: totalNutrition.fat / servings,
            saturatedFat: totalNutrition.saturatedFat / servings,
            fiber: totalNutrition.fiber / servings,
            sugars: totalNutrition.sugars / servings
        )
    }
}
