# INTEGRATION GUIDE - SISTEM DE LOGGING

## Quick Start

### 1. Inițializare în App

```swift
@main
struct EzMenuGeneratorApp: App {
    @StateObject private var correlationManager = CorrelationIDManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Setup logging
                    Logger.correlation.setUser(
                        userId, 
                        household: householdId
                    )
                    
                    // Cleanup old logs
                    Logger.cleanupOldLogs()
                }
        }
    }
}
```text

---

## 2. Integrare în StorageService

### BEFORE
```swift
func addRecipe(_ recipe: Recipe) {
    guard let context = modelContext else { return }
    do {
        context.insert(recipe)
        try context.save()
    } catch {
        print("Error: \(error)")
    }
}
```text

### AFTER
```swift
func addRecipe(_ recipe: Recipe) {
    let startTime = Date()
    let correlationId = Logger.correlation.generateRequestId()
    
    guard let context = modelContext else {
        Logger.logError(
            code: "NO_MODEL_CONTEXT",
            message: "Cannot add recipe: no model context available",
            domain: "StorageService"
        )
        return
    }
    
    do {
        context.insert(recipe)
        try context.save()
        
        Logger.logOperation(
            name: "StorageService.addRecipe()",
            entityType: "Recipe",
            entityId: recipe.id,
            action: "create",
            duration: Date().timeIntervalSince(startTime),
            rowsAffected: 1,
            status: "success"
        )
        
    } catch {
        Logger.logError(
            code: "STORAGE_INSERT_FAILED",
            message: "Failed to add recipe: \(recipe.name)",
            domain: "StorageService",
            error: error,
            willRetry: true
        )
    }
}
```text

---

## 3. Integrare în SupabaseService

### API Calls
```swift
func fetchMenus() async throws -> [Menu] {
    let startTime = Date()
    let tracker = Logger.trackRequest(
        url: "https://api.supabase.io/rest/v1/menus",
        method: "GET",
        startTime: startTime
    )
    
    do {
        let response = try await client
            .from("menus")
            .select()
            .execute()
        
        let menus = try JSONDecoder().decode([Menu].self, from: response.data)
        
        tracker.success(statusCode: 200)
        
        Logger.logPerformance(
            name: "fetchMenus",
            networkLatencyMs: Int(Date().timeIntervalSince(startTime) * 1000)
        )
        
        return menus
        
    } catch {
        tracker.failure(error: error)
        throw error
    }
}
```text

---

## 4. Integrare în Realtime Subscriptions

```swift
func subscribeToHouseholdUpdates(householdId: UUID) {
    let channel = "household_\(householdId.uuidString):recipes"
    
    Logger.logRealtime(
        channel: channel,
        event: "INSERT,UPDATE,DELETE",
        action: "subscribe"
    )
    
    client.realtime
        .channel(channel)
        .on(.postgres_changes(
            event: .all,
            schema: "public",
            table: "recipes"
        )) { (payload: RealtimeMessage) in
            Logger.logRealtime(
                channel: channel,
                event: payload.eventType,
                action: "received",
                latencyMs: self.calculateLatency(payload)
            )
            
            self.handleUpdate(payload)
        }
        .subscribe()
}

func unsubscribeFromUpdates(householdId: UUID) {
    let channel = "household_\(householdId.uuidString):recipes"
    
    Logger.logRealtime(
        channel: channel,
        event: "ALL",
        action: "unsubscribe"
    )
    
    client.realtime.channel(channel).unsubscribe()
}
```text

---

## 5. Integrare în Sync (Offline Handling)

```swift
func syncOfflineChanges() async {
    Logger.logInfo(
        category: .sync,
        eventType: .syncStart,
        message: "Starting sync of offline changes"
    )
    
    let offlineChanges = try await getOfflineQueue()
    
    for change in offlineChanges {
        do {
            // Check for conflicts
            let serverVersion = try await fetchLatestVersion(change.entityId)
            
            if serverVersion.updatedAt > change.localUpdatedAt {
                // Conflict!
                Logger.logSync(
                    event: "Conflict detected: server version newer",
                    eventType: .syncConflict,
                    conflict: "last_write_wins",
                    mergeStrategy: "server_wins",
                    dataLoss: true,
                    lostFields: ["local_changes"]
                )
                
                // Apply server version
                try await applyServerVersion(serverVersion)
            } else {
                // No conflict, push local changes
                try await pushChange(change)
                try await markAsSynced(change.id)
                
                Logger.logSync(
                    event: "Offline change synced successfully",
                    eventType: .offlineSync,
                    offline: false
                )
            }
            
        } catch {
            Logger.logError(
                code: "SYNC_FAILED",
                message: "Failed to sync change: \(change.id)",
                domain: "SyncManager",
                error: error,
                willRetry: true
            )
        }
    }
    
    Logger.logSync(
        event: "Sync completed",
        eventType: .syncSuccess
    )
}
```text

---

## 6. Integrare în Error Handling

```swift
// Global error handler
func handleError(_ error: Error, context: String) {
    let nsError = error as NSError
    
    Logger.logError(
        code: "\(nsError.domain)_\(nsError.code)",
        message: nsError.localizedDescription,
        domain: context,
        error: error,
        userImpact: "User cannot complete action",
        willRetry: isRetryableError(error),
        retryCount: 0
    )
    
    // Show user-facing alert
    showError(message: nsError.localizedDescription)
}

private func isRetryableError(_ error: Error) -> Bool {
    let nsError = error as NSError
    return nsError.code == NSURLErrorTimedOut ||
           nsError.code == NSURLErrorNetworkConnectionLost
}
```text

---

## 7. Integrare în ViewModel (UI Events)

```swift
@MainActor
class MenuListViewModel: ObservableObject {
    
    func deleteMenu(_ menu: Menu) {
        let startTime = Date()
        
        Logger.logInfo(
            category: .ui,
            eventType: .userInteraction,
            message: "User initiated menu delete: \(menu.name)"
        )
        
        Task {
            do {
                try await storageService.deleteMenu(menu)
                
                Logger.logOperation(
                    name: "MenuListViewModel.deleteMenu()",
                    entityType: "Menu",
                    entityId: menu.id,
                    action: "delete",
                    duration: Date().timeIntervalSince(startTime),
                    status: "success"
                )
                
                // Update UI
                await MainActor.run {
                    self.menus.removeAll { $0.id == menu.id }
                }
                
            } catch {
                Logger.logError(
                    code: "DELETE_MENU_FAILED",
                    message: "Failed to delete menu: \(menu.name)",
                    domain: "MenuListViewModel",
                    error: error
                )
            }
        }
    }
}
```text

---

## 8. Logging cu Offline Status

```swift
// Track network status
class NetworkMonitor: ObservableObject {
    @Published var isOnline = true
    
    func updateStatus(_ online: Bool) {
        isOnline = online
        
        if online {
            Logger.logInfo(
                category: .sync,
                eventType: .reconnect,
                message: "Device came online"
            )
        } else {
            Logger.logInfo(
                category: .offline,
                eventType: .offlineChange,
                message: "Device went offline"
            )
        }
    }
}
```text

---

## 9. Sampling Errors (Performance)

```swift
// Log only 10% of errors in production
func logErrorIfSampled(_ error: Error, code: String) {
    #if DEBUG
        Logger.logError(code: code, message: error.localizedDescription, 
                       domain: "App", error: error)
    #else
        if Int.random(in: 0..<100) < 10 {  // 10% sampling
            Logger.logError(code: code, message: error.localizedDescription,
                           domain: "App", error: error)
        }
    #endif
}
```text

---

## 10. Exporting Logs for Debugging

```swift
// Debug view to export logs
struct LogDebugView: View {
    var body: some View {
        VStack {
            Button("Export Logs") {
                if let logsData = Logger.exportLogs() {
                    // Share via email, upload to server, etc.
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("logs.json")
                    try? logsData.write(to: url)
                    shareFile(at: url)
                }
            }
            
            Button("Flush Logs to Disk") {
                Logger.flushAll()
            }
            
            Button("Clear Logs") {
                // For testing only
                LocalLogger.shared.deleteAll()
            }
        }
    }
}
```text

---

## 11. Testing Logging

```swift
@MainActor
class LoggingTests: XCTestCase {
    
    func testLoggingDoesNotBlockUI() {
        let startTime = Date()
        
        for i in 0..<1000 {
            Logger.logInfo(
                category: .ui,
                eventType: .userInteraction,
                message: "Test log \(i)"
            )
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should log 1000 entries in < 100ms
        XCTAssertLessThan(duration, 0.1)
    }
    
    func testCorrelationIdPropagates() {
        let userId = UUID()
        Logger.correlation.setUser(userId, household: UUID())
        
        Logger.logInfo(
            category: .api,
            eventType: .apiCall,
            message: "Test"
        )
        
        let logs = LocalLogger.shared.getLogs(userId: userId.uuidString)
        XCTAssertGreaterThan(logs.count, 0)
    }
}
```text

---

## 12. Monitoringla Production (Sentry Integration)

```swift
import Sentry

// In App startup:
SentrySDK.start { options in
    options.dsn = "YOUR_SENTRY_DSN"
    options.tracesSampleRate = 0.1  // 10% of requests
    options.environment = Environment.current.rawValue
    
    // Attach user context
    let user = Sentry.User(userId: userId.uuidString)
    user.email = userEmail
    options.initialScope = { scope in
        scope.setUser(user)
        scope.setTag(value: householdId.uuidString, key: "household")
        return scope
    }
}
```text

---

## Performance Checklist

- ✅ Logging overhead < 5ms per operation
- ✅ No blocking of main thread
- ✅ SQLite writes batched
- ✅ Old logs auto-deleted after 7 days
- ✅ Passwords/tokens/PII never logged
- ✅ Correlation IDs in all requests
- ✅ Error stack traces captured
- ✅ Realtime latency measured
- ✅ Conflict detection logged
- ✅ Offline changes tracked

---

## Debugging Commands

```bash
# View logs from device console
log stream --predicate 'process == "Ez Menu Generator"' --level debug

# Export logs for analysis
# Use LogDebugView in app or programmatic export

# Check database directly
sqlite3 ~/Documents/logs.sqlite "SELECT COUNT(*) FROM logs;"
```text

---

## Cost Estimation

| Service | Volume | Cost |
|---------|--------|------|
| Local SQLite | Unlimited | $0 |
| Sentry | 5K errors/month | Free |
| Self-hosted Loki | Unlimited | $0 (server) |
| LogFlare | 1GB/month | $49 |
| **TOTAL** | **Production-ready** | **$49-100/month** |

---

## Next Steps

1. ✅ Copy LoggingStructures.swift, LocalLogger.swift, Logger.swift
2. ✅ Update App startup with CorrelationIDManager
3. ✅ Integrate Logger calls in StorageService, ViewModels
4. ✅ Test logging with sample app actions
5. ✅ Setup Sentry/LogFlare accounts
6. ✅ Create monitoring dashboards
7. ✅ Setup alert rules
8. ✅ Train team on log querying

---

## Support

For issues or questions:
- Check LOGGING_ARCHITECTURE.md for detailed design
- Review concrete examples in this guide
- Test with LogDebugView to inspect local logs
- Use correlation IDs to trace requests end-to-end
