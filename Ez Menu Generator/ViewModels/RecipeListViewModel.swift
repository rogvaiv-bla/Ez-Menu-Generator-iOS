//
// RecipeListViewModel.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Manages recipe library (CRUD operations):
// - Create/Read/Update/Delete recipes
// - Auto-detect ingredient types and dietary tags
// - Calculate total nutrition from ingredients
// - Undo/redo support for deletions
// - Search/filter recipes
//
// MARK: - Key Methods
// - addRecipe() - Create new recipe with ingredients
// - updateRecipe() - Modify existing recipe
// - deleteRecipe() - Remove recipe (with undo support)
// - autoDetectDietaryTags() - Analyze ingredients for dietary tags
// - calculateTotalNutrition() - Sum nutrition from all ingredients
//
// MARK: - Auto-Detection
// Uses IngredientTypeDetector (50+ keywords):
// - Identifies ingredient types (meat, dairy, fruit, etc.)
// - Sets dietary tags based on ingredients
// - E.g. beef -> redMeat tag
//
// MARK: - Architecture
// MainActor for thread-safe updates
// Syncs with StorageService for persistence
// UndoRedoManager handles undo/redo state
//

import Foundation
import Combine
import SwiftData

@MainActor
class RecipeListViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory = "Toate"
    @Published var showFavoritesOnly = false
    @Published var undoRedoManager: UndoRedoManager
    private var cancellables: Set<AnyCancellable> = []
    private var hasFetchedInitialRecipes = false
    
    let storageService: StorageServiceProtocol
    
    init(
        storageService: StorageServiceProtocol? = nil,
        undoRedoManager: UndoRedoManager = UndoRedoManager()
    ) {
        self.storageService = storageService ?? StorageService.shared
        self.undoRedoManager = undoRedoManager

        // Propagate nested UndoRedoManager published changes (canUndo/canRedo)
        // so views observing RecipeListViewModel refresh immediately.
        self.undoRedoManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Fetch recipes only once on initialization
        Task {
            await MainActor.run {
                self.fetchRecipes()
            }
        }
    }
    
    var filteredRecipes: [Recipe] {
        let filtered = recipes.filter { recipe in
            let matchesSearch = searchText.isEmpty || recipe.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "Toate" || recipe.category == selectedCategory
            let matchesFavorite = !showFavoritesOnly || recipe.isFavorite
            return matchesSearch && matchesCategory && matchesFavorite
        }
        return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    var categories: [String] {
        let cats = Set(recipes.map { $0.category })
        return ["Toate"] + cats.sorted()
    }
    
    func fetchRecipes() {
        guard !hasFetchedInitialRecipes else { return }
        isLoading = true
        storageService.fetchAllRecipes()
        
        // Direct assignment - StorageService already deduplicated
        recipes = storageService.recipes
        
        hasFetchedInitialRecipes = true
        isLoading = false
    }

    func fetchRecipes(force: Bool) {
        guard force || !hasFetchedInitialRecipes else { return }
        isLoading = true
        storageService.fetchAllRecipes()
        
        // Direct assignment - StorageService already deduplicated
        recipes = storageService.recipes
        
        if force {
            // Don't update hasFetchedInitialRecipes when forcing, so initial fetch can still happen
        } else {
            hasFetchedInitialRecipes = true
        }
        isLoading = false
    }
    
    func addRecipe(_ recipe: Recipe) {
        recipes.append(recipe)
        storageService.addRecipe(recipe)
        
        // Create snapshot on MainActor, then record asynchronously
        let snapshot = RecipeSnapshot.from(recipe)
        Task {
            undoRedoManager.recordAction(.addRecipe(snapshot))
        }
    }

    func updateRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        }
        storageService.updateRecipe(recipe)
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        // Capture snapshot BEFORE delete to avoid reading faulted properties
        // (e.g. dietaryTags/ingredientType) from a detached SwiftData object.
        let snapshot = RecipeSnapshot.from(recipe)

        recipes.removeAll { $0.id == recipe.id }
        storageService.deleteRecipe(recipe)

        // Record delete for undo using the pre-delete snapshot
        Task {
            undoRedoManager.recordAction(.deleteRecipe(snapshot))
        }
    }
    
    func refreshRecipes() async {
        await Task { @MainActor in
            fetchRecipes(force: true)
        }.value
    }
    
    func undo() {
        objectWillChange.send()
        undoRedoManager.undo()
        fetchRecipes(force: true)
        objectWillChange.send()
    }
    
    func redo() {
        objectWillChange.send()
        undoRedoManager.redo()
        fetchRecipes(force: true)
        objectWillChange.send()
    }
}
