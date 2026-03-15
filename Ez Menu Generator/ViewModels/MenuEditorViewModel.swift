//
// MenuEditorViewModel.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Manages state for single menu editing:
// - Assign recipes to day meals (breakfast/lunch/dinner)
// - Regenerate individual days respecting constraints
// - Generate aggregated shopping list from all meals
// - Updates persisted via StorageService
//
// MARK: - Usage
// Instantiated in MenuEditorView with specific Menu object
// Handles all user interactions within menu edit screen
//
// MARK: - Key Methods
// - assignRecipeToMeal() - Set recipe for specific day/meal type
// - regenerateDay() - Regenerate 3 meals for single day
//   * Respects constraints (ConstraintTracker)
//   * Uses ConstraintTracker 3-pass algorithm
// - generateShoppingList() - Aggregate ingredients from all meals
//   * Combines quantities by name+unit
//   * Groups by category
//
// MARK: - Architecture
// @MainActor ensures UI updates on main thread
// @ObservableObject for SwiftUI reactivity
// Uses ConstraintTracker for constraint validation
//

import Foundation
import Combine
import SwiftData

@MainActor
class MenuEditorViewModel: ObservableObject {
    @Published var currentMenu: Menu
    @Published var generatedShoppingList: [ShoppingItem] = []
    
    let storageService = StorageService.shared
    
    init(menu: Menu) {
        self.currentMenu = menu
        sanitizeInvalidMealAssignments()
    }
    
    func assignRecipeToMeal(dayIndex: Int, mealType: String, recipe: Recipe) {
        guard dayIndex >= 0 && dayIndex < currentMenu.meals.count else { return }
        guard recipeMatchesMealType(recipe, mealType: mealType) else { return }
        
        let dayMeal = currentMenu.meals[dayIndex]
        
        switch mealType {
        case "breakfast":
            dayMeal.breakfast = recipe
        case "lunch":
            dayMeal.lunch = recipe
        case "dinner":
            dayMeal.dinner = recipe
        default:
            break
        }
        
        currentMenu.meals[dayIndex] = dayMeal
        storageService.updateMenu(currentMenu)
    }
    
    func regenerateDay(dayIndex: Int) {
        guard dayIndex >= 0 && dayIndex < currentMenu.meals.count else { return }
        
        let recipes = storageService.recipes
        guard !recipes.isEmpty else { return }
        
        let tracker = ConstraintTracker()
        tracker.currentDayIndex = dayIndex
        
        // Simulate tracker state up to this day
        for (idx, dayMeals) in currentMenu.meals.enumerated() {
            if idx < dayIndex {
                let meals = [dayMeals.breakfast, dayMeals.lunch, dayMeals.dinner].compactMap { $0 }
                for meal in meals {
                    tracker.addMeal(meal)
                }
                tracker.nextDay()
            }
        }
        
        // Generate new meals for this day
        let breakfast = findValidRecipe(from: recipes, tracker: tracker, mealType: "breakfast")
        if let breakfast = breakfast {
            tracker.addMeal(breakfast)
        }
        
        let lunch = findValidRecipe(from: recipes, tracker: tracker, mealType: "lunch")
        if let lunch = lunch {
            tracker.addMeal(lunch)
        }
        
        let dinner = findValidRecipe(from: recipes, tracker: tracker, mealType: "dinner")
        if let dinner = dinner {
            tracker.addMeal(dinner)
        }
        
        currentMenu.meals[dayIndex] = DayMeals(breakfast: breakfast, lunch: lunch, dinner: dinner)
        storageService.updateMenu(currentMenu)
    }
    
    private func findValidRecipe(from recipes: [Recipe], tracker: ConstraintTracker, mealType: String = "lunch") -> Recipe? {
        // Filter recipes by meal type
        let filteredRecipes = recipes.filter { recipe in
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
                return true // If no meal type specified, allow all
            }
        }
        
        guard !filteredRecipes.isEmpty else { return nil }
        let validRecipes = filteredRecipes
        let shuffled = validRecipes.shuffled()
        
        for recipe in shuffled {
            let violations = tracker.getViolations(recipe: recipe)
            if violations.isEmpty {
                return recipe
            }
        }
        
        return validRecipes.randomElement()
    }

    private func recipeMatchesMealType(_ recipe: Recipe, mealType: String) -> Bool {
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
            return false
        }
    }

    private func sanitizeInvalidMealAssignments() {
        var hasChanges = false

        for dayMeal in currentMenu.meals {
            if let breakfast = dayMeal.breakfast, !breakfast.isBreakfast {
                dayMeal.breakfast = nil
                hasChanges = true
            }
            if let lunch = dayMeal.lunch, !lunch.isLunch {
                dayMeal.lunch = nil
                hasChanges = true
            }
            if let dinner = dayMeal.dinner, !dinner.isDinner {
                dayMeal.dinner = nil
                hasChanges = true
            }
        }

        if hasChanges {
            storageService.updateMenu(currentMenu)
        }
    }
    
    func generateShoppingList() {
        var aggregatedItems: [String: ShoppingItem] = [:]
        
        for dayMeal in currentMenu.meals {
            let recipes = [dayMeal.breakfast, dayMeal.lunch, dayMeal.dinner].compactMap { $0 }
            
            for recipe in recipes {
                for ingredient in recipe.ingredients {
                    let key = "\(ingredient.name)-\(ingredient.unit)"
                    
                    if let existing = aggregatedItems[key] {
                        existing.quantity += ingredient.quantity
                    } else {
                        aggregatedItems[key] = ShoppingItem(
                            name: ingredient.name,
                            quantity: ingredient.quantity,
                            unit: ingredient.unit,
                            category: ingredient.category
                        )
                    }
                }
            }
        }
        
        generatedShoppingList = aggregatedItems.values.sorted { $0.category < $1.category }
    }
}

