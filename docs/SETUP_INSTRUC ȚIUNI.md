# Ez Menu Generator - Instrucțiuni de Setup

## Status actual

Ai o structură Xcode cu fișiere Swift care trebuie actualizate. Ai 3 arquivo principale care trebuie rescrise:

1. **ContentView.swift** - TabView cu 3 taburi (Meniuri, Rețete, Cumpărături)
2. **MenuDetailView.swift** - Detalii meniu cu secții și articole
3. **RecipeListView.swift** și **ShoppingListView.swift** - Două noi view-uri

## Fișierele care trebuie rescrise (în folder `Ez Menu Generator/Ez Menu Generator/`)

### 1. Rescrie COMPLET MenuModels.swift

```swift
//
//  MenuModels.swift
//  Ez Menu Generator
//
//  Created by eduard on 29/01/2026.
//

import Foundation
import SwiftData

@Model
final class Menu {
    var id: UUID = UUID()
    var name: String
    var sections: [MenuSection]
    var recipes: [Recipe]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var notes: String = ""
    
    init(name: String, sections: [MenuSection] = [], recipes: [Recipe] = []) {
        self.name = name
        self.sections = sections
        self.recipes = recipes
    }
    
    var totalPrice: Double {
        sections.reduce(0) { $0 + $1.sectionTotal }
    }
}

@Model
final class MenuSection {
    var id: UUID = UUID()
    var title: String
    var items: [MenuItem]
    var orderIndex: Int
    
    init(title: String, items: [MenuItem] = [], orderIndex: Int = 0) {
        self.title = title
        self.items = items
        self.orderIndex = orderIndex
    }
    
    var sectionTotal: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
}

@Model
final class MenuItem {
    var id: UUID = UUID()
    var name: String
    var details: String = ""
    var price: Double = 0
    var quantity: Int = 1
    var notes: String = ""
    
    init(name: String, details: String = "", price: Double = 0, quantity: Int = 1) {
        self.name = name
        self.details = details
        self.price = price
        self.quantity = quantity
    }
}

@Model
final class Recipe {
    var id: UUID = UUID()
    var name: String
    var category: String
    var servings: Int
    var prepTime: Int
    var cookTime: Int
    var ingredients: [String]
    var instructions: String
    var notes: String
    var difficulty: String
    var createdAt: Date = Date()
    
    init(name: String, category: String = "", servings: Int = 2, prepTime: Int = 0, cookTime: Int = 0, ingredients: [String] = [], instructions: String = "", notes: String = "", difficulty: String = "Ușor") {
        self.name = name
        self.category = category
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.ingredients = ingredients
        self.instructions = instructions
        self.notes = notes
        self.difficulty = difficulty
    }
}

@Model
final class ShoppingItem {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var isChecked: Bool = false
    var price: Double = 0
    var notes: String = ""
    var createdAt: Date = Date()
    
    init(name: String, quantity: Double = 1, unit: String = "buc", category: String = "Altele", price: Double = 0, notes: String = "") {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.price = price
        self.notes = notes
    }
}
```

### 2. Rescrie Ez_Menu_GeneratorApp.swift:

```swift
//
//  Ez_Menu_GeneratorApp.swift
//  Ez Menu Generator
//
//  Created by eduard on 29/01/2026.
//

import SwiftUI
import SwiftData

@main
struct Ez_Menu_GeneratorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Menu.self,
            MenuSection.self,
            MenuItem.self,
            Recipe.self,
            ShoppingItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

## Ștergere fișier

Șterge `Item.swift` - nu mai e necesar.

## Creează 3 noi fișiere (Optional - dacă vrei tot în ContentView)

Altfel, creează 3 fișiere separate:
- RecipeListView.swift
- ShoppingListView.swift  
- MenuDetailView.swift (mai detaliat decât cel curent)

Dar mai ușor e să pui TOT în **ContentView.swift** - vezi mai jos.

## Command pentru deschidere în Xcode

```bash
open -a Xcode "/Users/eduard/Downloads/Ez Menu Generator/Ez Menu Generator.xcodeproj"
```

Sau direct din Finder: `/Users/eduard/Downloads/Ez Menu Generator/`

Done! 🎉
