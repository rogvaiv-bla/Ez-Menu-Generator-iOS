//
// OpenFoodFactsModels.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Codable models for Open Food Facts API responses
// Handles optional fields gracefully using Optional decoding
// Represents product information from Open Food Facts database
//
// MARK: - API Reference
// https://wiki.openfoodfacts.org/API/Reference/Products
//
// MARK: - Field Mapping
// - energy-kcal_100g  → kcal per 100g
// - proteins_100g     → protein per 100g
// - fat_100g          → fat per 100g
// - carbohydrates_100g → carbs per 100g
//

import Foundation

// MARK: - API Response

/// Top-level API response from Open Food Facts
struct OpenFoodFactsResponse: Codable {
    let status: Int? // 1 = found, 0 = not found
    let product: OpenFoodFactsProduct?
    let code: String?
    let statusVerbose: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case product
        case code
        case statusVerbose = "status_verbose"
    }
}

// MARK: - Product Model

/// Product information from Open Food Facts
struct OpenFoodFactsProduct: Codable {
    /// Product name (required)
    let productName: String?
    
    /// Brand name
    let brands: String?
    
    /// Barcode/EAN
    let code: String?
    
    /// Product category (e.g., "Snacks")
    let categories: String?
    
    /// Country where sold
    let countriesTags: [String]?
    
    /// Front image URL
    let imageFrontUrl: String?
    
    /// Small front image URL
    let imageFrontSmallUrl: String?
    
    /// Nutrition information per 100g
    let nutriments: OpenFoodFactsNutriments?
    
    /// Generic name
    let genericName: String?
    
    /// Quantity (e.g., "400g")
    let quantity: String?
    
    /// Allergens tags (comma-separated)
    let allergensTags: [String]?
    
    /// Whether product contains alcohol
    let containsAlcohol: Bool?
    
    /// Ingredients text
    let ingredientsText: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case code
        case categories
        case countriesTags = "countries_tags"
        case imageFrontUrl = "image_front_url"
        case imageFrontSmallUrl = "image_front_small_url"
        case nutriments
        case genericName = "generic_name"
        case quantity
        case allergensTags = "allergens_tags"
        case containsAlcohol = "contains_alcohol"
        case ingredientsText = "ingredients_text"
    }
}

// MARK: - Nutriments Model

/// Nutritional information per 100g
struct OpenFoodFactsNutriments: Codable {
    /// Energy in kcal per 100g
    let energyKcal100g: Double?
    
    /// Proteins in grams per 100g
    let proteins100g: Double?
    
    /// Fat in grams per 100g
    let fat100g: Double?
    
    /// Carbohydrates in grams per 100g
    let carbohydrates100g: Double?
    
    /// Fiber in grams per 100g
    let fiber100g: Double?
    
    /// Sugar in grams per 100g
    let sugars100g: Double?
    
    /// Salt in grams per 100g
    let salt100g: Double?
    
    /// Saturated fat in grams per 100g
    let saturatedFat100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case fat100g = "fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
        case salt100g = "salt_100g"
        case saturatedFat100g = "saturated-fat_100g"
    }
}

// MARK: - Error Types

/// Errors that can occur during API communication
enum OpenFoodFactsError: LocalizedError {
    /// Product not found (HTTP 404 or status=0)
    case productNotFound(barcode: String)
    
    /// Invalid barcode format
    case invalidBarcode
    
    /// Network error (no internet, timeout, etc.)
    case networkError(Error)
    
    /// JSON decoding failed
    case decodingError(Error)
    
    /// Missing required fields in response
    case missingRequiredFields(field: String)
    
    /// Invalid API response structure
    case invalidResponse
    
    /// Server returned error
    case serverError(statusCode: Int, message: String)
    
    /// Generic/unknown error
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound(let barcode):
            return "Produsul cu codul de bare \(barcode) nu a fost găsit în baza de date Open Food Facts"
        case .invalidBarcode:
            return "Codul de bare este invalid (trebuie să conțină doar cifre)"
        case .networkError(let error):
            return "Eroare de rețea: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Eroare la decodarea datelor: \(error.localizedDescription)"
        case .missingRequiredFields(let field):
            return "Lipsesc câmpurile obligatorii: \(field)"
        case .invalidResponse:
            return "Răspunsul API este invalid"
        case .serverError(let code, let message):
            return "Eroare server (\(code)): \(message)"
        case .unknownError:
            return "Eroare necunoscută"
        }
    }
}
