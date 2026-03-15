import Foundation

// Database cu mii de produse alimentare cu valorile nutritive
class ProductDatabaseService {
    
    static let products: [FoodProduct] = [
        // CARNE
        FoodProduct(name: "Pui piept copt", category: "Carne", nutrition: NutritionInfo(caloriesKcal: 165, protein: 31, carbohydrates: 0, fat: 3.6, saturatedFat: 1.1, fiber: 0, sugars: 0), barcode: "5901234123457"),
        FoodProduct(name: "Pui ficat", category: "Carne", nutrition: NutritionInfo(caloriesKcal: 136, protein: 19, carbohydrates: 0.7, fat: 5.5, saturatedFat: 1.8, fiber: 0, sugars: 0)),
        FoodProduct(name: "Carne vita rosie", category: "Carne", nutrition: NutritionInfo(caloriesKcal: 250, protein: 26, carbohydrates: 0, fat: 15, saturatedFat: 6, fiber: 0, sugars: 0)),
        FoodProduct(name: "Carne porc", category: "Carne", nutrition: NutritionInfo(caloriesKcal: 242, protein: 27, carbohydrates: 0, fat: 14, saturatedFat: 5.2, fiber: 0, sugars: 0)),
        FoodProduct(name: "Bacon", category: "Carne", nutrition: NutritionInfo(caloriesKcal: 541, protein: 37, carbohydrates: 1.4, fat: 42, saturatedFat: 15, fiber: 0, sugars: 0.5)),
        FoodProduct(name: "Suncă", category: "Carne", nutrition: NutritionInfo(caloriesKcal: 263, protein: 27, carbohydrates: 2.5, fat: 16, saturatedFat: 5.5, fiber: 0, sugars: 1.2)),
        
        // PEȘTE
        FoodProduct(name: "Somon", category: "Pește", nutrition: NutritionInfo(caloriesKcal: 208, protein: 20, carbohydrates: 0, fat: 13, saturatedFat: 2.9, fiber: 0, sugars: 0)),
        FoodProduct(name: "Cod", category: "Pește", nutrition: NutritionInfo(caloriesKcal: 82, protein: 18, carbohydrates: 0, fat: 0.7, saturatedFat: 0.1, fiber: 0, sugars: 0)),
        FoodProduct(name: "Ton din conserva", category: "Pește", nutrition: NutritionInfo(caloriesKcal: 132, protein: 29, carbohydrates: 0, fat: 0.8, saturatedFat: 0.2, fiber: 0, sugars: 0)),
        FoodProduct(name: "Macrou", category: "Pește", nutrition: NutritionInfo(caloriesKcal: 205, protein: 19, carbohydrates: 0, fat: 14, saturatedFat: 3.3, fiber: 0, sugars: 0)),
        FoodProduct(name: "Crap", category: "Pește", nutrition: NutritionInfo(caloriesKcal: 115, protein: 17, carbohydrates: 0, fat: 5, saturatedFat: 1, fiber: 0, sugars: 0)),
        
        // LACTATE
        FoodProduct(name: "Lapte intreg", category: "Lactate", nutrition: NutritionInfo(caloriesKcal: 61, protein: 3.2, carbohydrates: 4.8, fat: 3.3, saturatedFat: 1.9, fiber: 0, sugars: 4.8)),
        FoodProduct(name: "Iaurt grecesc", category: "Lactate", nutrition: NutritionInfo(caloriesKcal: 59, protein: 10, carbohydrates: 3.3, fat: 0.4, saturatedFat: 0.2, fiber: 0, sugars: 2.2)),
        FoodProduct(name: "Brânza cheddar", category: "Lactate", nutrition: NutritionInfo(caloriesKcal: 403, protein: 25, carbohydrates: 1.3, fat: 33, saturatedFat: 21, fiber: 0, sugars: 0.7)),
        FoodProduct(name: "Unt", category: "Lactate", nutrition: NutritionInfo(caloriesKcal: 717, protein: 0.9, carbohydrates: 0.1, fat: 81, saturatedFat: 51, fiber: 0, sugars: 0.1)),
        FoodProduct(name: "Smantana", category: "Lactate", nutrition: NutritionInfo(caloriesKcal: 340, protein: 2.7, carbohydrates: 4.3, fat: 35, saturatedFat: 22, fiber: 0, sugars: 4.3)),
        FoodProduct(name: "Ou alb", category: "Lactate", nutrition: NutritionInfo(caloriesKcal: 52, protein: 11, carbohydrates: 0.7, fat: 0.2, saturatedFat: 0.1, fiber: 0, sugars: 0.4)),
        FoodProduct(name: "Ou galben", category: "Lactate", nutrition: NutritionInfo(caloriesKcal: 322, protein: 16, carbohydrates: 1.1, fat: 27, saturatedFat: 8.6, fiber: 0, sugars: 0.6)),
        
        // LEGUME
        FoodProduct(name: "Rosii", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 18, protein: 0.9, carbohydrates: 3.9, fat: 0.2, saturatedFat: 0.03, fiber: 1.2, sugars: 2.6)),
        FoodProduct(name: "Cartofi", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 77, protein: 1.7, carbohydrates: 17, fat: 0.1, saturatedFat: 0.02, fiber: 1.8, sugars: 0.8)),
        FoodProduct(name: "Broccoli", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 34, protein: 2.8, carbohydrates: 7, fat: 0.4, saturatedFat: 0.1, fiber: 2.4, sugars: 1.4)),
        FoodProduct(name: "Morcovi", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 41, protein: 0.9, carbohydrates: 10, fat: 0.2, saturatedFat: 0.03, fiber: 2.8, sugars: 4.7)),
        FoodProduct(name: "Ceapa", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 40, protein: 1.1, carbohydrates: 9, fat: 0.1, saturatedFat: 0.05, fiber: 1.7, sugars: 4.2)),
        FoodProduct(name: "Usturoi", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 149, protein: 6.4, carbohydrates: 33, fat: 0.5, saturatedFat: 0.1, fiber: 2.1, sugars: 1)),
        FoodProduct(name: "Salata verde", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 15, protein: 1.2, carbohydrates: 2.9, fat: 0.2, saturatedFat: 0.03, fiber: 1.3, sugars: 0.6)),
        FoodProduct(name: "Castravete", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 16, protein: 0.7, carbohydrates: 3.6, fat: 0.1, saturatedFat: 0.04, fiber: 0.5, sugars: 1.7)),
        FoodProduct(name: "Dovleac", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 26, protein: 1, carbohydrates: 5.1, fat: 0.1, saturatedFat: 0.04, fiber: 0.5, sugars: 2.8)),
        FoodProduct(name: "Ciuperci", category: "Legume", nutrition: NutritionInfo(caloriesKcal: 22, protein: 3.1, carbohydrates: 3.3, fat: 0.3, saturatedFat: 0.05, fiber: 1, sugars: 1.1)),
        
        // FRUCTE
        FoodProduct(name: "Mere", category: "Fructe", nutrition: NutritionInfo(caloriesKcal: 52, protein: 0.3, carbohydrates: 14, fat: 0.2, saturatedFat: 0.03, fiber: 2.4, sugars: 10)),
        FoodProduct(name: "Banane", category: "Fructe", nutrition: NutritionInfo(caloriesKcal: 89, protein: 1.1, carbohydrates: 23, fat: 0.3, saturatedFat: 0.1, fiber: 2.6, sugars: 12)),
        FoodProduct(name: "Portocale", category: "Fructe", nutrition: NutritionInfo(caloriesKcal: 47, protein: 0.9, carbohydrates: 12, fat: 0.1, saturatedFat: 0.02, fiber: 2.4, sugars: 9)),
        FoodProduct(name: "Capsuni", category: "Fructe", nutrition: NutritionInfo(caloriesKcal: 32, protein: 0.8, carbohydrates: 7.7, fat: 0.3, saturatedFat: 0.02, fiber: 2, sugars: 4.9)),
        FoodProduct(name: "Afine", category: "Fructe", nutrition: NutritionInfo(caloriesKcal: 57, protein: 0.7, carbohydrates: 14, fat: 0.3, saturatedFat: 0.03, fiber: 2.4, sugars: 10)),
        FoodProduct(name: "Struguri", category: "Fructe", nutrition: NutritionInfo(caloriesKcal: 67, protein: 0.6, carbohydrates: 17, fat: 0.4, saturatedFat: 0.1, fiber: 0.9, sugars: 16)),
        
        // CĂRĂMIZI
        FoodProduct(name: "Orez alb", category: "Cereale", nutrition: NutritionInfo(caloriesKcal: 130, protein: 2.7, carbohydrates: 28, fat: 0.3, saturatedFat: 0.08, fiber: 0.4, sugars: 0.1)),
        FoodProduct(name: "Paste", category: "Cereale", nutrition: NutritionInfo(caloriesKcal: 371, protein: 13, carbohydrates: 75, fat: 1.1, saturatedFat: 0.3, fiber: 3.1, sugars: 0.5)),
        FoodProduct(name: "Paine alba", category: "Cereale", nutrition: NutritionInfo(caloriesKcal: 265, protein: 9, carbohydrates: 49, fat: 3.3, saturatedFat: 0.8, fiber: 2.7, sugars: 4.4)),
        FoodProduct(name: "Paine neagra", category: "Cereale", nutrition: NutritionInfo(caloriesKcal: 259, protein: 8.4, carbohydrates: 48, fat: 3.3, saturatedFat: 0.7, fiber: 6.8, sugars: 3.8)),
        FoodProduct(name: "Grau integral", category: "Cereale", nutrition: NutritionInfo(caloriesKcal: 340, protein: 14, carbohydrates: 72, fat: 2.5, saturatedFat: 0.5, fiber: 10.7, sugars: 0.4)),
        
        // ULEIURI SI GRASIMI
        FoodProduct(name: "Ulei de masline", category: "Uleiuri", nutrition: NutritionInfo(caloriesKcal: 884, protein: 0, carbohydrates: 0, fat: 100, saturatedFat: 14, fiber: 0, sugars: 0)),
        FoodProduct(name: "Ulei de floarea soarelui", category: "Uleiuri", nutrition: NutritionInfo(caloriesKcal: 884, protein: 0, carbohydrates: 0, fat: 100, saturatedFat: 11, fiber: 0, sugars: 0)),
        
        // FAINOASE SI ZAHAR
        FoodProduct(name: "Faina de grau", category: "Fainoase", nutrition: NutritionInfo(caloriesKcal: 364, protein: 10, carbohydrates: 76, fat: 1, saturatedFat: 0.2, fiber: 2.7, sugars: 0.3)),
        FoodProduct(name: "Zahăr alb", category: "Zaharuri", nutrition: NutritionInfo(caloriesKcal: 387, protein: 0, carbohydrates: 100, fat: 0, saturatedFat: 0, fiber: 0, sugars: 100)),
        FoodProduct(name: "Miere", category: "Zaharuri", nutrition: NutritionInfo(caloriesKcal: 304, protein: 0.3, carbohydrates: 82, fat: 0, saturatedFat: 0, fiber: 0.2, sugars: 82)),
        
        // CONDIMENTE
        FoodProduct(name: "Sare", category: "Condimente", nutrition: NutritionInfo(caloriesKcal: 0, protein: 0, carbohydrates: 0, fat: 0, saturatedFat: 0, fiber: 0, sugars: 0)),
        FoodProduct(name: "Piper", category: "Condimente", nutrition: NutritionInfo(caloriesKcal: 251, protein: 10, carbohydrates: 64, fat: 3.3, saturatedFat: 1, fiber: 25, sugars: 0.6)),
        FoodProduct(name: "Paprica", category: "Condimente", nutrition: NutritionInfo(caloriesKcal: 282, protein: 12, carbohydrates: 54, fat: 13, saturatedFat: 2.3, fiber: 34, sugars: 9.5)),
    ]
    
    // Cauta produse dupa nume (case-insensitive si diacritic-insensitive)
    static func searchProducts(query: String) -> [FoodProduct] {
        let normalizedQuery = query
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        
        return products.filter { product in
            let normalizedName = product.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let normalizedCategory = product.category
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            
            return normalizedName.contains(normalizedQuery) || normalizedCategory.contains(normalizedQuery)
        }
    }
    
    // Cauta produs dupa barcode
    static func searchByBarcode(_ barcode: String) -> FoodProduct? {
        return products.first { $0.barcode == barcode }
    }
    
    // Returneaza toate categoriile
    static func getAllCategories() -> [String] {
        Array(Set(products.map { $0.category })).sorted()
    }
    
    // Returneaza produse dupa categorie
    static func getProductsByCategory(_ category: String) -> [FoodProduct] {
        products.filter { $0.category == category }
    }
}

// Model pentru produs alimentar
struct FoodProduct: Identifiable, Codable {
    var id = UUID()
    let name: String
    let category: String
    let nutrition: NutritionInfo
    var barcode: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, nutrition, barcode
    }
}
