# Developer Setup Guide

## Quick Start

### Prerequisites

- **macOS 13+**
- **Xcode 15+** (with iOS 17+ SDK)
- **Git**

### Installation (5 minutes)

```bash
# Clone repository
git clone https://github.com/yourusername/Ez-Menu-Generator.git
cd Ez-Menu-Generator

# Open in Xcode
open "Ez Menu Generator.xcodeproj"

# Select iPhone 15/16 simulator
# Press Cmd+R to build & run
```

## Project Structure

```
Ez Menu Generator/
├── App/                          # Entry point
│   └── EzMenuGeneratorApp.swift   # SwiftData setup
│
├── Models/                        # Data structures (15 min read)
│   ├── Recipe.swift
│   ├── Menu.swift
│   ├── Ingredient.swift
│   ├── ShoppingItem.swift
│   └── NutritionInfo.swift
│
├── Services/                      # Business logic (30 min read)
│   ├── StorageService.swift      # Database layer
│   ├── MenuListViewModel.swift    # Menu generator
│   ├── RecipeListViewModel.swift  # Recipe manager
│   ├── ConstraintTracker.swift    # Validation engine
│   ├── NutritionCalculator.swift  # Nutrition math
│   └── UndoRedoManager.swift      # Undo/redo state
│
├── ViewModels/                    # MVVM state (20 min read)
│   ├── MenuListViewModel.swift
│   ├── MenuEditorViewModel.swift
│   ├── RecipeListViewModel.swift
│   └── ShoppingListViewModel.swift
│
├── Views/                         # SwiftUI components (60 min explore)
│   ├── ContentView/               # Main navigation
│   ├── MenuList/                  # Menu screen
│   ├── MenuEditor/                # Edit menu screen
│   ├── RecipeList/                # Recipe screen
│   └── ShoppingList/              # Shopping screen
│
├── Design/                        # Styling
│   └── AppTheme.swift
│
├── Assets.xcassets/               # Images & colors
│
├── README.md                      # Project overview
├── ARCHITECTURE.md                # Design patterns
├── CONSTRAINTS.md                 # Dietary system
└── SETUP.md                       # This file
```

## First-Time Setup

### 1. Understand the Data Model (15 min)

Read files in this order:
1. `Models/Recipe.swift` - What is a recipe?
2. `Models/Ingredient.swift` - What goes in a recipe?
3. `Models/Menu.swift` - How are menus structured?

### 2. Understand Business Logic (30 min)

Read:
1. `Services/StorageService.swift` - How data is saved
2. `Services/ConstraintTracker.swift` - How constraints work
3. `Services/MenuListViewModel.swift` - How menus are generated

### 3. Explore the UI (Experiential)

1. Run the app (Cmd+R)
2. Click through each tab:
   - **Recipes** - Add a new recipe
   - **Menus** - Generate a menu
   - **Shopping** - See aggregated ingredients

### 4. Read the Documentation

- `README.md` - High-level overview
- `ARCHITECTURE.md` - Design patterns (25 min)
- `CONSTRAINTS.md` - Dietary system (20 min)

## Development Workflow

### Adding a New Feature

**Example: Add "Prep Time" field to shopping list**

1. **Update Model** (`Models/ShoppingItem.swift`)
   ```swift
   var prepTimeMinutes: Int = 0
   ```

2. **Update ViewModel** (`ViewModels/ShoppingListViewModel.swift`)
   ```swift
   func updatePrepTime(_ item: ShoppingItem, minutes: Int) {
       item.prepTimeMinutes = minutes
       StorageService.shared.updateShoppingItem(item)
   }
   ```

3. **Update Service** (`Services/StorageService.swift`)
   ```swift
   func updateShoppingItem(_ item: ShoppingItem) {
       // ... save to SwiftData
   }
   ```

4. **Update View** (`Views/ShoppingList/ShoppingItemRowView.swift`)
   ```swift
   HStack {
       Text(item.name)
       Spacer()
       Text("\(item.prepTimeMinutes) min")
   }
   ```

5. **Test**
   - Build (Cmd+B)
   - Run (Cmd+R)
   - Add item and verify prep time displays

### Code Style Guide

#### Naming Conventions

```swift
// Variables: camelCase
let recipeCount: Int
var selectedRecipe: Recipe?

// Classes/Structs: PascalCase
class MenuListViewModel
struct ShoppingItem

// Constants: UPPER_SNAKE_CASE
let MAX_RECIPES = 1000

// Functions: camelCase
func generateMenu()
func addRecipe(recipe: Recipe)
```

#### Comments

Use structured comments for clarity:

```swift
// MARK: - Purpose
// Explain what this section does

// MARK: - Parameters
// Explain function parameters

// MARK: - Returns
// Explain what function returns

// MARK: - Usage
// Show example usage
```

#### SwiftUI View Structure

```swift
struct RecipeListView: View {
    @StateObject var viewModel = RecipeListViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Content
            }
            .navigationTitle("Recipes")
        }
    }
}
```

### Common Tasks

#### Build the app

```bash
xcode: Cmd+B
# or
terminal: xcodebuild -scheme "Ez Menu Generator"
```

#### Run tests

```bash
xcode: Cmd+U
# or
terminal: xcodebuild test -scheme "Ez Menu Generator"
```

#### Add a new Swift file

1. Right-click in Xcode file browser
2. New File...
3. Choose Swift
4. Save in appropriate folder (Models/, Services/, Views/, etc.)

#### View SwiftData database

The database is stored in:
```
~/Library/Developer/Xcode/DerivedData/Ez\ Menu\ Generator-xxx/
```

Clear cache:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Ez*/
```

## Debugging

### Debug Prints

View Console output (Cmd+Shift+C):

```swift
print("✅ Recipe created: \(recipe.name)")
print("❌ Error saving: \(error.localizedDescription)")
```

### Breakpoints

1. Click line number to set breakpoint
2. Run app (Cmd+R)
3. When code hits breakpoint:
   - Step Over: Cmd+;
   - Step Into: Cmd+'
   - Continue: Cmd+Ctrl+Y

### View Hierarchy

Debug → View Hierarchy (Cmd+Alt+0) shows UI component tree

### SwiftData Errors

Common issues:

**"Model not found"**
- Delete app from simulator
- Clear DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/*/`
- Rebuild: Cmd+B

**"Constraint violation"**
- Check your constraint logic in ConstraintTracker
- Add debug prints in `getViolations()`

**"Memory leak"**
- Check for circular references in @Relationship
- Use `@Transient` for calculated properties

## Testing

### Unit Tests Location

```
Ez Menu GeneratorTests/
├── Ez_Menu_GeneratorTests.swift         # Core logic
├── NutritionCalculatorTests.swift       # Nutrition math
└── SampleDataServiceTests.swift         # Sample data
```

### Adding a Test

```swift
import XCTest

class MenuGenerationTests: XCTestCase {
    
    func testGenerateMenuRespectsConstraints() {
        // Arrange
        let tracker = ConstraintTracker()
        tracker.isVegetarian = true
        
        // Act
        let menu = generateMenu(tracker)
        
        // Assert
        XCTAssertTrue(menu.meals.allSatisfy { !$0.hasRedMeat })
    }
}
```

Run tests: Cmd+U

## Performance Tips

### Optimize List Rendering

Use `id` parameter explicitly:
```swift
List(recipes, id: \.id) { recipe in  // Better than default
    RecipeRow(recipe: recipe)
}
```

### Lazy Loading

Load relationships when needed:
```swift
@Relationship var ingredients: [Ingredient]  // Loaded on access
```

### Cache Expensive Calculations

```swift
// BAD: Recalculated every render
var totalNutrition: NutritionInfo {
    return ingredients.reduce(NutritionInfo()) { ... }
}

// GOOD: Cached
var nutrition: NutritionInfo?  // Calculated once, stored
```

## Deployment Checklist

Before submitting to App Store:

- [ ] Update version number in Info.plist
- [ ] Remove test/sample data (comment out SampleDataService)
- [ ] Remove debug print statements
- [ ] Test on physical device
- [ ] Run tests: Cmd+U
- [ ] Build archive: Product > Archive
- [ ] Check asset sizes (images < 5MB)

## Useful Links

- [Apple SwiftUI Tutorial](https://developer.apple.com/tutorials/swiftui/)
- [Apple SwiftData Tutorial](https://developer.apple.com/tutorials/swiftdata/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Getting Help

### Check Existing Code

1. Search feature (Cmd+F) in file
2. Find usages (Cmd+Ctrl+F) to see how code is used
3. Jump to definition (Cmd+Click) to see implementation

### Common Errors & Solutions

| Error | Solution |
|-------|----------|
| `Type 'X' has no member 'Y'` | Check import statements, run Cmd+B to refresh |
| `Constraint conflict` | Use debug prints in ConstraintTracker |
| `View not updating` | Ensure ViewModel is @ObservableObject with @Published |
| `SwiftData migration error` | Clear app from simulator, rebuild |
| `Memory warning` | Profile with Instruments (Cmd+I) |

## Questions?

- Check `README.md` for feature overview
- Check `ARCHITECTURE.md` for design patterns
- Check `CONSTRAINTS.md` for dietary system details
- Read source code comments (especially MARK: blocks)

---

**Updated:** February 2026
**Xcode Version:** 15+
**iOS Target:** 17+
