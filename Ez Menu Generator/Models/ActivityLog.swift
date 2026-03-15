//
// ActivityLog.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Audit trail model for tracking all changes in household:
// - What action was performed (create, update, delete)
// - Who performed it (user reference)
// - When it happened (timestamp)
// - What changed (entity type and ID)
// - Additional details/notes
//
// MARK: - Usage
// - Logged automatically by services
// - Provides transparency for multi-user households
// - Helps with debugging and auditing
// - Can show activity history in UI
//
// MARK: - Action Types
// - createItem: Added new shopping item
// - updateItem: Modified shopping item
// - deleteItem: Removed shopping item
// - checkItem: Marked item as purchased
// - uncheckItem: Unmarked item as purchased
// - createList: Created shopping list
// - updateList: Modified shopping list
// - deleteList: Removed shopping list
// - addUser: Added user to household
// - removeUser: Removed user from household
// - updateUserRole: Changed user role
//
// MARK: - Relationships
// ActivityLog belongs to Household
// ActivityLog references user who performed action
//

import Foundation
import SwiftData

@Model
final class ActivityLog {
    @Attribute(.unique) var id: UUID
    var action: String  // createItem, updateItem, deleteItem, checkItem, etc.
    var entityType: String  // ShoppingItem, ShoppingList, HouseholdUser, etc.
    var entityId: UUID?  // ID of the entity being modified
    var entityName: String?  // Name of entity for display
    
    var userId: UUID  // Who performed the action
    var username: String  // Username for display (denormalized)
    
    var details: String?  // Additional context (e.g., what changed)
    var timestamp: Date
    
    init(
        id: UUID = UUID(),
        action: String,
        entityType: String,
        entityId: UUID? = nil,
        entityName: String? = nil,
        userId: UUID,
        username: String,
        details: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.action = action
        self.entityType = entityType
        self.entityId = entityId
        self.entityName = entityName
        self.userId = userId
        self.username = username
        self.details = details
        self.timestamp = timestamp
    }
    
    // Formatted description for display
    var displayDescription: String {
        let actionLabel = formatAction(action)
        if let entityName = entityName {
            return "\(username) \(actionLabel) '\(entityName)'"
        }
        return "\(username) \(actionLabel) \(entityType)"
    }
    
    // Helper to format action for display
    private func formatAction(_ action: String) -> String {
        switch action {
        case "createItem": return "a adăugat"
        case "updateItem": return "a modificat"
        case "deleteItem": return "a șters"
        case "checkItem": return "a bifat"
        case "uncheckItem": return "a debifat"
        case "createList": return "a creat"
        case "updateList": return "a actualizat"
        case "deleteList": return "a șters"
        case "addUser": return "a adăugat utilizator"
        case "removeUser": return "a eliminat utilizator"
        case "updateUserRole": return "a schimbat rolul"
        default: return action
        }
    }
}
