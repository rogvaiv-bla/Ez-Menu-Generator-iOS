//
// ShoppingListV2.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Shopping list model with offline-first, realtime sync, conflict resolution
// - Belongs to a Household
// - Contains ShoppingItems with categories (RO/EN mapping)
// - Tracks offline changes and sync status
// - Conflict resolution with version tracking
//

import Foundation
import SwiftData

// MARK: - Category Mapping (RO ↔ EN)

enum ProductCategory: String, CaseIterable, Codable {
    case meat = "Meat"
    case fish = "Fish"
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case dairy = "Dairy"
    case bread = "Bread"
    case pasta = "Pasta"
    case rice = "Rice"
    case oilSpices = "Oil & Spices"
    case beverages = "Beverages"
    case desserts = "Desserts & Snacks"
    case other = "Other"
    
    var displayName: String {
        switch self {
        case .meat: return "Carne"
        case .fish: return "Pește"
        case .vegetables: return "Legume"
        case .fruits: return "Fructe"
        case .dairy: return "Lactate"
        case .bread: return "Pâine"
        case .pasta: return "Paste"
        case .rice: return "Orez"
        case .oilSpices: return "Ulei & Condimente"
        case .beverages: return "Băuturi"
        case .desserts: return "Deserturi & Snacks"
        case .other: return "Alte"
        }
    }
    
    static var allDisplayNames: [String] {
        self.allCases.map { $0.displayName }
    }
    
    static func fromDisplay(_ name: String) -> ProductCategory {
        self.allCases.first { $0.displayName == name } ?? .other
    }
}

// MARK: - ShoppingListV2 (Updated)

@Model
final class ShoppingListV2 {
    @Attribute(.unique) var id: UUID
    var name: String
    var descriptionText: String?
    
    @Relationship(deleteRule: .cascade) var items: [ShoppingItemV2] = []
    @Relationship(deleteRule: .cascade) var history: [ShoppingListHistory] = []
    
    var householdId: UUID
    var createdByUserId: UUID
    var createdByUsername: String
    
    var status: String = "active"  // "active", "archived", "completed"
    
    // NEW: Offline & Sync tracking
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var syncConflict: String?  // nil | "remote_newer" | "local_newer"
    
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String? = nil,
        householdId: UUID,
        createdByUserId: UUID,
        createdByUsername: String,
        status: String = "active",
        items: [ShoppingItemV2] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.householdId = householdId
        self.createdByUserId = createdByUserId
        self.createdByUsername = createdByUsername
        self.status = status
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDirty = false
        self.lastSyncedAt = Date()
    }
    
    var checkedCount: Int { items.filter { $0.isChecked }.count }
    var totalCount: Int { items.count }
    var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(checkedCount) / Double(totalCount) * 100
    }
    var allItemsChecked: Bool { totalCount > 0 && checkedCount == totalCount }
    
    // Group items by category
    var itemsByCategory: [String: [ShoppingItemV2]] {
        Dictionary(grouping: items) { $0.category }
    }
    
    var categoriesSorted: [String] {
        itemsByCategory.keys.sorted { 
            // Put categories with unchecked items first
            let aHasUnchecked = itemsByCategory[$0]?.contains { !$0.isChecked } ?? false
            let bHasUnchecked = itemsByCategory[$1]?.contains { !$0.isChecked } ?? false
            return aHasUnchecked && !bHasUnchecked
        }
    }
}

// MARK: - ShoppingItemV2 (Updated)

@Model
final class ShoppingItemV2 {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var category: String  // English internal (Meat, Vegetables, etc.)
    
    var isChecked: Bool = false
    var checkedByUserId: UUID?
    var checkedByUsername: String?
    var checkedAt: Date?
    
    var price: Double?
    var notes: String?
    var sortOrder: Int = 0
    
    var createdByUserId: UUID
    var createdByUsername: String
    
    // NEW: Offline & Sync tracking
    var isDirty: Bool = false
    var lastModifiedLocally: Date?
    var serverVersion: Int = 0
    var syncStatus: String = "synced"  // "synced", "pending", "conflict"
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: String = "buc",
        category: String = "Other",
        isChecked: Bool = false,
        price: Double? = nil,
        notes: String? = nil,
        createdByUserId: UUID,
        createdByUsername: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.price = price
        self.notes = notes
        self.createdByUserId = createdByUserId
        self.createdByUsername = createdByUsername
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isDirty = false
        self.syncStatus = "synced"
        self.serverVersion = 0
    }
}

// MARK: - ShoppingListHistory (New - Audit trail)

@Model
final class ShoppingListHistory {
    @Attribute(.unique) var id: UUID
    var listId: UUID
    var householdId: UUID
    
    var action: String
    var itemId: UUID?
    var itemName: String?
    
    var userId: UUID
    var username: String
    
    var oldValue: String?
    var newValue: String?
    
    var timestamp: Date
    
    init(
        id: UUID = UUID(),
        listId: UUID,
        householdId: UUID,
        action: String,
        itemId: UUID? = nil,
        itemName: String? = nil,
        userId: UUID,
        username: String,
        oldValue: String? = nil,
        newValue: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.listId = listId
        self.householdId = householdId
        self.action = action
        self.itemId = itemId
        self.itemName = itemName
        self.userId = userId
        self.username = username
        self.oldValue = oldValue
        self.newValue = newValue
        self.timestamp = timestamp
    }
    
    var displayMessage: String {
        switch action {
        case "item_added":
            return "\(username) added \(itemName ?? "item")"
        case "item_checked":
            return "\(username) checked \(itemName ?? "item")"
        case "item_unchecked":
            return "\(username) unchecked \(itemName ?? "item")"
        case "item_removed":
            return "\(username) removed \(itemName ?? "item")"
        case "list_renamed":
            return "\(username) renamed list to \(newValue ?? "list")"
        default:
            return "\(username) updated list"
        }
    }
}

// MARK: - SyncQueueItem (New - Offline tracking)

@Model
final class SyncQueueItem {
    @Attribute(.unique) var id: UUID
    var householdId: UUID
    
    var operation: String
    var entityType: String
    var entityId: UUID
    
    var status: String = "pending"
    var payload: String
    
    var conflictReason: String?
    var serverVersion: Int = 0
    var localVersion: Int = 0
    
    var retryCount: Int = 0
    var maxRetries: Int = 3
    var lastRetryAt: Date?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        householdId: UUID,
        operation: String,
        entityType: String,
        entityId: UUID,
        payload: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.householdId = householdId
        self.operation = operation
        self.entityType = entityType
        self.entityId = entityId
        self.payload = payload
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    var shouldRetry: Bool {
        retryCount < maxRetries
    }
}

// MARK: - RealtimePresence (Editing indicator)

struct RealtimePresence: Codable {
    let userId: UUID
    let username: String
    let householdId: UUID
    let listId: UUID?
    
    let status: String
    let lastActiveAt: Date
    let expiresAt: Date
    
    var isActive: Bool {
        Date() < expiresAt
    }
    
    var displayMessage: String {
        switch status {
        case "editing_list":
            return "\(username) is editing"
        case let status where status.starts(with: "editing_item:"):
            return "\(username) is editing an item"
        default:
            return "\(username) is online"
        }
    }
}
