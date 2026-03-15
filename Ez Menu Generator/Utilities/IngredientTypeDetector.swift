import Foundation

class IngredientTypeDetector {
    static func detectType(for ingredientName: String) -> Ingredient.IngredientType {
        let name = ingredientName.lowercased()
        
        // Red meat keywords
        let redMeatKeywords = ["vită", "vita", "beef", "carne de vită", "carne de vita", "mâncare", "goulash", "mici", "cotlet", "tocată"]
        if redMeatKeywords.contains(where: { name.contains($0) }) {
            return .redMeat
        }
        
        // Poultry keywords
        let poultryKeywords = ["pui", "chicken", "pasăre", "pasare", "găină", "gaina", "curcan", "cotlet de pui", "piept de pui", "pulpe"]
        if poultryKeywords.contains(where: { name.contains($0) }) {
            return .poultry
        }
        
        // Fish keywords
        let fishKeywords = ["pește", "peste", "fish", "somon", "cod", "merlan", "ton", "sardine", "macrou", "crap", "conger"]
        if fishKeywords.contains(where: { name.contains($0) }) {
            return .fish
        }
        
        // Eggs keywords
        let eggsKeywords = ["ou", "egg", "ouă"]
        if eggsKeywords.contains(where: { name.contains($0) }) {
            return .eggs
        }
        
        // Processed meats keywords
        let processedKeywords = ["bacon", "șuncă", "sunca", "ciorba", "mâncare", "mezeluri", "cârnați", "carnati", "șarpe", "sarpe"]
        if processedKeywords.contains(where: { name.contains($0) }) {
            return .processedMeats
        }
        
        // Legumes keywords
        let legumesKeywords = ["linte", "fasole", "boabe", "naut", "pastai", "mazare", "mazăre"]
        if legumesKeywords.contains(where: { name.contains($0) }) {
            return .legumes
        }
        
        // Fruit keywords
        let fruitKeywords = ["fruct", "fruit", "măr", "mar", "portocală", "portocala", "lămâie", "lamâie", "banana", "căpșune", "capsune", "cireșe", "cirese", "strugure", "ananas", "pepene", "piersică", "piersica"]
        if fruitKeywords.contains(where: { name.contains($0) }) {
            return .fruit
        }
        
        // Dairy keywords
        let dairyKeywords = ["brânză", "branza", "smântână", "smantana", "lapte", "milk", "iaurt", "creamă", "cream", "unt", "butter", "telemea"]
        if dairyKeywords.contains(where: { name.contains($0) }) {
            return .dairy
        }
        
        // Nuts keywords
        let nutsKeywords = ["nucă", "nuca", "migdală", "migdala", "caju", "alune", "pin", "semințe", "seminţe", "seminţe de", "chia", "flax"]
        if nutsKeywords.contains(where: { name.contains($0) }) {
            return .nuts
        }
        
        // Oil keywords
        let oilKeywords = ["ulei", "oil", "măsline", "masline", "rapita", "rapită", "avocado", "cocos", "floarea"]
        if oilKeywords.contains(where: { name.contains($0) }) {
            return .oil
        }
        
        return .other
    }
    
    static func detectTags(for recipe: Recipe) -> [Recipe.DietaryTag] {
        var tags = Set<Recipe.DietaryTag>()
        
        for ingredient in recipe.ingredients {
            let ingredientType = ingredient.ingredientType
            
            switch ingredientType {
            case .redMeat:
                tags.insert(.redMeat)
            case .poultry:
                tags.insert(.poultry)
            case .fish:
                tags.insert(.fish)
            case .eggs:
                tags.insert(.eggs)
            case .processedMeats:
                tags.insert(.processedMeats)
            case .legumes:
                tags.insert(.legumes)
            case .fruit:
                tags.insert(.fruit)
            case .dairy:
                tags.insert(.dairy)
            case .nuts:
                tags.insert(.nuts)
            default:
                break
            }
        }
        
        return Array(tags)
    }
}
