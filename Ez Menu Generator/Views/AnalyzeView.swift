import SwiftUI
import AVFoundation
import AudioToolbox
import SwiftData
import Combine

// MARK: - Environment Objects
// BarcodeScanner: Passes barcode from camera scanner to parent view
class BarcodeScanner: ObservableObject {
    @Published var scannedBarcode: String? = nil
}

struct AnalyzeView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "Toate"
    @State private var showBarcodeScanner = false
    @State private var scannedBarcode: String?
    @State private var viewModel = AnalyzeViewModel()
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    // Environment object for passing barcode back to parent
    @EnvironmentObject var barcodeScanner: BarcodeScanner
    
    var filteredProducts: [FoodProduct] {
        if searchText.isEmpty && selectedCategory == "Toate" {
            return []
        }
        
        let searchResults = searchText.isEmpty ? ProductDatabaseService.products : ProductDatabaseService.searchProducts(query: searchText)
        
        if selectedCategory == "Toate" {
            return searchResults
        }
        
        let normalizedSelectedCategory = selectedCategory
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        
        return searchResults.filter {
            let normalizedCategory = $0.category
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            return normalizedCategory == normalizedSelectedCategory
        }
    }
    
    var categories: [String] {
        ["Toate"] + ProductDatabaseService.getAllCategories()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Custom Navigation Bar (REDESIGN 3.0)
            VStack(spacing: 0) {
                NavigationBarView(
                    title: "Analyze",
                    showBackButton: false,
                    onSearch: { /* Integrated below */ },
                    onSettings: { showBarcodeScanner = true }
                )
                
                // Main Content
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(EzColors.Text.secondary)
                        
                        TextField("Cauta produse...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(EzColors.Text.primary)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(EzColors.Text.secondary)
                            }
                        }
                    }
                    .padding(EzSpacing.sm)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(8)
                    .padding(EzSpacing.md)
                    
                    // Category Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: EzSpacing.sm) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category)
                                        .ezLabelStyle()
                                        .padding(.horizontal, EzSpacing.sm)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == category ? EzColors.Accent.primary : EzColors.Background.secondary)
                                        .foregroundColor(selectedCategory == category ? EzColors.Text.primary : EzColors.Text.primary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, EzSpacing.md)
                    }
                    .padding(.vertical, EzSpacing.sm)
                    
                    // Products List
                    if filteredProducts.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(EzColors.Text.secondary)
                            
                            Text("Niciun produs găsit")
                                .headlineStyle()
                            
                            Text("Încearcă alta terminologie sau scanează codul de bare")
                                .bodyStyle()
                                .foregroundColor(EzColors.Text.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List {
                            ForEach(filteredProducts) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductRow(product: product)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .background(EzColors.Background.primary)
                        .padding(.bottom, 60)
                    }
                }
            }
            
            // Barcode Scanner Sheet
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(scannedCode: $scannedBarcode, showScanner: $showBarcodeScanner)
                    .onDisappear {
                        if let barcode = scannedBarcode {
                            // Pass barcode to parent via environment object
                            DispatchQueue.main.async {
                                self.barcodeScanner.scannedBarcode = barcode
                            }
                            self.dismiss()
                            
                            scannedBarcode = nil
                        }
                    }
            }
        }
        .background(EzColors.Background.primary)
        .ignoresSafeArea(edges: .bottom)
    }
}

struct ProductRow: View {
    let product: FoodProduct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text(product.category)
                            .font(.caption)
                            .foregroundColor(EzColors.Text.secondary)
                        
                        if let barcode = product.barcode {
                            Text("📊 \(barcode)")
                                .font(.caption2)
                                .foregroundColor(EzColors.Accent.primary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(product.nutrition.caloriesKcal)) kcal")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(EzColors.Accent.warning)
                    
                    Text("la 100g")
                        .font(.caption)
                        .foregroundColor(EzColors.Text.secondary)
                }
            }
            
            // Macros Preview
            HStack(spacing: 12) {
                MacroBadge(label: "P", value: product.nutrition.protein, color: EzColors.Accent.danger)
                MacroBadge(label: "C", value: product.nutrition.carbohydrates, color: EzColors.Accent.primary)
                MacroBadge(label: "G", value: product.nutrition.fat, color: EzColors.NutritionScore.fair)
                MacroBadge(label: "F", value: product.nutrition.fiber, color: EzColors.Accent.success)
            }
            .font(.caption2)
        }
        .padding(.vertical, 8)
    }
}

struct MacroBadge: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .fontWeight(.bold)
            Text(String(format: "%.1f", value))
        }
        .font(.caption)
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

#Preview {
    AnalyzeView()
        .environmentObject(BarcodeScanner())
}
