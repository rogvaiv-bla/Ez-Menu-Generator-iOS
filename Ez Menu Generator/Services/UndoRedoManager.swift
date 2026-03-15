import Foundation
import Combine
import SwiftData
import os.log

// Logging via system os_log

@MainActor
class UndoRedoManager: ObservableObject {
    @Published var canUndo = false
    @Published var canRedo = false
    
    private var undoStack: [UndoAction] = []
    private var redoStack: [UndoAction] = []
    
    nonisolated init() {}
    
    enum UndoableAction {
        case deleteRecipe(RecipeSnapshot)
        case deleteMenu(MenuSnapshot)
        case deleteShoppingItem(ShoppingItemSnapshot)
        case addRecipe(RecipeSnapshot)
        case addMenu(MenuSnapshot)
        case addShoppingItem(ShoppingItemSnapshot)
    }
    
    struct UndoAction {
        let action: UndoableAction
        let timestamp: Date
        
        var description: String {
            switch action {
            case .deleteRecipe(let snapshot):
                return "Ștergere rețetă: \(snapshot.name)"
            case .deleteMenu(let snapshot):
                return "Ștergere meniu: \(snapshot.name)"
            case .deleteShoppingItem(let snapshot):
                return "Ștergere item: \(snapshot.name)"
            case .addRecipe(let snapshot):
                return "Adăugare rețetă: \(snapshot.name)"
            case .addMenu(let snapshot):
                return "Adăugare meniu: \(snapshot.name)"
            case .addShoppingItem(let snapshot):
                return "Adăugare item: \(snapshot.name)"
            }
        }
    }
    
    let storageService = StorageService.shared
    
    func recordAction(_ action: UndoableAction) {
        undoStack.append(UndoAction(action: action, timestamp: Date()))
        redoStack.removeAll()
        updateButtons()
        
        // Keep max 20 undo actions
        if undoStack.count > 20 {
            undoStack.removeFirst()
        }
    }
    
    private func getActionDescription(_ action: UndoableAction) -> String {
        switch action {
        case .deleteRecipe(let snapshot):
            return "Delete Recipe: \(snapshot.name)"
        case .deleteMenu(let snapshot):
            return "Delete Menu: \(snapshot.name)"
        case .deleteShoppingItem(let snapshot):
            return "Delete Item: \(snapshot.name)"
        case .addRecipe(let snapshot):
            return "Add Recipe: \(snapshot.name)"
        case .addMenu(let snapshot):
            return "Add Menu: \(snapshot.name)"
        case .addShoppingItem(let snapshot):
            return "Add Item: \(snapshot.name)"
        }
    }
    
    func undo() {
        guard let lastAction = undoStack.popLast() else {
            // logger.warning("⚠️ Undo called but stack is empty")
            return
        }
        
        // logger.info("↶ Undoing action")
        
        switch lastAction.action {
        case .deleteRecipe(let snapshot):
            // logger.info("🔄 Restoring recipe: \(snapshot.name)")
            storageService.addRecipe(snapshot.toRecipe())
        case .deleteMenu(let snapshot):
            // logger.info("🔄 Restoring menu: \(snapshot.name)")
            storageService.addMenuFromSnapshot(snapshot)
            // logger.info("✅ Menu restored with all recipes")
        case .deleteShoppingItem(let snapshot):
            // logger.info("🔄 Restoring item: \(snapshot.name)")
            storageService.addShoppingItem(snapshot.toShoppingItem())
        case .addRecipe(let snapshot):
            // logger.info("🔄 Deleting recipe: \(snapshot.name)")
            storageService.deleteRecipeById(snapshot.id)
        case .addMenu(let snapshot):
            // logger.info("🔄 Deleting menu: \(snapshot.name)")
            storageService.deleteMenuById(snapshot.id)
        case .addShoppingItem(let snapshot):
            // logger.info("🔄 Deleting item: \(snapshot.name)")
            storageService.deleteShoppingItemById(snapshot.id)
        }
        
        redoStack.append(lastAction)
        updateButtons()
        // logger.info("✅ Undo completed")
    }
    
    func redo() {
        guard let lastAction = redoStack.popLast() else {
            // logger.warning("⚠️ Redo called but stack is empty")
            return
        }
        
        // logger.info("↷ Redoing action")
        
        switch lastAction.action {
        case .deleteRecipe(let snapshot):
            // logger.info("🔄 Deleting recipe: \(snapshot.name)")
            storageService.deleteRecipeById(snapshot.id)
        case .deleteMenu(let snapshot):
            // logger.info("🔄 Deleting menu: \(snapshot.name)")
            storageService.deleteMenuById(snapshot.id)
            // logger.info("✅ Menu deletion completed")
        case .deleteShoppingItem(let snapshot):
            // logger.info("🔄 Deleting item: \(snapshot.name)")
            storageService.deleteShoppingItemById(snapshot.id)
        case .addRecipe(let snapshot):
            // logger.info("🔄 Restoring recipe: \(snapshot.name)")
            storageService.addRecipe(snapshot.toRecipe())
        case .addMenu(let snapshot):
            // logger.info("🔄 Restoring menu: \(snapshot.name)")
            storageService.addMenuFromSnapshot(snapshot)
            // logger.info("✅ Menu restored with all recipes")
        case .addShoppingItem(let snapshot):
            // logger.info("🔄 Restoring item: \(snapshot.name)")
            storageService.addShoppingItem(snapshot.toShoppingItem())
        }
        
        undoStack.append(lastAction)
        updateButtons()
        // logger.info("✅ Redo completed")
    }
    
    private func updateButtons() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        // logger.info("🔘 Buttons updated: canUndo=\(self.canUndo), canRedo=\(self.canRedo)")
    }
    
    func getUndoDescription() -> String? {
        undoStack.last?.description
    }
    
    func getRedoDescription() -> String? {
        redoStack.last?.description
    }
}
