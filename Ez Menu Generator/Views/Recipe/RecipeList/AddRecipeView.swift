import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddRecipeView: View {
    @EnvironmentObject var viewModel: RecipeListViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var name = ""
    @State private var description = ""
    @State private var category = "Mic dejun & brunch"
    @State private var servings = 4
    @State private var instructions = ""
    @State private var difficulty: Recipe.DifficultyLevel = .easy
    @State private var ingredients: [Ingredient] = []
    @State private var showAddIngredient = false
    @State private var isBreakfast = false
    @State private var isLunch = true
    @State private var isDinner = false
    @State private var isDessert = false
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImageMimeType = "image/jpeg"
    @State private var selectedImageExtension = "jpg"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Imagine")) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        ZStack {
                            EzColors.Background.tertiary.opacity(0.3)
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(EzColors.Text.tertiary)
                                Text("Nicio imagine selectată")
                                    .font(.caption)
                                    .foregroundColor(EzColors.Text.tertiary)
                            }
                        }
                        .frame(height: 150)
                        .cornerRadius(8)
                    }
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Label("Alege imagine", systemImage: "photo.badge.plus")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("Detalii generale")) {
                    TextField("Nume rețetă", text: $name)
                    TextField("Descriere", text: $description)
                    
                    Picker("Categorie", selection: $category) {
                        ForEach(RecipeCategories.all, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("Ingrediente")) {
                    ForEach(ingredients) { ingredient in
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit)")
                                .font(.caption)
                        }
                    }
                    .onDelete { indices in
                        ingredients.remove(atOffsets: indices)
                    }
                    
                    Button(action: { showAddIngredient = true }) {
                        Label("Adaugă ingredient", systemImage: "plus.circle")
                    }
                    
                    // Warning if ingredients have incomplete nutrition
                    let missingNutrition = ingredients.filter { $0.nutritionPer100g == nil }
                    if !missingNutrition.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(EzColors.Accent.warning)
                            Text("\(missingNutrition.count) ingredient(e) fără nutriție")
                                .font(.caption)
                                .foregroundColor(EzColors.Accent.warning)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(EzColors.Accent.warning.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                Section(header: Text("Instrucțiuni")) {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                    
                    if !name.isEmpty {
                        Button(action: searchOnQwant) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("🔍 Cauta pe Qwant")
                            }
                        }
                        .foregroundColor(EzColors.Accent.success)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                Section(header: Text("Tip de masă")) {
                    HStack {
                        Text("Selectează tipurile de mese")
                        Spacer()
                        SwiftUI.Menu {
                            Button(action: { isBreakfast.toggle() }) {
                                Text("🌅 Mic dejun")
                                if isBreakfast {
                                    Image(systemName: "checkmark")
                                }
                            }
                            Button(action: { isLunch.toggle() }) {
                                Text("☀️ Prânz")
                                if isLunch {
                                    Image(systemName: "checkmark")
                                }
                            }
                            Button(action: { isDinner.toggle() }) {
                                Text("🌙 Cină")
                                if isDinner {
                                    Image(systemName: "checkmark")
                                }
                            }
                            Button(action: { isDessert.toggle() }) {
                                Text("✨ Desert")
                                if isDessert {
                                    Image(systemName: "checkmark")
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "slider.horizontal.3")
                                Text("Alege")
                                    .font(.caption)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(EzColors.Accent.primary.opacity(0.1))
                            .foregroundColor(EzColors.Accent.primary)
                            .cornerRadius(6)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if isBreakfast {
                            Text("🌅 Mic dejun")
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(EzColors.Accent.warning.opacity(0.1))
                                .cornerRadius(6)
                        }
                        if isLunch {
                            Text("☀️ Prânz")
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(EzColors.NutritionScore.fair.opacity(0.1))
                                .cornerRadius(6)
                        }
                        if isDinner {
                            Text("🌙 Cină")
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(EzColors.Accent.primary.opacity(0.1))
                                .cornerRadius(6)
                        }
                        if isDessert {
                            Text("✨ Desert")
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(EzColors.Accent.danger.opacity(0.15))
                                .cornerRadius(6)
                        }
                        Spacer()
                    }                    
                    // Validation warning if no meal type selected
                    if !isBreakfast && !isLunch && !isDinner && !isDessert {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(EzColors.Accent.danger)
                            Text("Selectează cel puțin un tip de masă")
                                .font(.caption)
                                .foregroundColor(EzColors.Accent.danger)
                        }
                        .padding(EzSpacing.md)
                        .background(EzColors.Accent.danger.opacity(0.1))
                        .cornerRadius(8)
                    }                }
            }
            .navigationTitle("Adaugă rețetă")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anulează") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvează") {
                        // Fallback: keep recipes valid even if user deselects all meal types.
                        if !isBreakfast && !isLunch && !isDinner && !isDessert {
                            isLunch = true
                        }

                        let recipe = Recipe(
                            name: name,
                            description: description,
                            category: category,
                            servings: servings,
                            prepTimeMinutes: 0,
                            cookTimeMinutes: 0,
                            ingredients: ingredients,
                            instructions: instructions,
                            difficulty: difficulty
                        )
                        // Set meal types
                        recipe.isBreakfast = isBreakfast
                        recipe.isLunch = isLunch
                        recipe.isDinner = isDinner
                        recipe.isDessert = isDessert
                        
                        // Auto-detect dietary tags from ingredients
                        recipe.autoDetectTags()
                        
                        // Auto-calculate nutrition from ingredients
                        let calculatedNutrition = NutritionCalculator.recipeNutrition(recipe)
                        recipe.nutrition = calculatedNutrition
                        print("📊 Nutrition auto-calculated: \(String(format: "%.0f", calculatedNutrition.caloriesKcal)) kcal")
                        
                        // Set image BEFORE saving to database
                        if let selectedImage = selectedImage {
                            recipe.setImage(selectedImage)
                            print("✅ Image set locally for recipe: \(recipe.name)")
                        }
                        
                        // Save recipe to database
                        viewModel.addRecipe(recipe)
                        
                        // Upload to Supabase in background (happens after save)
                        if let selectedImageData = selectedImageData {
                            Task {
                                do {
                                    try await recipe.uploadToCloud(
                                        imageData: selectedImageData,
                                        mimeType: selectedImageMimeType,
                                        fileExtension: selectedImageExtension
                                    )
                                    viewModel.updateRecipe(recipe)
                                    print("☁️ Image uploaded to Supabase: \(recipe.supabaseImagePath ?? "unknown")")
                                } catch {
                                    if let uploadError = error as? SupabaseImageService.ImageUploadError,
                                       case .bucketNotFound = uploadError {
                                        print("ℹ️ Cloud bucket missing. Recipe image remains saved locally.")
                                    } else {
                                        print("❌ Failed to upload image to cloud: \(error)")
                                    }
                                    // Still saved locally since we saved it before attempting cloud upload
                                }
                            }
                        } else if let selectedImage = selectedImage {
                            // Fallback for cases where raw data is not available
                            Task {
                                do {
                                    try await recipe.uploadToCloud(selectedImage)
                                    viewModel.updateRecipe(recipe)
                                    print("☁️ Image uploaded to Supabase (JPEG fallback): \(recipe.supabaseImagePath ?? "unknown")")
                                } catch {
                                    if let uploadError = error as? SupabaseImageService.ImageUploadError,
                                       case .bucketNotFound = uploadError {
                                        print("ℹ️ Cloud bucket missing. Recipe image remains saved locally.")
                                    } else {
                                        print("❌ Failed to upload image to cloud: \(error)")
                                    }
                                }
                            }
                        }
                        
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showAddIngredient) {
                AddIngredientView(ingredients: $ingredients)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }

                Task {
                    do {
                        let typeInfo = imageTypeInfo(from: newItem.supportedContentTypes.first)

                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                                selectedImageData = data
                                selectedImageMimeType = typeInfo.mimeType
                                selectedImageExtension = typeInfo.fileExtension
                            }
                        }
                    } catch {
                        #if DEBUG
                        print("❌ Failed to load selected photo: \(error)")
                        #endif
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func searchOnQwant() {
        let searchQuery = "recipe \(name)"
        // URL encode recipe name
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        if let url = URL(string: "https://www.qwant.com/?q=\(encodedQuery)") {
            openURL(url)
        }
    }

    private func imageTypeInfo(from type: UTType?) -> (mimeType: String, fileExtension: String) {
        guard let type else { return ("image/jpeg", "jpg") }

        if type.conforms(to: .heic) || type.identifier == "public.heif" || type.identifier == "public.heic" {
            return ("image/heic", "heic")
        }
        if type.conforms(to: .png) {
            return ("image/png", "png")
        }
        if type.conforms(to: .jpeg) {
            return ("image/jpeg", "jpg")
        }
        if type.conforms(to: .tiff) {
            return ("image/tiff", "tiff")
        }

        return ("image/jpeg", "jpg")
    }
}

#Preview {
    AddRecipeView()
        .environmentObject(RecipeListViewModel())
}
