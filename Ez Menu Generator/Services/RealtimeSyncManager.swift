//
// RealtimeSyncManager.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Manages real-time synchronization and presence tracking
// - Subscribe to list/item changes
// - Broadcast updates to UI
// - Track "who's editing now"
// - Handle incoming conflicts
//

import Foundation
import Combine
import SwiftData

@MainActor
class RealtimeSyncManager: ObservableObject {
    static let shared = RealtimeSyncManager()
    
    @Published var activeEditors: [UUID: RealtimePresence] = [:]  // userId -> presence
    @Published var listUpdates: [UUID: ShoppingListV2] = [:]       // listId -> updated list
    @Published var itemUpdates: [UUID: ShoppingItemV2] = [:]       // itemId -> updated item
    @Published var incomingConflicts: [UUID] = []                  // itemIds with conflicts
    
    private var modelContext: ModelContext?
    private var subscriptions: [AnyCancellable] = []
    private var presenceTimers: [UUID: Timer] = [:]
    
    nonisolated init() {}
    
    func setupContainer(_ container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }
    
    // MARK: - Presence Tracking
    
    /// Broadcast user presence (editing list)
    func setEditingList(userId: UUID, username: String, householdId: UUID, listId: UUID) {
        let presence = RealtimePresence(
            userId: userId,
            username: username,
            householdId: householdId,
            listId: listId,
            status: "editing_list",
            lastActiveAt: Date(),
            expiresAt: Date().addingTimeInterval(30)  // Expire after 30 seconds
        )
        
        updatePresence(presence)
        schedulePresenceExpiry(userId, expiresAt: presence.expiresAt)
        
        // Broadcast to other users
        broadcastPresence(presence)
        print("📍 Broadcasting: \(username) editing list")
    }
    
    /// Broadcast user presence (editing item - short)
    func setEditingItem(userId: UUID, username: String, householdId: UUID, listId: UUID, itemId: UUID) {
        let presence = RealtimePresence(
            userId: userId,
            username: username,
            householdId: householdId,
            listId: listId,
            status: "editing_item:\(itemId)",
            lastActiveAt: Date(),
            expiresAt: Date().addingTimeInterval(2)  // Expire after 2 seconds
        )
        
        updatePresence(presence)
        schedulePresenceExpiry(userId, expiresAt: presence.expiresAt)
        
        print("📍 Broadcasting: \(username) editing item")
    }
    
    /// Broadcast item checked
    func broadcastItemChecked(itemId: UUID, username: String, householdId: UUID, listId: UUID) {
        let presence = RealtimePresence(
            userId: UUID(),  // Anonymous for check notifications
            username: username,
            householdId: householdId,
            listId: listId,
            status: "checked_item:\(itemId)",
            lastActiveAt: Date(),
            expiresAt: Date().addingTimeInterval(1)
        )
        
        broadcastPresence(presence)
        print("✅ Broadcasting: \(username) checked item")
    }
    
    // MARK: - Subscriptions
    
    /// Subscribe to list changes
    func subscribeToList(_ listId: UUID) {
        // TODO: Connect to real Supabase Realtime
        // For now, simulate with timer
        print("🔗 Subscribed to list changes: \(listId)")
    }
    
    /// Subscribe to item changes
    func subscribeToItem(_ itemId: UUID) {
        // TODO: Connect to real Supabase Realtime
        print("🔗 Subscribed to item changes: \(itemId)")
    }
    
    /// Subscribe to household presence
    func subscribeToPresence(householdId: UUID) {
        // TODO: Connect to real Supabase Realtime
        print("🔗 Subscribed to presence: \(householdId)")
    }
    
    // MARK: - Incoming Updates
    
    /// Process incoming item update
    func processItemUpdate(_ remoteItem: ShoppingItemV2, localItem: ShoppingItemV2?) {
        if let local = localItem {
            // Resolve conflict
            let (winner, _) = resolveConflict(
                local: local,
                remote: remoteItem
            )
            
            if winner == "remote" {
                // Apply remote changes
                itemUpdates[remoteItem.id] = remoteItem
                print("🔄 Applied remote update for item: \(remoteItem.name)")
            } else {
                // Keep local
                itemUpdates[remoteItem.id] = local
                print("⚠️  Kept local version (conflict)")
                incomingConflicts.append(remoteItem.id)
            }
        } else {
            // No local version - apply remote
            itemUpdates[remoteItem.id] = remoteItem
            print("➕ Added remote item: \(remoteItem.name)")
        }
    }
    
    /// Process incoming list update
    func processListUpdate(_ remoteList: ShoppingListV2, localList: ShoppingListV2?) {
        if let _ = localList {
            // Merge list updates (simple: remote wins for metadata)
            listUpdates[remoteList.id] = remoteList
            print("🔄 Updated list: \(remoteList.name)")
        } else {
            listUpdates[remoteList.id] = remoteList
            print("➕ Added remote list: \(remoteList.name)")
        }
    }
    
    /// Process incoming presence
    func processPresence(_ presence: RealtimePresence) {
        if presence.isActive {
            activeEditors[presence.userId] = presence
            print("👤 Active: \(presence.username)")
            schedulePresenceExpiry(presence.userId, expiresAt: presence.expiresAt)
        } else {
            activeEditors.removeValue(forKey: presence.userId)
            print("👤 Inactive: \(presence.username)")
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(local: ShoppingItemV2, remote: ShoppingItemV2) -> (winner: String, data: ShoppingItemV2) {
        // Last-write-wins with version tracking
        
        if local.serverVersion > remote.serverVersion {
            print("📊 Local version newer (\(local.serverVersion) > \(remote.serverVersion))")
            return ("local", local)
        } else if remote.serverVersion > local.serverVersion {
            print("📊 Remote version newer (\(remote.serverVersion) > \(local.serverVersion))")
            return ("remote", remote)
        } else {
            // Same version - compare timestamps
            if local.updatedAt > remote.updatedAt {
                print("📊 Local timestamp newer")
                return ("local", local)
            } else {
                print("📊 Remote timestamp newer")
                return ("remote", remote)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func updatePresence(_ presence: RealtimePresence) {
        activeEditors[presence.userId] = presence
    }
    
    private func schedulePresenceExpiry(_ userId: UUID, expiresAt: Date) {
        // Cancel existing timer for this user
        presenceTimers[userId]?.invalidate()
        
        let delay = expiresAt.timeIntervalSinceNow
        guard delay > 0 else {
            activeEditors.removeValue(forKey: userId)
            return
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.activeEditors.removeValue(forKey: userId)
                self.presenceTimers.removeValue(forKey: userId)
            }
        }
        
        presenceTimers[userId] = timer
    }
    
    private func broadcastPresence(_ presence: RealtimePresence) {
        // TODO: Send to Supabase Realtime
        print("📡 Broadcasting presence: \(presence.username) - \(presence.status)")
    }
}
