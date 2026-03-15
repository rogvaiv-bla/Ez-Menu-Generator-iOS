//
// Recipe.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Defines the Recipe data model with:
// - Basic info (name, servings, prep/cook time)
// - Ingredients with relationships
// - Nutritional information
// - Dietary tags auto-detection
// - Favorite marking
//
// MARK: - Usage
// - Create recipes in AddRecipeView
// - Display in RecipeListView
// - Used in MenuListViewModel for menu generation
// - Dietary tags auto-populated by IngredientTypeDetector
//

import Foundation
import SwiftData
import UIKit

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    var recipeDescription: String
    var category: String
    var servings: Int
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe) var ingredients: [Ingredient]
    var instructions: String
    var difficulty: DifficultyLevel
    var createdAt: Date
    var dietaryTags: [DietaryTag] = []  // Tags for dietary restrictions
    var isFavorite: Bool = false  // Mark as favorite
    
    // Meal type categories
    var isBreakfast: Bool = false  // Potrivit pentru mic dejun
    var isLunch: Bool = false      // Potrivit pentru prânz
    var isDinner: Bool = false     // Potrivit pentru cină
    var isDessert: Bool = false    // Potrivit pentru desert
    
    // Computed property to check if recipe has at least one meal type
    var hasMealType: Bool {
        isBreakfast || isLunch || isDinner || isDessert
    }
    
    // Nutrition data - stored as JSON string to avoid SwiftData serialization issues
    @Attribute(.externalStorage) var nutritionJsonData: String?
    
    var nutrition: NutritionInfo? {
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
                    print("💾 Nutrition saved: \(String(format: "%.0f", newValue.caloriesKcal)) kcal")
                }
            } else {
                nutritionJsonData = nil
            }
        }
    }
    
    // Image data - stored as external storage to avoid DB bloat
    @Attribute(.externalStorage) var imageData: Data?
    
    // Cloud storage path for Supabase
    var supabaseImagePath: String?
    
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    func setImage(_ uiImage: UIImage?) {
        if let uiImage = uiImage {
            // Compress and store full image locally
            self.imageData = uiImage.jpegData(compressionQuality: 0.7)
            
            // Generate and cache thumbnail for fast list display
            let cached = ImageCacheManager.shared
            let thumbnail = cached.generateThumbnail(from: uiImage)
            cached.cacheThumbnail(thumbnail, for: id)
        } else {
            self.imageData = nil
        }
    }
    
    func uploadToCloud(_ uiImage: UIImage) async throws {
        let service = await MainActor.run { SupabaseImageService.shared }
        let imagePath = try await service.uploadImage(uiImage, for: id)
        self.supabaseImagePath = imagePath
        print("☁️ Recipe image stored in cloud: \(imagePath)")
    }

    func uploadToCloud(imageData: Data, mimeType: String, fileExtension: String) async throws {
        let service = await MainActor.run { SupabaseImageService.shared }
        let imagePath = try await service.uploadImageData(
            imageData,
            for: id,
            mimeType: mimeType,
            fileExtension: fileExtension
        )
        self.supabaseImagePath = imagePath
        print("☁️ Recipe image stored in cloud: \(imagePath)")
    }
    
    func deleteFromCloud() async throws {
        guard let imagePath = supabaseImagePath else { return }
        let service = await MainActor.run { SupabaseImageService.shared }
        try await service.deleteImage(at: imagePath)
        self.supabaseImagePath = nil
        print("☁️ Recipe image deleted from cloud")
    }
    
    enum DifficultyLevel: String, Codable {
        case easy = "Ușor"
        case medium = "Mediu"
        case hard = "Dificil"
    }
    
    enum DietaryTag: String, Codable, CaseIterable {
        case redMeat = "Carne roșie"
        case poultry = "Carne de pasăre"
        case fish = "Pește"
        case eggs = "Ouă"
        case processedMeats = "Mezeluri"
        case legumes = "Legume uscate"
        case fruit = "Fructe"
        case dairy = "Lactaticine"
        case nuts = "Nuci/semințe"
        case fried = "Prăjit"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        category: String = "Diverse",
        servings: Int = 4,
        prepTimeMinutes: Int = 0,
        cookTimeMinutes: Int = 0,
        ingredients: [Ingredient] = [],
        instructions: String = "",
        difficulty: DifficultyLevel = .easy,
        createdAt: Date = Date(),
        dietaryTags: [DietaryTag] = []
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = description
        self.category = category
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.ingredients = ingredients
        self.instructions = instructions
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.dietaryTags = dietaryTags.isEmpty ? IngredientTypeDetector.detectTags(for: self) : dietaryTags
    }
    
    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }
    
    func autoDetectTags() {
        self.dietaryTags = IngredientTypeDetector.detectTags(for: self)
    }
}
