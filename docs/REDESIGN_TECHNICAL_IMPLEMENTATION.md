# 🏗️ Redesign UX - Diagrame și Structură Tehnică

---

## 📊 DIAGRAMA NAVIGĂRII - REDESIGN

```text
┌─────────────────────────────────────────────────────────────┐
│                    TOP BAR (Global)                         │
│  [<] Context Title [🔍] [⚙️ Settings] [👥 Household]      │
└─────────────────────────────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
    ┌─────────┐        ┌─────────┐       ┌─────────┐
    │  HOME   │        │ RECIPES │       │  SHOP   │
    │ (Weekly)│        │(Library)│       │ (List)  │
    └────┬────┘        └────┬────┘       └────┬────┘
         │                  │                  │
    [Planning]          [Browse]            [Manage]
    [Stats]          [Favorites]            [Share]
    [AI]            [Filters]              [Track]
         │                  │                  │
         └──────────────────┼──────────────────┘
                            │
                    ┌───────┴────────┐
                    │                │
                    ▼                ▼
            ┌──────────────┐  ┌──────────┐
            │   ANALYZE    │  │ SETTINGS │
            │ (Scan/Track) │  │(Bottom    │
            └──────────────┘  │ sheet)   │
                │              └──────────┘
            [Scan]                │
            [History]          [Household]
            [Compare]          [Preferences]
                               [Allergies]

```text

---

## 🔄 STATE FLOW - Exemplu: Home → Generate Menu

```text
USER TAPS [Magic Wand]
       │
       ▼
┌─────────────────────┐
│ Preferences Modal   │
│ (Step 1/3)          │
│ - Budget            │
│ - Time              │
│ - Dietary           │
│ - Diversity         │
└─────────────────────┘
       │
       ├─ [Cancel] → Home (unchanged)
       │
       └─ [Next] → Step 2
              │
              ▼
       ┌─────────────────────┐
       │ Generation Loading  │
       │ (Step 2/3)          │
       │ 🔄 AI analyzing...  │
       │ Progress: 50%       │
       └─────────────────────┘
              │
              ├─ [Regenerate] → Back to Step 1
              │
              └─ [Next/Preview] → Step 3
                     │
                     ▼
       ┌─────────────────────┐
       │ Confirmation        │
       │ (Step 3/3)          │
       │ - Weekly stats      │
       │ - Meal preview      │
       │ - Shopping estimate │
       └─────────────────────┘
              │
              ├─ [< Back] → Step 2
              ├─ [Regenerate] → Step 1
              │
              └─ [✓ Confirm] → Apply
                     │
                     ▼
       ┌─────────────────────┐
       │ Success Toast       │
       │ "Menu generated!"   │
       │ [Open Menu]         │
       └─────────────────────┘

```text

---

## 🎯 HIERARCHICAL INFORMATION MAP

```text
APPLICATION STRUCTURE:

Ez Menu Generator (Root)
│
├─ Home Tab (Planning Hub)
│  ├─ Current Week View
│  │  ├─ Daily Cards (Mon-Sun)
│  │  │  ├─ Breakfast Meal Slot
│  │  │  ├─ Lunch Meal Slot
│  │  │  ├─ Dinner Meal Slot
│  │  │  └─ Dessert Meal Slot
│  │  │     ├─ [Swap] → Recipe Selector Modal
│  │  │     ├─ [Remove] → Confirmation
│  │  │     └─ [+Notes] → Text input
│  │  │
│  │  ├─ Weekly Overview Widget
│  │  │  ├─ Avg Kcal
│  │  │  ├─ Avg Nutri Score
│  │  │  ├─ Avg Eco Score
│  │  │  └─ Unique Recipes Count
│  │  │
│  │  └─ Actions
│  │     ├─ [Magic Wand] → Generate Modal (3-step)
│  │     ├─ [Randomize] → One-tap regenerate
│  │     └─ [Generate Shopping] → Auto-create list
│  │
│  └─ Past/Future Weeks (swipeable)
│     └─ Same structure as current week
│
├─ Recipes Tab (Discovery + Library)
│  ├─ Segmentation
│  │  ├─ All Recipes (default)
│  │  ├─ ⭐ Favorites
│  │  └─ Saved (drafts)
│  │
│  ├─ Filtering
│  │  ├─ Dietary (none/vegan/keto/gf/etc)
│  │  ├─ Time (<15min, 15-45min, 45+min, any)
│  │  ├─ Kcal (slider 0-2000)
│  │  └─ Nutri Score (all/80+/60-80/<60)
│  │
│  ├─ Recipe Grid (2-3 columns)
│  │  ├─ Recipe Card
│  │  │  ├─ Thumbnail
│  │  │  ├─ Title + Author
│  │  │  ├─ Time + Servings
│  │  │  ├─ Scores (Nutri)
│  │  │  └─ Actions
│  │  │     ├─ [⭐] toggle favorite
│  │  │     ├─ [+] add to meal
│  │  │     └─ [•••] context menu
│  │  │
│  │  ├─ Single tap → Detail View
│  │  │  ├─ Full image
│  │  │  ├─ Full nutrition
│  │  │  ├─ Ingredients list (with toggle scan)
│  │  │  ├─ Instructions
│  │  │  └─ Actions
│  │  │     ├─ [Add to today]
│  │  │     ├─ [Save to favorites]
│  │  │     ├─ [Print]
│  │  │     └─ [Share]
│  │  │
│  │  └─ Long press → Batch actions
│  │     ├─ [+Add to meal] (with date picker)
│  │     ├─ [⭐ Save]
│  │     ├─ [Compare] (add to compare mode)
│  │     ├─ [Duplicate] (save as new draft)
│  │     └─ [Delete] (with confirmation)
│  │
│  └─ Empty States
│     ├─ No recipes → Suggest browse or create
│     ├─ No favorites → Suggest add from all
│     └─ No filter results → Suggest reset
│
├─ Shop Tab (Collaborative List)
│  ├─ Segmentation
│  │  ├─ Pending (unchecked items)
│  │  └─ ✓ Completed (checked items)
│  │
│  ├─ Grouping by Household Member
│  │  ├─ Member Section (collapsible)
│  │  │  ├─ Shopping Items (grouped member)
│  │  │  │  ├─ Item Card
│  │  │  │  │  ├─ [Checkbox] toggle complete
│  │  │  │  │  ├─ Item name + quantity
│  │  │  │  │  ├─ Price + Store (if known)
│  │  │  │  │  ├─ Source meal (optional)
│  │  │  │  │  └─ Long-press menu
│  │  │  │  │     ├─ Edit qty/unit
│  │  │  │  │     ├─ Change store
│  │  │  │  │     ├─ Link meal
│  │  │  │  │     ├─ View nutrition
│  │  │  │  │     └─ Delete
│  │  │  │  │
│  │  │  │  └─ Add Manual Item
│  │  │  │     └─ Text input + qty + store
│  │  │  │
│  │  │  └─ Member Actions
│  │  │     ├─ Assign all items to me
│  │  │     └─ View member's meals
│  │  │
│  │  └─ Repeat for each household member
│  │
│  ├─ Summary Widget
│  │  ├─ Total items / completed
│  │  ├─ Est. total cost
│  │  ├─ Stores involved
│  │  └─ % coverage of weekly meals
│  │
│  ├─ Batch Actions (sticky bottom)
│  │  ├─ [Share] → Copy link / QR
│  │  ├─ [Print] → PDF export
│  │  ├─ [Clear completed]
│  │  ├─ [+ Add manually]
│  │  └─ [Smart suggestions] → AI additions
│  │
│  └─ Empty States
│     ├─ No pending → Congratulations screen
│     └─ No items at all → Generate from menu
│
├─ Analyze Tab (Scanning + Tracking)
│  ├─ Segmentation
│  │  ├─ Scan (default, prominent camera button)
│  │  ├─ History (recent scans)
│  │  ├─ Compare (when 2+ selected)
│  │  └─ (Future) Recommendations
│  │
│  ├─ Scan State (default)
│  │  ├─ [Large camera button]
│  │  │  └─ Opens camera modal
│  │  │     ├─ Barcode viewfinder
│  │  │     ├─ Product image upload
│  │  │     └─ Text search fallback
│  │  │
│  │  ├─ Recent Scans (last 5)
│  │  │  └─ Product Card (simplified)
│  │  │     ├─ Image + Name
│  │  │     ├─ Scores (Nutri, Eco)
│  │  │     ├─ Time scanned
│  │  │     └─ [Tap for detail]
│  │  │
│  │  └─ Quick Actions
│  │     ├─ [View more history]
│  │     └─ [Configure scanner]
│  │
│  ├─ Product Detail Modal (auto-opened after scan)
│  │  ├─ Image + Basic Info
│  │  │  ├─ Brand + volume
│  │  │  └─ Barcode
│  │  │
│  │  ├─ Score Cards (horizontal scroll)
│  │  │  ├─ Nutrition Score (0-100, colored)
│  │  │  ├─ Eco Score (A-E, colored)
│  │  │  └─ Health Alert (if applicable)
│  │  │
│  │  ├─ Quick Info Grid
│  │  │  ├─ Price
│  │  │  ├─ Volume
│  │  │  ├─ Store
│  │  │  └─ Expiry
│  │  │
│  │  ├─ Nutrition Facts (collapsible)
│  │  │  ├─ Per 100ml/serving
│  │  │  ├─ Energy, macros, micros
│  │  │  └─ RDA% indicators
│  │  │
│  │  ├─ Allergens & Additives
│  │  │  ├─ ⚠️ High sugar, salt, etc
│  │  │  ├─ ℹ️ Additives detected
│  │  │  └─ ✓ Safe for (dietary icons)
│  │  │
│  │  ├─ Smart Recommendations
│  │  │  ├─ Similar with better score
│  │  │  ├─ Cheaper alternatives
│  │  │  └─ Healthier swaps
│  │  │
│  │  └─ Actions (sticky bottom)
│  │     ├─ [🛒 Add to cart]
│  │     ├─ [⭐ Save to favorites]
│  │     ├─ [🔗 Link to meal]
│  │     ├─ [📸 Re-scan]
│  │     └─ [📤 Share]
│  │
│  ├─ History State
│  │  ├─ Date Filter (Today/Week/Month)
│  │  │
│  │  ├─ Timeline by Date
│  │  │  ├─ Date header (e.g., "TODAY")
│  │  │  ├─ Scan items chronological
│  │  │  │  ├─ Product name
│  │  │  │  ├─ Time scanned
│  │  │  │  └─ [Tap for detail]
│  │  │  │
│  │  │  ├─ Rep for each date period
│  │  │  └─ [Load more]
│  │  │
│  │  └─ Weekly Summary Widget
│  │     ├─ Avg Nutri score
│  │     ├─ Avg Eco score
│  │     └─ Most scanned category
│  │
│  ├─ Compare State (when 2+ items selected)
│  │  ├─ Product 1 | Product 2
│  │  │  ├─ Images side-by-side
│  │  │  ├─ All scores compared
│  │  │  ├─ Nutrition table (side-by-side)
│  │  │  └─ Price comparison
│  │  │
│  │  ├─ Key Differences (highlighted)
│  │  │  └─ Bullet list of main variations
│  │  │
│  │  ├─ Smart Recommendation
│  │  │  └─ "Product X is better for Y reason"
│  │  │
│  │  └─ Decision Actions
│  │     ├─ [Add both to cart]
│  │     ├─ [Choose product 1]
│  │     ├─ [Choose product 2]
│  │     └─ [← Scan another]
│  │
│  └─ Empty States
│     ├─ No scans yet → Encourage first scan
│     └─ No history matches filter → Clear filters
│
├─ Settings (Bottom Sheet / Tab)
│  ├─ Household Management
│  │  ├─ Current household (name, avatar)
│  │  ├─ Members list
│  │  │  ├─ Member name + role
│  │  │  └─ [Manage] → edit/remove
│  │  ├─ Invite new member
│  │  │  └─ Generate code / share link
│  │  └─ Leave household
│  │
│  ├─ Health Profile
│  │  ├─ Dietary restrictions
│  │  │  └─ Multi-select (vegan, keto, gf, etc)
│  │  ├─ Allergies & intolerances
│  │  │  └─ Custom multi-input
│  │  ├─ Daily nutrition goals
│  │  │  ├─ Kcal target
│  │  │  ├─ Macro targets
│  │  │  └─ Micro goals
│  │  └─ Activity level
│  │
│  ├─ Preferences
│  │  ├─ Currency (€, $, £)
│  │  ├─ Units (g/oz, ml/cup)
│  │  ├─ Language
│  │  ├─ Notifications (on/off)
│  │  └─ Dark mode (auto/on/off)
│  │
│  ├─ Data & Privacy
│  │  ├─ Sync status
│  │  ├─ Backup household data
│  │  ├─ Export data as CSV
│  │  ├─ Delete account
│  │  └─ Privacy policy
│  │
│  └─ About
│     ├─ App version
│     ├─ Changelog
│     └─ Contact support

```text

---

## 📱 COMPONENT LIBRARY STRUCTURE (Swift)

```text
EzMenuDesignSystem/
│
├─ Foundation/
│  ├─ Colors.swift
│  │  ├─ Background (primary, secondary, tertiary, surface)
│  │  ├─ Text (primary, secondary, tertiary)
│  │  ├─ Accent (primary, secondary, warning, danger)
│  │  ├─ Score-specific (nutri green/yellow/red, eco A-E)
│  │  └─ Semantic (success, error, warning, info)
│  │
│  ├─ Typography.swift
│  │  ├─ Display (24px, 700)
│  │  ├─ Headline (18px, 600)
│  │  ├─ Title (16px, 600)
│  │  ├─ Body (14px, 400)
│  │  ├─ Label (12px, 500)
│  │  └─ Helper (11px, 400)
│  │
│  └─ Spacing.swift
│     ├─ Micro (4px)
│     ├─ Small (8px)
│     ├─ Medium (16px)
│     ├─ Large (24px)
│     └─ XLarge (32px)
│
├─ Components/
│  ├─ Cards/
│  │  ├─ RecipeCard.swift
│  │  │  ├─ Props: recipe, isSelected, onFavorite, onAdd
│  │  │  ├─ States: normal, hover, pressed, favorite
│  │  │  └─ Layout: Image, Title, Meta, Actions
│  │  │
│  │  ├─ ProductCard.swift
│  │  │  ├─ Props: product, showDetail, compact mode
│  │  │  ├─ States: normal, alert, favorite
│  │  │  └─ Layout: Image, Scores, QuickInfo
│  │  │
│  │  ├─ ShoppingItemCard.swift
│  │  │  ├─ Props: item, member, onToggle, onEdit
│  │  │  ├─ States: pending, completed (strikethrough)
│  │  │  └─ Layout: Checkbox, Name, Price, Store
│  │  │
│  │  ├─ MealSlotCard.swift
│  │  │  ├─ Props: meal, mealType, date, onSwap
│  │  │  ├─ States: empty, filled, editing
│  │  │  └─ Layout: Icon, Recipe, Time, Kcal, Actions
│  │  │
│  │  └─ BaseCard.swift (reusable)
│  │     ├─ Props: padding, shadow, radius, backgroundColor
│  │     └─ Common styling for all cards
│  │
│  ├─ Buttons/
│  │  ├─ PrimaryButton.swift
│  │  │  ├─ Usage: Main CTAs (Generate, Confirm, Add)
│  │  │  ├─ Props: title, icon, size, isLoading
│  │  │  └─ Styling: Accent color, 48px height
│  │  │
│  │  ├─ SecondaryButton.swift
│  │  │  ├─ Usage: Less important actions (Cancel, Skip)
│  │  │  ├─ Props: title, icon, size
│  │  │  └─ Styling: Border, secondary text color
│  │  │
│  │  ├─ IconButton.swift (floating actions)
│  │  │  ├─ Usage: Toggle favorite, delete, etc
│  │  │  ├─ Props: icon, size, color, isSelected
│  │  │  └─ Styling: Background circle, animated
│  │  │
│  │  └─ SelectableButton.swift (filter options)
│  │     ├─ Props: title, isSelected
│  │     └─ Styling: Toggle background on select
│  │
│  ├─ Input/
│  │  ├─ TextInput.swift
│  │  │  ├─ Props: placeholder, value, onChange, icon
│  │  │  ├─ States: normal, focused, error, disabled
│  │  │  └─ Styling: Border, secondary background
│  │  │
│  │  ├─ Slider.swift (budget, kcal range)
│  │  │  ├─ Props: min, max, value, step, onChange
│  │  │  ├─ States: normal, dragging
│  │  │  └─ Styling: Custom track + thumb
│  │  │
│  │  ├─ Stepper.swift (quantity input)
│  │  │  ├─ Props: value, min, max, step, onChange
│  │  │  ├─ Buttons: [-] [count] [+]
│  │  │  └─ Styling: Compact, accessible
│  │  │
│  │  └─ Checkbox.swift (shopping list, filters)
│  │     ├─ Props: isSelected, onChange
│  │     ├─ States: unchecked, checked, indeterminate
│  │     └─ Animation: 200ms checkbox fill
│  │
│  ├─ Pickers/
│  │  ├─ DatePicker.swift
│  │  │  └─ Modal calendar for meal date selection
│  │  │
│  │  ├─ StorePicker.swift
│  │  │  └─ Dropdown for store selection
│  │  │
│  │  └─ MealTypePicker.swift
│  │     └─ Segmented control (Breakfast/Lunch/Dinner)
│  │
│  ├─ Loaders/
│  │  ├─ ProgressBar.swift (generation progress)
│  │  │  ├─ Props: progress (0-1), label
│  │  │  └─ Animation: Smooth fill
│  │  │
│  │  ├─ SkeletonLoader.swift (while loading data)
│  │  │  └─ Placeholder cards with shimmer
│  │  │
│  │  └─ ActivityIndicator.swift (spinning)
│  │
│  ├─ Indicators/
│  │  ├─ Badge.swift (score indicators)
│  │  │  ├─ Props: value, maxValue, type (score, alert)
│  │  │  ├─ Styling: Color-coded circular badges
│  │  │  └─ Variants: Small (12px), Medium (16px), Large (24px)
│  │  │
│  │  ├─ ChipTag.swift (dietary, allergies)
│  │  │  ├─ Props: label, icon, color, onRemove
│  │  │  └─ Styling: Rounded pill-shaped
│  │  │
│  │  ├─ Alert.swift (high sugar, allergens)
│  │  │  ├─ Props: type (warning, danger), title, message
│  │  │  ├─ Colors: Warning yellow, Danger red
│  │  │  └─ Icon: ⚠️ or 🔔
│  │  │
│  │  └─ ScoreIndicator.swift (Nutri, Eco, Health)
│  │     ├─ Props: score, type, size
│  │     ├─ Animation: Animated fill on appear
│  │     └─ Tooltip: Score explanation
│  │
│  ├─ Headers/
│  │  ├─ NavigationBar.swift (custom top bar)
│  │  │  ├─ Props: title, leftButton, rightButtons, style
│  │  │  ├─ Left: Back button
│  │  │  ├─ Center: Contextual title
│  │  │  └─ Right: Search, Settings, Household
│  │  │
│  │  ├─ SegmentedControl.swift (All/Favorites/Saved)
│  │  │  ├─ Props: items, selected, onChange
│  │  │  └─ Animation: Smooth background slide
│  │  │
│  │  └─ SectionHeader.swift (section titles)
│  │     ├─ Props: title, subtitle, action
│  │     └─ Styling: Large typography, optional icon
│  │
│  ├─ Modals & Sheets/
│  │  ├─ BottomSheet.swift (Settings, context menus)
│  │  │  ├─ Props: title, content, actions
│  │  │  ├─ Gesture: Swipe down to dismiss
│  │  │  └─ Animation: Slide from bottom
│  │  │
│  │  ├─ FullScreenModal.swift (Generate wizard, detail views)
│  │  │  ├─ Props: title, content, closeButton
│  │  │  └─ Gesture: Swipe right to go back
│  │  │
│  │  ├─ ConfirmationDialog.swift (delete, undo)
│  │  │  ├─ Props: title, message, actions
│  │  │  └─ CTA buttons: Primary (destructive) + Cancel
│  │  │
│  │  └─ StepperModal.swift (Generate menu 3-step)
│  │     ├─ Props: steps array, current step
│  │     ├─ Navigation: [< Back] [Next >] [Skip] [Done]
│  │     └─ Progress indicator at top
│  │
│  ├─ Lists/
│  │  ├─ VStack + Divider pattern (for items)
│  │  │  └─ Repeating item cards with separators
│  │  │
│  │  ├─ LazyVStack (for long lists)
│  │  │  └─ Performance optimized rendering
│  │  │
│  │  └─ Grid (for recipe browsing)
│  │     ├─ LazyVGrid with 2/3 columns
│  │     └─ Adaptive sizing
│  │
│  └─ EmptyStates/
│     ├─ EmptyStateView.swift
│     │  ├─ Props: icon, title, message, action
│     │  ├─ Variants: NoRecipes, NoMenu, NoScans
│     │  └─ Styling: Centered, large icon
│     │
│     └─ SuccessState.swift (menu generated, item added)
│        ├─ Props: message, action
│        └─ Animation: Celebration animation (optional)
│
├─ Utilities/
│  ├─ HapticFeedback.swift
│  │  ├─ Feedback on tap, delete, favorite toggle
│  │  └─ Types: Impact (light/med/heavy), Selection, Notification
│  │
│  ├─ Toast.swift (notifications)
│  │  ├─ Props: message, type (success/error/info), duration
│  │  └─ Animation: Slide up, fade out
│  │
│  └─ Modifiers/
│     ├─ CardModifier.swift (common card styling)
│     ├─ TextFieldModifier.swift (input styling)
│     └─ ButtonModifier.swift (state-aware styling)
│
└─ Theme/
   ├─ DarkTheme.swift (primary theme)
   │  └─ Color assignments for dark mode
   │
   ├─ LightTheme.swift (optional future)
   │  └─ Color assignments for light mode
   │
   └─ ThemeManager.swift (switching)
      └─ currentTheme: @Published var

```text

---

## 🔄 ViewModels & State Management

```text
MVVM Structure:

HomeTab/
├─ HomeViewModel.swift
│  ├─ @Published var weeklyMenu: [DayMenu]
│  ├─ @Published var selectedWeekStart: Date
│  ├─ @Published var weeklyStats: WeeklyStats
│  ├─ @Published var isGenerating: Bool
│  │
│  ├─ func generateMenu(preferences: GenerationPrefs) async
│  ├─ func swapMeal(date, mealType, newRecipe) async
│  ├─ func removeMeal(date, mealType) async
│  ├─ func generateShoppingList() async
│  └─ func selectWeek(_ date: Date)
│
└─ Views/
   ├─ HomeTabView.swift (container)
   ├─ WeeklyPlanningView.swift (main content)
   ├─ DailyMealCardView.swift (meal slot card)
   ├─ WeeklyOverviewWidget.swift (stats)
   ├─ GenerateMenuWizard.swift (3-step modal)
   │  ├─ PreferencesStep.swift (step 1)
   │  ├─ GenerationLoadingView.swift (step 2)
   │  └─ ConfirmationStep.swift (step 3)
   └─ RecipeSelectorModal.swift (swap modal)

RecipesTab/
├─ RecipeListViewModel.swift
│  ├─ @Published var recipes: [Recipe]
│  ├─ @Published var filteredRecipes: [Recipe]
│  ├─ @Published var filters: RecipeFilters
│  ├─ @Published var selectedSegment: RecipeSegment (All/Favorites/Saved)
│  │
│  ├─ func applyFilters()
│  ├─ func toggleFavorite(_ recipe: Recipe)
│  ├─ func deleteRecipe(_ recipe) async
│  └─ func searchRecipes(_ query: String)
│
└─ Views/
   ├─ RecipeTabView.swift (container)
   ├─ RecipeGridView.swift (2-column grid)
   ├─ RecipeCard.swift (card component)
   ├─ RecipeDetailView.swift (modal)
   ├─ FilterPanelView.swift (collapsible filters)
   └─ RecipeSelectorModal.swift (for adding to meals)

ShopTab/
├─ ShoppingListViewModel.swift
│  ├─ @Published var shoppingItems: [ShoppingItem]
│  ├─ @Published var groupedByMember: [HouseholdMember: [ShoppingItem]]
│  ├─ @Published var estimatedTotal: Double
│  ├─ @Published var shoppingStatistics: ShoppingStats
│  │
│  ├─ func toggleItemComplete(_ item) async
│  ├─ func updateItemQty(item, new qty) async
│  ├─ func changeStore(item, store) async
│  ├─ func generateFromWeeklyMenu() async
│  ├─ func addManualItem(name, qty, store) async
│  ├─ func deleteItem(_ item) async
│  ├─ func shareList() → URL
│  └─ func exportAsPDF() → Data
│
└─ Views/
   ├─ ShoppingTabView.swift (container)
   ├─ ShoppingListView.swift (main list with grouping)
   ├─ ShoppingItemCell.swift (single item)
   ├─ MemberSectionView.swift (grouped by member)
   ├─ ShoppingStatsWidget.swift (cost estimate)
   ├─ AddItemModalView.swift
   └─ ShareMenuView.swift (bottom sheet)

AnalyzeTab/
├─ ProductScanViewModel.swift
│  ├─ @Published var scannedProduct: Product?
│  ├─ @Published var recentScans: [Product]
│  ├─ @Published var selectedProducts: [Product] (for compare)
│  ├─ @Published var isScanning: Bool
│  ├─ @Published var scanHistory: [ScannedProduct]
│  │
│  ├─ func scanProduct(barcode: String) async
│  ├─ func searchProduct(name: String) async
│  ├─ func toggleFavorite(_ product) async
│  ├─ func addToShoppingList(_ product) async
│  ├─ func addToMeal(product, mealDate, mealType) async
│  ├─ func getRecommendations(_ product) async
│  └─ func compareProducts() → ComparisonData
│
└─ Views/
   ├─ AnalyzeTabView.swift (container with segmentation)
   ├─ ScanSegmentView.swift (camera + recent)
   │  ├─ CameraViewfinderView.swift (camera UI)
   │  ├─ RecentScansWidget.swift (carousel)
   │  └─ UploadImageView.swift (fallback)
   ├─ ProductDetailModal.swift (shows after scan)
   │  ├─ ProductImageHeader.swift
   │  ├─ ScoreCardsView.swift (horizontal scroll)
   │  ├─ QuickInfoGridView.swift
   │  ├─ NutritionFactsView.swift (expandable)
   │  ├─ AllergensView.swift
   │  ├─ RecommendationsView.swift (carousel)
   │  └─ ActionRowView.swift (sticky bottom)
   ├─ HistorySegmentView.swift
   │  ├─ DateFilterView.swift (tabs)
   │  ├─ ScannedItemTimelineView.swift
   │  └─ WeeklySummaryWidget.swift
   ├─ CompareSegmentView.swift
   │  ├─ ProductComparisonView.swift (side-by-side)
   │  ├─ ComparisonDifferencesView.swift
   │  └─ ComparisonRecommendationView.swift
   └─ EmptyState* (for each segment)

SettingsView/
├─ SettingsViewModel.swift
│  ├─ @Published var currentHousehold: Household
│  ├─ @Published var householdMembers: [HouseholdMember]
│  ├─ @Published var healthProfile: HealthProfile
│  ├─ @Published var preferences: UserPreferences
│  │
│  ├─ func inviteToHousehold(email: String) async
│  ├─ func leaveHousehold() async
│  ├─ func updateHealthProfile(_ profile) async
│  ├─ func updatePreferences(_ prefs) async
│  ├─ func exportData() → URL
│  └─ func deleteAccount() async
│
└─ Views/
   ├─ SettingsView.swift (bottom sheet)
   ├─ HouseholdSection.swift
   │  ├─ HouseholdHeaderView.swift
   │  ├─ MembersListView.swift
   │  └─ InviteModalView.swift
   ├─ HealthProfileSection.swift
   │  ├─ DietaryRestrictionsView.swift
   │  ├─ AllergiesInputView.swift
   │  └─ NutritionGoalsView.swift
   ├─ PreferencesSection.swift
   │  ├─ CurrencyPickerView.swift
   │  ├─ UnitsPickerView.swift
   │  └─ NotificationsToggleView.swift
   └─ DataPrivacySection.swift

```text

---

## 🎬 Migration Path (Faza Implementare)

### **Week 1-2: Setup & Design System**

```text
├─ Create design tokens file (Colors, Typography, Spacing)
├─ Build component library:
│  ├─ BaseCard
│  ├─ Primary/Secondary buttons
│  ├─ Badge, ChipTag, Alert
│  ├─ NavigationBar
│  └─ EmptyStateView
├─ Setup DesignSystem package (reusable SwiftUI)
└─ Test on multiple screen sizes (iPhone, iPad)

```text

### **Week 3-4: Tab Restructure**

```text
├─ Remove current top bar items (Undo, Redo, magic to contexts)
├─ Implement new top bar:
│  ├─ Back button
│  ├─ Contextual title
│  ├─ Search (🔍)
│  ├─ Settings (⚙️)
│  └─ Household selector (👥)
├─ Reorganize bottom tabs:
│  ├─ Home (from Meniu)
│  ├─ Recipes (existing)
│  ├─ Shop (from Cumpărături)
│  └─ Analyze (from Nutriție)
└─ Handle deep linking for tab switching

```text

### **Week 5-6: Home Tab Complete**

```text
├─ Implement weekly planning view
│  ├─ Daily cards for Mon-Sun
│  ├─ Meal slots (Breakfast, Lunch, Dinner, Dessert)
│  └─ Quick actions per meal (Swap, Remove, Notes)
├─ Create weekly overview widget
├─ Implement Generate Menu wizard (3 steps)
├─ Add shopping list generation
└─ Create empty states

```text

### **Week 7-8: Recipes Tab Polish**

```text
├─ Create recipe grid (2 columns)
├─ Implement advanced filtering
├─ Add favorites segment
├─ Create recipe detail view
├─ Add long-press context menus
├─ Test favoriting + sharing
└─ Create empty states

```text

### **Week 9-10: Analyze Tab Overhaul**

```text
├─ Redesign product detail modal
├─ Restyle all 3 score indicators
├─ Create expandable nutrition table
├─ Add allergen warning system
├─ Build recommendation engine UI
├─ Implement compare mode (2-product side-by-side)
├─ Test scan → detail flow
└─ Create empty states

```text

### **Week 11-12: Shop Tab Collaborative**

```text
├─ Implement household member grouping
├─ Add checkbox + strikethrough UX
├─ Create cost estimation widget
├─ Add store selection & hints
├─ Implement export/share functionality
├─ Test multi-user interactions
└─ Create empty states

```text

### **Week 13-14: Household System Core**

```text
├─ Create household data model
├─ Implement invitation system
├─ Build member management UI
├─ Add household-specific settings
├─ Implement role-based features
├─ Test real-time sync
└─ Handle edge cases (leave, remove member)

```text

### **Week 15: Polish & QA**

```text
├─ Dark mode verification
├─ Responsive design (iPad testing)
├─ Accessibility audit (WCAG A)
├─ Performance profiling
├─ User feedback integration
├─ Bug fixes
└─ Release preparation

```text

---

## ✅ VALIDATION CHECKLIST

### **Design System Completeness:**

- [ ] All colors defined and tested on backgrounds

- [ ] Typography scales match design

- [ ] Spacing system applied consistently

- [ ] Icon library reviewed and consistent

- [ ] Dark mode explicitly defined

- [ ] Contrast ratios verified (4.5:1 minimum)

### **Navigation:**

- [ ] Tab switching smooth (no lag)

- [ ] Deep linking works from external sources

- [ ] Back button/gesture handling correct

- [ ] State persistence across nav

### **Home Tab:**

- [ ] Weekly view displays correctly

- [ ] Meal swapping works smoothly

- [ ] Generate wizard 3-step flow complete

- [ ] Empty states testable

- [ ] Undo/redo integrated (context menu)

### **Recipes Tab:**

- [ ] Grid responsive (2/3 columns)

- [ ] Filtering logic correct

- [ ] Searching works

- [ ] Favorites toggles without reload

- [ ] Detail view complete

### **Shop Tab:**

- [ ] Grouping by household member works

- [ ] Checkbox toggles properly

- [ ] Cost estimates accurate

- [ ] Sharing functional

- [ ] Export to PDF works

### **Analyze Tab:**

- [ ] Camera integration functional

- [ ] Scan → detail modal flow smooth

- [ ] Product details complete

- [ ] Compare mode UI clear

- [ ] Recommendations relevant

- [ ] History timeline organized

### **Household System:**

- [ ] Invitation works

- [ ] Members see shared data

- [ ] Roles enforced

- [ ] Real-time sync tested

- [ ] Edge cases handled

### **Accessibility:**

- [ ] VoiceOver tested on all screens

- [ ] Touch targets ≥48pt minimum

- [ ] Color not only indicator

- [ ] Keyboard navigation works

- [ ] Text scaling supported

---

**Document Status:** ✅ Technical Reference Complete
**Version:** 1.0
**Last Updated:** 24.02.2026
