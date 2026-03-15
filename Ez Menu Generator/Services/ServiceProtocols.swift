import Foundation
import SwiftData
import SwiftUI

/// PHASE 4 - Dependency Injection Layer
/// Protocol-based service architecture for testability and flexibility

// MARK: - Storage Service Protocol

protocol StorageServiceProtocol {
    var recipes: [Recipe] { get }
    var menus: [Menu] { get }
    var shoppingItems: [ShoppingItem] { get }
    
    func fetchAllRecipes()
    func addRecipe(_ recipe: Recipe)
    func updateRecipe(_ recipe: Recipe)
    func deleteRecipe(_ recipe: Recipe)
    
    func fetchAllMenus()
    func addMenu(_ menu: Menu)
    func updateMenu(_ menu: Menu)
    func deleteMenu(_ menu: Menu)
    
    func fetchAllShoppingItems()
    func addShoppingItem(_ item: ShoppingItem)
    func addShoppingItems(_ items: [ShoppingItem])
    func updateShoppingItem(_ item: ShoppingItem)
    func updateShoppingItems(_ items: [ShoppingItem])
    func deleteShoppingItem(_ item: ShoppingItem)
    func clearShoppingList()
}

// MARK: - Open Food Facts Service Protocol

protocol ProductSearchServiceProtocol {
    func fetchProduct(barcode: String) async throws -> OpenFoodFactsProduct
}

// MARK: - StorageService Extension to conform to protocol

extension StorageService: StorageServiceProtocol {}

// MARK: - OpenFoodFactsService Extension to conform to protocol

extension OpenFoodFactsService: ProductSearchServiceProtocol {}

// MARK: - Service Container (Dependency Injection Container)

@MainActor
class ServiceContainer {
    
    // MARK: - Singleton
    
    static let shared = ServiceContainer()
    
    // MARK: - Services
    
    let storageService: StorageServiceProtocol
    let productSearchService: ProductSearchServiceProtocol
    
    // MARK: - Initializer (allows dependency injection for testing)
    
    init(
        storageService: StorageServiceProtocol? = nil,
        productSearchService: ProductSearchServiceProtocol? = nil
    ) {
        self.storageService = storageService ?? StorageService.shared
        self.productSearchService = productSearchService ?? OpenFoodFactsService.shared
    }
    
    // MARK: - Factory Methods for ViewModels
    
    func makeRecipeListViewModel() -> RecipeListViewModel {
        RecipeListViewModel(storageService: storageService)
    }
    
    func makeMenuListViewModel() -> MenuListViewModel {
        MenuListViewModel(storageService: storageService)
    }
    
    func makeShoppingListViewModel() -> ShoppingListViewModel {
        ShoppingListViewModel(storageService: storageService)
    }
    
    func makeProductSearchViewModel() -> ProductSearchViewModel {
        ProductSearchViewModel(productSearchService: productSearchService)
    }
}

// MARK: - Environment Key for ServiceContainer

struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// MARK: - View Extension for easy access

extension View {
    func serviceContainer(_ container: ServiceContainer) -> some View {
        environment(\.serviceContainer, container)
    }
}
