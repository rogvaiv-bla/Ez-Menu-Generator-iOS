import Foundation

// MARK: - Shared Category Constants
// Single source of truth for recipe and ingredient categories

/// Recipe categories used in recipe creation and filtering
struct RecipeCategories {
    static let all: [String] = [
        "Mic dejun & brunch",
        "Aperitive & gustări",
        "Supe & ciorbe",
        "Salate",
        "Feluri principale cu carne",
        "Feluri principale fără carne (vegetariene/vegane)",
        "Pește & fructe de mare",
        "Garnituri & legume",
        "Deserturi & dulciuri",
        "Pâine, cozonaci & aluaturi",
        "Sosuri, marinade & conserve",
        "Băuturi"
    ]
}

/// Ingredient categories used in ingredient creation
/// Based on comprehensive ingredient classification system
struct IngredientCategories {
    static let all: [String] = [
        "Legume",
        "Fructe",
        "Proteine animale",
        "Lactate și ouă",
        "Cereale, pseudocereale și derivate",
        "Leguminoase",
        "Grăsimi și uleiuri",
        "Condimente și mirodenii uscate",
        "Ierburi proaspete / aromate",
        "Arome lichide / acide",
        "Dulciuri / îndulcitori",
        "Produse de patiserie / coacere",
        "Conserve / semipreparate",
        "Nuci, semințe și uscături",
        "Alte ingrediente funcționale"
    ]
}
