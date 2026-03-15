//
// ShoppingItem.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Shopping list item representing aggregated ingredients:
// - Name, quantity (Int), unit (buc/g/kg/l)
// - Category for organization
// - Checkbox status for tracking purchases
//
// MARK: - Usage
// - Generated from menu via MenuEditorViewModel.generateShoppingList()
// - Displayed in ShoppingListView
// - Editable quantities in AddShoppingItemView/EditShoppingItemView
//

import Foundation
import SwiftData

@Model
final class ShoppingItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var isChecked: Bool = false
    var price: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: String = "buc",
        category: String = "Diverse",
        isChecked: Bool = false,
        price: Double? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.price = price
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
