//
// ShoppingListViewModel.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Manages shopping list operations:
// - Add/edit/delete shopping items
// - Organize items by category
// - Track purchase status (checked)
// - Persist via StorageService
// - Undo/redo support for deletions
//
// MARK: - Key Methods
// - addItem() - Add new shopping item
// - updateItem() - Modify quantity/unit
// - deleteItem() - Remove with undo support
// - toggleChecked() - Mark as purchased
// - clearChecked() - Remove all checked items
//
// MARK: - Category Organization
// Groups items by category for easy shopping:
// - Vegetables, Fruits, Meat, Dairy, Pantry, etc.
// - Sorted alphabetically within categories
//
// MARK: - Architecture
// MainActor for UI thread safety
// Uses StorageService for data persistence
// UndoRedoManager for deletion undo
//

import Foundation
import Combine
import SwiftData

@MainActor
class ShoppingListViewModel: ObservableObject {
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var searchText = ""
    @Published var selectedCategory = "Toate"
    @Published var isLoading = false
    @Published var undoRedoManager = UndoRedoManager()
    private var cancellables: Set<AnyCancellable> = []
    
    private var hasInitialized = false
    let storageService: StorageServiceProtocol
    private var searchTask: Task<Void, Never>?
    
    init(storageService: StorageServiceProtocol? = nil) {
        self.storageService = storageService ?? StorageService.shared

        undoRedoManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        if !hasInitialized {
            hasInitialized = true
            fetchItems()
        }
    }
    
    var filteredItems: [ShoppingItem] {
        shoppingItems.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "Toate" || item.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var groupedAndSortedItems: [(category: String, items: [ShoppingItem])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.category }
        
        // First, show categories in the ordered list
        var result: [(category: String, items: [ShoppingItem])] = []
        for category in CategoryManager.orderedCategories.map({ $0.name }) {
            if let items = grouped[category] {
                result.append((category: category, items: items.sorted { $0.name < $1.name }))
            }
        }
        
        // Then, show any other categories not in the ordered list
        let orderedNames = Set(CategoryManager.orderedCategories.map { $0.name })
        for category in grouped.keys.sorted() {
            if !orderedNames.contains(category) {
                if let items = grouped[category] {
                    result.append((category: category, items: items.sorted { $0.name < $1.name }))
                }
            }
        }
        
        return result
    }
    
    var categories: [String] {
        let cats = Set(shoppingItems.map { $0.category })
        var result = ["Toate"]
        
        // Add ordered categories that have items
        for category in CategoryManager.orderedCategories.map({ $0.name }) {
            if cats.contains(category) {
                result.append(category)
            }
        }
        
        // Add any other categories not in the ordered list
        let orderedNames = Set(CategoryManager.orderedCategories.map { $0.name })
        for category in cats.sorted() {
            if !orderedNames.contains(category) {
                result.append(category)
            }
        }
        
        return result
    }
    
    var totalPrice: Double {
        filteredItems.reduce(0) { $0 + ($1.price ?? 0) }
    }
    
    var checkedCount: Int {
        shoppingItems.filter { $0.isChecked }.count
    }
    
    private func sortItems() {
        // Sort by category order, then alphabetically by name within each category
        let categoryOrder = Dictionary(uniqueKeysWithValues: 
            CategoryManager.orderedCategories.enumerated().map { ($0.element.name, $0.offset) }
        )
        
        shoppingItems.sort { item1, item2 in
            let order1 = categoryOrder[item1.category] ?? Int.max
            let order2 = categoryOrder[item2.category] ?? Int.max
            
            if order1 != order2 {
                return order1 < order2
            }
            return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
        }
    }
    
    func fetchItems() {
        isLoading = true
        storageService.fetchAllShoppingItems()
        shoppingItems = storageService.shoppingItems
        sortItems()
        isLoading = false
    }

    func refreshItems() async {
        await Task { @MainActor in
            fetchItems()
        }.value
    }
    
    func toggleItem(_ item: ShoppingItem) {
        // Optimistic update
        if let index = shoppingItems.firstIndex(where: { $0.id == item.id }) {
            shoppingItems[index].isChecked.toggle()
        }
        storageService.updateShoppingItem(item)
    }
    
    func addItem(_ item: ShoppingItem) {
        shoppingItems.append(item)
        sortItems()
        storageService.addShoppingItem(item)
    }
    
    func deleteItem(_ item: ShoppingItem) {
        undoRedoManager.recordAction(.deleteShoppingItem(ShoppingItemSnapshot.from(item)))
        shoppingItems.removeAll { $0.id == item.id }
        sortItems()
        storageService.deleteShoppingItem(item)
    }
    
    func updateItem(_ item: ShoppingItem) {
        if let index = shoppingItems.firstIndex(where: { $0.id == item.id }) {
            shoppingItems[index] = item
            sortItems()
        }
        storageService.updateShoppingItem(item)
    }
    
    func clearChecked() {
        let checked = shoppingItems.filter { $0.isChecked }
        shoppingItems.removeAll { $0.isChecked }
        for item in checked {
            undoRedoManager.recordAction(.deleteShoppingItem(ShoppingItemSnapshot.from(item)))
            storageService.deleteShoppingItem(item)
        }
        sortItems()
    }
    
    func clearAll() {
        shoppingItems.removeAll()
        storageService.clearShoppingList()
    }
    
    func checkAll() {
        guard !shoppingItems.isEmpty else { return }
        for i in 0..<shoppingItems.count {
            shoppingItems[i].isChecked = true
        }
        storageService.updateShoppingItems(shoppingItems)
    }
    
    func uncheckAll() {
        guard !shoppingItems.isEmpty else { return }
        for i in 0..<shoppingItems.count {
            shoppingItems[i].isChecked = false
        }
        storageService.updateShoppingItems(shoppingItems)
    }
    
    func populateSampleData() {
        let itemsByCategory: [(category: String, items: [String])] = [
            ("Legume / Fructe", [
                "Castraveți 🥒", "Sfeclă", "Salată 🥗", "Avocado 🥑", "Mere 🍎🍏", "Banane 🍌",
                "Lămâi 🍋", "Cartofi 🥔", "Morcovi 🥕", "Ardei Kapia", "Roșii 🍅",
                "Pătrunjel / mărar 🌿", "Usturoi 🧄", "Ceapă 🧅", "Ardel grăsuț 🌶️",
                "Litchi", "Clementine 🍊", "Portocale 🍊", "Ceapă roșie", "Struguri 🍇",
                "Țelină", "Porumb 🌽", "Vânătă 🍆", "Caise", "Varză 🥬", "Frunze de vie 🍃",
                "Pepene 🍉", "Cireșe 🍒", "Ananas 🍍", "Nectarine 🍑", "Piersici 🍑",
                "Căpșuni 🍓", "Păstăi congelate 🫛", "Pomelo 🍈", "Fistic 🫘", "Spanac 🌿",
                "Afine 🫐", "Castravete Fabio 🥒", "Ciuperci 🍄", "Mazăre 🫛"
            ]),
            ("Lactate și ouă", [
                "Kefir", "Ouă 🥚", "Lapte 🥛", "Iaurt cu fructe", "Iaurt grecesc 🧿",
                "Madame Loik", "Unt 🧈", "Smântână", "Brânză rasă", "Clafoutis",
                "Ruladă de capră 🐐", "Cremă de brânză Madame Loik", "Brânza Turc", "Lapte condensat",
                "Crème entière", "Kiri", "Brânza proaspătă Faisselle", "Cașcaval 🧀",
                "Brânzică Făgăraș", "Smântână pentru frișcă", "Mascarpone", "Frișcă lichidă"
            ]),
            ("Carne", [
                "Carne vită/porc 🥩", "Găină 🐓", "Piept de pui 🧆🍗", "Cap de porc 🐷",
                "Picioare de porc 🍖", "Pulpe de pui 🐣", "Cârnați", "Carne tocată de vită",
                "Șuncă 🥓", "Ficaței de pui", "Carne tocată de porc"
            ]),
            ("Gospodărie", [
                "Detergent de vase 🫧", "Hârtie igienica 🧻", "Sacoșe 1L", "Rolă de hârtie 🧻",
                "Săpun", "Decolorant haine", "Lavete", "Balsam de rufe", "Spălător de sârmă",
                "Soluție WC", "Role scame", "Déboucher", "Javel", "Odorizant baie", "Hârtie de copt",
                "Saci gunoi - baie", "Șervețele nazale", "Degresant puternic", "Detergent haine 🫧",
                "Săpun lichid 🧴", "Calgon", "Bureți de vase", "Scobitori", "Folie alimentară",
                "Saci aspirator", "Kit îngrijire ghete 🥾"
            ]),
            ("Ingrijire personală", [
                "Deodorant Dana", "Capete periuță 🪥", "Parfum", "Gel de dus 🛀",
                "Șervețele umede", "Pastă de dinți 🪥🦷", "Lame de ras 🪒", "Șampon",
                "Bețișoare de urechi", "Lame de tuns - OneBlade"
            ]),
            ("Farmacie", [
                "Pentru gât", "Leucoplast", "Decasept", "Spirt", "Ibuprofen", "Iod"
            ]),
            ("Băuturi", [
                "Apă 💧", "Coca Cola 🥤", "Suc de fructe 🧃", "Capsule cafea ☕️",
                "Sprite", "Bere 🍺", "Vin 🍷"
            ]),
            ("Brutarie", [
                "Pâine 🍞", "Pâine feliată 🥪", "Biscuiți WASA 🍘", "Baghetă 🥖", "Lipii 🫓"
            ]),
            ("Pește", [
                "Crochete de cod 🍣🐟", "Conserve ton/somon", "Rillettes de thon", "Ton",
                "Somon afumat 🍣", "Pește 🎣", "Icre"
            ]),
            ("Cămară", [
                "Esență de vanilie", "Stafide", "Nuci", "Piper", "Zahăr cuburi",
                "Ulei de măsline 🫒", "Aluat patiserie", "Maioneză", "Orez 🍙",
                "Sos tomat", "Faină", "Zahăr", "Oțet", "Pesto", "Grâu Auchan 🌾",
                "Paste linguine", "Aluat pizza", "Pastă de tomate 🥫", "Filtru cană Brita",
                "Mălai", "Pateu mic", "Sare 🧂", "Ceai tata 🫖", "Paste coquillettes",
                "Ulei de floarea soarelui 🌻", "Zahăr vanilat", "Ciuperci borcan", "Ulei de cocos 🥥",
                "Drojdie", "Ceai negru", "Paste 🍝", "Zahăr pudră", "Roșii pasate",
                "Conservă fasole albe 🫘", "Hrișcă", "Conservă de roșii 🥫", "Pudră de chilli 🌶️",
                "Chimion 🫩", "Pesmet", "Scorțișoară", "Castraveți în oțet 🥒", "Muștar", "Sfeclă roșie cu hrean"
            ]),
            ("Dulciuri", [
                "Dulciuri 🍬", "Batoane Nakd", "Biscuiți capră", "Bucățele de ciocolată 🍫",
                "Ciocolată 🍫", "Înghețată 🍧🍦", "Sirop Agave", "Panettone", "Cereale 🥣"
            ]),
            ("De îmbrăcat", [
                "Șlapi", "Hanorac", "Pulover", "Pantaloni scurți"
            ]),
            ("Altele", [
                "Sită/plasă chiuvetă", "Bec congelator 40W E27", "Hârtie A4", "Folii dosar",
                "Markere whiteboard", "Farfurie adâncă", "Papuci medicali Dana"
            ])
        ]
        
        var itemsToAdd: [ShoppingItem] = []
        
        for (category, items) in itemsByCategory {
            for itemName in items {
                let item = ShoppingItem(
                    name: itemName,
                    quantity: 1,
                    unit: "buc",
                    category: category,
                    isChecked: true
                )
                itemsToAdd.append(item)
            }
        }
        
        storageService.addShoppingItems(itemsToAdd)
        fetchItems()  // This will sort automatically
    }
    
    func undo() {
        objectWillChange.send()
        undoRedoManager.undo()
        fetchItems()
        objectWillChange.send()
    }
    
    func redo() {
        objectWillChange.send()
        undoRedoManager.redo()
        fetchItems()
        objectWillChange.send()
    }
}
