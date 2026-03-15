# Ez Menu Generator 🍽️

O aplicație iOS inteligentă pentru **generarea automată de meniuri de 7 zile** cu respect pentru **16 restricții dietetice** personalizate.

## 📋 Caracteristici Principale

- ✅ **Generare inteligentă de meniuri** cu algoritm multi-pass care respectă constrângerile
- ✅ **16 restricții dietetice** (carne roșie, pasăre, pește, ouă, carne procesată, legume, fructe, lactate, nuci, prăjituri)
- ✅ **Sistem de Favorite** - marchează rețetele preferate
- ✅ **Undo/Redo** - pentru toate operațiile de ștergere
- ✅ **Shopping List** - generată automat din meniu cu cantități agreggate
- ✅ **Calcul Nutriție** - proteine, grăsimi, carbohidrați, calorii pe rețetă
- ✅ **Management Constrângeri** - tracking săptămânal și zilnic
- ✅ **Auto-detecție** - tip ingredient și etichete dietetice (50+ keywords)

## 🏗️ Arhitectură Proiect

```
Ez Menu Generator/
├── App/
│   └── EzMenuGeneratorApp.swift          # Entry point, SwiftData setup
│
├── Models/                                # Data structures
│   ├── Recipe.swift                       # Recipe model + dietary tags
│   ├── Menu.swift                         # 7-day menu container
│   ├── Ingredient.swift                   # Ingredient with type detection
│   ├── ShoppingItem.swift                 # Shopping list item
│   └── NutritionInfo.swift                # Nutrition data
│
├── Services/                              # Business logic & data
│   ├── StorageService.swift               # SwiftData persistence layer
│   ├── MenuListViewModel.swift            # Menu generation engine
│   ├── RecipeListViewModel.swift          # Recipe CRUD operations
│   ├── ShoppingListViewModel.swift        # Shopping list management
│   ├── NutritionCalculator.swift          # Nutrition computation
│   ├── UndoRedoManager.swift              # Undo/redo system
│   ├── SampleDataService.swift            # Sample recipes data
│   └── ConstraintTracker.swift            # Dietary constraint validation
│
├── ViewModels/                            # UI state management
│   ├── MenuListViewModel.swift            # Menu list screen state
│   ├── MenuEditorViewModel.swift          # Single menu editor state
│   ├── RecipeListViewModel.swift          # Recipe list screen state
│   ├── ShoppingListViewModel.swift        # Shopping list screen state
│   └── ProductSearchViewModel.swift       # Product search screen state
│
├── Views/                                 # SwiftUI UI components
│   ├── ContentView/
│   │   └── ContentView.swift              # Main navigation hub
│   ├── MenuList/
│   │   ├── MenuListView.swift             # List of saved menus
│   │   ├── AddMenuView.swift              # Create new menu
│   │   └── MenuListItemView.swift         # Menu list item card
│   ├── MenuEditor/
│   │   ├── MenuEditorView.swift           # Edit 7-day menu
│   │   ├── DayMealSelectorView.swift      # Day/meal selection
│   │   ├── RecipePickerView.swift         # Choose recipe for meal
│   │   └── ShoppingListPreviewView.swift  # Shopping list preview
│   ├── RecipeList/
│   │   ├── RecipeListView.swift           # Recipe library
│   │   ├── RecipeDetailView.swift         # Single recipe details
│   │   ├── AddRecipeView.swift            # Create new recipe
│   │   ├── AddIngredientView.swift        # Add ingredient modal
│   │   ├── NutritionDetailView.swift      # Nutrition breakdown
│   │   └── RecipeRowView.swift            # Recipe list item
│   ├── ShoppingList/
│   │   ├── ShoppingListView.swift         # Shopping list display
│   │   ├── AddShoppingItemView.swift      # Add new item
│   │   ├── EditShoppingItemView.swift     # Edit item modal
│   │   └── ShoppingItemRowView.swift      # Item row component
│   ├── ProductSearchView.swift            # Product search/filter
│   └── ProductDetailView.swift            # Product details modal
│
├── Design/
│   └── AppTheme.swift                     # Colors, typography, spacing
│
├── Utilities/
│   └── CategoryManager.swift              # Category management
│
└── Assets.xcassets/                       # Images, app icon, colors
```

## 🔧 Tehnologie

- **SwiftUI** - UI framework
- **SwiftData** - Local data persistence
- **MVVM + Combine** - Architecture pattern
- **iOS 17+**

## 🚀 Getting Started

### Prerequisite

- Xcode 15+
- iOS 17+ simulator/device

### Installation

```bash
cd "Ez Menu Generator"
open "Ez Menu Generator.xcodeproj"
```

1. Select simulator (iPhone 15/16)
2. Press `Cmd+R` to build & run

## 📚 Key Components

### Models

#### Recipe
```swift
@Model final class Recipe {
    var name: String
    var category: String
    var difficulty: String
    var ingredients: [Ingredient]
    var instructions: String
    var nutritionInfo: NutritionInfo
    var dietaryTags: [Recipe.DietaryTag]
    var isFavorite: Bool = false
    var createdAt: Date = Date()
}
```

#### Menu
```swift
@Model final class Menu {
    var name: String
    var weekStartDate: Date
    var meals: [DayMeals]  // 7 days
    var constraintTracker: ConstraintTracker
}
```

### Key ViewModels

#### MenuListViewModel
- `generateMenu()` - 3-pass algorithm for respecting constraints
- `getMenuValidationIssues()` - Validate menu against constraints
- **3-pass algorithm:**
  - Pass 1: Find recipes with ZERO violations
  - Pass 2: Find recipes with ≤1 violation
  - Pass 3: Use recipe with minimum violations

#### RecipeListViewModel
- `addRecipe()` - Create new recipe
- `deleteRecipe()` - Delete with undo support
- Recipe auto-detection for ingredients types

### Services

#### StorageService
- `fetchAllRecipes()` - Load recipes from SwiftData
- `updateMenu()` - Persist menu changes
- Singleton pattern for app-wide access

#### ConstraintTracker
- Tracks daily/weekly constraint violations
- `addMeal()` - Add meal and update tracking
- `getViolations()` - Check recipe against constraints

## 🎯 16 Dietary Restrictions

1. **Carne Roșie** - Max 3 zile/săptămână
2. **Pasăre** - Max 4 zile/săptămână
3. **Pește** - Max 3 zile/săptămână
4. **Ouă** - Max 2 zile/săptămână
5. **Carne Procesată** - Max 1 zi/săptămână
6. **Legume** - Min 4 zile/săptămână
7. **Fructe** - Min 5 zile/săptămână
8. **Lactate** - Max 1000g/săptămână
9. **Nuci** - Max 100g/săptămână
10. **Prăjituri** - Max 2 zile/săptămână
11. **Alergie Unt de arahidă** - Evitare completă
12. **Alergie Lactate** - Evitare completă
13. **Alergie Fructe de pădure** - Evitare completă
14. **Alergie Soia** - Evitare completă
15. **Vegetarian** - Fără produse din carne
16. **Vegan** - Fără produse de origine animală

## 📁 Filepaths & Responsibilități

| Fișier | Responsabilitate | Tip |
|--------|------------------|-----|
| `EzMenuGeneratorApp.swift` | Init app, SwiftData setup | Entry point |
| `StorageService.swift` | Persistență date, SwiftData bridge | Service |
| `MenuListViewModel.swift` | Generare + validare meniu | ViewModel |
| `RecipeListViewModel.swift` | CRUD rețete | ViewModel |
| `ConstraintTracker.swift` | Validare constrângeri | Service |
| `NutritionCalculator.swift` | Calcul nutriție | Service |
| `UndoRedoManager.swift` | Undo/redo operations | Service |
| `ContentView.swift` | Main navigation TabView | View |
| `MenuListView.swift` | List saved menus | View |
| `RecipeListView.swift` | Recipe library UI | View |

## 🔄 Data Flow

```
ContentView (Navigation)
    ├→ MenuListView
    │   ├→ MenuListViewModel (generare menu)
    │   └→ StorageService (persista menu)
    │
    ├→ RecipeListView
    │   ├→ RecipeListViewModel (CRUD rețete)
    │   └→ StorageService (persista rețete)
    │
    └→ ShoppingListView
        ├→ ShoppingListViewModel
        └→ StorageService (persista items)
```

## 🧪 Testing

Unit tests pentru:
- `NutritionCalculatorTests.swift` - Calcule nutriție
- `SampleDataServiceTests.swift` - Sample data integrity
- `Ez_Menu_GeneratorTests.swift` - Core logic

Run tests: `Cmd+U` in Xcode

## 📝 Code Style

- Variabile: `camelCase`
- Clase: `PascalCase`
- Constants: `ALWAYS_UPPERCASE`
- Funcții: `camelCase`
- Files: same as main class name

Exemple:
```swift
let recipeCount: Int           // Variables
class RecipeListView           // Classes
let MAX_RECIPES = 100          // Constants
func generateMenu()            // Functions
```

## 🐛 Common Issues

### EXC_BREAKPOINT on Launch
✅ **Fixed** - Removed CloudKit, using local SwiftData only

### Missing Models Error
✅ **Solution** - All models use `@Model` attribute for SwiftData

### Shopping List Dupes
✅ **Solution** - Items aggregated by name+unit in `MenuEditorViewModel`

## 🚢 Deployment Checklist

- [ ] Remove test data (SampleDataService clear)
- [ ] Update app version in Info.plist
- [ ] Test on actual device
- [ ] Remove debug prints (keep only errors)
- [ ] Archive & upload to App Store Connect

## 📄 License

Proprietary - Eduard

## 👤 Author

**Eduard**
- GitHub: [Your Profile]
- Email: [Your Email]

---

**Last Updated:** February 2026
