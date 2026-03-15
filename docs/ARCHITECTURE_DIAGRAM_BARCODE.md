# Barcode Search Architecture & Data Flow

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           AddIngredientView (UI Layer)                   │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ Barcode Search Section                             │ │  │
│  │  │ ┌─────────────────┐  ┌──────────┐                 │ │  │
│  │  │ │ TextField       │  │ Search   │                 │ │  │
│  │  │ │ (barcode input) │→ │ Button   │                 │ │  │
│  │  │ └─────────────────┘  └──────────┘                 │ │  │
│  │  │        ↓                 ↓                         │ │  │
│  │  │  ┌──────────────────────────────┐                 │ │  │
│  │  │  │ viewModel.searchByBarcode()  │                 │ │  │
│  │  │  │ (triggers async search)      │                 │ │  │
│  │  │  └──────────────────────────────┘                 │ │  │
│  │  │                 ↓                                  │ │  │
│  │  │  ┌──────────────────────────────┐                 │ │  │
│  │  │  │ Display Results or Errors    │                 │ │  │
│  │  │  │ ├─ productName               │                 │ │  │
│  │  │  │ ├─ brand                     │                 │ │  │
│  │  │  │ ├─ nutrition                 │                 │ │  │
│  │  │  │ └─ error message             │                 │ │  │
│  │  │  └──────────────────────────────┘                 │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ Manual Entry Section (Existing UI)                 │ │  │
│  │  │ ├─ Name, Quantity, Unit, Category                 │ │  │
│  │  │ └─ (Same as before)                                │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │        ProductSearchViewModel (Logic Layer)              │  │
│  │                                                          │  │
│  │  @MainActor @Observable                                 │  │
│  │  ├─ searchByBarcode(String) async                       │  │
│  │  ├─ clearAPIResults()                                   │  │
│  │  ├─ isLoadingProduct: Bool                              │  │
│  │  ├─ hasAPIResults: Bool                                 │  │
│  │  ├─ apiProductName: String?                             │  │
│  │  ├─ apiProductBrand: String?                            │  │
│  │  ├─ apiProductNutrition: Nutrition?                     │  │
│  │  └─ apiError: String?                                   │  │
│  │          ↓                                               │  │
│  │  Delegates to → OpenFoodFactsService                    │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │       OpenFoodFactsService (Network Layer)               │  │
│  │                                                          │  │
│  │  @MainActor                                             │  │
│  │  ├─ environment: Environment                            │  │
│  │  │  ├─ .staging (https://world.openfoodfacts.net)      │  │
│  │  │  └─ .production (https://world.openfoodfacts.org)   │  │
│  │  │                                                      │  │
│  │  ├─ func fetchProduct(barcode) async throws             │  │
│  │  ├─ Validation                                          │  │
│  │  │  └─ Barcode format check (8-14 digits)             │  │
│  │  ├─ Request building                                   │  │
│  │  │  ├─ User-Agent header                              │  │
│  │  │  ├─ Authorization (staging only)                   │  │
│  │  │  └─ Timeout: 10s request, 30s resource            │  │
│  │  ├─ Response handling                                  │  │
│  │  │  ├─ HTTP status validation                         │  │
│  │  │  └─ JSON decoding to models                        │  │
│  │  └─ Error handling                                     │  │
│  │     ├─ NetworkError                                   │  │
│  │     ├─ DecodingError                                  │  │
│  │     └─ (7 error types total)                          │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │    OpenFoodFactsModels (Data Layer)                      │  │
│  │                                                          │  │
│  │  struct OpenFoodFactsResponse                           │  │
│  │  ├─ status: Int                                         │  │
│  │  ├─ code: String                                        │  │
│  │  ├─ product: OpenFoodFactsProduct?                      │  │
│  │  └─ statusVerbose: String                               │  │
│  │                                                          │  │
│  │  struct OpenFoodFactsProduct                            │  │
│  │  ├─ productName: String?                                │  │
│  │  ├─ brands: String?                                     │  │
│  │  ├─ code: String?                                       │  │
│  │  ├─ imageFrontUrl: String?                              │  │
│  │  ├─ nutriments: OpenFoodFactsNutriments?                │  │
│  │  └─ allergens: String?                                  │  │
│  │                                                          │  │
│  │  struct OpenFoodFactsNutriments                         │  │
│  │  ├─ energyKcal100g: Double?                             │  │
│  │  ├─ proteins100g: Double?                               │  │
│  │  ├─ fat100g: Double?                                    │  │
│  │  └─ carbohydrates100g: Double?                          │  │
│  │                                                          │  │
│  │  enum OpenFoodFactsError                                │  │
│  │  ├─ invalidBarcode(String)                              │  │
│  │  ├─ productNotFound(String)                             │  │
│  │  ├─ networkError(String)                                │  │
│  │  ├─ decodingError(String)                               │  │
│  │  ├─ missingRequiredFields(String)                       │  │
│  │  ├─ serverError(Int)                                    │  │
│  │  └─ unknownError(String)                                │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                          ↓ (URLSession)
┌─────────────────────────────────────────────────────────────────┐
│                    Open Food Facts API                          │
│                                                                 │
│  Request:                                                       │
│  GET /api/v0/product/{barcode}.json                            │
│  Headers:                                                       │
│    User-Agent: EzMenuGenerator/1.0                             │
│    Authorization: Basic (staging only)                          │
│                                                                 │
│  Response (JSON):                                               │
│  {                                                              │
│    "status": 1,                                                │
│    "code": "5411188000181",                                    │
│    "product": {                                                │
│      "product_name": "Tomato juice",                           │
│      "brands": "Campbell's",                                   │
│      "image_front_url": "https://...",                         │
│      "nutriments": {                                           │
│        "energy-kcal_100g": 18,                                │
│        "proteins_100g": 1.0,                                  │
│        "fat_100g": 0.0,                                       │
│        "carbohydrates_100g": 4.0                             │
│      }                                                          │
│    }                                                            │
│  }                                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: Step-by-Step

### User Enters Barcode and Taps Search

```
1. User types "5411188000181" in TextField
   ├─ @State var barcode = "5411188000181"
   └─ Updates automatically via binding

2. User taps Search button
   ├─ Button { Task { await viewModel.searchByBarcode(barcode) } }
   └─ Enters async context

3. ViewController receives call
   ├─ searchByBarcode("5411188000181")
   ├─ Sets isLoadingProduct = true
   ├─ Clears previous results
   └─ Creates Task to offService.fetchProduct(barcode)

4. Service validates barcode
   ├─ Check: Contains only digits
   ├─ Check: 8-14 characters long
   └─ Throw invalidBarcode error if validation fails

5. Service builds HTTP request
   ├─ URL: https://world.openfoodfacts.net/api/v0/product/5411188000181.json
   ├─ Headers:
   │  ├─ User-Agent: EzMenuGenerator/1.0
   │  └─ Authorization: Basic off:off (staging)
   ├─ Timeout: 10s
   └─ Method: GET

6. URLSession sends request
   ├─ Network call over HTTP
   ├─ Waits for response (usually 1-2 seconds)
   └─ Receives JSON data

7. Service processes response
   ├─ Check HTTP status (must be 200-299)
   ├─ Decode JSON to OpenFoodFactsResponse
   ├─ Validate required fields present
   └─ Extract OpenFoodFactsProduct

8. Service creates wrapper model
   ├─ OpenFoodFactsProduct with optional fields
   ├─ Convenience extensions:
   │  ├─ displayName = brand + " - " + productName
   │  └─ nutritionSummary = "X kcal | Xg protein | ..."
   └─ Returns product to ViewModel

9. ViewModel updates state
   ├─ apiProductName = product.productName
   ├─ apiProductBrand = product.brands
   ├─ apiProductNutrition = (kcal, protein, fat, carbs)
   ├─ isLoadingProduct = false
   └─ apiError = nil (cleared on success)

10. SwiftUI detects state change
    ├─ @Observable triggers view update
    ├─ Conditional rendering evaluates:
    │  ├─ if viewModel.hasAPIResults → show results section
    │  └─ if viewModel.apiError → show error section
    └─ View re-renders with new content

11. UI displays results
    ├─ ProgressView disappears
    ├─ Green success box appears with:
    │  ├─ Product name
    │  ├─ Brand
    │  ├─ Energy content
    │  └─ "Complete with these data" button
    └─ User can now populate ingredient form
```

### Error Path: Product Not Found

```
1-6. Steps same as above...

7. API responds with product not found
   ├─ HTTP 404 or status code != 1
   ├─ JSON: { "status": 0, "code": "5411188000181" }
   └─ Service detects no product in response

8. Service throws productNotFound error
   ├─ Error type: OpenFoodFactsError.productNotFound("5411188000181")
   ├─ Localized message: "Produsul nu a fost găsit în baza de date"
   └─ Error logged to Console with OSLog

9. ViewModel catches error
   ├─ catch let error as OpenFoodFactsError
   ├─ apiError = error.localizedDescription
   ├─ isLoadingProduct = false
   └─ clearAPIResults() not called (to show error)

10. SwiftUI re-renders
    ├─ hasAPIResults = false (no product data)
    ├─ apiError != nil (error present)
    └─ Error section displays with red icon and localized message

11. User sees error message
    ├─ Red error box appears
    ├─ Can try different barcode
    └─ Can enter data manually
```

### User Populates Form from API Result

```
1. User taps "Complete with these data" button
   └─ Action: populateFromAPI()

2. populateFromAPI() function executes
   ├─ name = viewModel.apiProductName
   │  │  (Copy "Tomato juice" from API)
   │  └─ Trigger ingredient type detection
   │
   ├─ suggestedType = IngredientTypeDetector.detectType(name)
   │  │  (Detect "Legume" type)
   │  └─ showTypeSuggestion = true
   │
   ├─ Infer category from nutrition
   │  ├─ if protein > 15g → category = "Carne"
   │  ├─ if fat > 20g → category = "Lactate"
   │  ├─ if carbs > 40g → category = "Diverse"
   │  └─ (In this case: ~0g protein, so defaults)
   │
   ├─ Clear API data
   │  ├─ viewModel.clearAPIResults()
   │  ├─ barcode = ""
   │  └─ Remove result display
   │
   └─ Ready for user to confirm and add

3. Form now shows:
   ├─ Name: "Tomato juice" (pre-filled)
   ├─ Quantity: 1.0 (default)
   ├─ Unit: "buc" (default)
   └─ Category: "Diverse" (inferred)

4. User can now:
   ├─ Adjust quantity/unit as needed
   ├─ Tap "Add" to save ingredient
   └─ Ingredient added to recipe
```

## Error Handling Decision Tree

```
searchByBarcode("123456789")
    │
    ├─→ Validation Phase
    │   ├─ Is barcode 8-14 digits only? NO
    │   │   └─ throw invalidBarcode("123456789")
    │   └─ YES → continue
    │
    ├─→ Network Phase
    │   ├─ Can reach openfoodfacts.net? NO
    │   │   └─ throw networkError("No internet")
    │   ├─ Request timeout after 10s? YES
    │   │   └─ throw networkError("Request timeout")
    │   └─ YES & complete → continue
    │
    ├─→ Status Code Phase
    │   ├─ HTTP 200-299? NO
    │   │   └─ throw serverError(404)
    │   └─ YES → continue
    │
    ├─→ JSON Decode Phase
    │   ├─ Valid JSON structure? NO
    │   │   └─ throw decodingError("Invalid JSON")
    │   └─ YES → continue
    │
    ├─→ Product Presence Phase
    │   ├─ Product exists in response? NO
    │   │   └─ throw productNotFound("123456789")
    │   └─ YES → continue
    │
    ├─→ Required Fields Phase
    │   ├─ All required fields present? NO
    │   │   └─ throw missingRequiredFields("product_name")
    │   └─ YES → continue
    │
    └─→ Success Phase
        └─ return OpenFoodFactsProduct
```

## State Management Over Time

```
Timeline: User searches for barcode "5411188000181"

T=0.0s  User types barcode
        ├─ barcode = "5411188000181"
        └─ viewModel state unchanged

T=0.1s  User taps Search button
        ├─ isLoadingProduct = true ✓
        ├─ apiProductName = nil
        ├─ apiError = nil
        ├─ hasAPIResults = false
        └─ ProgressView appears

T=0.2s  Network request sent
        └─ URLSession active, waiting...

T=1.5s  API response received (1.3s latency)
        └─ JSONDecoder processes response

T=1.6s  ViewModel receives product
        ├─ isLoadingProduct = false ✓
        ├─ apiProductName = "Tomato juice" ✓
        ├─ apiProductBrand = "Campbell's" ✓
        ├─ apiProductNutrition = (18, 1.0, 0.0, 4.0) ✓
        ├─ apiError = nil
        └─ hasAPIResults = true ✓

T=1.7s  SwiftUI re-renders
        ├─ ProgressView removed
        ├─ Result display shown
        ├─ Green success box appears
        └─ "Complete with these data" button available

T=2.0s  User taps "Complete with these data"
        ├─ name = "Tomato juice"
        ├─ apiProductName = nil (cleared)
        ├─ apiProductBrand = nil (cleared)
        ├─ barcode = "" (cleared)
        └─ Result display hidden

T=2.1s  User sees populated form
        └─ Ready to adjust and save
```

## Performance Metrics

```
Component              | Time      | Note
─────────────────────────────────────────────────────────────
Barcode validation     | < 1ms     | Local, synchronous
Request preparation    | < 1ms     | URL building, headers
Network request        | 1-2s      | API latency, typical case
JSON decoding         | 50-100ms  | Depends on response size
State update          | < 1ms     | SwiftData write
View re-render        | < 30ms    | SwiftUI diffing
─────────────────────────────────────────────────────────────
Total user perception | 1-2s      | From tap to results show
```

## Concurrency Model

```
┌─────────────────────────────────────────┐
│ Main Thread (UI Thread)                 │
│                                         │
│  AddIngredientView ──────────────────┐  │
│  (Tap handler calls Task)            │  │
│                                      │  │
│              Task {                  │  │
│                ├─→ @MainActor        │  │
│                │   (guaranteed safe) │  │
│                │                     │  │
│                ├─→ ViewModel         │  │
│                │   updates           │  │
│                │   (on main thread)  │  │
│                │                     │  │
│                └─→ View re-renders   │  │
│                    (on main thread)  │  │
│              }                        │  │
│                                      │  │
│  ┌──────────────────────────────────┘   │
│  │                                      │
│  └─→ await searchByBarcode()  (in UI ctx)
│                                         │
└─────────────────────────────────────────┘
         │
         │ URLSession internally handles
         │ networking on background thread
         │
    ┌────v─────────────────────────────┐
    │ Network Thread (Background)       │
    │                                   │
    │  URLSession sends HTTP request    │
    │  ├─ Non-blocking                  │
    │  ├─ Result delivered via callback │
    │  └─ Automatically marshals back   │
    │      to main thread when done     │
    └───────────────────────────────────┘
         │
         │ Callback delivered to main
         │ (thanks to @MainActor)
         │
         v
    ┌─────────────────────────────────┐
    │ Back on Main Thread              │
    │ · Update ViewModel properties    │
    │ · SwiftUI detects changes        │
    │ · View re-renders with results   │
    └─────────────────────────────────┘
```

## File Organization

```
Ez Menu Generator/
├── Services/
│   ├── OpenFoodFactsService.swift ────────┐
│   │   (URLSession + request building)    │
│   │                                       │
│   └── OpenFoodFactsModels.swift ─────────┤
│       (Codable structs + error enum)     │
│                                           │
├── ViewModels/                             │
│   └── ProductSearchViewModel.swift ──────┤
│       (searchByBarcode() + state)        │
│                                           │
├── Views/                                  │
│   └── RecipeList/                         │
│       └── AddIngredientView.swift ───────┤
│           (Barcode input + results UI)   │
│                                           │
└── Documentation/                          │
    ├── BARCODE_INTEGRATION_GUIDE.md       │
    ├── BARCODE_QUICK_REFERENCE.md        │
    ├── SESSION_SUMMARY_BARCODE_*.md       │
    └── This file (ARCHITECTURE_DIAGRAM.md)
```

---

This diagram provides a complete visual reference for understanding the barcode search feature.
See [BARCODE_INTEGRATION_GUIDE.md](BARCODE_INTEGRATION_GUIDE.md) for detailed documentation.
