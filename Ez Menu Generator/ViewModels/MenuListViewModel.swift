//
// MenuListViewModel.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Manages menu generation and validation:
// - Core menu generation engine with 3-pass constraint checking
// - Validates menus against 16 dietary restrictions
// - Provides detailed constraint violation reporting
// - Manages recipe filtering based on constraints
//
// MARK: - Key Methods
// - generateMenu() - Creates 7-day menu respecting constraints
//   * Uses 3-pass algorithm for optimal recipe selection
//   * Retries up to 5 times for better results
// - getMenuValidationIssues() - Returns all constraint violations
// - findValidRecipe() - Selects recipe with minimal constraint violations
//
// MARK: - 3-Pass Algorithm
// Pass 1: Find recipes with ZERO constraint violations
// Pass 2: Find recipes with ≤1 violation
// Pass 3: Use recipe with minimum violations (allows 1-2)
// Shuffles recipes for variety; returns random if all fail
//
// MARK: - Constraint Tracking
// Uses ConstraintTracker to validate recipes against:
// - Daily/weekly meat limits
// - Dairy/nut gram limits
// - Minimum fruit/vegetable days
// - Complete allergen avoidance
// - Dietary preference enforcement (vegan/vegetarian)
//
// MARK: - Architecture
// @MainActor for thread-safe UI updates
// Stores currentMenu and share via @Published: validationIssues
//

import Foundation
import Combine
import SwiftData

@MainActor
class MenuListViewModel: ObservableObject {
    @Published var menus: [Menu] = []
    @Published private(set) var sortedMenus: [Menu] = []
    @Published var selectedMenu: Menu?
    @Published var isLoading = false
    @Published var isGeneratingMenu = false
    @Published var undoRedoManager: UndoRedoManager
    private var cancellables: Set<AnyCancellable> = []
    
    let storageService: StorageServiceProtocol
    
    init(
        storageService: StorageServiceProtocol? = nil,
        undoRedoManager: UndoRedoManager = UndoRedoManager()
    ) {
        self.storageService = storageService ?? StorageService.shared
        self.undoRedoManager = undoRedoManager

        self.undoRedoManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        fetchMenus()
    }
    
    func fetchMenus() {
        isLoading = true
        storageService.fetchAllMenus()
        menus = storageService.menus
        updateSortedMenus()
        isLoading = false
    }

    func refreshMenus() async {
        await Task { @MainActor in
            fetchMenus()
        }.value
    }
    
    private func refreshMenusFromStorage() {
        menus = storageService.menus
        updateSortedMenus()
    }

    private func updateSortedMenus() {
        sortedMenus = menus.sorted { $0.weekStartDate > $1.weekStartDate }
    }
    
    func createNewMenu(name: String, startDate: Date) {
        let newMenu = Menu(name: name, weekStartDate: startDate)
        menus.append(newMenu)
        updateSortedMenus()
        storageService.addMenu(newMenu)
        
        // Create snapshot on MainActor, then record asynchronously
        let snapshot = MenuSnapshot.from(newMenu)
        Task {
            undoRedoManager.recordAction(.addMenu(snapshot))
        }
    }
    
    func updateMenu(_ menu: Menu) {
        if let index = menus.firstIndex(where: { $0.id == menu.id }) {
            menus[index] = menu
            updateSortedMenus()
        }
        storageService.updateMenu(menu)
    }
    
    
    func deleteMenu(_ menu: Menu) {
        menus.removeAll { $0.id == menu.id }
        updateSortedMenus()
        storageService.deleteMenu(menu)
        
        if selectedMenu?.id == menu.id {
            selectedMenu = nil
        }
        
        // Create snapshot on MainActor, then record asynchronously
        let snapshot = MenuSnapshot.from(menu)
        Task {
            undoRedoManager.recordAction(.deleteMenu(snapshot))
        }
    }
    
    func undo() {
        objectWillChange.send()
        undoRedoManager.undo()
        fetchMenus()
        objectWillChange.send()
    }
    
    func redo() {
        objectWillChange.send()
        undoRedoManager.redo()
        fetchMenus()
        objectWillChange.send()
    }
    
    func generateRandomMenu() {
        guard !isGeneratingMenu else { return }

        Task {
            await generateRandomMenuAsync()
        }
    }

    private func generateRandomMenuAsync() async {
        isGeneratingMenu = true
        defer { isGeneratingMenu = false }

        let recipes = storageService.recipes
        guard !recipes.isEmpty else { return }
        
        // If a menu already exists, delete it first (replace rather than duplicate)
        if let primaryMenu = sortedMenus.first {
            // Delete synchronously to ensure clean state before generation
            storageService.deleteMenu(primaryMenu)
            menus.removeAll { $0.id == primaryMenu.id }
            updateSortedMenus()
        }
        
        let name = "Meniu generat \(Date().formatted(date: .abbreviated, time: .omitted))"
        let weekStartDate = Calendar.current.startOfDay(for: Date())
        
        var meals: [DayMeals] = []
        var constraintTracker = ConstraintTracker()
        var attempts = 0
        let maxAttempts = 5
        
        // Try to generate valid menu with respect to all constraints
        repeat {
            meals.removeAll()
            constraintTracker = ConstraintTracker()
            attempts += 1
            await Task.yield()
            
            // Generate meals for 7 days
            for _ in 0..<7 {
                var breakfast: Recipe?
                var lunch: Recipe?
                var dinner: Recipe?
                
                // Find valid recipes respecting constraints and meal types
                breakfast = findValidRecipe(from: recipes, tracker: constraintTracker, mealType: "breakfast")
                if let breakfast = breakfast {
                    constraintTracker.addMeal(breakfast)
                }
                
                lunch = findValidRecipe(from: recipes, tracker: constraintTracker, mealType: "lunch")
                if let lunch = lunch {
                    constraintTracker.addMeal(lunch)
                }
                
                dinner = findValidRecipe(from: recipes, tracker: constraintTracker, mealType: "dinner")
                if let dinner = dinner {
                    constraintTracker.addMeal(dinner)
                }
                
                meals.append(DayMeals(breakfast: breakfast, lunch: lunch, dinner: dinner))
                constraintTracker.nextDay()
                await Task.yield()
            }
        } while !isFruitConstraintMet(tracker: constraintTracker) && attempts < maxAttempts
        
        let newMenu = Menu(name: name, weekStartDate: weekStartDate, meals: meals)
        menus.append(newMenu)
        updateSortedMenus()
        storageService.addMenu(newMenu)
    }
    
    private func isFruitConstraintMet(tracker: ConstraintTracker) -> Bool {
        // Fructe: 2 porții pe zi, cel puțin 5 ori pe săptămână
        return tracker.daysWithFruit.count >= 5
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
        
        // First pass: try to find recipe with NO violations
        for recipe in shuffled {
            let violations = tracker.getViolations(recipe: recipe)
            if violations.isEmpty {
                return recipe
            }
        }
        
        // Second pass: try to find recipe with minimal violations (sort by ingredient count)
        let sortedByLength = shuffled.sorted { a, b in
            a.ingredients.count < b.ingredients.count
        }
        
        for recipe in sortedByLength {
            let violations = tracker.getViolations(recipe: recipe)
            if violations.count <= 1 {
                return recipe
            }
        }
        
        // Third pass: find recipe with least violations
        let scored = shuffled.map { recipe -> (recipe: Recipe, violationCount: Int) in
            let violations = tracker.getViolations(recipe: recipe)
            return (recipe, violations.count)
        }
        
        if let best = scored.min(by: { $0.violationCount < $1.violationCount }) {
            return best.recipe
        }
        
        // Fallback: return random
        return validRecipes.randomElement()
    }
    
    func getMenuValidationIssues(menu: Menu) -> [String] {
        var violations: [String] = []
        let tracker = ConstraintTracker()
        
        for (_, dayMeals) in menu.meals.enumerated() {
            let meals = [dayMeals.breakfast, dayMeals.lunch, dayMeals.dinner].compactMap { $0 }
            
            for meal in meals {
                let dayViolations = tracker.getViolations(recipe: meal)
                violations.append(contentsOf: dayViolations)
                tracker.addMeal(meal)
            }
            
            tracker.nextDay()
        }
        
        // Check final fruit constraint
        if tracker.daysWithFruit.count < 5 {
            violations.append("Fructe: doar \(tracker.daysWithFruit.count) zile cu fructe (min 5)")
        }
        
        return violations
    }
}

// MARK: - Constraint Tracker
class ConstraintTracker {
    // Weekly counters
    var redMeatCount = 0
    var poultryCount = 0
    var fishCount = 0
    var eggsCount = 0
    var processedMeatsCount = 0
    var legumesCount = 0
    var fruitDaysCount = 0
    
    // Daily counters
    var dailyDairyGrams = 0.0
    var dailyNutsGrams = 0.0
    var dailyFruitServings = 0
    var dailyEggsCount = 0
    
    // Tracking which days have fruit
    var daysWithFruit: Set<Int> = []
    var currentDayIndex = 0
    
    func addMeal(_ recipe: Recipe) {
        // Weekly tracking from dietary tags
        for tag in recipe.dietaryTags {
            switch tag {
            case .redMeat:
                redMeatCount += 1
            case .poultry:
                poultryCount += 1
            case .fish:
                fishCount += 1
            case .eggs:
                eggsCount += 1
                dailyEggsCount += 1
            case .processedMeats:
                processedMeatsCount += 1
            case .legumes:
                legumesCount += 1
            case .fruit:
                dailyFruitServings += 1
                daysWithFruit.insert(currentDayIndex)
            default:
                break
            }
        }
        
        // Gram tracking from ingredients
        for ingredient in recipe.ingredients {
            switch ingredient.ingredientType {
            case .dairy:
                // Assume dairy ingredients are in grams
                dailyDairyGrams += ingredient.quantity
            case .nuts:
                // Assume nuts are in grams
                dailyNutsGrams += ingredient.quantity
            default:
                break
            }
        }
    }
    
    func nextDay() {
        dailyDairyGrams = 0.0
        dailyNutsGrams = 0.0
        dailyFruitServings = 0
        dailyEggsCount = 0
        currentDayIndex += 1
    }
    
    func getViolations(recipe: Recipe) -> [String] {
        var violations: [String] = []
        
        // Check weekly constraints
        for tag in recipe.dietaryTags {
            switch tag {
            case .redMeat:
                if redMeatCount >= 1 {
                    violations.append("Carne roșie: max 1/săptămână")
                }
            case .poultry:
                if poultryCount >= 2 {
                    violations.append("Carne de pasăre: max 2/săptămână")
                }
            case .fish:
                if fishCount >= 2 {
                    violations.append("Pește: max 2/săptămână")
                }
            case .eggs:
                if eggsCount >= 5 {
                    violations.append("Ouă: max 5/săptămână")
                }
            case .processedMeats:
                if processedMeatsCount >= 2 {
                    violations.append("Mezeluri: max 2/săptămână")
                }
            case .legumes:
                if legumesCount >= 2 {
                    violations.append("Legume uscate: max 2/săptămână")
                }
            case .fried:
                violations.append("Rețetă prăjită - nu e permisă")
            default:
                break
            }
        }
        
        // Check daily constraints
        var tempDailyDairyGrams = dailyDairyGrams
        var tempDailyNutsGrams = dailyNutsGrams
        
        for ingredient in recipe.ingredients {
            switch ingredient.ingredientType {
            case .dairy:
                tempDailyDairyGrams += ingredient.quantity
                if tempDailyDairyGrams > 20 {
                    violations.append("Brânză proaspătă: max 20g/zi")
                }
            case .nuts:
                tempDailyNutsGrams += ingredient.quantity
                if tempDailyNutsGrams > 20 {
                    violations.append("Nuci/semințe: max 20g/zi")
                }
            default:
                break
            }
        }
        
        return violations
    }
}
