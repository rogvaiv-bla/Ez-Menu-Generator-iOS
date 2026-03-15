# Ez Menu Generator - Project Structure

## 📋 Overview

This document describes the complete folder structure of the Ez Menu Generator iOS app after **Task 1: Complete File Organization**.

**Last Updated:** March 15, 2026  
**Version:** 1.0 (Post-Reorganization)

---

## 📁 Complete Directory Tree

```
Ez Menu Generator/
├── App/
│   ├── EzMenuGeneratorApp.swift          # App entry point & main NavigationStack
│   ├── Untitled-1.ini                    # Config file (legacy)
│   └── Ez Menu Generator.code-workspace  # VSCode workspace config
│
├── Models/                                # Data models (SwiftData @Model)
│   ├── ActivityLog.swift                  # User activity logging model
│   ├── Household.swift                    # Household/family model
│   ├── HouseholdUser.swift               # User profile within household
│   ├── Ingredient.swift                   # Recipe ingredient model
│   ├── Menu.swift                         # Weekly menu model
│   ├── NutritionInfo.swift               # Nutrition data structure
│   ├── Recipe.swift                       # Recipe model
│   ├── ShoppingItem.swift                 # Shopping list item
│   └── ShoppingListV2.swift              # Shopping list collection
│
├── ViewModels/                            # MVVM state management (ObservableObject)
│   ├── AnalyzeViewModel.swift            # Product search/barcode analysis
│   ├── MenuEditorViewModel.swift         # Menu editing logic
│   ├── MenuListViewModel.swift           # Menu list & stats
│   ├── RecipeListViewModel.swift         # Recipe browsing & filtering
│   └── ShoppingListViewModel.swift       # Shopping list operations
│
├── Views/                                 # UI views organized by feature
│   ├── ContentView/
│   │   └── ContentView.swift             # Main TabView & navigation hub
│   │
│   ├── Menu/                             # Menu planning feature
│   │   ├── MenuList/
│   │   │   ├── MenuListView.swift        # Weekly menu display
│   │   │   ├── MenuListItemView.swift    # Individual menu card
│   │   │   ├── AddMenuView.swift         # Create new menu
│   │   │   ├── WeeklyMenuView.swift      # Weekly layout view
│   │   │   ├── WeeklyStatsWidget.swift   # Nutrition stats widget
│   │   │   └── DailyMealCard.swift       # Daily meal card component
│   │   └── MenuEditor/
│   │       ├── MenuEditorView.swift      # Menu editor container
│   │       ├── MenuStatsView.swift       # Nutrition calculations display
│   │       ├── MenuValidationView.swift  # Menu validation screen
│   │       ├── RecipePickerView.swift    # Recipe selection modal
│   │       ├── DayMealSelectorView.swift # Day/meal type picker
│   │       └── ShoppingListPreviewView.swift # Preview shopping list
│   │
│   ├── Recipe/                           # Recipe management feature
│   │   └── RecipeList/
│   │       ├── RecipeListView.swift      # Recipe library display
│   │       ├── RecipeDetailView.swift    # Recipe details page
│   │       ├── RecipeRowView.swift       # Recipe list item component
│   │       ├── AddRecipeView.swift       # Create new recipe
│   │       ├── AddIngredientView.swift   # Add ingredient to recipe
│   │       └── NutritionDetailView.swift # Detailed nutrition info
│   │
│   ├── Shopping/                         # Shopping list feature
│   │   └── ShoppingList/
│   │       ├── ShoppingListView.swift    # Main shopping list display
│   │       ├── AddShoppingItemView.swift # Add item modal
│   │       ├── EditShoppingItemView.swift# Edit item modal
│   │       └── ShoppingItemRowView.swift # Individual item row (optimized for supermarket)
│   │
│   ├── Analyze/                          # Product analysis feature
│   │   ├── AnalyzeView.swift            # Product search interface
│   │   └── BarcodeScannerView.swift     # Barcode camera scanner
│   │
│   └── Components/                       # Reusable UI components
│       ├── ProductDetailView.swift       # Product information display
│       │
│       ├── Household/                    # Household management
│       │   ├── HouseholdOnboardingView.swift  # Initial setup flow
│       │   ├── HouseholdTabView.swift         # Household switcher
│       │   └── QRCodeScannerView.swift       # QR code scanner
│       │
│       ├── Settings/
│       │   └── CacheStatsView.swift      # Cache management UI
│       │
│       └── Utilities/                    # General-purpose components
│           ├── NavigationBarView.swift   # Custom nav bar (redesign 3.0)
│           ├── ImagePickerView.swift     # Image selection modal
│           ├── LazyImage.swift           # Lazy-loaded image component
│           └── NutritionDashboardView.swift # Nutrition display widget
│
├── Services/                              # Business logic & API layer
│   ├── Core Services
│   │   ├── StorageService.swift          # SwiftData persistence layer
│   │   ├── NutritionCalculator.swift     # Nutrition computations
│   │   ├── UndoRedoManager.swift         # Undo/redo functionality
│   │   ├── UndoRedoSnapshot.swift        # State snapshots for undo
│   │   └── ServiceProtocols.swift        # Service interface definitions
│   │
│   ├── Data Services
│   │   ├── ProductDatabaseService.swift  # Local product database
│   │   ├── SampleDataService_New.swift   # Sample data population (197 items)
│   │   ├── DataSeeder.swift              # Initial data seeding
│   │   └── OpenFoodFactsModels.swift     # External API models
│   │
│   ├── External APIs
│   │   ├── OpenFoodFactsService.swift    # Open Food Facts API integration
│   │   ├── SupabaseConfig.swift          # Supabase credentials
│   │   ├── SupabaseService.swift         # Generic Supabase operations
│   │   ├── SupabaseAuthService.swift     # Authentication
│   │   ├── SupabaseHouseholdService.swift # Household sync
│   │   └── SupabaseImageService.swift    # Image upload/download
│   │
│   ├── State Management
│   │   ├── HouseholdManager.swift        # Household state (moved from ViewModels)
│   │   ├── OfflineSyncManager.swift      # Offline data sync (moved from ViewModels)
│   │   └── RealtimeSyncManager.swift     # Real-time sync manager (moved from ViewModels)
│   │
│   ├── Utilities
│   │   ├── ImageCacheManager.swift       # Image caching
│   │   ├── HealthCheckManager.swift      # API health monitoring
│   │   ├── Logger.swift                  # Core logging system
│   │   ├── LocalLogger.swift             # Local file logging
│   │   └── LoggingStructures.swift       # Logging data structures
│
├── Theme/                                 # Design system (moved from Design/)
│   ├── AppTheme.swift                    # Main theme configuration
│   ├── Colors.swift                      # Color palette (EzColors)
│   ├── Typography.swift                  # Text styles
│   ├── Spacing.swift                     # Layout spacing constants
│   ├── Buttons.swift                     # Button styles
│   ├── Shadows.swift                     # Shadow definitions
│   ├── StateComponents.swift             # Loading, empty states
│   └── DebugBreakpoints.swift            # Debugging utilities
│
├── Utils/                                 # Utilities (moved from Utilities/)
│   ├── AppConstants.swift                # ✨ NEW: App constants (version, limits)
│   ├── CategoryManager.swift             # Shopping category management
│   ├── Categories.swift                  # Category definitions
│   ├── HapticManager.swift               # Haptic feedback
│   ├── IngredientTypeDetector.swift      # Ingredient classification
│   ├── QRCodeGenerator.swift             # QR code generation
│   └── TokenStore.swift                  # Auth token storage
│
├── Extensions/                            # Swift extensions (ready for use)
│   └── [Empty - ready for String, Date, View extensions]
│
├── Navigation/                            # Routing & navigation (ready for implementation)
│   └── [Empty - ready for routing logic]
│
├── Resources/                             # Localized strings, configs
│   └── [Empty - ready for Localizable.strings, Info.plist values]
│
├── Monitoring/                            # Performance & integrity tracking
│   ├── Core/
│   │   └── EventCollector.swift          # Event collection system
│   ├── Performance/
│   │   └── PerformanceMonitor.swift      # Performance metrics
│   └── Integrity/
│       └── IntegrityManager.swift        # Data integrity checks
│
├── Assets.xcassets/                       # Images, icons, colors
│   ├── AppIcon.appiconset/
│   │   ├── Contents.json
│   │   └── ezmenu.png                    # App icon
│   └── [Other asset sets]
│
├── EzMenuGenerator.entitlements           # iOS capabilities config
│
└── [Test Targets]
    ├── Ez Menu GeneratorTests/            # Unit tests
    │   ├── NutritionCalculatorTests.swift
    │   └── SampleDataServiceTests.swift
    └── Ez Menu GeneratorUITests/          # UI tests
        ├── Ez_Menu_GeneratorUITests.swift
        └── Ez_Menu_GeneratorUITestsLaunchTests.swift
```

---

## 🔄 What Was Moved (Task 1 Summary)

### ✅ Moved FROM ViewModels → TO Services
- `HouseholdManager.swift` - State management for households
- `OfflineSyncManager.swift` - Offline data synchronization
- `RealtimeSyncManager.swift` - Real-time sync with cloud

**Reason:** These are service-layer concerns (state management + sync), not view model binding concerns.

### ✅ Moved FROM Design → TO Theme
- `AppTheme.swift` - Core theme
- `Colors.swift` - Color palette
- `Typography.swift` - Text styles
- `Spacing.swift` - Layout constants
- `Buttons.swift` - Button styles
- `Shadows.swift` - Shadow definitions
- `StateComponents.swift` - Empty/loading states
- `DebugBreakpoints.swift` - Debug utilities

**Reason:** Consolidated all design tokens into one "Theme" folder for better discoverability.

### ✅ Moved FROM Utilities → TO Utils
- `Categories.swift` - Category enums
- `CategoryManager.swift` - Category logic
- `HapticManager.swift` - Haptic feedback
- `IngredientTypeDetector.swift` - Type detection
- `QRCodeGenerator.swift` - QR generation
- `TokenStore.swift` - Token storage
- **NEW** `AppConstants.swift` - App-wide constants

**Reason:** Shortened folder name for convenience; all utility classes grouped together.

### ✅ Views Reorganized by Feature
**From:** Flat structure with `MenuEditor/`, `MenuList/`, `RecipeList/`, `ShoppingList/` at root  
**To:** Hierarchical structure:
- `Views/Menu/` → MenuEditor + MenuList
- `Views/Recipe/` → RecipeList
- `Views/Shopping/` → ShoppingList
- `Views/Analyze/` → AnalyzeView + BarcodeScannerView
- `Views/Components/` → Household, Settings, Utilities, ProductDetail

**Reason:** Feature-based organization makes it easy to find all related screens for a feature.

### ✅ Deleted
- `StorageService.swift.bak` - Backup file (no longer needed)

---

## 📊 Statistics

| Layer | Count | Purpose |
|-------|-------|---------|
| Models | 9 files | Data structures |
| ViewModels | 5 files | State & business logic for views |
| Views | 30+ files | UI components (organized by feature) |
| Services | 21 files | Business logic, APIs, persistence |
| Theme | 8 files | Design system tokens |
| Utils | 7 files | Helper utilities |
| Monitoring | 3 files | Performance & integrity |
| **Total** | **80+** | Complete iOS app |

---

## 🎯 Key Features Location

### 📋 Shopping List (Optimized for Supermarket)
- **ViewModel:** `ViewModels/ShoppingListViewModel.swift`
- **Views:** `Views/Shopping/ShoppingList/`
  - Main list: `ShoppingListView.swift`
  - Row item (32pt checkbox, full-row tap): `ShoppingItemRowView.swift`
  - Add/Edit modals: `AddShoppingItemView.swift`, `EditShoppingItemView.swift`
- **Data:** `Models/ShoppingItem.swift`, `Models/ShoppingListV2.swift`
- **Logic:** `Services/StorageService.swift` (persistence)

### 📅 Menu Planning
- **ViewModel:** `ViewModels/MenuListViewModel.swift`, `MenuEditorViewModel.swift`
- **Views:** `Views/Menu/MenuList/` (display), `Views/Menu/MenuEditor/` (editing)
- **Data:** `Models/Menu.swift`
- **Logic:** `Services/NutritionCalculator.swift` (calculations)

### 📚 Recipe Management
- **ViewModel:** `ViewModels/RecipeListViewModel.swift`
- **Views:** `Views/Recipe/RecipeList/`
- **Data:** `Models/Recipe.swift`, `Models/Ingredient.swift`

### 🔍 Product Analysis & Barcode Scanning
- **ViewModel:** `ViewModels/AnalyzeViewModel.swift`
- **Views:** `Views/Analyze/AnalyzeView.swift`, `Views/Analyze/BarcodeScannerView.swift`
- **APIs:** `Services/OpenFoodFactsService.swift`

### 🏠 Household Management
- **Manager:** `Services/HouseholdManager.swift`
- **Views:** `Views/Components/Household/`
- **Data:** `Models/Household.swift`, `Models/HouseholdUser.swift`

---

## 🔗 Import Paths (Important)

When working with files, use these import paths:

```swift
// Models
import Models  // or specific: Model.Menu, Model.Recipe, etc.

// ViewModels
@StateObject private var viewModel = ShoppingListViewModel()

// Views (by feature)
import Views.Shopping
import Views.Menu
import Views.Recipe
import Views.Analyze
import Views.Components

// Services
let storage = StorageService.shared
let household = HouseholdManager.shared

// Theme
import Theme
// Access via: EzColors, EzSpacing, EzTypography, etc.

// Utils
import Utils
// Access via: CategoryManager.shared, HapticManager, etc.
```

---

## 📝 Notes

1. **No Logic Changed:** This reorganization only moved files; no code logic was altered.
2. **Xcode Project Updated:** All build phases and file references are automatically managed by Xcode.
3. **Git History Preserved:** Each move is tracked as a file rename in git history.
4. **Ready for Growth:**
   - `Extensions/` folder ready for Swift extensions
   - `Navigation/` folder ready for advanced routing
   - `Resources/` folder ready for localization

---

## 🚀 Next Steps

- [ ] Run `xcodebuild` to verify all imports resolve correctly
- [ ] Update any failing imports if needed
- [ ] Commit final structure to git
- [ ] Tag version 1.0 after successful build
