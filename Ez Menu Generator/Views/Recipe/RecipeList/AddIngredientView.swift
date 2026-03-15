import SwiftUI
import AVFoundation

struct AddIngredientView: View {
    @Binding var ingredients: [Ingredient]
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var quantity = 1.0
    @State private var unit = "buc"
    @State private var category = "Legume"
    @State private var suggestedType: Ingredient.IngredientType = .other
    @State private var showTypeSuggestion = false
    @State private var showManualNutrition = false
    
    // Manual nutrition input
    @State private var manualCalories = ""
    @State private var manualProtein = ""
    @State private var manualCarbs = ""
    @State private var manualFat = ""
    @State private var manualFiber = ""
    @State private var manualSugars = ""
    
    // Open Food Facts barcode search
    @State private var barcode = ""
    @State private var viewModel = AnalyzeViewModel()
    @State private var showAPIResult = false
    @State private var lastScannedBarcode = ""  // Track barcode to avoid duplicate searches
    @State private var showBarcodeScanner = false  // Show/hide camera scanner
    @EnvironmentObject var barcodeScanner: BarcodeScanner  // Receives from app root
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: EzSpacing.lg) {
                    // MARK: - Barcode Search Section
                    VStack(spacing: EzSpacing.md) {
                        Text("Căutare după cod de bare")
                            .font(.headline)
                            .foregroundColor(EzColors.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: EzSpacing.sm) {
                            TextField("Introduceți codul de bare", text: $barcode)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: barcode) { oldValue, newValue in
                                    // Auto-search when barcode changes
                                    if !newValue.isEmpty && newValue != oldValue {
                                        Task {
                                            await viewModel.searchByBarcode(newValue)
                                        }
                                    }
                                }
                                .onChange(of: barcodeScanner.scannedBarcode) { oldValue, newValue in
                                    // Watch for barcode from scanner
                                    if let scannedBarcode = newValue {
                                        barcode = scannedBarcode
                                        // onChange on barcode field will trigger search
                                    }
                                }
                            
                            if viewModel.isLoadingProduct {
                                ProgressView()
                                    .frame(width: 24, height: 24)
                            } else {
                                // Camera scanner button
                                Button(action: { showBarcodeScanner = true }) {
                                    Image(systemName: "barcode.viewfinder")
                                        .foregroundColor(EzColors.Accent.success)
                                        .font(.title3)
                                }
                                
                                // Manual search button
                                if !barcode.isEmpty {
                                    Button(action: {
                                        Task {
                                            await viewModel.searchByBarcode(barcode)
                                        }
                                    }) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(EzColors.Accent.primary)
                                            .font(.title3)
                                    }
                                }
                            }
                        }
                        
                        // Error display
                        if let error = viewModel.apiError {
                            HStack(spacing: EzSpacing.sm) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(EzColors.Accent.danger)
                                VStack(alignment: .leading, spacing: EzSpacing.xs) {
                                    Text("Eroare căutare")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text(error)
                                        .font(.caption2)
                                }
                                Spacer()
                            }
                            .foregroundColor(EzColors.Accent.danger)
                            .padding(EzSpacing.md)
                            .background(EzColors.Accent.danger.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        
                        // Success display - API results
                        if viewModel.hasAPIResults {
                            VStack(alignment: .leading, spacing: EzSpacing.md) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(EzColors.Accent.success)
                                    Text("Produs găsit")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                // Product image
                                if let imageUrl = viewModel.apiProductImage, let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            HStack {
                                                Spacer()
                                                ProgressView()
                                                    .frame(height: 120)
                                                Spacer()
                                            }
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: 150)
                                                .cornerRadius(AppTheme.CornerRadius.medium)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 120)
                                                .foregroundColor(EzColors.Text.tertiary)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                                
                                if let name = viewModel.apiProductName {
                                    Text(name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                if let brand = viewModel.apiProductBrand {
                                    Text("Brand: \(brand)")
                                        .font(.caption)
                                        .foregroundColor(EzColors.Text.tertiary)
                                }
                                
                                if let kcal = viewModel.apiProductNutrition?.kcal {
                                    HStack(spacing: EzSpacing.md) {
                                        Text("Energie:")
                                            .font(.caption)
                                            .foregroundColor(EzColors.Text.tertiary)
                                        Text(String(format: "%.0f", kcal))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text("kcal/100g")
                                            .font(.caption)
                                            .foregroundColor(EzColors.Text.tertiary)
                                    }
                                }
                                
                                Button(action: {
                                    populateFromAPI()
                                    // Don't dismiss yet - let user confirm
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.square.fill")
                                        Text("Foloseaza aceste date")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, EzSpacing.md)
                                }
                                .buttonStyle(.bordered)
                                .tint(EzColors.Accent.success)
                            }
                            .padding(EzSpacing.md)
                            .background(EzColors.Accent.success.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Manual Entry Section
                    VStack(spacing: EzSpacing.md) {
                        Text("Detalii ingredient")
                            .font(.headline)
                            .foregroundColor(EzColors.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            TextField("Nume", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: name) { oldValue, newValue in
                                    if !newValue.isEmpty {
                                        suggestedType = IngredientTypeDetector.detectType(for: newValue)
                                        showTypeSuggestion = suggestedType != .other
                                    }
                                }
                            
                            if showTypeSuggestion && !name.isEmpty {
                                Button(action: {}) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(EzColors.Accent.warning)
                                        .font(.title3)
                                }
                                .popover(isPresented: $showTypeSuggestion) {
                                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                                        Text("Tip detectat")
                                            .font(.caption)
                                            .foregroundColor(EzColors.Text.tertiary)
                                        
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(EzColors.Accent.success)
                                            Text(suggestedType.rawValue)
                                                .font(.subheadline)
                                        }
                                        
                                        Text("Tag-ul a fost auto-detectat pe baza numelui ingredientului.")
                                            .font(.caption)
                                            .foregroundColor(EzColors.Text.tertiary)
                                    }
                                    .padding(EzSpacing.md)
                                }
                            }
                        }
                        
                        Stepper("Cantitate: \(String(format: "%.1f", quantity))", value: $quantity, in: 0.1...1000, step: 0.1)
                            .padding(.vertical, EzSpacing.sm)
                        
                        Picker("Unitate", selection: $unit) {
                            ForEach(["buc", "g", "kg", "ml", "l", "linguri", "linguriță", "ceașcă"], id: \.self) { u in
                                Text(u).tag(u)
                            }
                        }
                        
                        Picker("Categorie", selection: $category) {
                            ForEach(IngredientCategories.all, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Manual Nutrition Input
                    VStack(spacing: EzSpacing.md) {
                        HStack {
                            Text("Valori nutritive manuale")
                                .font(.headline)
                                .foregroundColor(EzColors.Text.primary)
                            Spacer()
                            Button(action: { showManualNutrition.toggle() }) {
                                Image(systemName: showManualNutrition ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(EzColors.Accent.primary)
                            }
                        }
                        
                        if showManualNutrition {
                            Text("Completați daca API-ul nu a găsit datele (per 100g)")
                                .font(.caption)
                                .foregroundColor(EzColors.Text.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Calorii (kcal)", text: $manualCalories)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Proteine (g)", text: $manualProtein)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Carbohidrați (g)", text: $manualCarbs)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Grăsimi (g)", text: $manualFat)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Fibre (g)", text: $manualFiber)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Zahăr (g)", text: $manualSugars)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text("Apasă pentru a introduce valori nutritive manual")
                                .font(.caption)
                                .foregroundColor(EzColors.Text.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Action Buttons
                    VStack(spacing: EzSpacing.md) {
                        Button(action: {
                            let ingredientType = IngredientTypeDetector.detectType(for: name)
                            let ingredient = Ingredient(
                                name: name,
                                quantity: quantity,
                                unit: unit,
                                category: category,
                                ingredientType: ingredientType
                            )
                            
                            // Set manual nutrition if provided
                            if !manualCalories.isEmpty || !manualProtein.isEmpty || !manualCarbs.isEmpty || !manualFat.isEmpty {
                                let nutrition = NutritionInfo(
                                    caloriesKcal: Double(manualCalories) ?? 0,
                                    protein: Double(manualProtein) ?? 0,
                                    carbohydrates: Double(manualCarbs) ?? 0,
                                    fat: Double(manualFat) ?? 0,
                                    saturatedFat: 0,
                                    fiber: Double(manualFiber) ?? 0,
                                    sugars: Double(manualSugars) ?? 0
                                )
                                ingredient.nutritionPer100g = nutrition
                            }
                            
                            ingredients.append(ingredient)
                            dismiss()
                        }) {
                            Text("Adaugă")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, EzSpacing.md)
                                .background(EzColors.Accent.primary)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.6 : 1.0)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Anulează")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, EzSpacing.md)
                                .background(EzColors.Background.tertiary)
                                .foregroundColor(EzColors.Text.primary)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                    }
                    .padding(.vertical, EzSpacing.md)
                }
                .padding(.horizontal, EzSpacing.md)
                .padding(.vertical, EzSpacing.md)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Adaugă ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showBarcodeScanner) {
                // No action needed - onChange will detect barcode from environment
            } content: {
                AnalyzeView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helpers
    
    private func populateFromAPI() {
        if let productName = viewModel.apiProductName {
            name = productName
            suggestedType = IngredientTypeDetector.detectType(for: productName)
            showTypeSuggestion = suggestedType != .other
        }
        
        // Set category based on nutrition or brand
        if let nutrition = viewModel.apiProductNutrition {
            if let protein = nutrition.protein, protein > 15 {
                category = "Proteine animale"
            } else if let fat = nutrition.fat, fat > 20 {
                category = "Lactate și ouă"
            } else if let carbs = nutrition.carbs, carbs > 40 {
                category = "Cereale, pseudocereale și derivate"
            }
        }
    }
}

#Preview {
    @Previewable @State var ingredients: [Ingredient] = []
    AddIngredientView(ingredients: $ingredients)
}

