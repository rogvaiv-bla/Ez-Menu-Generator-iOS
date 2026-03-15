import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct RecipeDetailView: View {
    let recipeId: UUID
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var viewModel: RecipeListViewModel
    @Query private var recipes: [Recipe]
    
    private var recipe: Recipe? {
        recipes.first { $0.id == recipeId }
    }
    
    @State private var selectedTags: Set<Recipe.DietaryTag> = []
    @State private var showDeleteAlert = false
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImageMimeType = "image/jpeg"
    @State private var selectedImageExtension = "jpg"
    @State private var showAddIngredient = false
    @State private var showEditIngredient = false
    @State private var selectedIngredientIndex: Int?
    @State private var editingName = ""
    @State private var editingQuantity = 1.0
    @State private var editingUnit = "buc"
    @State private var showCategoryEdit = false
    @State private var editingCategory = ""
    @State private var newIngredients: [Ingredient] = []
    @State private var showNutritionEdit = false
    @State private var editingCalories = ""
    @State private var editingProtein = ""
    @State private var editingCarbs = ""
    @State private var editingFat = ""
    
    var body: some View {
        Group {
            if let recipe = recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Recipe Image
                        LazyImage(
                            image: recipe.image,
                            recipeId: recipe.id,
                            displayType: .full,
                            supabaseImagePath: recipe.supabaseImagePath
                        )
                        .frame(height: 250)
                        .cornerRadius(12)
                        
                        // Image Actions
                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                Label("Schimbă imagine", systemImage: "photo.badge.plus")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(EzColors.Accent.primary.opacity(0.1))
                            .cornerRadius(8)
                            .accessibilityLabel("Schimbă imaginea rețetei")
                            .accessibilityHint("Deschide galeria pentru a selecta o altă imagine")
                            
                            if recipe.image != nil {
                                if recipe.supabaseImagePath != nil {
                                    Label("În cloud", systemImage: "cloud.fill")
                                        .font(.caption)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(EzColors.Accent.primary.opacity(0.1))
                                        .foregroundColor(EzColors.Accent.primary)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    let r = recipe
                                    let vm = viewModel
                                    let context = modelContext
                                    r.setImage(nil)
                                    r.supabaseImagePath = nil
                                    ImageCacheManager.shared.clearCache(for: r.id)
                                    Task {
                                        do {
                                            try await r.deleteFromCloud()
                                        } catch {
                                            #if DEBUG
                                            print("❌ Delete failed: \(error)")
                                            #endif
                                        }
                                        await MainActor.run {
                                            try? context.save()
                                            vm.updateRecipe(r)
                                        }
                                    }
                                }) {
                                    Label("Șterge", systemImage: "trash")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(EzColors.Accent.danger.opacity(0.1))
                                .foregroundColor(EzColors.Accent.danger)
                                .cornerRadius(8)
                                .accessibilityLabel("Șterge imaginea rețetei")
                                .accessibilityHint("Elimină imaginea și o șterge din cloud dacă există")
                            }
                        }
                        
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(recipe.name)
                                .titleStyle()
                            
                            HStack(spacing: 16) {
                                Spacer()
                                
                                Button(action: {
                                    recipe.isFavorite.toggle()
                                    viewModel.updateRecipe(recipe)
                                }) {
                                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(recipe.isFavorite ? EzColors.Accent.danger : EzColors.Text.tertiary)
                                }
                                .accessibilityLabel(recipe.isFavorite ? "Elimina din favorite" : "Adaugă la favorite")
                                .accessibilityHint("Marchează sau elimină rețeta ca favorită")
                                .accessibilityAddTraits(.isButton)
                            }
                            
                            Text(recipe.recipeDescription)
                                .bodySecondaryStyle()
                            
                            if let encodedName = recipe.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                               let qwantURL = URL(string: "https://www.qwant.com/?q=cum+se+face+\(encodedName)+reteta") {
                                Link(destination: qwantURL) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "globe")
                                        Text("rețeta")
                                            .font(.caption)
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                    }
                                    .foregroundColor(EzColors.Accent.primary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(EzColors.Accent.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(EzColors.Background.secondary).cornerRadius(12)
                        
                        // Dietary Tags Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Etichete dietetice")
                                    .headlineStyle()
                                Spacer()
                                SwiftUI.Menu("Alege", systemImage: "slider.horizontal.3") {
                                    ForEach(Recipe.DietaryTag.allCases, id: \.self) { tag in
                                        Button(tag.rawValue) {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                            recipe.dietaryTags = Array(selectedTags)
                                            viewModel.updateRecipe(recipe)
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    recipe.autoDetectTags()
                                    selectedTags = Set(recipe.dietaryTags)
                                    viewModel.updateRecipe(recipe)
                                }) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.caption)
                                        .foregroundColor(EzColors.Accent.warning)
                                }
                            }
                            
                            if recipe.dietaryTags.isEmpty {
                                Text("Nicio etichetă selectată")
                                    .helperStyle()
                                    .foregroundColor(EzColors.Text.tertiary)
                            } else {
                                TagCloud(tags: recipe.dietaryTags)
                            }
                        }
                        .padding()
                        .background(EzColors.Background.secondary).cornerRadius(12)
                        
                        // Meal Types Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Tip de masă")
                                    .headlineStyle()
                                Spacer()
                                SwiftUI.Menu("Alege", systemImage: "slider.horizontal.3") {
                                    Button(action: { recipe.isBreakfast.toggle(); viewModel.updateRecipe(recipe) }) {
                                        Text("🌅 Mic dejun")
                                        if recipe.isBreakfast {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    Button(action: { recipe.isLunch.toggle(); viewModel.updateRecipe(recipe) }) {
                                        Text("☀️ Prânz")
                                        if recipe.isLunch {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    Button(action: { recipe.isDinner.toggle(); viewModel.updateRecipe(recipe) }) {
                                        Text("🌙 Cină")
                                        if recipe.isDinner {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    Button(action: { recipe.isDessert.toggle(); viewModel.updateRecipe(recipe) }) {
                                        Text("✨ Desert")
                                        if recipe.isDessert {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            
                            if recipe.hasMealType {
                                HStack(spacing: 8) {
                                    if recipe.isBreakfast {
                                        Text("🌅 Mic dejun")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(EzColors.Accent.warning.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                    if recipe.isLunch {
                                        Text("☀️ Prânz")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(EzColors.NutritionScore.fair.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                    if recipe.isDinner {
                                        Text("🌙 Cină")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(EzColors.Accent.primary.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                    if recipe.isDessert {
                                        Text("✨ Desert")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(EzColors.Accent.danger.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                    Spacer()
                                }
                            } else {
                                Text("Nicio masă selectată")
                                    .helperStyle()
                                    .foregroundColor(EzColors.Text.tertiary)
                            }
                        }
                        .padding()
                        .background(EzColors.Background.secondary).cornerRadius(12)
                        
                        // Nutrition Dashboard
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Dashboard nutrițional")
                                    .headlineStyle()
                                Spacer()
                                Button(action: {
                                    if let nutrition = recipe.nutrition {
                                        editingCalories = String(format: "%.0f", nutrition.caloriesKcal)
                                        editingProtein = String(format: "%.1f", nutrition.protein)
                                        editingCarbs = String(format: "%.1f", nutrition.carbohydrates)
                                        editingFat = String(format: "%.1f", nutrition.fat)
                                    }
                                    showNutritionEdit = true
                                }) {
                                    Image(systemName: "pencil.circle")
                                        .foregroundColor(EzColors.Accent.primary)
                                }
                            }
                            
                            NutritionDashboardView(nutrition: recipe.nutrition, servings: recipe.servings)
                        }
                        .padding()
                        .background(EzColors.Background.secondary).cornerRadius(12)
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Ingrediente")
                                    .headlineStyle()
                                Spacer()
                                Button(action: { showAddIngredient = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(EzColors.Accent.primary)
                                }
                            }
                            
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                HStack {
                                    Text(ingredient.name)
                                    Spacer()
                                    Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit)")
                                        .helperStyle()
                                    Button(action: { selectedIngredientIndex = index; showEditIngredient = true }) {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundColor(EzColors.Accent.primary)
                                    }
                                    Button(action: { recipe.ingredients.remove(at: index); viewModel.updateRecipe(recipe) }) {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundColor(EzColors.Accent.danger)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(EzColors.Background.secondary).cornerRadius(12)
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instrucțiuni")
                                .headlineStyle()
                            
                            Text(recipe.instructions)
                                .bodySecondaryStyle()
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(EzColors.Background.secondary).cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationBarBackButtonHidden(false)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: { showDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(EzColors.Accent.danger)
                        }
                    }
                }
                .alert("Șterge rețetă", isPresented: $showDeleteAlert) {
                    Button("Șterge", role: .destructive) {
                        HapticManager.Context.delete()
                        viewModel.deleteRecipe(recipe)
                        dismiss()
                    }
                    Button("Anulează", role: .cancel) { }
                } message: {
                    Text("Ești sigur că vrei să ștergi '\(recipe.name)'?")
                }
                .sheet(isPresented: $showEditIngredient) {
                    if let index = selectedIngredientIndex, index < recipe.ingredients.count {
                        let ingredient = recipe.ingredients[index]
                        NavigationStack {
                            Form {
                                Section(header: Text("Editează ingredient")) {
                                    TextField("Nume", text: $editingName)
                                    Stepper("Cantitate: \(String(format: "%.1f", editingQuantity))", value: $editingQuantity, in: 0.1...1000, step: 0.1)
                                    Picker("Unitate", selection: $editingUnit) {
                                        ForEach(["buc", "g", "kg", "ml", "l", "linguri", "linguriță", "ceașcă"], id: \.self) { u in
                                            Text(u).tag(u)
                                        }
                                    }
                                }
                            }
                            .navigationTitle("Editează ingredient")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Anulează") {
                                        showEditIngredient = false
                                    }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Salvează") {
                                        ingredient.name = editingName
                                        ingredient.quantity = editingQuantity
                                        ingredient.unit = editingUnit
                                        viewModel.updateRecipe(recipe)
                                        showEditIngredient = false
                                    }
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showAddIngredient) {
                    AddIngredientView(ingredients: $newIngredients)
                        .onChange(of: newIngredients) { _, newValue in
                            if let newIngredient = newValue.last {
                                recipe.ingredients.append(newIngredient)
                                viewModel.updateRecipe(recipe)
                                newIngredients.removeAll()
                                showAddIngredient = false
                            }
                        }
                }
                .sheet(isPresented: $showCategoryEdit) {
                    NavigationStack {
                        Form {
                            Section(header: Text("Selectează categoria")) {
                                Picker("Categorie", selection: $editingCategory) {
                                    ForEach(["Carne", "Pui", "Pește", "Legume", "Paste", "Supe", "Deserturi", "Ouă/Mic dejun", "Salate", "Preparate lactate", "Grătar/BBQ", "Rapid/Snacks", "Vegan/Vegetarian", "Tradiționale/Clasice", "Internaționale", "Diverse"], id: \.self) { cat in
                                        Text(cat).tag(cat)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Editează categoria")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Anulează") {
                                    showCategoryEdit = false
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Salvează") {
                                    recipe.category = editingCategory
                                    viewModel.updateRecipe(recipe)
                                    showCategoryEdit = false
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showNutritionEdit) {
                    NavigationStack {
                        Form {
                            Section(header: Text("Valori nutritive manuale")) {
                                TextField("Calorii (kcal)", text: $editingCalories)
                                    .keyboardType(.decimalPad)
                                TextField("Proteine (g)", text: $editingProtein)
                                    .keyboardType(.decimalPad)
                                TextField("Carbohidrați (g)", text: $editingCarbs)
                                    .keyboardType(.decimalPad)
                                TextField("Grăsimi (g)", text: $editingFat)
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .navigationTitle("Editează nutriție")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Anulează") {
                                    showNutritionEdit = false
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Salvează") {
                                    let nutrition = NutritionInfo(
                                        caloriesKcal: Double(editingCalories) ?? 0,
                                        protein: Double(editingProtein) ?? 0,
                                        carbohydrates: Double(editingCarbs) ?? 0,
                                        fat: Double(editingFat) ?? 0,
                                        saturatedFat: 0,
                                        fiber: 0,
                                        sugars: 0
                                    )
                                    recipe.nutrition = nutrition
                                    viewModel.updateRecipe(recipe)
                                    showNutritionEdit = false
                                }
                            }
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }

                    Task {
                        do {
                            let type = newItem.supportedContentTypes.first
                            let typeInfo: (mimeType: String, fileExtension: String)

                            if let type, (type.conforms(to: .heic) || type.identifier == "public.heif" || type.identifier == "public.heic") {
                                typeInfo = ("image/heic", "heic")
                            } else if let type, type.conforms(to: .png) {
                                typeInfo = ("image/png", "png")
                            } else if let type, type.conforms(to: .jpeg) {
                                typeInfo = ("image/jpeg", "jpg")
                            } else if let type, type.conforms(to: .tiff) {
                                typeInfo = ("image/tiff", "tiff")
                            } else {
                                typeInfo = ("image/jpeg", "jpg")
                            }

                            if let data = try await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    selectedImage = image
                                    selectedImageData = data
                                    selectedImageMimeType = typeInfo.mimeType
                                    selectedImageExtension = typeInfo.fileExtension
                                    recipe.setImage(image)
                                    viewModel.updateRecipe(recipe)
                                }

                                do {
                                    try await recipe.uploadToCloud(
                                        imageData: data,
                                        mimeType: selectedImageMimeType,
                                        fileExtension: selectedImageExtension
                                    )
                                    await MainActor.run {
                                        viewModel.updateRecipe(recipe)
                                    }
                                    #if DEBUG
                                    print("☁️ Image updated in cloud")
                                    #endif
                                } catch {
                                    if let uploadError = error as? SupabaseImageService.ImageUploadError,
                                       case .bucketNotFound = uploadError {
                                        #if DEBUG
                                        print("ℹ️ Cloud bucket missing. Recipe image remains saved locally.")
                                        #endif
                                    } else {
                                        #if DEBUG
                                        print("❌ Failed to upload image to cloud: \(error)")
                                        #endif
                                    }
                                }
                            }
                        } catch {
                            #if DEBUG
                            print("❌ Failed to load selected photo: \(error)")
                            #endif
                        }
                    }
                }
            } else {
                VStack {
                    Text("Rețeta nu a fost găsită")
                        .headlineStyle()
                        .padding()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let recipe = recipe {
                selectedTags = Set(recipe.dietaryTags)
            }
        }
    }
}

// Simple tag cloud with wrapping
struct TagCloud: View {
    let tags: [Recipe.DietaryTag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag.rawValue)
                    .font(.caption2)
                    .lineLimit(1)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(EzColors.Accent.primary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
}

#Preview {
    @Previewable @State var container = try! ModelContainer(for: Recipe.self, Ingredient.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    let sampleRecipe = Recipe(
        id: UUID(),
        name: "Preview Recipe",
        description: "Sample description",
        category: "Breakfast",
        servings: 2,
        prepTimeMinutes: 10,
        cookTimeMinutes: 15,
        ingredients: [],
        instructions: "Sample instructions",
        difficulty: .easy,
        createdAt: Date()
    )
    
    let _ = container.mainContext.insert(sampleRecipe)
    
    return RecipeDetailView(recipeId: sampleRecipe.id)
        .modelContainer(container)
        .environmentObject(RecipeListViewModel())
        .preferredColorScheme(.dark)
}
