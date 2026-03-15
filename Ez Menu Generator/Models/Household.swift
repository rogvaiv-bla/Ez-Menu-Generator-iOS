//
// Household.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Household model representing a shared living space with multiple users:
// - Household metadata (name, created date)
// - Owner user reference
// - Members collection (users in the household)
// - Timestamps for audit trail
//
// MARK: - Usage
// - Root aggregate for multi-user collaboration
// - Contains Users who can manage shopping lists
// - Tracks creation and last modification
// - One household per living space (apartment, house, etc.)
//
// MARK: - Relationships
// Household (1) -> Users (many)
// Household (1) -> ShoppingLists (many)
// Household (1) -> ActivityLogs (many)
//

import Foundation
import SwiftData

@Model
final class Household {
    @Attribute(.unique) var id: UUID
    var name: String  // e.g., "Apartament Eduard", "Casa Familia"
    var descriptionText: String?  // Renamed to avoid conflict with CustomStringConvertible
    
    @Relationship(deleteRule: .cascade) var users: [HouseholdUser] = []
    @Relationship(deleteRule: .cascade) var shoppingLists: [ShoppingListV2] = []
    @Relationship(deleteRule: .cascade) var activityLogs: [ActivityLog] = []
    
    var ownerId: UUID  // Reference to the owner user
    var inviteKey: UUID?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        ownerId: UUID = UUID(),
        inviteKey: UUID? = nil,
        users: [HouseholdUser] = [],
        shoppingLists: [ShoppingListV2] = [],
        activityLogs: [ActivityLog] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = description
        self.ownerId = ownerId
        self.inviteKey = inviteKey
        self.users = users
        self.shoppingLists = shoppingLists
        self.activityLogs = activityLogs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Helper to get owner user
    func getOwner() -> HouseholdUser? {
        users.first { $0.id == ownerId }
    }
    
    // Helper to add user to household
    func addUser(_ user: HouseholdUser) {
        if !users.contains(where: { $0.id == user.id }) {
            users.append(user)
            updatedAt = Date()
        }
    }
    
    // Helper to remove user
    func removeUser(_ userId: UUID) {
        users.removeAll { $0.id == userId }
        updatedAt = Date()
    }
}
