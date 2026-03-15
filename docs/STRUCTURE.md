# Project File Structure - Complete Reference

## Documentation Files (GitHub Ready)

```
Ez Menu Generator/ (root)
├── README.md                    # Main project overview + features list
├── ARCHITECTURE.md              # MVVM design patterns + data flow
├── CONSTRAINTS.md               # 16 dietary restrictions system explained
├── SETUP.md                     # Developer onboarding guide
├── CHANGELOG.md                 # Version history + roadmap
├── .gitignore                   # Git exclusion patterns
└── This file                    # File reference guide
```

## Source Code Structure

### Entry Point
```
Ez Menu Generator/App/
└── EzMenuGeneratorApp.swift
    - Initializes ModelContainer (SwiftData)
    - Seeds sample data
    - Sets up StorageService
    - Injects modelContainer into ContentView
```

### Data Models (15 files total)
```
Ez Menu Generator/Models/
├── Recipe.swift
│   └── @Model with:
│       - id, name, description, category
│       - ingredients (cascade relationship)
│       - difficulty, prep/cook time
│       - nutrition, dietaryTags
│       - isFavorite boolean
│
├── Menu.swift
│   └── @Model with:
│       - name, weekStartDate
│       - meals: [DayMeals] (7 days)
│       - constraintTracker
│
├── Ingredient.swift
│   └── @Model with:
│       - name, quantity (Int), unit
│       - category, ingredientType
│       - Auto-detection via IngredientTypeDetector
│
├── ShoppingItem.swift
│   └── @Model with:
│       - name, quantity (Int), unit
│       - category, isChecked
│
├── NutritionInfo.swift
│   └── Struct with:
│       - protein, fat, carbs, calories
│       - per100g values
│
└── [Additional]: DayMeals.swift, etc.
```

### Services (Business Logic)
```
Ez Menu Generator/Services/
├── StorageService.swift [CRITICAL]
│   └── Singleton managing:
│       - SwiftData ModelContext
│       - CRUD for Recipe/Menu/ShoppingItem
│       - Fetch operations with predicates
│       - Error logging via OSLog
│
├── MenuListViewModel.swift [CORE ALGORITHM]
│   └── Menu generation engine:
│       - generateMenu() - 5 attempts
│       - 3-pass recipe selection (0→1→min violations)
│       - Constraint validation
│       - Violation reporting
│
├── RecipeListViewModel.swift
│   └── Recipe management:
│       - addRecipe(), updateRecipe(), deleteRecipe()
│       - autoDetectDietaryTags()
│       - calculateTotalNutrition()
│
├── MenuEditorViewModel.swift
│   └── Single menu editing:
│       - assignRecipeToMeal()
│       - regenerateDay()
│       - generateShoppingList()
│
├── ShoppingListViewModel.swift
│   └── Shopping operations:
│       - addItem(), deleteItem(), toggleChecked()
│       - Category organization
│       - Persistence via StorageService
│
├── ProductSearchViewModel.swift
│   └── Product filtering:
│       - Search by name
│       - Filter by category
│
├── ConstraintTracker.swift [DIETARY SYSTEM]
│   └── Validates constraints:
│       - 7 daily/weekly limits
│       - 3 gram-based limits
│       - 4 allergen checks
│       - 2 dietary preferences
│
├── NutritionCalculator.swift
│   └── Math operations:
│       - Sum nutrition from ingredients
│       - Cache in Recipe.nutrition
│
├── UndoRedoManager.swift
│   └── Undo/redo system:
│       - Records deletion actions
│       - Supports undo/redo
│
├── SampleDataService.swift
│   └── Sample recipes:
│       - 50+ initial recipes
│       - Cleared on app startup (dev mode)
│
└── [Supporting]: IngredientTypeDetector, etc.
```

### ViewModels (State Management)
```
Ez Menu Generator/ViewModels/
├── MenuListViewModel.swift      -> Used by MenuListView
├── MenuEditorViewModel.swift    -> Used by MenuEditorView
├── RecipeListViewModel.swift    -> Used by RecipeListView
├── ShoppingListViewModel.swift  -> Used by ShoppingListView
└── ProductSearchViewModel.swift -> Used by ProductSearchView
├── AnalyzeViewModel.swift       -> Used by AnalyzeView
```

### Views (SwiftUI Components)
```
Ez Menu Generator/Views/
├── ContentView/
│   └── ContentView.swift        # Main TabView (Recipes/Menus/Shopping)
│
├── MenuList/ (Menu management screen)
│   ├── MenuListView.swift       # List of saved menus
│   ├── AddMenuView.swift        # Create menu (with generation)
│   └── MenuListItemView.swift   # Menu card component
│
├── MenuEditor/ (Edit 7-day menu)
│   ├── MenuEditorView.swift     # Main editor
│   ├── DayMealSelectorView.swift # Day/meal picker
│   ├── RecipePickerView.swift   # Choose recipe
│   └── ShoppingListPreviewView.swift
│
├── RecipeList/ (Recipe library)
│   ├── RecipeListView.swift     # List all recipes
│   ├── AddRecipeView.swift      # Create recipe
│   ├── RecipeDetailView.swift   # View recipe details
│   ├── AddIngredientView.swift  # Add ingredient modal
│   ├── NutritionDetailView.swift # Nutrition breakdown
│   └── RecipeRowView.swift      # List item component
│
├── ShoppingList/
│   ├── ShoppingListView.swift   # Shopping list display
│   ├── AddShoppingItemView.swift # Add item
│   ├── EditShoppingItemView.swift # Edit quantity
│   └── ShoppingItemRowView.swift # Item component
│
├── ProductSearchView.swift      # Product search
└── ProductDetailView.swift      # Product details modal
```

### Design & Assets
```
Ez Menu Generator/Design/
└── AppTheme.swift              # Colors, typography, spacing

Ez Menu Generator/Assets.xcassets/
├── AppIcon.appiconset/         # App icons
├── AccentColor.colorset/       # Accent colors
└── [Other assets]
```

### Project Configuration
```
Ez Menu Generator/
├── EzMenuGenerator.entitlements # CloudKit configuration (unused in v1.0)
├── Ez Menu Generator.code-workspace # Workspace file
└── Info.plist                   # App metadata

Ez Menu Generator.xcodeproj/
├── project.pbxproj             # Project settings
└── xcworkspace/                # Workspace configuration
```

### Tests
```
Ez Menu GeneratorTests/
├── Ez_Menu_GeneratorTests.swift # Core logic tests
├── NutritionCalculatorTests.swift # Nutrition math tests
└── SampleDataServiceTests.swift # Data integrity tests

Ez Menu GeneratorUITests/
├── Ez_Menu_GeneratorUITests.swift # UI tests
└── Ez_Menu_GeneratorUITestsLaunchTests.swift
```

## File Statistics

| Category | Count | Est. Lines |
|----------|-------|-----------|
| **Models** | 6 | 400 |
| **Services** | 12 | 3,000 |
| **ViewModels** | 5 | 800 |
| **Views** | 18 | 2,500 |
| **Design/Utilities** | 2 | 200 |
| **Tests** | 5 | 600 |
| **Total Source** | 48 | ~7,500 |
| **Documentation** | 5 | ~2,000 |

## Key Dependencies

### Built-in (No external packages)
- **SwiftUI** - UI framework
- **SwiftData** - Local persistence  
- **Combine** - Reactive programming
- **Foundation** - Standard library
- **OSLog** - Structured logging

### No third-party dependencies! 🎉

## File Dependency Map

```
Entry Point: EzMenuGeneratorApp.swift
    ├─→ ModelContainer (SwiftData)
    ├─→ SampleDataService (seed data)
    └─→ StorageService (persistence)
         ├─→ All Models
         └─→ ContentView (UI)


MenuListView
    └─→ MenuListViewModel
         ├─→ generateMenu()
         ├─→ ConstraintTracker (validation)
         ├─→ StorageService (save)
         └─→ MenuEditorView

RecipeListView
    └─→ RecipeListViewModel
         ├─→ IngredientTypeDetector (auto-config)
         ├─→ NutritionCalculator (math)
         ├─→ StorageService (CRUD)
         └─→ AddRecipeView

ShoppingListView
    └─→ ShoppingListViewModel
         ├─→ StorageService (CRUD)
         └─→ UndoRedoManager (undo history)
```

## Critical Files to Understand

### First Read (In Order)
1. **README.md** (5 min) - What is this app?
2. **Models/Recipe.swift** (10 min) - What's the data?
3. **Models/Menu.swift** (5 min) - How is data structured?
4. **Services/StorageService.swift** (15 min) - How is data saved?
5. **Services/MenuListViewModel.swift** (20 min) - How are menus generated?

### Then Read
6. **Services/ConstraintTracker.swift** (20 min) - How are constraints validated?
7. **ARCHITECTURE.md** (30 min) - Overall design patterns
8. **CONSTRAINTS.md** (30 min) - Dietary system details

### Finally Explore
- Rest of Views/ for UI implementation
- Test files for validation logic
- AppTheme.swift for styling

## Common File Locations

| Task | File |
|------|------|
| Change app icon | Assets.xcassets/AppIcon.appiconset/ |
| Add new color | Design/AppTheme.swift |
| Add new model | Models/[Model].swift |
| Add new service | Services/[Service].swift |
| Add new view | Views/[Screen]/[View].swift |
| Change splash/launch | Info.plist |
| Add tests | Ez Menu GeneratorTests/ |

## File Sizes (Approximate)

| Component | Size | Complexity |
|-----------|------|-----------|
| Recipe.swift | 100 lines | Medium |
| StorageService.swift | 200 lines | High |
| MenuListViewModel.swift | 300 lines | Very High |
| MenuEditorView.swift | 150 lines | Medium |
| RecipeListView.swift | 250 lines | High |
| ConstraintTracker.swift | 400 lines | High |

## Naming Conventions Used

### Files
- Models: Singular (Recipe.swift, Menu.swift)
- Services: Plural or functional (StorageService.swift)
- Views: Screen+Component (MenuListView.swift)
- ViewModels: Same as main class (MenuListViewModel.swift)

### Classes/Structs
- Always PascalCase (Recipe, StorageService)
- Descriptive names (ConstraintTracker, not Validator)
- Use suffixes: Service, ViewModel, View, Manager

### Functions
- Always camelCase (generateMenu, addRecipe)
- Start with verb when possible (fetch, create, update, delete)
- Use get/is for queries (getViolations, isVegetarian)

### Variables
- Always camelCase (currentMenus, selectedRecipe)
- Use descriptive names (avoidCryptickness)
- Booleans start with is/has/can (isVegetarian, hasRedMeat)

## Next Steps

1. **Clone the repository**
   ```bash
   git clone [repo-url]
   ```

2. **Open in Xcode**
   ```bash
   open "Ez Menu Generator.xcodeproj"
   ```

3. **Read SETUP.md** for developer onboarding

4. **Build & Run**
   - Xcode: Cmd+R
   - Simulator: iPhone 15/16

---

**Documentation Version:** 1.0.0
**Last Updated:** February 8, 2025
**Xcode Target:** 15+
**iOS Minimum:** 17.0
