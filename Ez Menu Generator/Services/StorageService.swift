//
// StorageService.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Centralized data persistence layer using SwiftData:
// - Recipe CRUD operations (Create, Read, Update, Delete)
// - Menu management (save, load, delete)
// - Shopping item persistence
// - Singleton pattern for app-wide access
// - Logging via OSLog for debugging
//
// MARK: - Usage
// Access via `StorageService.shared` from any ViewModel/View
// Example: `StorageService.shared.addRecipe(newRecipe)`
//
// MARK: - Key Methods
// - setupContainer() - Initialize SwiftData container
// - fetchAllRecipes() - Load all recipes (sorted by name)
// - addRecipe/addMenu/addShoppingItem()
// - updateRecipe/updateMenu() - Persist changes
// - deleteRecipe/deleteMenu() - Remove with logging
//
// MARK: - Architecture
// Uses @Published properties for SwiftUI reactivity
// All operations synchronized with SwiftData backend
//

import Foundation
import Combine
import SwiftData
import os.log

private let storageLog = OSLog(subsystem: "com.eduard.ezmenu", category: "StorageService")

@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()
    
    @Published var recipes: [Recipe] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var menus: [Menu] = []
    
    var modelContainer: ModelContainer?
    var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func setupContainer(_ container: ModelContainer) {
        self.modelContainer = container
        // Use autosave context which is provided by ModelContainer
        self.modelContext = ModelContext(container)
        // Fetch initial data
        fetchAllRecipes()
        fetchAllShoppingItems()
        fetchAllMenus()
    }
    
    // MARK: - Recipe Operations
    
    func fetchAllRecipes() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
            let fetchedRecipes = try context.fetch(descriptor)
            
            // Deduplicate by ID to prevent SwiftData relationship duplicates
            var uniqueRecipes: [UUID: Recipe] = [:]
            for recipe in fetchedRecipes {
                uniqueRecipes[recipe.id] = recipe
            }
            
            recipes = Array(uniqueRecipes.values).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            os_log("❌ Error fetching recipes: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func addRecipe(_ recipe: Recipe) {
        guard let context = modelContext else { return }
        do {
            context.insert(recipe)
            try context.save()
            fetchAllRecipes()
        } catch {
            os_log("❌ Error adding recipe: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func updateRecipe(_ recipe: Recipe) {
        guard let context = modelContext else { return }
        do {
            try context.save()
            fetchAllRecipes()
        } catch {
            os_log("❌ Error updating recipe: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        guard let context = modelContext else { return }
        do {
            context.delete(recipe)
            try context.save()
            fetchAllRecipes()
        } catch {
            os_log("❌ Error deleting recipe: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Shopping Item Operations
    
    func fetchAllShoppingItems() {
        guard let context = modelContext else { return }
        do {
            shoppingItems = try context.fetch(FetchDescriptor<ShoppingItem>(sortBy: [SortDescriptor(\.category), SortDescriptor(\.name)]))
        } catch {
            os_log("❌ Error fetching shopping items: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func addShoppingItem(_ item: ShoppingItem) {
        guard let context = modelContext else { return }
        do {
            context.insert(item)
            try context.save()
            fetchAllShoppingItems()
        } catch {
            os_log("❌ Error adding shopping item: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func updateShoppingItem(_ item: ShoppingItem) {
        guard let context = modelContext else { return }
        do {
            try context.save()
            fetchAllShoppingItems()
        } catch {
            os_log("❌ Error updating shopping item: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }

    func updateShoppingItems(_ items: [ShoppingItem]) {
        guard let context = modelContext, !items.isEmpty else { return }
        do {
            try context.save()
            fetchAllShoppingItems()
        } catch {
            os_log("❌ Error batch updating shopping items: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func deleteShoppingItem(_ item: ShoppingItem) {
        guard let context = modelContext else { return }
        do {
            context.delete(item)
            try context.save()
            fetchAllShoppingItems()
        } catch {
            os_log("❌ Error deleting shopping item: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func clearShoppingList() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: ShoppingItem.self)
            try context.save()
            fetchAllShoppingItems()
        } catch {
            os_log("❌ Error clearing shopping list: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func addShoppingItems(_ items: [ShoppingItem]) {
        guard let context = modelContext, !items.isEmpty else { return }
        do {
            for item in items {
                context.insert(item)
            }
            try context.save()
            fetchAllShoppingItems()
        } catch {
            os_log("❌ Error batch adding shopping items: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Menu Operations
    
    func fetchAllMenus() {
        guard let context = modelContext else { return }
        do {
            menus = try context.fetch(FetchDescriptor<Menu>(sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]))
        } catch {
            os_log("❌ Error fetching menus: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func addMenu(_ menu: Menu) {
        guard let context = modelContext else { return }
        do {
            // Simply insert the menu - SwiftData will handle recipes through relationships
            context.insert(menu)
            
            try context.save()
            
            // Refresh menus from storage
            fetchAllMenus()
            
        } catch {
            os_log("❌ Error adding menu: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func addMenuFromSnapshot(_ snapshot: MenuSnapshot) {
        guard let context = modelContext else { return }
        do {
            #if DEBUG
            print("📝 Restoring Menu from snapshot: \(snapshot.name) with \(snapshot.dayMeals.count) days")
            #endif
            
            // STRATEGY: Refetch recipes from database instead of recreating them
            // This avoids SwiftData object graph corruption
            
            // Step 1: Collect all recipe IDs from snapshot
            let recipeIds = Set<UUID>(
                snapshot.dayMeals.flatMap { dayMeal in
                    [dayMeal.breakfast?.id, dayMeal.lunch?.id, dayMeal.dinner?.id].compactMap { $0 }
                }
            )
            
            #if DEBUG
            print("   Need to find \(recipeIds.count) recipes: \(recipeIds.map { $0.uuidString }.joined(separator: ", "))")
            #endif
            
            // Step 2: Fetch recipes from database by ID
            var recipeMap: [UUID: Recipe] = [:]
            for recipeId in recipeIds {
                var descriptor = FetchDescriptor<Recipe>(
                    predicate: #Predicate { $0.id == recipeId }
                )
                descriptor.fetchLimit = 1
                
                if let recipe = try context.fetch(descriptor).first {
                    recipeMap[recipeId] = recipe
                    #if DEBUG
                    print("   ✅ Found recipe: \(recipe.name)")
                    #endif
                } else {
                    #if DEBUG
                    print("   ⚠️ Recipe not found in DB: \(recipeId.uuidString)")
                    #endif
                }
            }
            
            // Step 3: Build meals with refetched recipes
            let meals = snapshot.dayMeals.map { dayMealSnapshot in
                let breakfast = dayMealSnapshot.breakfast.flatMap { snap in recipeMap[snap.id] }
                let lunch = dayMealSnapshot.lunch.flatMap { snap in recipeMap[snap.id] }
                let dinner = dayMealSnapshot.dinner.flatMap { snap in recipeMap[snap.id] }
                
                #if DEBUG
                print("   Day meal: b=\(breakfast?.name ?? "nil"), l=\(lunch?.name ?? "nil"), d=\(dinner?.name ?? "nil")")
                #endif
                
                return DayMeals(breakfast: breakfast, lunch: lunch, dinner: dinner)
            }
            
            // Step 4: Create menu with refetched recipes
            let menu = Menu(
                id: snapshot.id,
                name: snapshot.name,
                weekStartDate: snapshot.weekStartDate,
                meals: meals,
                lastModifiedAt: snapshot.lastModifiedAt,
                notes: snapshot.notes
            )
            
            // Set back-references for SwiftData relationship tracking
            for dayMeal in menu.meals {
                dayMeal.menu = menu
            }
            
            // Step 5: Insert menu (recipes already exist in DB)
            context.insert(menu)
            
            #if DEBUG
            print("✅ Menu inserted, attempting save...")
            #endif
            
            try context.save()
            
            #if DEBUG
            print("✅ Menu restored and saved successfully (recipes refetched from DB)")
            #endif
            
            fetchAllMenus()
        } catch {
            os_log("❌ Error restoring menu from snapshot: %{public}@", log: storageLog, type: .error, error.localizedDescription)
            // Force reload from persistent store to avoid corrupted data
            do {
                modelContext?.rollback()
                try modelContext?.delete(model: Menu.self)
                fetchAllMenus()
            } catch {
                os_log("❌ Rollback failed: %{public}@", log: storageLog, type: .error, error.localizedDescription)
            }
        }
    }
    
    func updateMenu(_ menu: Menu) {
        guard let context = modelContext else { return }
        do {
            menu.lastModifiedAt = Date()
            try context.save()
            fetchAllMenus()
        } catch {
            os_log("❌ Error updating menu: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func deleteMenu(_ menu: Menu) {
        guard let context = modelContext else { return }
        do {
            context.delete(menu)
            try context.save()
            fetchAllMenus()
        } catch {
            os_log("❌ Error deleting menu: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func deleteMenuById(_ id: UUID) {
        guard let context = modelContext else { return }
        do {
            // Fetch the actual menu object from context by ID
            let descriptor = FetchDescriptor<Menu>(
                predicate: #Predicate { $0.id == id }
            )
            let results = try context.fetch(descriptor)
            if let menu = results.first {
                context.delete(menu)
                try context.save()
                fetchAllMenus()
            }
        } catch {
            os_log("❌ Error deleting menu by ID: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func deleteRecipeById(_ id: UUID) {
        guard let context = modelContext else { return }
        do {
            // Fetch the actual recipe object from context by ID
            let descriptor = FetchDescriptor<Recipe>(
                predicate: #Predicate { $0.id == id }
            )
            let results = try context.fetch(descriptor)
            if let recipe = results.first {
                context.delete(recipe)
                try context.save()
                fetchAllRecipes()
            }
            
        } catch {
            os_log("❌ Error deleting recipe by ID: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    func deleteShoppingItemById(_ id: UUID) {
        guard let context = modelContext else { return }
        do {
            // Fetch the actual shopping item object from context by ID
            let descriptor = FetchDescriptor<ShoppingItem>(
                predicate: #Predicate { $0.id == id }
            )
            let results = try context.fetch(descriptor)
            if let item = results.first {
                context.delete(item)
                try context.save()
                fetchAllShoppingItems()
            }
        } catch {
            os_log("❌ Error deleting shopping item by ID: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Utility
    
    func clearAllData() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: Recipe.self)
            try context.delete(model: ShoppingItem.self)
            try context.delete(model: Menu.self)
            try context.delete(model: Ingredient.self)
            try context.save()
            recipes.removeAll()
            shoppingItems.removeAll()
            menus.removeAll()
        } catch {
            os_log("❌ Error clearing all data: %{public}@", log: storageLog, type: .error, error.localizedDescription)
        }
    }
}
