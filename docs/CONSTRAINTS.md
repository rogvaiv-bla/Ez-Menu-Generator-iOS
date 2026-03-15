# Constraint System Documentation

## Overview

Ez Menu Generator enforces **16 dietary restrictions** with a sophisticated tracking system. This document explains how constraints work, how they're validated, and how the menu generation respects them.

## Table of Contents

1. [Constraint Types](#constraint-types)
2. [ConstraintTracker Architecture](#constrainttracker-architecture)
3. [Menu Generation Algorithm](#menu-generation-algorithm)
4. [Validation & Reporting](#validation--reporting)
5. [Code Examples](#code-examples)

---

## Constraint Types

### Weekly/Daily Limits (7 constraints)

These restrict how many days per week a food type appears.

#### 1. Carne Roșie (Red Meat)
- **Limit:** Max 3 days/week
- **Triggers:** beefsteak, beef, vită, file, entrecote
- **Meal:** Any meal (tracked daily)
- **Repository:** `ConstraintTracker.redMeatDays`

#### 2. Carne de Pasăre (Poultry)
- **Limit:** Max 4 days/week
- **Triggers:** chicken, pui, rață, turturică, quail
- **Meal:** Any meal
- **Repository:** `ConstraintTracker.poultryDays`

#### 3. Pește (Fish)
- **Limit:** Max 3 days/week
- **Triggers:** salmon, trout, bass, cod, mackerel, tuna
- **Meal:** Any meal
- **Repository:** `ConstraintTracker.fishDays`

#### 4. Ouă (Eggs)
- **Limit:** Max 2 days/week
- **Triggers:** oua, ou, egg (in omelet, scrambled, boiled)
- **Meal:** Any meal
- **Repository:** `ConstraintTracker.eggDays`

#### 5. Carne Procesată (Processed Meat)
- **Limit:** Max 1 day/week
- **Triggers:** salam, cabanossi, mortadella, hot dog, bacon, prosciutto
- **Meal:** Any meal
- **Repository:** `ConstraintTracker.processedMeatDays`

#### 6. Legume (Vegetables)
- **Limit:** MIN 4 days/week (minimum)
- **Triggers:** broccoli, carrot, spinach, tomato, cucumber, bell pepper
- **Meal:** Any meal
- **Repository:** `ConstraintTracker.vegetableDays`

#### 7. Fructe (Fruits)
- **Limit:** MIN 5 days/week (minimum)
- **Triggers:** apple, banana, orange, blueberry, strawberry, mango, kiwi
- **Meal:** Any meal
- **Repository:** `ConstraintTracker.fruitDays`

### Gram-Based Limits (3 constraints)

These track cumulative grams per week.

#### 8. Lactate (Dairy)
- **Limit:** Max 1000g/week
- **Includes:** milk, cheese, yogurt, butter, cream
- **Calculation:** Ingredient quantity (if unit = g/ml, assume 1:1 ratio)
- **Repository:** `ConstraintTracker.dairyGramsWeekly`

#### 9. Nuci (Nuts)
- **Limit:** Max 100g/week
- **Includes:** walnut, almond, peanut, cashew, hazelnut, pistachio
- **Calculation:** Same as dairy
- **Repository:** `ConstraintTracker.nutsGramsWeekly`

#### 10. Prăjituri (Baked Goods/Sweets)
- **Limit:** Max 2 days/week (appearance-based, not grams)
- **Triggers:** cake, pastry, cookie, donut, chocolate cake, cheesecake
- **Meal:** Any meal
- **Repository:** `ConstraintTracker.bakedGoodsDays`

### Allergen Avoidance (4 constraints)

Complete avoidance - recipe violates if ANY ingredient triggers.

#### 11. Alergie Unt de Arahidă (Peanut Butter Allergy)
- **Triggers:** peanut, arahidă, peanut butter, unt de arahidă
- **Severity:** Complete avoidance (1 violation = FAIL)

#### 12. Alergie Lactate (Lactose/Dairy Allergy)
- **Triggers:** milk, cheese, yogurt, butter, cream, lactate
- **Severity:** Complete avoidance

#### 13. Alergie Fructe de Pădure (Berry Allergy)
- **Triggers:** blueberry, strawberry, raspberry, blackberry
- **Severity:** Complete avoidance

#### 14. Alergie Soia (Soy Allergy)
- **Triggers:** soy, soia, tofu, edamame, soy sauce
- **Severity:** Complete avoidance

### Dietary Preferences (2 constraints)

Comprehensive restrictions on food types.

#### 15. Vegetarian
- **Restrictions:** NO meat (red, poultry, fish, processed)
- **Allowed:** Eggs, dairy, vegetables, fruits, nuts
- **Check:** Recipe has NO ingredients with tags: redMeat | poultry | fish | processedMeat
- **Violation:** 1 (recipe contains meat)

#### 16. Vegan
- **Restrictions:** NO animal products whatsoever
- **Allowed:** Vegetables, fruits, nuts, seeds, legumes, plant-based oils
- **Check:** Recipe has NO ingredients with tags: redMeat | poultry | fish | eggs | dairy | processedMeat
- **Violation:** 1 (recipe contains animal product)

---

## ConstraintTracker Architecture

### Core Class

```swift
class ConstraintTracker {
    // Daily trackers (for current day)
    var redMeatCount: Int = 0
    var poultryCount: Int = 0
    var fishCount: Int = 0
    var eggCount: Int = 0
    var processedMeatCount: Int = 0
    
    // Weekly counters (across 7 days)
    var redMeatDays: Set<Int> = []      // Set of day indices (0-6)
    var poultryDays: Set<Int> = []
    var fishDays: Set<Int> = []
    var eggDays: Set<Int> = []
    var processedMeatDays: Set<Int> = []
    var vegetableDays: Set<Int> = []
    var fruitDays: Set<Int> = []
    var bakedGoodsDays: Set<Int> = []
    
    // Gram-based limits (cumulative)
    var dairyGramsWeekly: Int = 0
    var nutsGramsWeekly: Int = 0
    
    // Allergy flags (user-selected)
    var allergyPeanutButter: Bool = false
    var allergyDairy: Bool = false
    var allergyBerries: Bool = false
    var allergySoy: Bool = false
    
    // Dietary preference
    var isVegetarian: Bool = false
    var isVegan: Bool = false
    
    // Current tracking
    var currentDayIndex: Int = 0
}
```

### Key Methods

#### `addMeal(_ recipe: Recipe)`
Adds a recipe's ingredients to tracking:
```swift
// 1. Increment daily counters for each tag
// 2. Add currentDayIndex to weekly sets
// 3. Accumulate gram measurements
```

#### `nextDay()`
Resets daily counters, moves to next day:
```swift
redMeatCount = 0
poultryCount = 0
// ... reset all daily counters
currentDayIndex += 1
```

#### `getViolations(recipe: Recipe) -> [String]`
Returns list of constraint violations for a recipe:
```swift
var violations: [String] = []

// Check allergens
if allergyPeanutButter && recipe.ingredients.contains(where: { $0.isPeanutButterAllergy }) {
    violations.append("Contains peanut butter (allergy)")
}

// Check daily limits (e.g., red meat)
if redMeatCount > 0 && recipe.hasRedMeat && !redMeatDays.contains(currentDayIndex) {
    violations.append("Red meat limit exceeded")
}

// Check dietary preferences
if isVegetarian && recipe.hasMeat {
    violations.append("Recipe contains meat (vegetarian diet)")
}

return violations
```

---

## Menu Generation Algorithm

### 3-Pass Algorithm (in MenuListViewModel)

The menu generator uses a sophisticated multi-pass approach to find valid recipes.

```swift
func generateMenu() {
    var menus: [Menu] = []
    
    for attempt in 1...5 {  // Max 5 attempts for good variation
        let tracker = ConstraintTracker()
        tracker.applyUserConstraints()  // Load user's dietary preferences
        
        let newMenu = Menu(name: "Menu \(attempt)")
        
        for dayIndex in 0..<7 {
            tracker.currentDayIndex = dayIndex
            
            // Generate 3 meals for this day
            var dayMeals = DayMeals()
            
            dayMeals.breakfast = findValidRecipe(pass: 1, 2, 3)
            tracker.addMeal(dayMeals.breakfast)
            
            dayMeals.lunch = findValidRecipe(pass: 1, 2, 3)
            tracker.addMeal(dayMeals.lunch)
            
            dayMeals.dinner = findValidRecipe(pass: 1, 2, 3)
            tracker.addMeal(dayMeals.dinner)
            
            newMenu.meals.append(dayMeals)
            tracker.nextDay()
        }
        
        menus.append(newMenu)
    }
    
    // Return menu with best score (fewest violations)
    return menus.min { getViolations($0).count < getViolations($1).count }
}
```

### 3-Pass Recipe Selection

For **each meal**, the algorithm tries 3 passes:

**Pass 1: Zero Violations**
```swift
// Find recipes with NO constraint violations
for recipe in recipes.shuffled() {
    if tracker.getViolations(recipe: recipe).isEmpty {
        return recipe  // Perfect match!
    }
}
```

**Pass 2: One or Fewer Violations**
```swift
// If no perfect recipes, allow up to 1 violation
for recipe in recipes.shuffled() {
    let violations = tracker.getViolations(recipe: recipe)
    if violations.count <= 1 {
        return recipe  // Acceptable
    }
}
```

**Pass 3: Minimum Violations**
```swift
// Fallback: use recipe with fewest violations
let sorted = recipes.sorted { 
    tracker.getViolations(recipe: $0).count < 
    tracker.getViolations(recipe: $1).count
}
return sorted.first ?? recipes.randomElement()
```

### Algorithm Benefits

1. **Variety** - Shuffles recipes each pass for different menus
2. **Constraint Respect** - Prioritizes recipes with no violations
3. **Fallback Handling** - Always finds a recipe (never crashes)
4. **Retry Logic** - Generates 5 menus, returns best one

---

## Validation & Reporting

### MenuListViewModel Validation

The `getMenuValidationIssues()` function returns violations per day:

```swift
func getMenuValidationIssues(_ menu: Menu) -> [String] {
    var allIssues: [String] = []
    let tracker = ConstraintTracker()
    tracker.applyUserConstraints()
    
    for (dayIndex, dayMeal) in menu.meals.enumerated() {
        tracker.currentDayIndex = dayIndex
        
        let recipes = [dayMeal.breakfast, dayMeal.lunch, dayMeal.dinner].compactMap { $0 }
        
        for recipe in recipes {
            let violations = tracker.getViolations(recipe: recipe)
            for violation in violations {
                allIssues.append("Day \(dayIndex + 1): \(recipe.name) - \(violation)")
            }
            tracker.addMeal(recipe)
        }
        
        tracker.nextDay()
    }
    
    return allIssues
}
```

### UI Display (MenuValidationView)

```swift
List {
    ForEach(validationIssues, id: \.self) { issue in
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
            Text(issue)
                .font(.caption)
        }
    }
}
```

---

## Code Examples

### Example 1: Check if Recipe Violates Vegetarian Constraint

```swift
// User has vegetarian constraint enabled
tracker.isVegetarian = true

// Recipe: "Grilled Steak"
let violations = tracker.getViolations(recipe: steak)
// Returns: ["Recipe contains meat (vegetarian diet)"]

// Menu generation skips this recipe
```

### Example 2: Dairy Gram Tracking

```swift
// User limit: 1000g dairy/week
tracker.dairyGramsWeekly = 0

// Recipe 1: Beef with cheese (100g cheese)
// tracker.dairyGramsWeekly = 100

// Recipe 2: Yogurt parfait (200g yogurt)
// tracker.dairyGramsWeekly = 300

// Recipe 3: Cream pasta (300g cream)
// tracker.dairyGramsWeekly = 600

// Recipe 4: Chicken with butter (150g butter)
// tracker.dairyGramsWeekly = 750

// Recipe 5: Cheese pie (300g cheese)
// tracker.dairyGramsWeekly = 1050 -> VIOLATION!
// Returns: ["Dairy limit exceeded (1050g > 1000g)"]
```

### Example 3: Multi-Day Constraint

```swift
// User limit: Max 3 red meat days/week
tracker.redMeatDays = Set()

// Day 0: Steak for dinner
tracker.redMeatDays.insert(0)  // {0}

// Day 1: Beef pasta for lunch
tracker.redMeatDays.insert(1)  // {0, 1}

// Day 3: Beef burger for lunch
tracker.redMeatDays.insert(3)  // {0, 1, 3}

// Day 4: Trying to add another steak
if tracker.redMeatDays.count >= 3 {
    violations.append("Red meat limit exceeded (3/3 days used)")
}
```

---

## Testing Constraints

### Unit Tests

See `NutritionCalculatorTests.swift` for examples:

```swift
func testConstraintViolation() {
    let tracker = ConstraintTracker()
    tracker.isVegetarian = true
    
    let beefRecipe = Recipe(name: "Steak", ingredients: [Ingredient(name: "beef", type: .meat)])
    let violations = tracker.getViolations(recipe: beefRecipe)
    
    XCTAssertTrue(violations.contains("Recipe contains meat"))
}
```

### Manual Testing

1. **Create a Menu** with Vegetarian constraint enabled
2. **Check MenuValidationView** - should show red/orange warnings
3. **Edit Menu** - try adding meat recipe (should show violation)
4. **Generate New Menu** - algorithm respects constraint automatically

---

## Future Enhancements

- Custom daily calorie limits
- Macro ratio preferences (carbs:fat:protein)
- Seasonal ingredient preferences
- Price-based constraints
- Preparation time limits

---

## References

- `Models/Recipe.swift` - Recipe model with dietaryTags
- `Services/ConstraintTracker.swift` - Core constraint logic
- `ViewModels/MenuListViewModel.swift` - Menu generation algorithm
- `Views/MenuValidationView.swift` - UI for violation display
