# Architecture Documentation

## Overview

Ez Menu Generator follows **MVVM (Model-View-ViewModel)** architecture with **SwiftUI** and **SwiftData** for persistence.

## Architectural Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI Views                          │
├─────────────────────────────────────────────────────────────┤
│  ContentView → MenuListView                                 │
│             → RecipeListView                                │
│             → ShoppingListView                              │
│             → MenuEditorView                                │
└─────────────────────────────────────────────────────────────┘
                              ↑ Binds to
┌─────────────────────────────────────────────────────────────┐
│                    ViewModels (@MainActor)                  │
├─────────────────────────────────────────────────────────────┤
│  MenuListViewModel    - Menu generation + validation        │
│  RecipeListViewModel  - Recipe CRUD + auto-detection        │
│  MenuEditorViewModel  - Single menu editing                 │
│  ShoppingListViewModel - Shopping list management           │
└─────────────────────────────────────────────────────────────┘
                              ↑ Uses
┌─────────────────────────────────────────────────────────────┐
│                     Services (Singletons)                   │
├─────────────────────────────────────────────────────────────┤
│  StorageService      - SwiftData persistence bridge         │
│  ConstraintTracker   - Dietary constraint validation        │
│  NutritionCalculator - Protein/fat/carbs/calories           │
│  UndoRedoManager     - Undo/redo deletion history           │
│  IngredientTypeDetector - Auto-detect ingredient types      │
└─────────────────────────────────────────────────────────────┘
                              ↑ Manages
┌─────────────────────────────────────────────────────────────┐
│                  Data Models (@Model)                       │
├─────────────────────────────────────────────────────────────┤
│  Recipe              - Meal with nutrients + dietary tags   │
│  Menu                - 7-day meal plan with meals           │
│  Ingredient          - Item with quantity/unit/type         │
│  ShoppingItem        - Aggregated ingredient for shopping   │
│  NutritionInfo       - Cached nutrition totals              │
└─────────────────────────────────────────────────────────────┘
                              ↑ Persisted by
┌─────────────────────────────────────────────────────────────┐
│                  SwiftData Database                         │
├─────────────────────────────────────────────────────────────┤
│  Local SQLite storage with automatic syncing                │
│  Eager loading of relationships (recipes → ingredients)     │
└─────────────────────────────────────────────────────────────┘
```

## MVVM Pattern

### Model Layer

**Purpose:** Defines data structures and relationships

**Components:**
- `Recipe.swift` - Core recipe model
- `Menu.swift` - 7-day meal plan container
- `Ingredient.swift` - Individual ingredient with type detection
- `ShoppingItem.swift` - Aggregated ingredient for shopping lists
- `NutritionInfo.swift` - Cached nutrition totals

**Key Feature:** All models are `@Model` (SwiftData compliant)

```swift
@Model final class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
    var dietaryTags: [DietaryTag] = []
    var isFavorite: Bool = false
    // ...
}
```

### ViewModel Layer

**Purpose:** Manages state and business logic

**Components:**
- `MenuListViewModel` - Menu generation engine
- `RecipeListViewModel` - Recipe CRUD operations
- `MenuEditorViewModel` - Single menu editing state
- `ShoppingListViewModel` - Shopping list operations
- `ProductSearchViewModel` - Product search filtering

**Design Pattern:** All marked with `@MainActor` for thread safety

```swift
@MainActor
class MenuListViewModel: ObservableObject {
    @Published var currentMenu: Menu?
    @Published var validationIssues: [String] = []
    
    func generateMenu() { ... }
    func getMenuValidationIssues() { ... }
}
```

### View Layer

**Purpose:** SwiftUI UI components that bind to ViewModels

**Structure:**
```
Views/
├── ContentView/
│   └── ContentView.swift          # Main TabView navigation
├── MenuList/
│   ├── MenuListView.swift         # Display saved menus
│   ├── AddMenuView.swift          # Create new menu (with generation)
│   └── MenuListItemView.swift     # Single menu card
├── MenuEditor/
│   ├── MenuEditorView.swift       # Edit 7-day menu
│   ├── DayMealSelectorView.swift  # Day/meal picker
│   └── RecipePickerView.swift     # Choose recipe for meal
├── RecipeList/
│   ├── RecipeListView.swift       # Recipe library
│   ├── AddRecipeView.swift        # Create new recipe
│   ├── RecipeDetailView.swift     # Recipe details modal
│   └── AddIngredientView.swift    # Add ingredient modal
└── ShoppingList/
    ├── ShoppingListView.swift     # Display shopping list
    ├── AddShoppingItemView.swift  # Add new item
    └── ShoppingItemRowView.swift  # Item card component
```

**Binding Pattern:**
```swift
@StateObject var viewModel = RecipeListViewModel()

struct RecipeListView: View {
    var body: some View {
        List(viewModel.recipes) { recipe in
            RecipeRowView(recipe: recipe)
        }
    }
}
```

## Data Flow

### 1. App Initialization Flow

```
EzMenuGeneratorApp.init()
    ↓
Initialize ModelContainer (SwiftData)
    ↓
SampleDataService.seedDataIfNeeded()
    ↓
StorageService.shared.setupContainer()
    ↓
StorageService.fetchAllRecipes/Menus/Items
    ↓
ContentView displayed with @modelContainer modifier
```

### 2. Menu Generation Flow

```
MenuListView (user taps "Generate Menu")
    ↓
AddMenuView.generateMenu()
    ↓
MenuListViewModel.generateMenu()
    ├─ Initialize ConstraintTracker
    ├─ For each day (0-6):
    │   ├─ Pass 1: Find recipe with 0 violations
    │   ├─ Pass 2: Find recipe with ≤1 violation
    │   └─ Pass 3: Use recipe with minimum violations
    └─ Return best menu from 5 attempts
    ↓
StorageService.addMenu(newMenu)
    ↓
SwiftData persists menu
    ↓
MenuListView refreshes (recipes list updated)
```

### 3. Recipe CRUD Flow

```
RecipeListView (user taps "Add Recipe")
    ↓
AddRecipeView loads
    ↓
User fills name, ingredients, instructions
    ↓
IngredientTypeDetector.detectType() - auto-fills ingredient type
    ↓
RecipeListViewModel.autoDetectDietaryTags() - analyzes ingredients
    ↓
RecipeListViewModel.addRecipe(recipe)
    ↓
StorageService.addRecipe(recipe)
    ↓
SwiftData inserts + cascades ingredients
    ↓
RecipeListView refreshes
```

### 4. Shopping List Generation Flow

```
MenuEditorView (user taps "Shopping List")
    ↓
MenuEditorViewModel.generateShoppingList()
    ├─ Iterate all 21 meals (7 days × 3)
    ├─ For each recipe, iterate ingredients
    ├─ Aggregate by (name, unit)
    │   if exists: quantity += ingredient.quantity
    │   else: create new ShoppingItem
    └─ Sort by category
    ↓
ShoppingListPreviewView displays aggregated items
    ↓
User can save to ShoppingListView
    ↓
StorageService.addShoppingItem() for each item
```

## Service Layer

### StorageService (Singleton)

**Responsibilities:**
- SwiftData ModelContext management
- CRUD operations for all models
- Fetch predicate building
- Error logging

**Access Pattern:**
```swift
StorageService.shared.fetchAllRecipes()
StorageService.shared.addRecipe(newRecipe)
StorageService.shared.updateMenu(menu)
```

### ConstraintTracker

**Responsibilities:**
- Daily/weekly constraint tracking
- Gram-based accumulation
- Violation detection
- Dietary preference enforcement

**Used By:**
- MenuListViewModel (menu generation)
- MenuEditorViewModel (day regeneration)
- MenuValidationView (violation display)

### NutritionCalculator

**Responsibilities:**
- Calculate total protein/fat/carbs/calories
- Sum from ingredient list
- Cache in Recipe.nutrition

**Formula:**
```swift
totalProtein = ingredients.sum { ingredient.nutrition.protein * (quantity/100) }
```

### UndoRedoManager

**Responsibilities:**
- Record deletion history
- Undo/redo operations
- Action state tracking

**Supported Actions:**
- deleteRecipe
- deleteMenu
- deleteShoppingItem

### IngredientTypeDetector (50+ Keywords)

**Detection Logic:**
```swift
if ingredient.name.lowercased().contains("beef") {
    return .meat
}
if ingredient.name.lowercased().contains("spinach") {
    return .vegetable
}
```

## State Management

### Observable Objects

All ViewModels are `@ObservableObject` with `@Published` properties:

```swift
@MainActor
class MenuListViewModel: ObservableObject {
    @Published var currentMenu: Menu?
    @Published var validationIssues: [String] = []
}
```

### Main Actor

All ViewModels marked `@MainActor` for thread safety:

```swift
@MainActor
class RecipeListViewModel: ObservableObject {
    // All properties/methods run on main thread
}
```

## Dependency Injection

### Explicit Constructor Injection

```swift
// MenuEditorView passes menu to ViewModel
@StateObject var viewModel = MenuEditorViewModel(menu: selectedMenu)
```

### Singleton Access

```swift
// Services accessed via singleton
StorageService.shared.fetchAllRecipes()
```

## Error Handling

### Persistent Logging

Services use OSLog for structured logging:

```swift
private let log = Logger(subsystem: "com.eduard.ezmenu", category: "StorageService")

do {
    try context.save()
} catch {
    log.error("Error saving: \(error)")
}
```

### Fallback Strategies

Menu generation never fails - if no perfect recipe found, returns random:

```swift
return recipes.randomElement() ?? Recipe()  // Fallback
```

## Performance Considerations

### Lazy Loading

Relationships loaded on-demand:
```swift
@Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
```

### Caching

Nutrition info cached in Recipe model:
```swift
var nutrition: NutritionInfo?  // Cached
```

### Pagination

ShoppingList and RecipeList support filtering/pagination:
```swift
let filtered = recipes.filter { $0.name.contains(searchText) }
```

## Future Improvements

### Architecture Enhancements

1. **Repository Pattern** - Add abstraction layer between Services and Models
2. **Dependency Container** - Replace singletons with DI container
3. **Coordinator Pattern** - Centralize navigation logic
4. **Network Layer** - Add API support for cloud recipes

### Testing Architecture

1. **Mock Services** - Create MockStorageService for testing
2. **Test ViewModels** - Unit test ViewModel logic without UI
3. **Snapshot Testing** - Verify UI appearance

## Design Decisions

### Why SwiftData?

✅ Built-in to iOS 17+
✅ Automatic persistence
✅ Native SwiftUI interoperability
❌ No CloudKit sync in current implementation

### Why MVVM?

✅ Clear separation of concerns
✅ Testable business logic
✅ SwiftUI native pattern
❌ Requires more boilerplate than simple patterns

### Why @MainActor on ViewModels?

✅ Guaranteed thread safety for UI updates
✅ Prevents common concurrency bugs
❌ Cannot do heavy background work (need Task{})

## References

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata/)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
