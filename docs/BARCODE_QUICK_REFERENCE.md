# Quick Reference: Barcode Search API

## One-Minute Setup

```swift
// 1. In your ViewModel
@MainActor @Observable
class YourViewModel {
    let productSearch = ProductSearchViewModel()
}

// 2. In your View
TextField("Barcode", text: $barcode)
Button("Search") {
    Task {
        await productSearch.searchByBarcode(barcode)
    }
}

// 3. Display results
if productSearch.hasAPIResults {
    Text(productSearch.apiProductName ?? "")
    Text("Energy: \(productSearch.apiProductNutrition?.kcal ?? 0) kcal")
}
if let error = productSearch.apiError {
    Text(error).foregroundColor(.red)
}
```

## Common Patterns

### Search and Populate Form
```swift
await viewModel.searchByBarcode("5411188000181")

if viewModel.hasAPIResults {
    ingredientName = viewModel.apiProductName ?? ""
    brand = viewModel.apiProductBrand ?? ""
    kcalPer100g = viewModel.apiProductNutrition?.kcal ?? 0
}
```

### Error Handling
```swift
do {
    let product = try await offService.fetchProduct(barcode: barcode)
    print("✅ Found: \(product.displayName)")
} catch OpenFoodFactsError.productNotFound(let code) {
    print("Not in database: \(code)")
} catch OpenFoodFactsError.invalidBarcode {
    print("Bad format (need 8-14 digits)")
} catch {
    print("Network error: \(error)")
}
```

### Environment Switching
```swift
// Development/Testing
let service = OpenFoodFactsService(environment: .staging)

// Production
let service = OpenFoodFactsService(environment: .production)
```

## Barcode Format

| Format | Digits | Example |
|--------|--------|---------|
| UPC-A | 12 | 042100005264 |
| EAN-8 | 8 | 96385074 |
| EAN-13 | 13 | 5411188000181 |
| EAN-14 | 14 | 16012345678905 |

## API Response Fields

```swift
viewModel.apiProductName       // "Tomato juice"
viewModel.apiProductBrand      // "Campbell's"
viewModel.apiProductImage      // URL to product photo
viewModel.apiProductNutrition  // (kcal, protein, fat, carbs)
viewModel.apiError             // Error message if failed
viewModel.isLoadingProduct     // true during API call
viewModel.hasAPIResults        // true if product found
```

## Error Cases

| Error | Meaning |
|-------|---------|
| `invalidBarcode` | Not 8-14 digits or has letters |
| `productNotFound` | Barcode not in database |
| `networkError` | No internet/connection failed |
| `decodingError` | API response format unexpected |
| `serverError` | Server returned 4xx/5xx |

## Test Barcodes

```swift
"5411188000181"  // ✅ Campbell's tomato juice
"3596710173975"  // ✅ Bonne Maman apricot jam
"8718215037627"  // ✅ All Nutrition peanut flour
"123"            // ❌ Too short
"5411188ABC123"  // ❌ Contains letters
```

## Performance

- **Search time**: ~1-2 seconds (network dependent)
- **Timeout**: 10s request, 30s resource
- **Rate limit**: ~1 request/second (don't spam)
- **Cache**: None (data changes frequently)

## Files You'll Use

| File | Purpose |
|------|---------|
| `ProductSearchViewModel.swift` | Main API - call `searchByBarcode()` here |
| `OpenFoodFactsService.swift` | Internal - handles network calls |
| `OpenFoodFactsModels.swift` | Internal - data structures |
| `AddIngredientView.swift` | Example - shows barcode search UI |

## Thread Safety

✅ All public APIs are `@MainActor` - safe to call from any thread

```swift
// Safe from any thread
DispatchQueue.global().async {
    Task {
        await viewModel.searchByBarcode("123456789")
    }
}
```

## Logging

Logs appear in Console.app with tag `[ProductSearch]`:

```
[ProductSearch] ✅ Found product: Campbell's - Tomato juice
[ProductSearch] ❌ Product search failed: Produsul nu a fost găsit
```

Filter by subsystem: `com.eduard.ezmenu`

## Next Steps

1. **Now**: Use barcode search in AddIngredientView
2. **Soon**: Add camera scanner with AVFoundation
3. **Later**: Cache products locally, enable offline mode

---

See [BARCODE_INTEGRATION_GUIDE.md](BARCODE_INTEGRATION_GUIDE.md) for complete documentation.
