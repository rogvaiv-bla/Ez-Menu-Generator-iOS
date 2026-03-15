import SwiftUI

struct RecipeListView: View {
    @EnvironmentObject var viewModel: RecipeListViewModel
    @State private var showAddRecipe = false
    @State private var showSearch = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Custom Navigation Bar (REDESIGN 3.0)
            VStack(spacing: 0) {
                NavigationBarView(
                    title: "Recipes",
                    showBackButton: false,
                    onPrimaryAction: { showAddRecipe = true },
                    primaryActionIcon: "plus",
                    onUndo: { viewModel.undo() },
                    onRedo: { viewModel.redo() },
                    canUndo: viewModel.undoRedoManager.canUndo,
                    canRedo: viewModel.undoRedoManager.canRedo
                )
                
                // Main Content
                ZStack {
                    if viewModel.filteredRecipes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 48))
                                .foregroundColor(EzColors.Accent.primary.opacity(0.3))
                                .accessibilityHidden(true)
                            Text("Nicio rețetă")
                                .headlineStyle()
                            Text("Adaugă prima ta rețetă")
                                .bodyStyle()
                                .foregroundColor(EzColors.Text.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(EzColors.Background.primary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Lista de rețete este goală")
                        .accessibilityHint("Apasă butonul plus pentru a adăuga prima rețetă")
                    } else {
                        List {
                            ForEach(viewModel.filteredRecipes, id: \.id) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)
                                    .environmentObject(viewModel)) {
                                    RecipeRowView(recipe: recipe)
                                }
                            }
                            .onDelete { indices in
                                for index in indices {
                                    let recipe = viewModel.filteredRecipes[index]
                                    viewModel.deleteRecipe(recipe)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .background(EzColors.Background.primary)
                        .padding(.bottom, 60)
                        .refreshable {
                            await viewModel.refreshRecipes()
                        }
                    }
                    
                }
            }
            
            // Search/Add Sheets
            .sheet(isPresented: $showSearch) {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(EzColors.Text.secondary)
                        
                        TextField("Cauta rețete...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(EzColors.Text.primary)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(EzColors.Text.secondary)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(8)
                    .padding(EzSpacing.md)
                    
                    List {
                        ForEach(viewModel.filteredRecipes, id: \.id) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)
                                .environmentObject(viewModel)) {
                                RecipeRowView(recipe: recipe)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .padding(.bottom, 60)
                    
                    Spacer()
                }
                .background(EzColors.Background.primary)
            }
            .sheet(isPresented: $showAddRecipe) {
                AddRecipeView()
                    .environmentObject(viewModel)
            }
        }
        .background(EzColors.Background.primary)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RecipeListView()
        .environmentObject(RecipeListViewModel())
}
