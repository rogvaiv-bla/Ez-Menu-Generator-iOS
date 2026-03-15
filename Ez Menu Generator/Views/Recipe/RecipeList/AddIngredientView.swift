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
            Form {
                // MARK: - Barcode Search Section
                Section(header: Text("Căutare după cod de bare")) {
                    HStack {
                        TextField("Introduceți codul de bare", text: $barcode)
                            .keyboardType(.numberPad)
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
                                .frame(width: 20, height: 20)
                        } else {
                            // Camera scanner button
                            Button(action: { showBarcodeScanner = true }) {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(EzColors.Accent.success)
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
                                }
                            }
                        }
                    }
                    
                    // Error display
                    if let error = viewModel.apiError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(EzColors.Accent.danger)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Eroare căutare")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(error)
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(EzColors.Accent.danger)
                    }
                    
                    // Success display - API results
                    if viewModel.hasAPIResults {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(EzColors.Accent.success)
                                Text("Produs găsit")
                                    .font(.headline)
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
                                            .cornerRadius(8)
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
                                HStack(spacing: 12) {
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
                            }
                            .buttonStyle(.bordered)
                            .tint(EzColors.Accent.success)
                        }
                        .padding(8)
                        .background(EzColors.Accent.success.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - Manual Entry Section
                Section(header: Text("Detalii ingredient")) {
                    HStack {
                        TextField("Nume", text: $name)
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
                            }
                            .popover(isPresented: $showTypeSuggestion) {
                                VStack(alignment: .leading, spacing: 12) {
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
                                .padding()
                            }
                        }
                    }
                    
                    Stepper("Cantitate: \(String(format: "%.1f", quantity))", value: $quantity, in: 0.1...1000, step: 0.1)
                    
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
                
                // MARK: - Manual Nutrition Input
                Section(header: HStack {
                    Text("Valori nutritive manuale")
                    Spacer()
                    Button(action: { showManualNutrition.toggle() }) {
                        Image(systemName: showManualNutrition ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(EzColors.Accent.primary)
                    }
                }) {
                    if showManualNutrition {
                        Text("Completați daca API-ul nu a găsit datele (per 100g)")
                            .font(.caption)
                            .foregroundColor(EzColors.Text.secondary)
                        
                        TextField("Calorii (kcal)", text: $manualCalories)
                            .keyboardType(.decimalPad)
                        TextField("Proteine (g)", text: $manualProtein)
                            .keyboardType(.decimalPad)
                        TextField("Carbohidrați (g)", text: $manualCarbs)
                            .keyboardType(.decimalPad)
                        TextField("Grăsimi (g)", text: $manualFat)
                            .keyboardType(.decimalPad)
                        TextField("Fibre (g)", text: $manualFiber)
                            .keyboardType(.decimalPad)
                        TextField("Zahăr (g)", text: $manualSugars)
                            .keyboardType(.decimalPad)
                    } else {
                        Text("Apasă pentru a introduce valori nutritive manual")
                            .font(.caption)
                            .foregroundColor(EzColors.Text.tertiary)
                    }
                }
            }
            .navigationTitle("Adaugă ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anulează") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adaugă") {
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
                    }
                    .disabled(name.isEmpty)
                }
            }
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

