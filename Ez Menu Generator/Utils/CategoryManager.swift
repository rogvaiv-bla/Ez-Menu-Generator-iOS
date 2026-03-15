import Foundation

struct CategoryManager {
    static let orderedCategories: [(name: String, emoji: String)] = [
        ("Legume / Fructe", "🥬"),
        ("Lactate și ouă", "🥛"),
        ("Carne", "🥩"),
        ("Gospodărie", "🏠"),
        ("Ingrijire personală", "💆"),
        ("Farmacie", "💊"),
        ("Băuturi", "🥤"),
        ("Brutarie", "🍞"),
        ("Pește", "🐟"),
        ("Cămară", "🏪"),
        ("Dulciuri", "🍬"),
        ("De îmbrăcat", "👕"),
        ("Altele", "📦"),
        ("Diverse", "📝")
    ]
    
    static func displayName(for category: String) -> String {
        if let found = orderedCategories.first(where: { $0.name == category }) {
            return "\(found.emoji) \(category)"
        }
        return "📦 \(category)"
    }
    
    static func sortedCategories(from items: [ShoppingItem]) -> [String] {
        let uniqueCategories = Set(items.map { $0.category })
        return orderedCategories
            .map { $0.name }
            .filter { uniqueCategories.contains($0) }
    }
    
    static func categoryOrder(for category: String) -> Int {
        return orderedCategories.firstIndex(where: { $0.name == category }) ?? Int.max
    }
}
