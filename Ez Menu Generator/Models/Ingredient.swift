//
// Ingredient.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Ingredient model with auto-detection of ingredient type:
// - Name, quantity, unit tracking
// - Category organization
// - IngredientType enum (11 types for classification)
// - Automatic type detection by IngredientTypeDetector (50+ keywords)
//
// MARK: - Usage
// - Added in AddRecipeView via AddIngredientView
// - Aggregated for shopping lists
// - Type used for dietary constraint checking
//

import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID  
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var ingredientType: IngredientType = IngredientType.other
    var recipe: Recipe?  // Inverse relationship to Recipe
    
    // Nutrition data - stored as JSON string to avoid SwiftData serialization issues
    @Attribute(.externalStorage) private var nutritionJsonData: String?
    
    nonisolated var nutritionPer100g: NutritionInfo? {
        get {
            guard let jsonData = nutritionJsonData else { return nil }
            let decoder = JSONDecoder()
            return try? decoder.decode(NutritionInfo.self, from: jsonData.data(using: .utf8) ?? Data())
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(newValue),
                   let jsonString = String(data: encoded, encoding: .utf8) {
                    nutritionJsonData = jsonString
                }
            } else {
                nutritionJsonData = nil
            }
        }
    }
    
    enum IngredientType: String, Codable, CaseIterable {
        case redMeat = "Carne roșie"
        case poultry = "Carne de pasăre"
        case fish = "Pește"
        case eggs = "Ouă"
        case processedMeats = "Mezeluri"
        case legumes = "Legume uscate"
        case fruit = "Fructe"
        case dairy = "Lactaticine"
        case nuts = "Nuci/semințe"
        case oil = "Ulei"
        case other = "Altul"
    }
    
    init(id: UUID = UUID(), name: String, quantity: Double = 1.0, unit: String = "buc", category: String = "Legume", nutritionPer100g: NutritionInfo? = nil, ingredientType: IngredientType = .other) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.nutritionPer100g = nutritionPer100g
        self.ingredientType = ingredientType
    }
    
    convenience init(id: UUID = UUID(), name: String, quantity: Double = 1.0, unit: String = "buc", category: String = "Legume", nutritionPer100g: NutritionInfo? = nil) {
        let detectedType = IngredientTypeDetector.detectType(for: name)
        self.init(id: id, name: name, quantity: quantity, unit: unit, category: category, nutritionPer100g: nutritionPer100g, ingredientType: detectedType)
    }
}
