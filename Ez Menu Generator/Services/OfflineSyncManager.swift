//
// OfflineSyncManager.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Manages offline-first synchronization with conflict resolution
// - Track pending changes in SyncQueue
// - Auto-sync when online
// - Conflict resolution (last-write-wins with version tracking)
// - Retry logic with exponential backoff
//

import Foundation
import Combine
import SwiftData

@MainActor
class OfflineSyncManager: ObservableObject {
    static let shared = OfflineSyncManager()
    
    @Published var pendingChanges: [SyncQueueItem] = []
    @Published var hasConflicts: [UUID] = []  // itemIds with conflicts
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false
    
    private var modelContext: ModelContext?
    private var networkMonitor: NetworkMonitor?
    private var syncTimer: Timer?
    
    nonisolated init() {}
    
    func setupContainer(_ container: ModelContainer) {
        self.modelContext = ModelContext(container)
        self.networkMonitor = NetworkMonitor { [weak self] isOnline in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isOnline = isOnline
                if isOnline {
                    await self.syncPendingChanges()
                }
            }
        }
    }
    
    // MARK: - Queue Management
    
    /// Add item to sync queue (offline operation)
    func queueOperation(
        householdId: UUID,
        operation: String,  // "item_create", "item_update", "item_check", etc.
        entityType: String,
        entityId: UUID,
        payload: String
    ) {
        guard let context = modelContext else { return }
        
        let queueItem = SyncQueueItem(
            householdId: householdId,
            operation: operation,
            entityType: entityType,
            entityId: entityId,
            payload: payload
        )
        
        context.insert(queueItem)
        try? context.save()
        
        // Update UI state (already on @MainActor)
        self.pendingChanges.append(queueItem)
        
        // Try to sync immediately if online
        if isOnline {
            Task {
                await syncPendingChanges()
            }
        }
    }
    
    // MARK: - Sync Operations
    
    /// Synchronize all pending changes
    func syncPendingChanges() async {
        guard let context = modelContext else { return }
        
        // Fetch pending items from database
        var descriptor = FetchDescriptor<SyncQueueItem>()
        descriptor.predicate = #Predicate { $0.status == "pending" || $0.status == "syncing" }
        
        guard let pending = try? context.fetch(descriptor), !pending.isEmpty else {
            print("✅ No pending changes to sync")
            return
        }
        
        isSyncing = true
        var synced = 0
        var failed = 0
        
        for item in pending {
            let success = await syncItem(item, context: context)
            success ? (synced += 1) : (failed += 1)
        }
        
        isSyncing = false
        print("📊 Sync complete: \(synced) synced, \(failed) failed")
    }
    
    /// Sync individual item
    private func syncItem(_ item: SyncQueueItem, context: ModelContext) async -> Bool {
        guard isOnline else {
            print("❌ Offline - retrying \(item.id)")
            return false
        }
        
        // Update status
        item.status = "syncing"
        item.lastRetryAt = Date()
        try? context.save()
        
        // TODO: Call actual server endpoint
        // For now, simulate success
        let success = await simulateServerSync(item)
        
        if success {
            // Mark as synced
            item.status = "synced"
            item.retryCount = 0
            try? context.save()
            print("✅ Synced: \(item.operation)")
            return true
        } else {
            // Handle failure
            if item.shouldRetry {
                item.status = "pending"
                item.retryCount += 1
                let delay = exponentialBackoff(item.retryCount)
                // Retry after exponential backoff
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    _ = await self.syncItem(item, context: context)
                }
                try? context.save()
            } else {
                item.status = "conflict"
                try? context.save()
                print("❌ Max retries exceeded for \(item.id)")
            }
            return false
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolve conflict between local and remote versions
    func resolveConflict(
        itemId: UUID,
        localVersion: Int,
        remoteVersion: Int,
        localTimestamp: Date,
        remoteTimestamp: Date,
        localData: String,
        remoteData: String
    ) -> (winner: String, data: String) {
        // Strategy: Last-Write-Wins
        
        if localVersion > remoteVersion {
            // Local has newer version
            print("📊 Conflict: Local version (\(localVersion)) > Remote (\(remoteVersion))")
            return ("local", localData)
        } else if remoteVersion > localVersion {
            // Remote has newer version
            print("📊 Conflict: Remote version (\(remoteVersion)) > Local (\(localVersion))")
            return ("remote", remoteData)
        } else {
            // Same version - check timestamp
            if localTimestamp > remoteTimestamp {
                print("📊 Conflict: Local timestamp is newer")
                return ("local", localData)
            } else if remoteTimestamp > localTimestamp {
                print("📊 Conflict: Remote timestamp is newer")
                return ("remote", remoteData)
            } else {
                // Fallback to userId comparison (deterministic)
                print("📊 Conflict: Timestamps equal - using deterministic order")
                return ("remote", remoteData)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func exponentialBackoff(_ retryCount: Int) -> TimeInterval {
        let base: TimeInterval = 2.0
        let maxDelay: TimeInterval = 300.0  // 5 minutes
        let delay = pow(base, Double(retryCount))
        return min(delay, maxDelay)
    }
    
    // Simulate server response (TODO: Replace with real API call)
    private func simulateServerSync(_ item: SyncQueueItem) async -> Bool {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
        
        // Simulate 90% success rate
        return Int.random(in: 1...10) <= 9
    }
}

// MARK: - Network Monitor

class NetworkMonitor {
    private let onStatusChange: (Bool) -> Void
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init(onStatusChange: @escaping (Bool) -> Void) {
        self.onStatusChange = onStatusChange
        
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                let isOnline = path.status == .satisfied
                self?.onStatusChange(isOnline)
            }
        }
        
        networkMonitor.start(queue: queue)
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

import Network
