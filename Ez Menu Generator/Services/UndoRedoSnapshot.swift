import Foundation
import SwiftData
import UIKit

// MARK: - Serializable Snapshots for Undo/Redo
// These store data without SwiftData model references to avoid relationship conflicts

struct RecipeSnapshot: Codable {
    let id: UUID
    let name: String
    let description: String
    let category: String
    let servings: Int
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let instructions: String
    let difficulty: String
    let createdAt: Date
    let dietaryTags: [String]
    let isFavorite: Bool
    let isBreakfast: Bool
    let isLunch: Bool
    let isDinner: Bool
    let isDessert: Bool
    let ingredientSnapshots: [IngredientSnapshot]
    let nutrition: NutritionSnapshot?
    let imageData: Data?
    
    func toRecipe() -> Recipe {
        // Create recipe ensuring ALL fields are properly initialized
        // IMPORTANT: Use ORIGINAL ID from snapshot to avoid creating duplicate recipes
        let recipe = Recipe(
            id: id,
            name: name,
            description: description,
            category: category,
            servings: servings,
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            ingredients: ingredientSnapshots.map { snapshot in
                let ingredient = Ingredient(
                    id: snapshot.id,  // Preserve original ingredient ID
                    name: snapshot.name,
                    quantity: snapshot.quantity,
                    unit: snapshot.unit,
                    category: snapshot.category,
                    nutritionPer100g: snapshot.nutrition?.toNutritionInfo()
                )
                ingredient.ingredientType = Ingredient.IngredientType(rawValue: snapshot.ingredientType) ?? .other
                return ingredient
            },
            instructions: instructions,
            difficulty: Recipe.DifficultyLevel(rawValue: difficulty) ?? .easy,
            createdAt: createdAt,
            dietaryTags: dietaryTags.compactMap { Recipe.DietaryTag(rawValue: $0) }
        )
        
        // Explicitly set properties that aren't in the initializer
        recipe.nutrition = nutrition?.toNutritionInfo()
        recipe.isFavorite = isFavorite
        recipe.isBreakfast = isBreakfast
        recipe.isLunch = isLunch
        recipe.isDinner = isDinner
        recipe.isDessert = isDessert
        
        if let imageData = imageData {
            recipe.setImage(UIImage(data: imageData))
        }
        
        // Validation: Ensure critical fields are not nil
        assert(!name.isEmpty, "❌ Recipe snapshot toRecipe(): name is empty")
        assert(!category.isEmpty, "❌ Recipe snapshot toRecipe(): category is empty")
        assert(!instructions.isEmpty, "❌ Recipe snapshot toRecipe(): instructions is empty")
        
        #if DEBUG
        print("✅ Recipe restored from snapshot: id=\(id.uuidString), name=\(name), category=\(category)")
        #endif
        
        return recipe
    }
    
    static func from(_ recipe: Recipe) -> RecipeSnapshot {
        let snapshot = RecipeSnapshot(
            id: recipe.id,
            name: recipe.name,
            description: recipe.recipeDescription,
            category: recipe.category,
            servings: recipe.servings,
            prepTimeMinutes: recipe.prepTimeMinutes,
            cookTimeMinutes: recipe.cookTimeMinutes,
            instructions: recipe.instructions,
            difficulty: recipe.difficulty.rawValue,
            createdAt: recipe.createdAt,
            dietaryTags: recipe.dietaryTags.map { $0.rawValue },
            isFavorite: recipe.isFavorite,
            isBreakfast: recipe.isBreakfast,
            isLunch: recipe.isLunch,
            isDinner: recipe.isDinner,
            isDessert: recipe.isDessert,
            ingredientSnapshots: recipe.ingredients.map { IngredientSnapshot.from($0) },
            nutrition: recipe.nutrition.map { NutritionSnapshot.from($0) },
            imageData: recipe.image?.jpegData(compressionQuality: 0.7)
        )
        
        return snapshot
    }
}

struct IngredientSnapshot: Codable {
    let id: UUID
    let name: String
    let quantity: Double
    let unit: String
    let category: String
    let ingredientType: String
    let nutrition: NutritionSnapshot?
    
    func toIngredient() -> Ingredient {
        let ingredient = Ingredient(
            id: id,
            name: name,
            quantity: quantity,
            unit: unit,
            category: category,
            nutritionPer100g: nutrition?.toNutritionInfo()
        )
        ingredient.ingredientType = Ingredient.IngredientType(rawValue: ingredientType) ?? .other
        return ingredient
    }
    
    static func from(_ ingredient: Ingredient) -> IngredientSnapshot {
        IngredientSnapshot(
            id: ingredient.id,
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            category: ingredient.category,
            ingredientType: ingredient.ingredientType.rawValue,
            nutrition: ingredient.nutritionPer100g.map { NutritionSnapshot.from($0) }
        )
    }
}

struct MenuSnapshot: Codable {
    let id: UUID
    let name: String
    let weekStartDate: Date
    let lastModifiedAt: Date
    let notes: String?
    var dayMeals: [DayMealsSnapshot]
    
    func toMenu() -> Menu {
        let meals = dayMeals.map { $0.toDayMeals() }
        let menu = Menu(
            id: id,
            name: name,
            weekStartDate: weekStartDate,
            meals: meals,
            lastModifiedAt: lastModifiedAt,
            notes: notes
        )
        
        // Ensure back-references are set properly for SwiftData relationship tracking
        for dayMeal in menu.meals {
            dayMeal.menu = menu
        }
        
        // Validation
        #if DEBUG
        print("✅ Menu restored from snapshot: id=\(id.uuidString), name=\(name)")
        for (index, dayMeal) in menu.meals.enumerated() {
            print("   Day \(index): breakfast=\(dayMeal.breakfast?.name ?? "nil"), lunch=\(dayMeal.lunch?.name ?? "nil"), dinner=\(dayMeal.dinner?.name ?? "nil")")
        }
        #endif
        
        return menu
    }
    
    func toMenuWithoutRecipes() -> Menu {
        // Create menu with empty day meals to avoid recipe validation issues
        let emptyMeals = (0..<7).map { _ in
            DayMeals(breakfast: nil, lunch: nil, dinner: nil)
        }
        let menu = Menu(
            id: id,
            name: name,
            weekStartDate: weekStartDate,
            meals: emptyMeals,
            lastModifiedAt: lastModifiedAt,
            notes: notes
        )
        return menu
    }
    
    static func from(_ menu: Menu) -> MenuSnapshot {
        let dayMealsSnapshots = menu.meals.map { dayMeal in
            return DayMealsSnapshot.from(dayMeal)
        }
        
        return MenuSnapshot(
            id: menu.id,
            name: menu.name,
            weekStartDate: menu.weekStartDate,
            lastModifiedAt: menu.lastModifiedAt,
            notes: menu.notes,
            dayMeals: dayMealsSnapshots
        )
    }
}

struct DayMealsSnapshot: Codable {
    let breakfast: RecipeSnapshot?
    let lunch: RecipeSnapshot?
    let dinner: RecipeSnapshot?
    
    func toDayMeals() -> DayMeals {
        #if DEBUG
        print("🔄 DayMealsSnapshot.toDayMeals(): breakfast=\(breakfast?.name ?? "nil"), lunch=\(lunch?.name ?? "nil"), dinner=\(dinner?.name ?? "nil")")
        #endif
        
        let breakfast = breakfast?.toRecipe()
        let lunch = lunch?.toRecipe()
        let dinner = dinner?.toRecipe()
        
        let dayMeals = DayMeals(breakfast: breakfast, lunch: lunch, dinner: dinner)
        
        #if DEBUG
        print("✅ DayMeals created: breakfast=\(dayMeals.breakfast?.name ?? "nil"), lunch=\(dayMeals.lunch?.name ?? "nil"), dinner=\(dayMeals.dinner?.name ?? "nil")")
        #endif
        
        return dayMeals
    }
    
    static func from(_ dayMeals: DayMeals) -> DayMealsSnapshot {
        DayMealsSnapshot(
            breakfast: dayMeals.breakfast.map { RecipeSnapshot.from($0) },
            lunch: dayMeals.lunch.map { RecipeSnapshot.from($0) },
            dinner: dayMeals.dinner.map { RecipeSnapshot.from($0) }
        )
    }
}

struct ShoppingItemSnapshot: Codable {
    let id: UUID
    let name: String
    let quantity: Double
    let unit: String
    let category: String
    let isChecked: Bool
    let price: Double?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    func toShoppingItem() -> ShoppingItem {
        // IMPORTANT: Preserve original ID and timestamps to avoid creating duplicates on undo/redo
        return ShoppingItem(
            id: id,
            name: name,
            quantity: quantity,
            unit: unit,
            category: category,
            isChecked: isChecked,
            price: price,
            notes: notes,
            createdAt: createdAt,  // Preserve original creation time
            updatedAt: updatedAt
        )
    }
    
    static func from(_ item: ShoppingItem) -> ShoppingItemSnapshot {
        ShoppingItemSnapshot(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            category: item.category,
            isChecked: item.isChecked,
            price: item.price,
            notes: item.notes,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt
        )
    }
}

struct NutritionSnapshot: Codable {
    let caloriesKcal: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let saturatedFat: Double
    let fiber: Double
    let sugars: Double
    let alcohol: Double
    
    func toNutritionInfo() -> NutritionInfo {
        return NutritionInfo(
            caloriesKcal: caloriesKcal,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            saturatedFat: saturatedFat,
            fiber: fiber,
            sugars: sugars,
            alcohol: alcohol
        )
    }
    
    static func from(_ nutrition: NutritionInfo) -> NutritionSnapshot {
        NutritionSnapshot(
            caloriesKcal: nutrition.caloriesKcal,
            protein: nutrition.protein,
            carbohydrates: nutrition.carbohydrates,
            fat: nutrition.fat,
            saturatedFat: nutrition.saturatedFat,
            fiber: nutrition.fiber,
            sugars: nutrition.sugars,
            alcohol: nutrition.alcohol
        )
    }
}
