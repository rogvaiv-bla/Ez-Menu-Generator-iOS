import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @EnvironmentObject var viewModel: ShoppingListViewModel
    @State private var showAddItem = false
    @State private var showProductSearch = false
    @State private var showMenu = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Custom Navigation Bar (REDESIGN 3.0)
            VStack(spacing: 0) {
                NavigationBarView(
                    title: "Shop",
                    showBackButton: false,
                    onSearch: { showProductSearch = true },
                    onPrimaryAction: { showAddItem = true },
                    primaryActionIcon: "plus",
                    onUndo: { viewModel.undo() },
                    onRedo: { viewModel.redo() },
                    onSettings: { showMenu = true },
                    canUndo: viewModel.undoRedoManager.canUndo,
                    canRedo: viewModel.undoRedoManager.canRedo
                )
                
                // Main Content
                contentView
                    .background(EzColors.Background.primary)
            }
            
            // Sheets
            .sheet(isPresented: $showAddItem) {
                AddShoppingItemView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showProductSearch) {
                AnalyzeView()
            }
            .sheet(isPresented: $showMenu) {
                ShoppingListMenuSheet(viewModel: viewModel, isPresented: $showMenu)
            }
        }
        .background(EzColors.Background.primary)
        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    var contentView: some View {
        if viewModel.filteredItems.isEmpty {
            EmptyStateView.noShoppingItems {
                showAddItem = true
            }
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    // Statistics Header
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Progres")
                                    .ezLabelStyle()
                                    .foregroundColor(EzColors.Text.secondary)
                                Text("\(viewModel.checkedCount)/\(viewModel.shoppingItems.count) articole")
                                    .headlineStyle()
                            }
                            
                            Spacer()
                            
                            ProgressView(value: Float(viewModel.checkedCount), total: Float(max(viewModel.shoppingItems.count, 1)))
                                .tint(EzColors.Accent.primary)
                                .frame(maxWidth: 100)
                        }
                        .padding(EzSpacing.md)
                        .background(EzColors.Background.secondary)
                        .cornerRadius(EzSpacing.Card.cornerRadius)
                        
                        // Category Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.selectedCategory = category
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            if category != "Toate" {
                                                let emoji = CategoryManager.orderedCategories.first(where: { $0.name == category })?.emoji ?? "📦"
                                                Text(emoji)
                                                    .font(.system(size: 18))
                                            }
                                            Text(category)
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(viewModel.selectedCategory == category ? .white : EzColors.Text.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(viewModel.selectedCategory == category ? EzColors.Accent.primary : EzColors.Background.secondary)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, EzSpacing.md)
                        }
                    }
                    .padding(.vertical, EzSpacing.md)
                    
                    // Items List - Grouped by Category
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.groupedAndSortedItems, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 0) {
                                // Category Header
                                HStack {
                                    Text(CategoryManager.displayName(for: group.category))
                                        .titleStyle()
                                    
                                    Spacer()
                                    
                                    Text("\(group.items.filter { $0.isChecked }.count)/\(group.items.count)")
                                        .ezLabelStyle()
                                        .foregroundColor(EzColors.Text.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                                .background(EzColors.Background.secondary)
                                
                                // Items in Category
                                LazyVStack(spacing: 0) {
                                    ForEach(group.items, id: \.id) { item in
                                        ShoppingItemRowView(item: item)
                                            .environmentObject(viewModel)
                                    }
                                }
                                .background(EzColors.Background.secondary)
                            }
                            .cornerRadius(12)
                            .padding(.horizontal, EzSpacing.md)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .refreshable {
                await viewModel.refreshItems()
            }
        }
    }
}

// MARK: - Menu Sheet
struct ShoppingListMenuSheet: View {
    let viewModel: ShoppingListViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Opțiuni")
                .headlineStyle()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(EzSpacing.md)
                .background(EzColors.Background.secondary)
            
            ScrollView {
                VStack(spacing: EzSpacing.sm) {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) { 
                            viewModel.checkAll() 
                        }
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "checkmark.square.fill")
                            Text("Bifează tot")
                            Spacer()
                        }
                        .padding(EzSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(EzColors.Text.primary)
                    }
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) { 
                            viewModel.uncheckAll() 
                        }
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "square")
                            Text("Debifează tot")
                            Spacer()
                        }
                        .padding(EzSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(EzColors.Text.primary)
                    }
                    
                    Divider()
                    
                    Button(action: { 
                        viewModel.filteredItems.forEach { item in
                            viewModel.undoRedoManager.recordAction(.deleteShoppingItem(ShoppingItemSnapshot.from(item)))
                        }
                        withAnimation(.easeInOut(duration: 0.3)) { 
                            viewModel.clearChecked() 
                        }
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Șterge bifate")
                            Spacer()
                        }
                        .padding(EzSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(EzColors.Accent.danger)
                    }
                    
                    Button(action: { 
                        viewModel.shoppingItems.forEach { item in
                            viewModel.undoRedoManager.recordAction(.deleteShoppingItem(ShoppingItemSnapshot.from(item)))
                        }
                        viewModel.clearAll()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Gol tot")
                            Spacer()
                        }
                        .padding(EzSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(EzColors.Accent.danger)
                    }
                    
                    Divider()
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) { 
                            viewModel.populateSampleData()
                        }
                        // Give the view a moment to update before closing the sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPresented = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard.fill")
                            Text("Încarcă lista de cumpărături")
                            Spacer()
                        }
                        .padding(EzSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(EzColors.Accent.success)
                    }
                }
                .padding(EzSpacing.md)
            }
            
            Button(action: { isPresented = false }) {
                Text("Închide")
                    .bodyStyle()
                    .frame(maxWidth: .infinity)
                    .padding(EzSpacing.md)
                    .background(EzColors.Accent.primary)
                    .foregroundColor(EzColors.Text.primary)
                    .cornerRadius(EzSpacing.Card.cornerRadius)
            }
            .padding(EzSpacing.md)
        }
        .background(EzColors.Background.primary)
    }
}

#Preview {
    ShoppingListView()
        .environmentObject(ShoppingListViewModel())
}
