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
            ScrollView(.vertical) {
                VStack(spacing: EzSpacing.lg) {
                    // MARK: - Image Section
                    VStack(spacing: EzSpacing.md) {
                        Text("Imagine")
                            .font(.headline)
                            .foregroundColor(EzColors.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        } else {
                            ZStack {
                                EzColors.Background.tertiary.opacity(0.3)
                                VStack(spacing: EzSpacing.md) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(EzColors.Text.tertiary)
                                    Text("Nicio imagine selectată")
                                        .font(.caption)
                                        .foregroundColor(EzColors.Text.tertiary)
                                }
                            }
                            .frame(height: 150)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Label("Alege imagine", systemImage: "photo.badge.plus")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    
                    // MARK: - General Details Section
                    VStack(spacing: EzSpacing.md) {
                        Text("Detalii generale")
                            .font(.headline)
                            .foregroundColor(EzColors.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("Nume rețetă", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, EzSpacing.xs)
                        
                        TextField("Descriere", text: $description)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, EzSpacing.xs)
                        
                        Picker("Categorie", selection: $category) {
                            ForEach(RecipeCategories.all, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Ingredients Section
                    VStack(spacing: EzSpacing.md) {
                        Text("Ingrediente")
                            .font(.headline)
                            .foregroundColor(EzColors.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if !ingredients.isEmpty {
                            VStack(spacing: EzSpacing.sm) {
                                ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                    HStack {
                                        VStack(alignment: .leading, spacing: EzSpacing.xs) {
                                            Text(ingredient.name)
                                                .font(.body)
                                            Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit)")
                                                .font(.caption)
                                                .foregroundColor(EzColors.Text.tertiary)
                                        }
                                        Spacer()
                                        Button(action: {
                                            ingredients.remove(at: index)
                                        }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(EzColors.Accent.danger)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(EzSpacing.sm)
                                    .background(EzColors.Background.tertiary)
                                    .cornerRadius(AppTheme.CornerRadius.small)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                }
                            }
                        }
                        
                        Button(action: { showAddIngredient = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Adaugă ingredient")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, EzSpacing.md)
                            .background(EzColors.Accent.primary.opacity(0.2))
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .foregroundColor(EzColors.Accent.primary)
                        }
                        
                        // Warning if ingredients have incomplete nutrition
                        let missingNutrition = ingredients.filter { $0.nutritionPer100g == nil }
                        if !missingNutrition.isEmpty {
                            HStack(spacing: EzSpacing.sm) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(EzColors.Accent.warning)
                                Text("\(missingNutrition.count) ingredient(e) fără nutriție")
                                    .font(.caption)
                                    .foregroundColor(EzColors.Accent.warning)
                            }
                            .padding(EzSpacing.md)
                            .background(EzColors.Accent.warning.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Instructions Section
                    VStack(spacing: EzSpacing.md) {
                        Text("Instrucțiuni")
                            .font(.headline)
                            .foregroundColor(EzColors.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextEditor(text: $instructions)
                            .frame(minHeight: 120)
                            .padding(EzSpacing.sm)
                            .background(EzColors.Background.tertiary)
                            .cornerRadius(AppTheme.CornerRadius.small)
                        
                        if !name.isEmpty {
                            Button(action: searchOnQwant) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Cauta pe Qwant")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, EzSpacing.md)
                                .background(EzColors.Accent.success.opacity(0.2))
                                .cornerRadius(AppTheme.CornerRadius.medium)
                                .foregroundColor(EzColors.Accent.success)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Meal Type Section
                    VStack(spacing: EzSpacing.md) {
                        HStack {
                            Text("Tip de masă")
                                .font(.headline)
                                .foregroundColor(EzColors.Text.primary)
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
                                HStack(spacing: EzSpacing.sm) {
                                    Image(systemName: "slider.horizontal.3")
                                    Text("Alege")
                                        .font(.caption)
                                }
                                .padding(.vertical, EzSpacing.sm)
                                .padding(.horizontal, EzSpacing.md)
                                .background(EzColors.Accent.primary.opacity(0.15))
                                .foregroundColor(EzColors.Accent.primary)
                                .cornerRadius(AppTheme.CornerRadius.small)
                            }
                        }
                        
                        HStack(spacing: EzSpacing.sm) {
                            if isBreakfast {
                                Text("🌅 Mic dejun")
                                    .font(.caption)
                                    .padding(.vertical, EzSpacing.xs)
                                    .padding(.horizontal, EzSpacing.sm)
                                    .background(EzColors.Accent.warning.opacity(0.2))
                                    .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            if isLunch {
                                Text("☀️ Prânz")
                                    .font(.caption)
                                    .padding(.vertical, EzSpacing.xs)
                                    .padding(.horizontal, EzSpacing.sm)
                                    .background(EzColors.NutritionScore.fair.opacity(0.2))
                                    .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            if isDinner {
                                Text("🌙 Cină")
                                    .font(.caption)
                                    .padding(.vertical, EzSpacing.xs)
                                    .padding(.horizontal, EzSpacing.sm)
                                    .background(EzColors.Accent.primary.opacity(0.2))
                                    .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            if isDessert {
                                Text("✨ Desert")
                                    .font(.caption)
                                    .padding(.vertical, EzSpacing.xs)
                                    .padding(.horizontal, EzSpacing.sm)
                                    .background(EzColors.Accent.danger.opacity(0.15))
                                    .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            Spacer()
                        }
                        
                        // Validation warning if no meal type selected
                        if !isBreakfast && !isLunch && !isDinner && !isDessert {
                            HStack(spacing: EzSpacing.sm) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(EzColors.Accent.danger)
                                Text("Selectează cel puțin un tip de masă")
                                    .font(.caption)
                                    .foregroundColor(EzColors.Accent.danger)
                            }
                            .padding(EzSpacing.md)
                            .background(EzColors.Accent.danger.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // MARK: - Action Buttons
                    VStack(spacing: EzSpacing.md) {
                        Button(action: {
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
                        }) {
                            Text("Salvează")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, EzSpacing.md)
                                .background(EzColors.Accent.primary)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.6 : 1.0)
                        .scaleEffect(name.isEmpty ? 0.95 : 1.0)
                        .accessibilityLabel("Salvează rețetă")
                        .accessibilityHint("Salvează rețeta cu toate ingredientele și instrucțiunile")
                        
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
                        .accessibilityLabel("Anulează")
                        .accessibilityHint("Închide dialogul fără a salva rețeta")
                    }
                    .padding(.vertical, EzSpacing.md)
                }
                .padding(.horizontal, EzSpacing.md)
                .padding(.vertical, EzSpacing.md)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Adaugă rețetă")
            .navigationBarTitleDisplayMode(.inline)
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
