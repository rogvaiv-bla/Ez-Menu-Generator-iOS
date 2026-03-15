import Foundation

// Valori nutritive per 100g (similar cu OpenNutriTracker)

struct NutritionInfo: Codable, @unchecked Sendable {
    // MARK: - Codable Conformance
    enum CodingKeys: String, CodingKey {
        case caloriesKcal, protein, carbohydrates, fat, saturatedFat, fiber, sugars, alcohol
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(caloriesKcal, forKey: .caloriesKcal)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbohydrates, forKey: .carbohydrates)
        try container.encode(fat, forKey: .fat)
        try container.encode(saturatedFat, forKey: .saturatedFat)
        try container.encode(fiber, forKey: .fiber)
        try container.encode(sugars, forKey: .sugars)
        try container.encode(alcohol, forKey: .alcohol)
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.caloriesKcal = try container.decodeIfPresent(Double.self, forKey: .caloriesKcal) ?? 0
        self.protein = try container.decodeIfPresent(Double.self, forKey: .protein) ?? 0
        self.carbohydrates = try container.decodeIfPresent(Double.self, forKey: .carbohydrates) ?? 0
        self.fat = try container.decodeIfPresent(Double.self, forKey: .fat) ?? 0
        self.saturatedFat = try container.decodeIfPresent(Double.self, forKey: .saturatedFat) ?? 0
        self.fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        self.sugars = try container.decodeIfPresent(Double.self, forKey: .sugars) ?? 0
        self.alcohol = try container.decodeIfPresent(Double.self, forKey: .alcohol) ?? 0
    }
    
    init(caloriesKcal: Double = 0, protein: Double = 0, carbohydrates: Double = 0, fat: Double = 0, saturatedFat: Double = 0, fiber: Double = 0, sugars: Double = 0, alcohol: Double = 0) {
        self.caloriesKcal = caloriesKcal
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.fiber = fiber
        self.sugars = sugars
        self.alcohol = alcohol
    }
    
    var caloriesKcal: Double            // Energie în kcal/100g
    var protein: Double                 // Proteine în g/100g
    var carbohydrates: Double           // Glucide în g/100g
    var fat: Double                     // Grăsimi totale în g/100g
    var saturatedFat: Double            // Grăsimi saturate în g/100g
    var fiber: Double                   // Fibre în g/100g
    var sugars: Double                  // Zaharuri în g/100g
    var alcohol: Double                 // Alcool în g/100g
    
    // Calculated macro percentages
    var proteinCalories: Double {
        protein * 4  // 1g proteină = 4 kcal
    }
    
    var carbsCalories: Double {
        carbohydrates * 4  // 1g carbs = 4 kcal
    }
    
    var fatCalories: Double {
        fat * 9  // 1g fat = 9 kcal
    }
    
    var fiberCalories: Double {
        fiber * 1  // 1g fiber ≈ 0-2 kcal (aproximare: 1 kcal)
    }
    
    var alcoholCalories: Double {
        alcohol * 7  // 1g alcool = 7 kcal
    }
    
    // For easy display
    var macroSummary: String {
        "P:\(String(format: "%.0f", protein))g | C:\(String(format: "%.0f", carbohydrates))g | G:\(String(format: "%.0f", fat))g"
    }
}

// Extension cu valori predefinite pentru ingrediente comune
extension NutritionInfo {
    static let chicken = NutritionInfo(caloriesKcal: 165, protein: 31, carbohydrates: 0, fat: 3.6, saturatedFat: 1.3, fiber: 0, sugars: 0)
    static let beef = NutritionInfo(caloriesKcal: 250, protein: 26, carbohydrates: 0, fat: 15, saturatedFat: 6, fiber: 0, sugars: 0)
    static let pork = NutritionInfo(caloriesKcal: 242, protein: 27, carbohydrates: 0, fat: 14, saturatedFat: 5, fiber: 0, sugars: 0)
    static let tomato = NutritionInfo(caloriesKcal: 18, protein: 0.9, carbohydrates: 3.9, fat: 0.2, saturatedFat: 0.03, fiber: 1.2, sugars: 2.6)
    static let onion = NutritionInfo(caloriesKcal: 40, protein: 1.1, carbohydrates: 9, fat: 0.1, saturatedFat: 0.04, fiber: 1.7, sugars: 4.2)
    static let garlic = NutritionInfo(caloriesKcal: 149, protein: 6.4, carbohydrates: 33, fat: 0.5, saturatedFat: 0.1, fiber: 2.1, sugars: 1)
    static let olive_oil = NutritionInfo(caloriesKcal: 884, protein: 0, carbohydrates: 0, fat: 100, saturatedFat: 14, fiber: 0, sugars: 0)
    static let butter = NutritionInfo(caloriesKcal: 717, protein: 0.9, carbohydrates: 0.1, fat: 81, saturatedFat: 51, fiber: 0, sugars: 0.1)
    static let flour = NutritionInfo(caloriesKcal: 364, protein: 10, carbohydrates: 76, fat: 1, saturatedFat: 0.2, fiber: 2.7, sugars: 0.3)
    static let egg = NutritionInfo(caloriesKcal: 155, protein: 13, carbohydrates: 1.1, fat: 11, saturatedFat: 3.3, fiber: 0, sugars: 1.1)
    static let milk = NutritionInfo(caloriesKcal: 61, protein: 3.2, carbohydrates: 4.8, fat: 3.3, saturatedFat: 2, fiber: 0, sugars: 4.8)
    static let cheese = NutritionInfo(caloriesKcal: 402, protein: 25, carbohydrates: 1.3, fat: 33, saturatedFat: 21, fiber: 0, sugars: 0.7)
    static let carrot = NutritionInfo(caloriesKcal: 41, protein: 0.9, carbohydrates: 10, fat: 0.2, saturatedFat: 0.03, fiber: 2.8, sugars: 4.7)
    static let potato = NutritionInfo(caloriesKcal: 77, protein: 2, carbohydrates: 17, fat: 0.1, saturatedFat: 0.03, fiber: 2.1, sugars: 0.8)
    static let rice = NutritionInfo(caloriesKcal: 130, protein: 2.7, carbohydrates: 28, fat: 0.3, saturatedFat: 0.1, fiber: 0.4, sugars: 0.1)
    static let salt = NutritionInfo(caloriesKcal: 0, protein: 0, carbohydrates: 0, fat: 0, saturatedFat: 0, fiber: 0, sugars: 0)
    static let sour_cream = NutritionInfo(caloriesKcal: 193, protein: 3.7, carbohydrates: 3.6, fat: 20, saturatedFat: 12, fiber: 0, sugars: 3.6)
}
