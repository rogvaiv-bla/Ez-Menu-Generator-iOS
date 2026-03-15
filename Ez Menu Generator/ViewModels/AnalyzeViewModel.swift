//
// AnalyzeViewModel.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Product search with local database and Open Food Facts API integration:
// - Search by name in local database
// - Search by barcode via Open Food Facts API
// - Filter by category
// - Display complete nutrition information
// - Handle API errors gracefully
//
// MARK: - Key Methods
// - updateFiltered() - Search local products by name
// - searchByBarcode() - Lookup product via Open Food Facts API
// - getProductNutrition() - Extract nutrition from local or API product
//
// MARK: - Usage
// Used in AddIngredientView, ProductSearchView for ingredient selection
// Supports both local database and online lookups
// Shows full nutrition per 100g
//
// MARK: - Architecture
// Observable pattern for SwiftUI reactivity
// Asynchronous API calls with proper error handling
// Fallback to local database if API unavailable
//

import SwiftUI
import SwiftData
import os.log

// Logging via system os_log

@MainActor
@Observable
class AnalyzeViewModel {
    var searchText: String = ""
    var selectedCategory: String = "Toate"
    var filteredProducts: [FoodProduct] = []
    
    // Open Food Facts API
    var isLoadingProduct = false
    var apiProductName: String?
    var apiProductBrand: String?
    var apiProductImage: String?
    var apiProductNutrition: (kcal: Double?, protein: Double?, fat: Double?, carbs: Double?)?
    var apiError: String?
    
    private let productSearchService: ProductSearchServiceProtocol
    
    init(productSearchService: ProductSearchServiceProtocol? = nil) {
        self.productSearchService = productSearchService ?? OpenFoodFactsService.shared
        updateFiltered()
    }
    
    // MARK: - Local Product Search
    
    func updateFiltered() {
        let searchResults = searchText.isEmpty ? 
            ProductDatabaseService.products : 
            ProductDatabaseService.searchProducts(query: searchText)
        
        if selectedCategory == "Toate" {
            filteredProducts = searchResults
        } else {
            filteredProducts = searchResults.filter { $0.category == selectedCategory }
        }
    }
    
    // MARK: - Open Food Facts API Search
    
    /// Search for product by barcode via Open Food Facts
    /// - Parameter barcode: Product barcode/EAN (digits only)
    ///
    /// Usage:
    /// ```swift
    /// await viewModel.searchByBarcode("5411188000181")
    /// if let name = viewModel.apiProductName {
    ///     print("Found: \(name)")
    ///     print("Kcal: \(viewModel.apiProductNutrition?.kcal ?? 0)")
    /// }
    /// ```
    func searchByBarcode(_ barcode: String) async {
        isLoadingProduct = true
        
        apiError = nil
        apiProductName = nil
        apiProductBrand = nil
        apiProductNutrition = nil
        
        do {
            let product = try await productSearchService.fetchProduct(barcode: barcode)
            
            // Extract and cache product data
            apiProductName = product.productName
            apiProductBrand = product.brands
            apiProductImage = product.imageFrontSmallUrl ?? product.imageFrontUrl
            
            // Extract nutrition data
            if let nutriments = product.nutriments {
                apiProductNutrition = (
                    kcal: nutriments.energyKcal100g,
                    protein: nutriments.proteins100g,
                    fat: nutriments.fat100g,
                    carbs: nutriments.carbohydrates100g
                )
            }
            
            isLoadingProduct = false
            
        } catch let error as OpenFoodFactsError {
            isLoadingProduct = false
            apiError = error.localizedDescription
            print("[ViewModel] ❌ API Error: \(error.localizedDescription)")
            print("[ViewModel] 📊 Loading state: OFF")
            // logger.error("❌ Product search failed: \(error.localizedDescription)")
            
        } catch {
            isLoadingProduct = false
            apiError = "Eroare necunoscută: \(error.localizedDescription)"
            print("[ViewModel] ❌ Unexpected error: \(error)")
            print("[ViewModel] 📊 Loading state: OFF")
            // logger.error("❌ Unexpected error: \(error)")
        }
    }
    
    /// Clear API search results
    func clearAPIResults() {
        apiProductName = nil
        apiProductBrand = nil
        apiProductImage = nil
        apiProductNutrition = nil
        apiError = nil
    }
    
    /// Check if API search returned results
    var hasAPIResults: Bool {
        apiProductName != nil
    }
}

