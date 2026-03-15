import Foundation
import SwiftData

class SampleDataService {
    static let sampleRecipes: [Recipe] = [
        {
            let recipe = Recipe(name: "Pui copt cu cartofi la cuptor și legume", description: "Pui gustos cu cartofi și legume la cuptor", category: "Pui", servings: 4, prepTimeMinutes: 15, cookTimeMinutes: 45, ingredients: [Ingredient(name: "Pui", quantity: 1, unit: "buc", category: "Carne", ingredientType: .poultry), Ingredient(name: "Cartofi", quantity: 800, unit: "g", category: "Legume", nutritionPer100g: .potato), Ingredient(name: "Morcovi", quantity: 300, unit: "g", category: "Legume", nutritionPer100g: .carrot), Ingredient(name: "Broccoli", quantity: 300, unit: "g", category: "Legume"), Ingredient(name: "Ulei", quantity: 3, unit: "linguri", category: "Uleiuri", ingredientType: .oil), Ingredient(name: "Usturoi", quantity: 3, unit: "cati", category: "Legume")], instructions: "Pune carnea și legumele în tavă. Stropește cu ulei și usturoi. Coacere la 200°C timp de 45 minute.", difficulty: .easy, dietaryTags: [.poultry])
            recipe.nutrition = NutritionInfo(caloriesKcal: 180, protein: 28, carbohydrates: 15, fat: 3.5, saturatedFat: 1, fiber: 2.5, sugars: 0, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Somon la cuptor cu legume", description: "Somon proaspăt copt cu morcovi și broccoli", category: "Pește", servings: 2, prepTimeMinutes: 10, cookTimeMinutes: 25, ingredients: [Ingredient(name: "Somon", quantity: 400, unit: "g", category: "Pește", ingredientType: .fish), Ingredient(name: "Morcovi", quantity: 200, unit: "g", category: "Legume", nutritionPer100g: .carrot), Ingredient(name: "Broccoli", quantity: 200, unit: "g", category: "Legume"), Ingredient(name: "Cartofi dulci", quantity: 300, unit: "g", category: "Legume"), Ingredient(name: "Ulei de măsline", quantity: 3, unit: "linguri", category: "Uleiuri", ingredientType: .oil)], instructions: "Preincalzează la 200°C. Pune somonul pe foaie de aluminiu cu legumele. Coacere 25 minute.", difficulty: .easy, dietaryTags: [.fish])
            recipe.nutrition = NutritionInfo(caloriesKcal: 220, protein: 26, carbohydrates: 12, fat: 9, saturatedFat: 2, fiber: 2, sugars: 1, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Paste Carbonara", description: "Paste cremă cu bacon și brânză dură", category: "Paste", servings: 2, prepTimeMinutes: 10, cookTimeMinutes: 15, ingredients: [Ingredient(name: "Paste", quantity: 250, unit: "g", category: "Paste"), Ingredient(name: "Bacon", quantity: 150, unit: "g", category: "Carne", ingredientType: .processedMeats), Ingredient(name: "Ouă", quantity: 3, unit: "buc", category: "Lactate", ingredientType: .eggs), Ingredient(name: "Brânză dură rasă", quantity: 100, unit: "g", category: "Lactate", ingredientType: .dairy), Ingredient(name: "Piperă", quantity: 1, unit: "la gust", category: "Condimente")], instructions: "Gătește pastele. Prăjește baconul. Bate ouăle cu brânza. Combină pastele fierbinți cu bacon și sos de ouă. Condimentează cu piperă.", difficulty: .medium, dietaryTags: [.processedMeats, .eggs, .dairy])
            recipe.nutrition = NutritionInfo(caloriesKcal: 450, protein: 22, carbohydrates: 42, fat: 20, saturatedFat: 8, fiber: 1.5, sugars: 0.5, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Cotlet de pui la cuptor cu orez", description: "Cotlete de pui crocante cu orez și broccoli", category: "Pui", servings: 4, prepTimeMinutes: 15, cookTimeMinutes: 35, ingredients: [Ingredient(name: "Cotlete de pui", quantity: 800, unit: "g", category: "Carne", ingredientType: .poultry), Ingredient(name: "Orez", quantity: 250, unit: "g", category: "Cereale"), Ingredient(name: "Broccoli", quantity: 300, unit: "g", category: "Legume"), Ingredient(name: "Morcovi", quantity: 200, unit: "g", category: "Legume", nutritionPer100g: .carrot), Ingredient(name: "Ulei", quantity: 2, unit: "linguri", category: "Uleiuri", ingredientType: .oil)], instructions: "Gătește orezul. Fierbe broccoli-ul și morcovii. Prăjește cotletele în ulei. Coacere la 180°C 20 minute.", difficulty: .easy, dietaryTags: [.poultry])
            recipe.nutrition = NutritionInfo(caloriesKcal: 260, protein: 32, carbohydrates: 24, fat: 5, saturatedFat: 1.5, fiber: 2, sugars: 2, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Peștele alb la cuptor cu lămâie", description: "Cod sau merlan proaspăt copt cu lămâie și dafin", category: "Pește", servings: 3, prepTimeMinutes: 10, cookTimeMinutes: 25, ingredients: [Ingredient(name: "Cod/Merlan", quantity: 600, unit: "g", category: "Pește", ingredientType: .fish), Ingredient(name: "Lămâie", quantity: 1, unit: "buc", category: "Fructe", ingredientType: .fruit), Ingredient(name: "Ulei de măsline", quantity: 3, unit: "linguri", category: "Uleiuri", ingredientType: .oil), Ingredient(name: "Usturoi", quantity: 2, unit: "cati", category: "Legume"), Ingredient(name: "Dafin", quantity: 2, unit: "foi", category: "Iarbe aromatice")], instructions: "Pune peștele pe foaie de aluminiu. Adaugă felii de lămâie, usturoi și dafin. Stropește cu ulei. Coacere la 200°C timp de 20-25 minute.", difficulty: .easy, dietaryTags: [.fish, .fruit])
            recipe.nutrition = NutritionInfo(caloriesKcal: 130, protein: 24, carbohydrates: 2, fat: 3.5, saturatedFat: 0.5, fiber: 0.5, sugars: 0.2, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Ciorba de legume cu orez", description: "Supă ușoară cu linte și orez", category: "Supe", servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 45, ingredients: [Ingredient(name: "Linte", quantity: 200, unit: "g", category: "Legume", ingredientType: .legumes), Ingredient(name: "Morcovi", quantity: 200, unit: "g", category: "Legume", nutritionPer100g: .carrot), Ingredient(name: "Cartofi", quantity: 300, unit: "g", category: "Legume"), Ingredient(name: "Ceapă", quantity: 1, unit: "buc", category: "Legume"), Ingredient(name: "Roșii pasate", quantity: 200, unit: "g", category: "Conserve"), Ingredient(name: "Orez", quantity: 100, unit: "g", category: "Cereale")], instructions: "Fierbe lintea 20 minute. Adaugă legumele și roșiile pasate. Fierbe 20 minute. Adaugă orezul și fierbe 10 minute. Condimentează la gust.", difficulty: .easy, dietaryTags: [.legumes])
            recipe.nutrition = NutritionInfo(caloriesKcal: 110, protein: 8, carbohydrates: 20, fat: 0.5, saturatedFat: 0, fiber: 4, sugars: 3, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Pui cu smântână și ciuperci", description: "Piept de pui în sos cremos cu ciuperci", category: "Pui", servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 30, ingredients: [Ingredient(name: "Piept de pui", quantity: 800, unit: "g", category: "Carne", ingredientType: .poultry), Ingredient(name: "Ciuperci", quantity: 300, unit: "g", category: "Legume"), Ingredient(name: "Smântână light", quantity: 200, unit: "ml", category: "Lactate", ingredientType: .dairy), Ingredient(name: "Ceapă", quantity: 1, unit: "buc", category: "Legume"), Ingredient(name: "Usturoi", quantity: 2, unit: "cati", category: "Legume")], instructions: "Prăjește pieptul în ulei. Adaugă ceapa și ciupercile. Gătește 10 minute. Adaugă smântâna și usturoiul. Fierbe 10 minute.", difficulty: .easy, dietaryTags: [.poultry, .dairy])
            recipe.nutrition = NutritionInfo(caloriesKcal: 200, protein: 32, carbohydrates: 5, fat: 6, saturatedFat: 3, fiber: 1, sugars: 2, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Chilly con carne cu orez", description: "Carne de vită cu fasole și roșii în sos piquant", category: "Mâncăruri", servings: 4, prepTimeMinutes: 15, cookTimeMinutes: 45, ingredients: [Ingredient(name: "Carne de vită", quantity: 500, unit: "g", category: "Carne", ingredientType: .redMeat), Ingredient(name: "Fasole boabe", quantity: 400, unit: "g", category: "Legume", ingredientType: .legumes), Ingredient(name: "Ceapă", quantity: 2, unit: "buc", category: "Legume"), Ingredient(name: "Roșii pasate", quantity: 300, unit: "g", category: "Conserve"), Ingredient(name: "Usturoi", quantity: 2, unit: "cati", category: "Legume"), Ingredient(name: "Ardei", quantity: 1, unit: "buc", category: "Legume"), Ingredient(name: "Orez", quantity: 200, unit: "g", category: "Cereale")], instructions: "Prăjește carnea. Adaugă ceapa și usturiul. Adaugă fasole, roșii și ardei. Fierbe 30 minute. Servește peste orez.", difficulty: .medium, dietaryTags: [.redMeat, .legumes])
            recipe.nutrition = NutritionInfo(caloriesKcal: 280, protein: 28, carbohydrates: 28, fat: 6, saturatedFat: 2, fiber: 6, sugars: 3, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Chiftele cremoase", description: "Chiftele în sos cremos", category: "Mâncăruri", servings: 4, prepTimeMinutes: 20, cookTimeMinutes: 30, ingredients: [Ingredient(name: "Carne tocată de vită", quantity: 500, unit: "g", category: "Carne", ingredientType: .redMeat), Ingredient(name: "Grâu", quantity: 100, unit: "g", category: "Cereale"), Ingredient(name: "Mazăre", quantity: 150, unit: "g", category: "Legume"), Ingredient(name: "Ceapă", quantity: 1, unit: "buc", category: "Legume"), Ingredient(name: "Usturoi", quantity: 2, unit: "cati", category: "Legume"), Ingredient(name: "Ou", quantity: 1, unit: "buc", category: "Lactate", ingredientType: .eggs)], instructions: "Amestecă carnea cu grâu, ou și ceapă. Formează chiftele. Prăjește până sunt gătite. Servește cu sos cremos.", difficulty: .medium, dietaryTags: [.redMeat, .eggs])
            recipe.nutrition = NutritionInfo(caloriesKcal: 290, protein: 30, carbohydrates: 18, fat: 12, saturatedFat: 5, fiber: 2, sugars: 1, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Couscous cu piept de pui și legume", description: "Couscous ușor cu pui și legume proaspete", category: "Paste", servings: 4, prepTimeMinutes: 10, cookTimeMinutes: 25, ingredients: [Ingredient(name: "Piept de pui", quantity: 600, unit: "g", category: "Carne", ingredientType: .poultry), Ingredient(name: "Couscous", quantity: 250, unit: "g", category: "Paste"), Ingredient(name: "Dovlecel", quantity: 300, unit: "g", category: "Legume"), Ingredient(name: "Ardei gras", quantity: 1, unit: "buc", category: "Legume"), Ingredient(name: "Ceapă", quantity: 1, unit: "buc", category: "Legume")], instructions: "Gătește couscous-ul conform instrucțiunilor. Prăjește piuptul cu legumele. Combină couscous-ul cu piuptul și legumele.", difficulty: .easy, dietaryTags: [.poultry])
            recipe.nutrition = NutritionInfo(caloriesKcal: 310, protein: 36, carbohydrates: 32, fat: 4, saturatedFat: 1, fiber: 2.5, sugars: 2, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Supă cremă dovleac", description: "Supă cremă din dovleac proaspăt", category: "Supe", servings: 4, prepTimeMinutes: 15, cookTimeMinutes: 30, ingredients: [Ingredient(name: "Dovleac", quantity: 800, unit: "g", category: "Legume"), Ingredient(name: "Smântână", quantity: 200, unit: "ml", category: "Lactate", ingredientType: .dairy), Ingredient(name: "Brânză", quantity: 100, unit: "g", category: "Lactate", ingredientType: .dairy), Ingredient(name: "Usturoi", quantity: 2, unit: "cati", category: "Legume"), Ingredient(name: "Ceapă", quantity: 1, unit: "buc", category: "Legume")], instructions: "Fierbe dovlecul cu ceapa în apă. Pasează cu blender. Adaugă smântâna și brânza. Condimentează cu usturoi.", difficulty: .easy, dietaryTags: [.dairy])
            recipe.nutrition = NutritionInfo(caloriesKcal: 160, protein: 6, carbohydrates: 14, fat: 8, saturatedFat: 5, fiber: 2.5, sugars: 4, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Paste cu sos de pesto și ton", description: "Paste cu sos pesto și ton din conservă", category: "Paste", servings: 2, prepTimeMinutes: 10, cookTimeMinutes: 12, ingredients: [Ingredient(name: "Paste", quantity: 250, unit: "g", category: "Paste"), Ingredient(name: "Ton din conservă", quantity: 200, unit: "g", category: "Pește", ingredientType: .fish), Ingredient(name: "Pesto", quantity: 100, unit: "g", category: "Condimente", ingredientType: .nuts), Ingredient(name: "Usturoi", quantity: 2, unit: "cati", category: "Legume"), Ingredient(name: "Pin", quantity: 50, unit: "g", category: "Cereale", ingredientType: .nuts), Ingredient(name: "Brânză dură rasă", quantity: 50, unit: "g", category: "Lactate", ingredientType: .dairy), Ingredient(name: "Ulei de măsline", quantity: 2, unit: "linguri", category: "Uleiuri", ingredientType: .oil)], instructions: "Gătește pastele. Amestecă tonul cu pesto. Combină cu pastele calde. Garnisire cu brânza și pin.", difficulty: .easy, dietaryTags: [.fish, .nuts, .dairy])
            recipe.nutrition = NutritionInfo(caloriesKcal: 480, protein: 32, carbohydrates: 40, fat: 18, saturatedFat: 4, fiber: 2, sugars: 1, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Bors cu perișoare", description: "Bors tradițional cu perișoare de carne", category: "Supe", servings: 6, prepTimeMinutes: 20, cookTimeMinutes: 60, ingredients: [Ingredient(name: "Sfeclă roșie", quantity: 400, unit: "g", category: "Legume"), Ingredient(name: "Apă", quantity: 2000, unit: "ml", category: "Lichide"), Ingredient(name: "Morcov", quantity: 200, unit: "g", category: "Legume", nutritionPer100g: .carrot), Ingredient(name: "Carne tocată", quantity: 400, unit: "g", category: "Carne", ingredientType: .redMeat), Ingredient(name: "Ceapă", quantity: 2, unit: "buc", category: "Legume"), Ingredient(name: "Usturoi", quantity: 3, unit: "cati", category: "Legume"), Ingredient(name: "Dafin", quantity: 2, unit: "foi", category: "Iarbe aromatice")], instructions: "Fierbe sfecla și morcovul. Formează perișoare din carne. Adaugă-le în bors. Fierbe 30 minute. Condimentează cu usturoi și dafin.", difficulty: .medium, dietaryTags: [.redMeat])
            recipe.nutrition = NutritionInfo(caloriesKcal: 140, protein: 16, carbohydrates: 12, fat: 3, saturatedFat: 1, fiber: 2, sugars: 2, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Bors roșu din sfeclă cu carne de porc", description: "Bors deasă cu carne de porc", category: "Supe", servings: 6, prepTimeMinutes: 20, cookTimeMinutes: 90, ingredients: [Ingredient(name: "Sfeclă roșie", quantity: 500, unit: "g", category: "Legume"), Ingredient(name: "Carne de porc", quantity: 600, unit: "g", category: "Carne"), Ingredient(name: "Morcov", quantity: 200, unit: "g", category: "Legume", nutritionPer100g: .carrot), Ingredient(name: "Ceapă", quantity: 2, unit: "buc", category: "Legume"), Ingredient(name: "Usturoi", quantity: 3, unit: "cati", category: "Legume"), Ingredient(name: "Brânză", quantity: 100, unit: "g", category: "Lactate", ingredientType: .dairy), Ingredient(name: "Dafin", quantity: 2, unit: "foi", category: "Iarbe aromatice")], instructions: "Fierbe carnea cu ceapa. Adaugă sfecla și morcovul. Fierbe 60 minute. Adaugă usturoiul și dafinul. Servește cu brânza.", difficulty: .medium, dietaryTags: [.dairy])
            recipe.nutrition = NutritionInfo(caloriesKcal: 180, protein: 22, carbohydrates: 10, fat: 6, saturatedFat: 2, fiber: 1.5, sugars: 2, alcohol: 0)
            return recipe
        }(),
        
        {
            let recipe = Recipe(name: "Goulash cu carne de vită", description: "Goulash tradițional cu carne de vită și paprika", category: "Mâncăruri", servings: 6, prepTimeMinutes: 20, cookTimeMinutes: 120, ingredients: [Ingredient(name: "Carne de vită", quantity: 800, unit: "g", category: "Carne", ingredientType: .redMeat), Ingredient(name: "Ceapă", quantity: 3, unit: "buc", category: "Legume"), Ingredient(name: "Paprica", quantity: 3, unit: "linguri", category: "Condimente"), Ingredient(name: "Morcov", quantity: 300, unit: "g", category: "Legume", nutritionPer100g: .carrot), Ingredient(name: "Cartofi", quantity: 500, unit: "g", category: "Legume"), Ingredient(name: "Usturoi", quantity: 3, unit: "cati", category: "Legume")], instructions: "Prăjești ceapa până devine colorată. Adaugă paprica și carnea. Fierbe 1 oră. Adaugă cartofi și morcovi. Fierbe 45 minute. Condimentează cu usturoi și sare.", difficulty: .medium, dietaryTags: [.redMeat])
            recipe.nutrition = NutritionInfo(caloriesKcal: 240, protein: 32, carbohydrates: 18, fat: 5, saturatedFat: 2, fiber: 2.5, sugars: 3, alcohol: 0)
            return recipe
        }()
    ]
    
    static let shoppingCategories: [String] = [
        "Legume / Fructe 🥕🍎",
        "Lactate și ouă 🧈🥚",
        "Carne 🥩",
        "Gospodarie 🧹",
        "Ingrijire personală 🧴",
        "Farmacie 💊",
        "Băuturi 🥤",
        "Brutarie 🍞",
        "Pește 🐟",
        "Cămară 🏠",
        "Dulciuri 🍫",
        "De îmbrăcat 👕",
        "Altele ❓"
    ]
    
    static let shoppingItems: [String: [String]] = [:]
    
    static func seedDataIfNeeded(context: ModelContext) {
        do {
            let recipeCount = try context.fetchCount(FetchDescriptor<Recipe>())
            
            if recipeCount == 0 {
                for recipe in sampleRecipes {
                    context.insert(recipe)
                }
                try context.save()
            }
        } catch {
            // Silently fail - data loading not critical
        }
    }
}
