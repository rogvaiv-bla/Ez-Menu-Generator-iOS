//
// HouseholdManager.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Central manager for all household operations:
// - Create/read/update/delete households
// - Manage users within households (invite, remove, role changes)
// - Create/manage shopping lists
// - Add/edit/delete shopping items
// - Track all activities in ActivityLog
// - Permission checking based on user roles
//
// MARK: - Key Methods
// Household CRUD: createHousehold, updateHousehold, deleteHousehold, fetchHousehold
// User Management: addUserToHousehold, removeUserFromHousehold, changeUserRole
// Shopping Lists: createShoppingList, updateShoppingList, deleteShoppingList
// Shopping Items: addItemToList, updateItem, deleteItem, checkItem
// Activity Tracking: logActivity (automatic)
// Permission Checking: canUserAction (private helper)
//
// MARK: - Architecture
// MainActor for thread safety
// Uses SwiftData for persistence
// Automatic activity logging for all changes
// Permission validation on sensitive operations
//

import Foundation
import SwiftData
import Combine
import os.log

// Logging via system os_log

@MainActor
class HouseholdManager: ObservableObject {
    static let shared = HouseholdManager()
    
    @Published var currentHousehold: Household?
    @Published var currentUser: HouseholdUser?
    @Published var activities: [ActivityLog] = []
    @Published var isLoading = false
    
    var modelContainer: ModelContainer?
    var modelContext: ModelContext?
    private var membersSyncTimer: Timer?
    private var isSyncingMembers = false
    private var lastMembersSyncTime: Date?
    private var membersSyncFailureCount = 0
    private let membersSyncMaxFailures = 5  // Disable sync after 5 consecutive failures
    
    nonisolated init() {}
    
    func setupContainer(_ container: ModelContainer) {
        self.modelContainer = container
        self.modelContext = ModelContext(container)
        loadCurrentHouseholdIfNeeded()
        startMembersSync()
    }
    
    // MARK: - Household Operations
    
    func createHousehold(
        name: String,
        description: String? = nil,
        ownerUsername: String
    ) -> Household? {
        guard let context = modelContext else { return nil }
        
        let userId = UUID()
        let owner = HouseholdUser(
            id: userId,
            username: ownerUsername,
            role: .owner,
            joinedAt: Date()
        )
        
        let household = Household(
            name: name,
            description: description,
            ownerId: userId,
            users: [owner],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            context.insert(household)
            try context.save()
            
            // Log household creation
            logActivity(
                action: "createHousehold",
                entityType: "Household",
                entityId: household.id,
                entityName: household.name,
                userId: userId,
                username: ownerUsername,
                details: "Locuință creată"
            )
            
            self.currentHousehold = household
            self.currentUser = owner
            return household
        } catch {
            // log.error("Error creating household: \(error)")
            return nil
        }
    }
    
    func updateHousehold(_ household: Household) {
        guard let context = modelContext else { return }
        
        do {
            household.updatedAt = Date()
            try context.save()
        } catch {
            // log.error("Error updating household: \(error)")
        }
    }
    
    func deleteHousehold(_ household: Household) {
        guard let context = modelContext, let currentUser = currentUser else { return }
        
        // Permission check: only owner can delete
        guard currentUser.canDeleteHousehold else {
            // log.error("User not permitted to delete household")
            return
        }
        
        do {
            context.delete(household)
            try context.save()
            
            logActivity(
                action: "deleteHousehold",
                entityType: "Household",
                entityId: household.id,
                entityName: household.name,
                userId: currentUser.id,
                username: currentUser.username,
                details: "Locuință ștearsă"
            )
            
            self.currentHousehold = nil
        } catch {
            // log.error("Error deleting household: \(error)")
        }
    }
    
    // MARK: - User Management
    
    func addUserToHousehold(
        _ household: Household,
        username: String,
        email: String? = nil,
        role: HouseholdUser.UserRole = .member
    ) -> HouseholdUser? {
        guard let context = modelContext, let currentUser = currentUser else { return nil }
        
        // Permission check: only admin/owner can add users
        guard currentUser.canManageUsers else {
            // log.error("User not permitted to add members")
            return nil
        }
        
        // Check if user already exists
        if household.users.contains(where: { $0.username == username }) {
            // log.warning("User already in household")
            return nil
        }
        
        let newUser = HouseholdUser(
            username: username,
            email: email,
            role: role,
            joinedAt: Date()
        )
        
        do {
            household.addUser(newUser)
            try context.save()
            
            logActivity(
                action: "addUser",
                entityType: "HouseholdUser",
                entityId: newUser.id,
                entityName: newUser.username,
                userId: currentUser.id,
                username: currentUser.username,
                details: "Utilizator adăugat cu rol: \(role.rawValue)"
            )
            
            return newUser
        } catch {
            // log.error("Error adding user: \(error)")
            return nil
        }
    }
    
    func removeUserFromHousehold(_ household: Household, userId: UUID) {
        guard let context = modelContext, let currentUser = currentUser else { return }
        
        // Permission check
        guard currentUser.canManageUsers else {
            // log.error("User not permitted to remove members")
            return
        }
        
        // Can't remove owner
        if userId == household.ownerId {
            // log.error("Cannot remove household owner")
            return
        }
        
        do {
            let removedUser = household.users.first { $0.id == userId }
            household.removeUser(userId)
            try context.save()
            
            if let removedUser = removedUser {
                logActivity(
                    action: "removeUser",
                    entityType: "HouseholdUser",
                    entityId: userId,
                    entityName: removedUser.username,
                    userId: currentUser.id,
                    username: currentUser.username,
                    details: "Utilizator eliminat"
                )
            }
        } catch {
            // log.error("Error removing user: \(error)")
        }
    }
    
    func changeUserRole(
        _ household: Household,
        userId: UUID,
        newRole: HouseholdUser.UserRole
    ) {
        guard let context = modelContext, let currentUser = currentUser else { return }
        
        // Permission check: only owner can change roles
        guard currentUser.role == .owner else {
            // log.error("Only owner can change user roles")
            return
        }
        
        do {
            if let index = household.users.firstIndex(where: { $0.id == userId }) {
                let oldRole = household.users[index].role
                household.users[index].updatePermissionsForRole(newRole)
                try context.save()
                
                logActivity(
                    action: "updateUserRole",
                    entityType: "HouseholdUser",
                    entityId: userId,
                    entityName: household.users[index].username,
                    userId: currentUser.id,
                    username: currentUser.username,
                    details: "Rol schimbat de la \(oldRole.rawValue) la \(newRole.rawValue)"
                )
            }
        } catch {
            // log.error("Error changing user role: \(error)")
        }
    }
    
    // MARK: - Shopping List Operations
    
    func createShoppingList(
        name: String,
        description: String? = nil,
        in household: Household
    ) -> ShoppingListV2? {
        guard let context = modelContext, let currentUser = currentUser else { return nil }
        
        let shoppingList = ShoppingListV2(
            name: name,
            descriptionText: description,
            householdId: household.id,
            createdByUserId: currentUser.id,
            createdByUsername: currentUser.username,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            context.insert(shoppingList)
            household.shoppingLists.append(shoppingList)
            try context.save()
            
            logActivity(
                action: "createList",
                entityType: "ShoppingList",
                entityId: shoppingList.id,
                entityName: shoppingList.name,
                userId: currentUser.id,
                username: currentUser.username,
                details: "Liste de cumpărături creată"
            )
            
            return shoppingList
        } catch {
            // log.error("Error creating shopping list: \(error)")
            return nil
        }
    }
    
    func updateShoppingList(_ shoppingList: ShoppingListV2) {
        guard let context = modelContext else { return }

        do {
            shoppingList.updatedAt = Date()
            try context.save()
        } catch {
            // log.error("Error updating shopping list: \(error)")
        }
    }
    
    func deleteShoppingList(_ shoppingList: ShoppingListV2, from household: Household) {
        guard let context = modelContext, let currentUser = currentUser else { return }

        do {
            context.delete(shoppingList)
            household.shoppingLists.removeAll { $0.id == shoppingList.id }
            try context.save()
            
            logActivity(
                action: "deleteList",
                entityType: "ShoppingList",
                entityId: shoppingList.id,
                entityName: shoppingList.name,
                userId: currentUser.id,
                username: currentUser.username,
                details: "Liste de cumpărături ștearsă"
            )
        } catch {
            // log.error("Error deleting shopping list: \(error)")
        }
    }
    
    // MARK: - Shopping Item Operations
    
    func addItemToList(
        _ item: ShoppingItemV2,
        to shoppingList: ShoppingListV2
    ) {
        guard let context = modelContext, let currentUser = currentUser else { return }
        
        do {
            context.insert(item)
            try context.save()
            
            logActivity(
                action: "createItem",
                entityType: "ShoppingItem",
                entityId: item.id,
                entityName: item.name,
                userId: currentUser.id,
                username: currentUser.username,
                details: "\(item.quantity) \(item.unit) adăugat"
            )
        } catch {
            // log.error("Error adding item to list: \(error)")
        }
    }
    
    func updateItem(_ item: ShoppingItemV2) {
        guard let context = modelContext else { return }
        
        do {
            item.updatedAt = Date()
            try context.save()
        } catch {
            // log.error("Error updating item: \(error)")
        }
    }
    
    func deleteItem(_ itemId: UUID, itemName: String, from shoppingList: ShoppingListV2) {
        guard let context = modelContext, let currentUser = currentUser else { return }
        
        if let itemToDelete = shoppingList.items.first(where: { $0.id == itemId }) {
            do {
                context.delete(itemToDelete)
                try context.save()
                
                logActivity(
                    action: "deleteItem",
                    entityType: "ShoppingItem",
                    entityId: itemId,
                    entityName: itemName,
                    userId: currentUser.id,
                    username: currentUser.username,
                    details: "Element șters"
                )
            } catch {
                // log.error("Error deleting item: \(error)")
            }
        }
    }
    
    func checkItem(_ item: ShoppingItemV2, in shoppingList: ShoppingListV2) {
        guard let context = modelContext, let currentUser = currentUser else { return }
        
        do {
            item.isChecked.toggle()
            item.updatedAt = Date()
            
            if item.isChecked {
                item.checkedByUserId = currentUser.id
                item.checkedByUsername = currentUser.username
                item.checkedAt = Date()
            }
            
            try context.save()
            
            let action = item.isChecked ? "checkItem" : "uncheckItem"
            let actionText = item.isChecked ? "bifat" : "debifat"
            
            logActivity(
                action: action,
                entityType: "ShoppingItem",
                entityId: item.id,
                entityName: item.name,
                userId: currentUser.id,
                username: currentUser.username,
                details: "Element \(actionText)"
            )
        } catch {
            // log.error("Error checking item: \(error)")
        }
    }
    
    // MARK: - Activity Logging
    
    private func logActivity(
        action: String,
        entityType: String,
        entityId: UUID? = nil,
        entityName: String? = nil,
        userId: UUID,
        username: String,
        details: String? = nil
    ) {
        guard let context = modelContext, let household = currentHousehold else { return }
        
        let activityLog = ActivityLog(
            action: action,
            entityType: entityType,
            entityId: entityId,
            entityName: entityName,
            userId: userId,
            username: username,
            details: details,
            timestamp: Date()
        )
        
        do {
            context.insert(activityLog)
            household.activityLogs.append(activityLog)
            try context.save()
            
            // Update local activities
            activities.append(activityLog)
        } catch {
            // log.error("Error logging activity: \(error)")
        }
    }
    
    func fetchActivityLogs(for household: Household) {
        activities = household.activityLogs.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Session Management

    private func loadCurrentHouseholdIfNeeded() {
        guard currentHousehold == nil, let context = modelContext else {
            return
        }
        
        guard TokenStore.shared.isTokenValid() else {
            return
        }
        
        do {
            let descriptor = FetchDescriptor<Household>(sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse)
            ])
            let households = try context.fetch(descriptor)
            if let household = households.first {
                setCurrentHousehold(household)
            }
        } catch {
            // Error loading household
        }
    }

    func findHousehold(byInviteKey inviteKey: String) -> Household? {
        guard let context = modelContext else { return nil }
        let trimmedKey = inviteKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmedKey.isEmpty { return nil }

        do {
            let descriptor = FetchDescriptor<Household>()
            let households = try context.fetch(descriptor)

            if let uuid = UUID(uuidString: trimmedKey) {
                return households.first { $0.id == uuid }
            }

            return households.first {
                String($0.id.uuidString.prefix(8)).uppercased() == trimmedKey
            }
        } catch {
            // log.error("Error finding household by invite key: \(error)")
            return nil
        }
    }

    func joinHousehold(inviteKey: String, username: String) -> Household? {
        guard let context = modelContext else { return nil }
        guard let household = findHousehold(byInviteKey: inviteKey) else { return nil }

        if household.users.contains(where: { $0.username.caseInsensitiveCompare(username) == .orderedSame }) {
            return nil
        }

        let newUser = HouseholdUser(
            username: username,
            role: .member,
            joinedAt: Date()
        )

        do {
            household.addUser(newUser)
            try context.save()
            setCurrentHousehold(household)
            return household
        } catch {
            // log.error("Error joining household: \(error)")
            return nil
        }
    }

    /// Set current household (call after creation or join)
    func setCurrentHousehold(_ household: Household) {
        self.currentHousehold = household
        
        if let owner = household.getOwner() {
            self.currentUser = owner
        } else if !household.users.isEmpty {
            self.currentUser = household.users.first
        }
        
        startMembersSync()
    }
    
    /// Clear current household (used when token expires or auth fails)
    func clearCurrentHousehold() {
        // log.warning("🔑 Clearing household due to token invalidation")
        currentHousehold = nil
        currentUser = nil
        stopMembersSync()
    }
    
    /// Create household with provided ModelContext (for onboarding)
    func createHousehold(
        name: String,
        createdBy username: String,
        in context: ModelContext
    ) -> Household? {
        let userId = UUID()
        let owner = HouseholdUser(
            id: userId,
            username: username,
            role: .owner,
            joinedAt: Date()
        )
        
        let household = Household(
            name: name,
            description: nil,
            ownerId: userId,
            users: [owner],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            context.insert(household)
            self.currentHousehold = household
            self.currentUser = owner
            return household
        }
    }
    
    func applyRemoteSession(_ session: SupabaseSession, in context: ModelContext) {
        let householdId = session.household.id
        let userId = session.user.id
        let role = mapRole(session.user.role)

        let household = fetchHousehold(by: householdId, in: context)
            ?? Household(
                id: householdId,
                name: session.household.name,
                ownerId: session.household.ownerId,
                inviteKey: session.household.inviteKey,
                createdAt: Date(),
                updatedAt: Date()
            )

        household.name = session.household.name
        household.ownerId = session.household.ownerId
        household.inviteKey = session.household.inviteKey
        household.updatedAt = Date()

        if household.users.first(where: { $0.id == userId }) == nil {
            let newUser = HouseholdUser(
                id: userId,
                username: session.user.username,
                role: role,
                joinedAt: Date(),
                updatedAt: Date()
            )
            household.addUser(newUser)
        } else if let index = household.users.firstIndex(where: { $0.id == userId }) {
            household.users[index].username = session.user.username
            household.users[index].updatePermissionsForRole(role)
            household.users[index].updatedAt = Date()
        }

        context.insert(household)
        do {
            try context.save()
        } catch {
            // log.error("Error saving remote session: \(error)")
        }

        currentHousehold = household
        currentUser = household.users.first { $0.id == userId }

        startMembersSync()
        Task {
            await refreshMembersFromSupabase()
        }
    }

    func refreshMembersFromSupabase() async {
        // Prevent concurrent syncs
        guard !isSyncingMembers else { 
            // log.debug("⏸️  Members sync already in progress, skipping")
            return 
        }
        
        // Throttle: only sync if at least 10 seconds have passed since last sync
        if let lastSync = lastMembersSyncTime, Date().timeIntervalSince(lastSync) < 10 {
            // log.debug("⏱️  Members sync throttled (last sync: \(Int(Date().timeIntervalSince(lastSync)))s ago)")
            return
        }
        
        guard let context = modelContext, let household = currentHousehold else { 
            // log.debug("⚠️  Can't sync members: context or household not available")
            return 
        }
        
        // log.debug("🔄 Starting members sync for household: \(household.name)")
        await refreshMembersFromSupabase(household: household, context: context)
    }

    private func startMembersSync() {
        membersSyncTimer?.invalidate()
        guard currentHousehold != nil, modelContext != nil else {
            return
        }

        membersSyncTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let household = self.currentHousehold,
                      let context = self.modelContext else { return }
                await self.refreshMembersFromSupabase(household: household, context: context)
            }
        }
    }

    private func stopMembersSync() {
        membersSyncTimer?.invalidate()
        membersSyncTimer = nil
    }

    private func refreshMembersFromSupabase(household: Household, context: ModelContext) async {
        isSyncingMembers = true
        defer { isSyncingMembers = false }
        
        do {
            let members = try await SupabaseHouseholdService.shared.fetchMembers(householdId: household.id)
            lastMembersSyncTime = Date()
            membersSyncFailureCount = 0  // Reset failure count on success
            
            await MainActor.run {
                for member in members {
                    if let existing = household.users.first(where: { $0.id == member.id }) {
                        existing.username = member.username
                        existing.updatePermissionsForRole(mapRole(member.role))
                        existing.updatedAt = Date()
                    } else {
                        let newUser = HouseholdUser(
                            id: member.id,
                            username: member.username,
                            role: mapRole(member.role),
                            joinedAt: Date(),
                            updatedAt: Date()
                        )
                        household.addUser(newUser)
                    }
                }
                household.updatedAt = Date()
                do {
                    try context.save()
                } catch {
                    // log.error("Error updating members from Supabase: \(error)")
                }
            }
        } catch {
            membersSyncFailureCount += 1
            let failureCount = membersSyncFailureCount
            let maxFailures = membersSyncMaxFailures
            // log.error("❌ Supabase members sync failed (\(failureCount)/\(maxFailures)): \(error.localizedDescription)")
            
            // Stop syncing if too many failures
            if failureCount >= maxFailures {
                // log.error("🛑 Disabling members sync after \(maxFailures) failures")
                stopMembersSync()
            }
        }
    }

    private func fetchHousehold(by id: UUID, in context: ModelContext) -> Household? {
        let descriptor = FetchDescriptor<Household>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    private func mapRole(_ role: String) -> HouseholdUser.UserRole {
        switch role.lowercased() {
        case "owner": return .owner
        case "admin": return .admin
        case "guest": return .guest
        default: return .member
        }
    }
    
    // MARK: - Error Handling

    enum LeaveHouseholdError: LocalizedError {
        case noActiveHousehold
        case ownerCannotLeaveWithMembers

        var errorDescription: String? {
            switch self {
            case .noActiveHousehold:
                return "Nu există household activ."
            case .ownerCannotLeaveWithMembers:
                return "Owner-ul nu poate părăsi household-ul cât timp există alți membri."
            }
        }
    }

    func leaveCurrentHousehold() throws {
        guard let context = modelContext,
              let household = currentHousehold,
              let user = currentUser else {
            throw LeaveHouseholdError.noActiveHousehold
        }

        let otherMembers = household.users.filter { $0.id != user.id }
        if user.role == .owner, !otherMembers.isEmpty {
            throw LeaveHouseholdError.ownerCannotLeaveWithMembers
        }

        do {
            if user.role == .owner, otherMembers.isEmpty {
                context.delete(household)
            } else {
                household.removeUser(user.id)
            }
            try context.save()
        } catch {
            // log.error("Error leaving household: \(error)")
            throw error
        }

        currentHousehold = nil
        currentUser = nil
        TokenStore.shared.clear()
        stopMembersSync()
    }
}
