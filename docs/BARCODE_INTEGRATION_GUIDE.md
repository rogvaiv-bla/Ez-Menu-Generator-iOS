# Barcode Search Integration Guide

## Overview

The Ez Menu Generator app now includes **Open Food Facts API integration** for barcode-based product lookup and nutrition data import. This guide explains how the system works and how to use it.

## Architecture

### Components

```
AddIngredientView (UI)
    ↓
ProductSearchViewModel (Logic)
    ↓
OpenFoodFactsService (Networking)
    ↓
OpenFoodFactsModels (Data)
    ↓
Open Food Facts API
```

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| [ProductSearchViewModel.swift](Ez Menu Generator/ViewModels/ProductSearchViewModel.swift) | Search logic and state management | 95 |
| [OpenFoodFactsService.swift](Ez Menu Generator/Services/OpenFoodFactsService.swift) | Network requests and API communication | 320 |
| [OpenFoodFactsModels.swift](Ez Menu Generator/Services/OpenFoodFactsModels.swift) | Codable models for API responses | 210 |
| [AddIngredientView.swift](Ez Menu Generator/Views/RecipeList/AddIngredientView.swift) | UI for barcode search | 200 |

## Features

### 1. Barcode Search in AddIngredientView

Users can now search for products by barcode code:

```swift
// User enters barcode in the UI
TextField("Introduceți codul de bare", text: $barcode)

// User taps search button
Button(action: {
    Task {
        await viewModel.searchByBarcode(barcode)
    }
})

// Results displayed:
// - Product name
// - Brand
// - Nutrition per 100g
// - "Complete with these data" button
```

### 2. Automatic Fields Population

When user taps "Complete with these data", the form is populated:

```swift
// Name is auto-filled with product name
name = viewModel.apiProductName

// Type is auto-detected
suggestedType = IngredientTypeDetector.detectType(for: productName)

// Category is inferred from nutrition
if let protein = nutrition.protein, protein > 15 {
    category = "Carne"  // High protein = Meat
} else if let fat = nutrition.fat, fat > 20 {
    category = "Lactate"  // High fat = Dairy
}
```

### 3. Nutrition Data Import

Product nutrition is extracted from API response:

```swift
struct ApiProductNutrition {
    kcal: Double?      // Energy in kcal per 100g
    protein: Double?   // Protein in grams per 100g
    fat: Double?       // Fat in grams per 100g
    carbs: Double?     // Carbohydrates in grams per 100g
}
```

## Usage Examples

### Basic Barcode Search

```swift
let viewModel = ProductSearchViewModel()

// Trigger search
await viewModel.searchByBarcode("5411188000181")

// Check results
if viewModel.hasAPIResults {
    print("✅ Found: \(viewModel.apiProductName!)")
    print("Brand: \(viewModel.apiProductBrand!)")
    print("Energy: \(viewModel.apiProductNutrition?.kcal ?? 0) kcal")
} else if let error = viewModel.apiError {
    print("❌ Error: \(error)")
}
```

### Testing with Sample Barcodes

| Barcode | Product | Brand |
|---------|---------|-------|
| `5411188000181` | Tomato juice | Campbell's |
| `3596710173975` | Apricot preserves | Bonne Maman |
| `8718215037627` | Peanut flour | All Nutrition |
| `5410041002028` | Cottage cheese | Danone |

### In a View Model

```swift
@MainActor
@Observable
class IngredientEditorViewModel {
    var productSearchViewModel = ProductSearchViewModel()
    
    func lookupByBarcode(_ barcode: String) async {
        await productSearchViewModel.searchByBarcode(barcode)
        
        if productSearchViewModel.hasAPIResults {
            // Auto-populate ingredient form
            populateFromAPI()
        }
    }
    
    private func populateFromAPI() {
        ingredientName = productSearchViewModel.apiProductName ?? ""
        brand = productSearchViewModel.apiProductBrand ?? ""
        
        if let nutrition = productSearchViewModel.apiProductNutrition {
            nutritionKcal = nutrition.kcal
            nutritionProtein = nutrition.protein ?? 0
            nutritionFat = nutrition.fat ?? 0
            nutritionCarbs = nutrition.carbs ?? 0
        }
    }
}
```

## API Details

### Open Food Facts Endpoints

#### Staging (for testing)
```
Base URL: https://world.openfoodfacts.net
Auth: Basic auth (username: "off", password: "off")
Purpose: Testing with demo data
```

#### Production (for real data)
```
Base URL: https://world.openfoodfacts.org
Auth: None required (public API)
Purpose: Production lookups
```

### Switching Environments

```swift
// Staging (default in development)
let service = OpenFoodFactsService(environment: .staging)

// Production (for release builds)
let service = OpenFoodFactsService(environment: .production)
```

### Request Headers

```
User-Agent: EzMenuGenerator/1.0
Authorization: Basic (staging only)
```

### Barcode Validation

Valid barcodes:
- **EAN-8**: 8 digits (short format)
- **EAN-13**: 13 digits (standard format)
- **EAN-14**: 14 digits (logistics format)

Examples:
```
✅ Valid:   5411188000181 (13 digits)
✅ Valid:   96385074 (8 digits)
❌ Invalid: 123 (too short)
❌ Invalid: 123ABC (contains letters)
```

## Error Handling

### Error Types

```swift
enum OpenFoodFactsError: Error {
    case invalidBarcode(String)           // Not 8-14 digits
    case productNotFound(String)          // Barcode not in database
    case networkError(String)             // Network connectivity
    case decodingError(String)            // JSON parsing failed
    case missingRequiredFields(String)     // Required fields missing
    case serverError(Int)                 // Server returned error status
    case unknownError(String)             // Catch-all
    
    var localizedDescription: String { ... }
}
```

### In User Interface

```swift
if let error = viewModel.apiError {
    // Show to user in Romanian
    HStack {
        Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.red)
        Text(error)
            .font(.caption)
            .foregroundColor(.red)
    }
}
```

### Error Messages (Localized)

| Error | User Message |
|-------|--------------|
| `invalidBarcode` | "Cod de bare invalid (trebuie 8-14 cifre)" |
| `productNotFound` | "Produsul nu a fost găsit în baza de date" |
| `networkError` | "Eroare de conectivitate. Verificați internetul" |
| `decodingError` | "Eroare la procesarea datelor produsului" |
| `serverError` | "Server indisponibil. Încercați mai târziu" |

## Thread Safety

All API calls use `@MainActor`:

```swift
@MainActor
class ProductSearchViewModel { ... }

@MainActor
class OpenFoodFactsService { ... }
```

This ensures:
- ✅ UI updates happen on main thread
- ✅ Thread-safe state management
- ✅ No race conditions
- ✅ Proper Swift concurrency support

## Logging & Debugging

### Enable Debug Logs

Logs are automatically written to Console.app with subsystem: `com.eduard.ezmenu`

```swift
private let logger = Logger(
    subsystem: "com.eduard.ezmenu",
    category: "ProductSearch"
)

logger.info("✅ Found product: \(product.displayName)")
logger.error("❌ Lookup failed: \(error)")
```

### View Logs in Xcode

1. Run app in simulator
2. Xcode → Product → Scheme → Edit Scheme
3. Environment Variables → OBJC_TRACE_DESCRIPTORS = 1
4. Run app and check console output

### Sample Log Output

```
[ProductSearch] ✅ Found product via barcode: Campbell's - Tomato juice
[ProductSearch] Product image: https://images.openfoodfacts.org/images/products/541/118/800/0181/front_en_100.jpg
[ProductSearch] Nutrition: 18 kcal | 1.0g protein | 0.0g fat | 4.0g carbs
```

## Performance Considerations

### Network

- **Timeout**: 10 seconds for request, 30 seconds for resource
- **Caching**: Not implemented (API changes frequently)
- **Rate Limit**: Open Food Facts allows ~1 request/second

### UI

- **Loading state**: Shows ProgressView during search
- **Debouncing**: Not needed (user must tap search button)
- **Cancellation**: User can cancel by navigating away

### Data

- **Optional fields**: All nutrition fields are optional
- **Validation**: Response validated before use
- **Fallback**: User can enter data manually if API fails

## Future Enhancements

### Planned Features

- [ ] Barcode camera scanner (AVFoundation)
- [ ] Search history (last 10 lookups)
- [ ] Offline mode (cache recent products)
- [ ] Nutrition data editing after import
- [ ] Product image display
- [ ] Allergen detection from product data
- [ ] Integration with dietary constraints system
- [ ] Batch barcode import from receipts

### Implementation Notes

```swift
// TODO: Add AVCaptureSession for barcode scanning
// TODO: Document AVFoundation integration
// TODO: Add image display with URLImage wrapper
// TODO: Implement allergen parsing from API response
// TODO: Add nutritional data validation and correction UI
```

## Common Issues & Solutions

### Issue: "Produsul nu a fost găsit"

**Cause**: Barcode not in Open Food Facts database (only ~100M products)

**Solutions**:
1. ✅ Try another barcode from same brand
2. ✅ Check barcode format (8-14 digits only)
3. ✅ Try production database instead of staging
4. ✅ Enter product data manually

### Issue: "Eroare de conectivitate"

**Cause**: No internet or firewall blocking API

**Solutions**:
1. ✅ Check WiFi/cellular connection
2. ✅ Disable VPN/proxy
3. ✅ Check if device can reach openfoodfacts.org
4. ✅ Try again in 5 seconds (API might be restarting)

### Issue: App crashes on search

**Cause**: Missing error handling in caller

**Solution**:
```swift
// ❌ Wrong - will crash if error
let product = try await service.fetchProduct(barcode: "123")

// ✅ Correct - proper error handling
do {
    let product = try await service.fetchProduct(barcode: "123")
} catch let error as OpenFoodFactsError {
    print("API error: \(error.localizedDescription)")
} catch {
    print("Unexpected: \(error)")
}
```

### Issue: UI doesn't update after search

**Cause**: ViewModel not marked @MainActor

**Solution**: Ensure ProductSearchViewModel is @MainActor:
```swift
@MainActor  // ← Required
@Observable
class ProductSearchViewModel { ... }
```

## File Structure

```
Ez Menu Generator/
├── Services/
│   ├── OpenFoodFactsService.swift      [Primary]
│   └── OpenFoodFactsModels.swift       [Models]
├── ViewModels/
│   └── ProductSearchViewModel.swift    [Logic]
├── Views/
│   └── RecipeList/
│       └── AddIngredientView.swift     [UI]
└── Documentation/
    └── BARCODE_INTEGRATION_GUIDE.md    [This file]
```

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall app architecture
- [SETUP.md](SETUP.md) - Build and run instructions
- [CONSTRAINTS.md](CONSTRAINTS.md) - Dietary constraints system
- [CHANGELOG.md](CHANGELOG.md) - Recent changes

## Version Information

- **Swift**: 5.9+
- **iOS**: 16.0+
- **Xcode**: 16.0+
- **API**: Open Food Facts (https://world.openfoodfacts.org)
- **Last Updated**: 2025-02-08

## Production Checklist

Before shipping to App Store:

- [ ] Switch environment to `.production`
- [ ] Remove staging auth credentials
- [ ] Test with 10+ real barcodes
- [ ] Verify error messages in Romanian
- [ ] Check network timeout values
- [ ] Add user consent for API usage
- [ ] Document Open Food Facts license compliance
- [ ] Test on real device (not just simulator)
- [ ] Monitor API response times
- [ ] Set up error reporting/monitoring

## Credits

- **Open Food Facts**: https://world.openfoodfacts.org
- **License**: Open Food Facts data is CC0 (public domain)
- **Attribution**: App uses Open Food Facts API

---

**Need Help?**
- See [SETUP.md](SETUP.md) for build issues
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Review code comments in [OpenFoodFactsService.swift](Ez Menu Generator/Services/OpenFoodFactsService.swift)
