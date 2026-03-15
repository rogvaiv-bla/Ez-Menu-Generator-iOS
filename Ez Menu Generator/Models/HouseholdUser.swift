//
// HouseholdUser.swift
// Ez Menu Generator
//
// MARK: - Purpose
// User model within a household:
// - User credentials and profile
// - Role-based access control (owner, admin, member, guest)
// - Permission flags for specific actions
// - Timestamps for audit trail
//
// MARK: - Roles
// - owner: Full access, can manage household and users
// - admin: Can manage shopping lists and users (no household delete)
// - member: Can create/edit own lists and items
// - guest: Read-only access
//
// MARK: - Usage
// - Created when user joins household
// - Contains role for permission checking
// - Tracks when user was added and last active
//
// MARK: - Relationships
// HouseholdUser belongs to Household
// HouseholdUser can have ActivityLogs
//

import Foundation
import SwiftData

@Model
final class HouseholdUser {
    @Attribute(.unique) var id: UUID
    var username: String
    var email: String?
    var roleRawValue: String = "Membru"  // Store as String for SwiftData compatibility
    
    // Permissions
    var canEditShoppingList: Bool = true
    var canDeleteItems: Bool = true
    var canManageUsers: Bool = false  // Only admin/owner
    var canDeleteHousehold: Bool = false  // Only owner
    
    var isActive: Bool = true
    var joinedAt: Date
    var updatedAt: Date
    var lastActiveAt: Date?
    
    enum UserRole: String, Codable, CaseIterable {
        case owner = "Proprietar"
        case admin = "Administrator"
        case member = "Membru"
        case guest = "Oaspete"
        
        var priority: Int {
            switch self {
            case .owner: return 4
            case .admin: return 3
            case .member: return 2
            case .guest: return 1
            }
        }
    }
    
    // Computed property to convert between String and Enum
    var role: UserRole {
        get {
            UserRole(rawValue: roleRawValue) ?? .member
        }
        set {
            roleRawValue = newValue.rawValue
        }
    }
    
    init(
        id: UUID = UUID(),
        username: String,
        email: String? = nil,
        role: UserRole = .member,
        joinedAt: Date = Date(),
        updatedAt: Date = Date(),
        lastActiveAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.roleRawValue = role.rawValue  // Store as String for SwiftData
        self.joinedAt = joinedAt
        self.updatedAt = updatedAt
        self.lastActiveAt = lastActiveAt
        
        // Set permissions based on role
        switch role {
        case .owner:
            self.canEditShoppingList = true
            self.canDeleteItems = true
            self.canManageUsers = true
            self.canDeleteHousehold = true
        case .admin:
            self.canEditShoppingList = true
            self.canDeleteItems = true
            self.canManageUsers = true
            self.canDeleteHousehold = false
        case .member:
            self.canEditShoppingList = true
            self.canDeleteItems = true
            self.canManageUsers = false
            self.canDeleteHousehold = false
        case .guest:
            self.canEditShoppingList = false
            self.canDeleteItems = false
            self.canManageUsers = false
            self.canDeleteHousehold = false
        }
    }
    
    // Update permissions based on role
    func updatePermissionsForRole(_ newRole: UserRole) {
        self.role = newRole
        switch newRole {
        case .owner:
            canEditShoppingList = true
            canDeleteItems = true
            canManageUsers = true
            canDeleteHousehold = true
        case .admin:
            canEditShoppingList = true
            canDeleteItems = true
            canManageUsers = true
            canDeleteHousehold = false
        case .member:
            canEditShoppingList = true
            canDeleteItems = true
            canManageUsers = false
            canDeleteHousehold = false
        case .guest:
            canEditShoppingList = false
            canDeleteItems = false
            canManageUsers = false
            canDeleteHousehold = false
        }
        updatedAt = Date()
    }
}
