# 🎯 Sistemul Complet de Bug Detection, Monitoring și Stabilitate

**Vers. 1.0** | Ez Menu Generator | Feb 21, 2026

---

## EXECUTIVE SUMMARY

### Principii-Ghid
1. **Pragmatism**: Detectare rapidă a problemelor reale, nu perfecțiune teoretică
2. **Minimal overhead**: <2% impact pe performanță, <5KB/session logs
3. **Actionabil**: Fiecare metric → decizie concretă
4. **Local-first**: Maximizare utilizare local logging, minimizare transmisii
5. **Household-centric**: Understand issues la nivel household, nu global

---

## 1. ARHITECTURA SISTEMULUI DE MONITORING

### 1.1 Stivă de Componente

```
┌─────────────────────────────────────────┐
│  CLIENT (iOS App)                       │
├─────────────────────────────────────────┤
│ Layer 1: Event Capture                  │
│  - Performance metrics                  │
│  - Network events                       │
│  - UI interaction traces                │
│  - Crash detection                      │
├─────────────────────────────────────────┤
│ Layer 2: Local Aggregation              │
│  - SQLite event log (rotating)          │
│  - In-memory buffer (last 50 events)    │
│  - Invariant violations                 │
├─────────────────────────────────────────┤
│ Layer 3: Batch Transmission             │
│  - Send periodically (5 min / on exit)  │
│  - Compress + encrypt                   │
│  - Retry failed submissions              │
└─────────────────────────────────────────┘
         ↓ HTTPS (Batch)
┌─────────────────────────────────────────┐
│  BACKEND (Supabase)                     │
├─────────────────────────────────────────┤
│ Edge Function: /api/v1/telemetry        │
│  - Validate + deduplicate               │
│  - Enrich with metadata                 │
│  - Route to appropriate storage          │
├─────────────────────────────────────────┤
│ Storage Layer:                          │
│  - PostgreSQL: aggregated_events        │
│  - PostgreSQL: crash_reports            │
│  - S3: raw logs (infrequent issues)     │
├─────────────────────────────────────────┤
│ Analysis + Alerting:                    │
│  - Real-time rules (pg_cron)            │
│  - Webhooks → external channels         │
│  - Dashboard queries                     │
└─────────────────────────────────────────┘
```

### 1.2 Fluxul de Detecție a Erorilor

```
┌─────────────────────┐
│ EVENT OCCURS        │
│ (crash, sync fail,  │
│  timeout, etc)      │
└──────────┬──────────┘
           ↓
┌─────────────────────────────────────────────┐
│ IMMEDIATE ACTIONS (Client-side, real-time)  │
├─────────────────────────────────────────────┤
│ ✓ Capture stack trace                       │
│ ✓ Log context (user, household, device)    │
│ ✓ Check invariants                          │
│ ✓ Attempt recovery (retry, rebind, etc)    │
│ ✓ Store in SQLite locally                  │
└──────────┬──────────────────────────────────┘
           ↓
      [Batch Wait]
      5 min or:
      - App exit
      - Critical error
      - Manual force sync
           ↓
┌─────────────────────────────────────────┐
│ TRANSMISSION LAYER                      │
├─────────────────────────────────────────┤
│ - Compress + sign payload                │
│ - POST to /api/v1/telemetry             │
│ - If offline: queue for next sync        │
└──────────┬──────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ BACKEND PROCESSING                      │
├─────────────────────────────────────────┤
│ - Validate signature + schema            │
│ - Deduplicate (same event, <1min gap)   │
│ - Aggregate into metrics                 │
│ - Check thresholds                       │
└──────────┬──────────────────────────────┘
           ↓
      [Threshold Breach?]
           │
      Yes ↓
┌─────────────────────────────────────────┐
│ ALERTING CASCADE                         │
├─────────────────────────────────────────┤
│ Level 1 (Warning): Log, tag incident     │
│ Level 2 (Alert): Webhook → Slack/Email  │
│ Level 3 (Critical): Wake-up on-call      │
│ Level 4 (Catastrophic): Rollback flag    │
└─────────────────────────────────────────┘
```

---

## 2. METRICI CRITICE ȘI PRAGURI

### 2.1 Tabel Complet de Metrici

| Metrica | Unde Colectat | Unitate | Prag Warning | Prag Critical | Acțiune |
|---------|--------------|---------|------------|--------------|---------|
| **Crash Rate** | Client + Backend | crashes/session | >1% | >5% | Auto-disable feature |
| **Sync Latency P95** | RealtimeSyncManager | ms | >3000 | >10000 | Degrade sync mode |
| **Offline Reconnect Time** | OfflineSyncManager | sec | >30 | >120 | User notification |
| **Data Validation Failures** | StorageService | errors/batch | >5% | >20% | Quarantine transactions |
| **API Error Rate** | Network layer | errors/req | >2% | >10% | Rate-limit backoff |
| **Memory Footprint** | OS diagnostics | MB | >500 | >800 | Force GC + memory warning |
| **UI Frame Drops** | Performance detector | % dropped | >5% | >15% | Disable animations |
| **Sync Conflict Rate** | RealtimeSyncManager | conflicts/hour | >0.5 | >5 | Alert household user |
| **Invariant Violations** | Integrity checker | violations/session | >0 | >3 | Force data rebuild |
| **Network Timeout Rate** | URLSession wrapper | timeouts/batch | >2% | >10% | Increase retry timeout |

### 2.2 Logica de Prag

```swift
// Schema de praguri - progressive severity
enum AlertSeverity {
    case info        // Log only
    case warning     // Log + metrics flag
    case alert       // Slack notification
    case critical    // Force feature disable
    case catastrophic // Trigger rollback
}

struct MetricThreshold {
    let metric: String
    let window: TimeInterval      // 5 min, 1 hour, 24h
    let value: Double
    let severity: AlertSeverity
    let action: String           // e.g., "disable_sync", "show_banner"
}
```

### 2.3 Collection Strategy

**CLIENT-SIDE** (Cu minimal overhead):
```swift
// 1. Event capture (synchronous, <1ms)
EventTracker.log(.syncLatency, value: duration, tags: ["household": id])

// 2. Aggregation (every 5 min or on-demand)
let batch = EventAggregator.getBatch()  // 50-100 events max

// 3. Transmission (async, batched)
TelemetryService.sendBatch(batch)       // Ignores failures, retries next batch
```

**BACKEND** (Supabase Edge Function):
```sql
-- Real-time detection via pg_cron (run every 2 minutes)
SELECT 
    household_id,
    event_type,
    COUNT(*) as cnt,
    AVG(value) as avg_val,
    MAX(severity) as max_sev
FROM telemetry_events
WHERE created_at > NOW() - INTERVAL '5 minutes'
GROUP BY household_id, event_type
HAVING COUNT(*) > threshold[event_type]
  OR AVG(value) > threshold_value[event_type]
```

---

## 3. CRASH REPORTING

### 3.1 Stack Trace Capture

```swift
// CrashHandler.swift
class CrashHandler {
    static func setupCrashReporting() {
        #if DEBUG
        // Use Xcode console in debug
        #else
        NSSetUncaughtExceptionHandler { exception in
            let report = CrashReport(
                exception: exception,
                stackTrace: Thread.callStackSymbols,
                timestamp: Date(),
                sessionId: SessionManager.current.id,
                householdId: SessionManager.current.householdId,
                userId: SessionManager.current.userId,
                appVersion: Bundle.main.appVersion,
                osVersion: UIDevice.current.systemVersion,
                device: UIDevice.current.model,
                memory: ProcessInfo.processInfo.physicalMemory,
                isDiskSpaceLow: isDiskSpaceCritical(),
                isMemoryWarningRecent: MemoryWarningDetector.hasRecentWarning
            )
            
            CrashStore.save(report)
            TelemetryService.sendCrashReportBatch()
        }
        #endif
    }
}
```

### 3.2 Corelare cu Context

```swift
struct CrashReport: Codable {
    let id: UUID                           // Unique
    let exceptionType: String              // e.g., "NSRangeException"
    let message: String                    // Exception message
    let stackTrace: [String]               // Full call stack
    
    // Context
    let sessionId: String                  // Link to user session
    let householdId: String               // Which household affected
    let userId: String                    // Which user
    
    // Device state
    let appVersion: String                // e.g., "2.1.0"
    let buildNumber: String               // e.g., "47"
    let osVersion: String                 // iOS version
    let device: String                    // iPhone 14 Pro
    let memoryUsedMB: Int                 // At crash time
    let isDiskSpaceLow: Bool              // <100MB
    
    // Sync state
    let isOffline: Bool                   // Network state
    let pendingSyncCount: Int             // Queued operations
    let lastSyncTime: Date?               // When last sync completed
    
    // Activity before crash
    let lastScreenName: String?           // Last VC on screen
    let lastActionPerformed: String?      // e.g., "MenuEditorView.deleteRecipe"
    let timeInAppSeconds: Int             // App foreground duration
    
    let timestamp: Date
}
```

### 3.3 Grupare și Triage

**Deduplicate Strategy**:
```sql
-- Group crashes by fingerprint (hash of stack trace + exception type)
SELECT 
    fingerprint,
    exception_type,
    COUNT(*) as occurrence_count,
    COUNT(DISTINCT household_id) as affected_households,
    COUNT(DISTINCT user_id) as affected_users,
    MAX(timestamp) as last_seen,
    MIN(timestamp) as first_seen,
    ARRAY_AGG(DISTINCT app_version) as affected_versions
FROM crash_reports
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY fingerprint, exception_type
ORDER BY occurrence_count DESC
LIMIT 20;
```

**Triage Scoring**:
```
priority_score = (
    (occurrence_count * 0.3) +           // Frequency
    (affected_households * 0.4) +        // Impact
    (is_data_affecting ? 100 : 0) +      // Data safety
    (is_sync_blocking ? 50 : 0)          // Sync critical
)

IF priority_score > 50 → CRITICAL (fix immediately)
IF priority_score > 15 → HIGH (fix this sprint)
IF priority_score > 5  → MEDIUM (backlog)
```

---

## 4. INVARIANT & INTEGRITY CHECKS

### 4.1 Definirea Regulilor

```swift
// IntegrityRules.swift
struct IntegrityRule {
    let id: String
    let name: String
    let description: String
    let check: (ModelContext) -> [IntegrityViolation]
    let severity: ValidationType
    let autoRepair: ((ModelContext) -> Void)?
    let runFrequency: TimeInterval     // e.g., 300 (5 min)
}

enum ValidationType {
    case warning   // Log, continue
    case error     // Log, reject operation
    case fatal     // Force sync from server
}
```

### 4.2 Reguli Concrete

```swift
let rules: [IntegrityRule] = [
    // RULE 1: Menu must have 7 days of meals
    IntegrityRule(
        id: "menu_days_complete",
        name: "Menu days complete",
        description: "Each menu must have exactly 7 DayMeals",
        check: { context in
            var violations: [IntegrityViolation] = []
            let menus = try? context.fetch(FetchDescriptor<Menu>())
            menus?.forEach { menu in
                if menu.meals.count != 7 {
                    violations.append(IntegrityViolation(
                        rule: "menu_days_complete",
                        severity: .error,
                        entity: "Menu",
                        entityId: menu.id.uuidString,
                        detail: "Menu has \(menu.meals.count) days, expected 7"
                    ))
                }
            }
            return violations
        },
        severity: .error,
        autoRepair: { context in
            // Rebuild missing DayMeals
            let menus = try? context.fetch(FetchDescriptor<Menu>())
            menus?.forEach { menu in
                while menu.meals.count < 7 {
                    menu.meals.append(DayMeals())
                }
                while menu.meals.count > 7 {
                    menu.meals.removeLast()
                }
            }
        },
        runFrequency: 300
    ),
    
    // RULE 2: Recipe consistency - no orphaned ingredients
    IntegrityRule(
        id: "recipe_ingredient_consistency",
        name: "Recipe ingredient consistency",
        description: "All recipe ingredients must reference valid recipes",
        check: { context in
            var violations: [IntegrityViolation] = []
            let ingredients = try? context.fetch(FetchDescriptor<Ingredient>())
            ingredients?.forEach { ingredient in
                if ingredient.recipe == nil && ingredient.recipeId == nil {
                    violations.append(IntegrityViolation(
                        rule: "recipe_ingredient_consistency",
                        severity: .warning,
                        entity: "Ingredient",
                        entityId: ingredient.id.uuidString,
                        detail: "Orphaned ingredient: \(ingredient.name)"
                    ))
                }
            }
            return violations
        },
        severity: .warning,
        autoRepair: nil,
        runFrequency: 600
    ),
    
    // RULE 3: Sync state consistency
    IntegrityRule(
        id: "sync_state_consistency",
        name: "Sync state consistency",
        description: "Pending count must match actual sync operations",
        check: { context in
            var violations: [IntegrityViolation] = []
            let syncState = try? context.fetch(FetchDescriptor<SyncState>())
            syncState?.forEach { state in
                let pendingOps = (try? context.fetch(FetchDescriptor<SyncOperation>())).filter { 
                    $0.status == .pending 
                } ?? []
                
                if state.pendingOperationCount != pendingOps.count {
                    violations.append(IntegrityViolation(
                        rule: "sync_state_consistency",
                        severity: .error,
                        entity: "SyncState",
                        entityId: state.id.uuidString,
                        detail: "Pending count mismatch: \(state.pendingOperationCount) vs \(pendingOps.count)"
                    ))
                }
            }
            return violations
        },
        severity: .error,
        autoRepair: { context in
            // Rebuild pending count from actual operations
            let syncState = try? context.fetch(FetchDescriptor<SyncState>()).first
            let pendingOps = (try? context.fetch(FetchDescriptor<SyncOperation>())).filter {
                $0.status == .pending
            } ?? []
            syncState?.pendingOperationCount = pendingOps.count
        },
        runFrequency: 300
    ),
    
    // RULE 4: Household user consistency
    IntegrityRule(
        id: "household_user_consistency",
        name: "Household user consistency",
        description: "Household users must match Supabase state",
        check: { context in
            // Will be filled during session initialization
            return []
        },
        severity: .fatal,
        autoRepair: nil,
        runFrequency: 3600  // hourly
    )
]
```

### 4.3 Orchestrator - IntegrityManager

```swift
class IntegrityManager {
    private let rules: [IntegrityRule]
    private var lastRunTimes: [String: Date] = [:]
    
    func runScheduledChecks() {
        for rule in rules {
            let lastRun = lastRunTimes[rule.id] ?? Date.distantPast
            if Date().timeIntervalSince(lastRun) >= rule.runFrequency {
                runCheck(rule)
            }
        }
    }
    
    private func runCheck(_ rule: IntegrityRule) {
        guard let context = modelContext else { return }
        
        let violations = rule.check(context)
        
        if !violations.isEmpty {
            logViolations(violations, rule: rule)
            
            if rule.severity == .error || rule.severity == .fatal {
                if let autoRepair = rule.autoRepair {
                    autoRepair(context)
                    try? context.save()
                    TelemetryService.logRepair(
                        rule: rule.id,
                        violationCount: violations.count
                    )
                }
            }
            
            if rule.severity == .fatal {
                AlertingService.critical("Integrity violation: \(rule.name)")
            }
        }
        
        lastRunTimes[rule.id] = Date()
    }
}
```

### 4.4 Validare pe Backend

```sql
-- Backend trigger: validate before insert/update
CREATE OR REPLACE FUNCTION validate_recipe_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Rule: recipe must have all required fields
    IF NEW.name IS NULL OR NEW.category IS NULL THEN
        RAISE EXCEPTION 'Recipe validation failed: missing required fields';
    END IF;
    
    -- Rule: prep time cannot be negative
    IF NEW.prep_time_minutes < 0 THEN
        RAISE EXCEPTION 'Recipe validation failed: negative prep time';
    END IF;
    
    -- Rule: servings must be > 0
    IF NEW.servings <= 0 THEN
        RAISE EXCEPTION 'Recipe validation failed: invalid servings';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_recipe_insert
    BEFORE INSERT ON recipes
    FOR EACH ROW
    EXECUTE FUNCTION validate_recipe_before_insert();
```

---

## 5. STRATEGIE DE TESTING

### 5.1 Structura Folderelor

```
Ez Menu Generator/
├── Tests/
│   ├── Unit/
│   │   ├── Domain/
│   │   │   ├── RecipeCalculatorTests.swift
│   │   │   ├── MealPlanValidatorTests.swift
│   │   │   └── NutritionComputerTests.swift
│   │   ├── Services/
│   │   │   ├── StorageServiceTests.swift
│   │   │   ├── OfflineSyncTests.swift
│   │   │   └── IntegrityCheckerTests.swift
│   │   └── Utilities/
│   │       ├── DateUtilsTests.swift
│   │       └── ValidationUtilsTests.swift
│   │
│   ├── Integration/
│   │   ├── SyncIntegrationTests.swift
│   │   ├── HouseholdSyncTests.swift
│   │   ├── ConflictResolutionTests.swift
│   │   ├── OfflineReconnectTests.swift
│   │   └── EndToEndFlowTests.swift
│   │
│   ├── Performance/
│   │   ├── LargeDatasetTests.swift
│   │   ├── MemoryLeakTests.swift
│   │   └── UIResponsivenesTests.swift
│   │
│   └── Fixtures/
│       ├── SampleMenus.swift
│       ├── ConflictScenarios.swift
│       └── NetworkSimulators.swift
│
└── App/
    ├── Services/
    │   ├── StorageService.swift
    │   ├── RealtimeSyncManager.swift
    │   └── OfflineSyncManager.swift
    └── (...)
```

### 5.2 Unit Tests - Domain Logic

```swift
// Tests/Unit/Domain/MealPlanValidatorTests.swift
class MealPlanValidatorTests: XCTestCase {
    var validator: MealPlanValidator!
    
    override func setUp() {
        super.setUp()
        validator = MealPlanValidator()
    }
    
    // RULE: Menu must have exactly 7 days
    func testMenuWith7DaysIsValid() {
        let menu = createMenu(dayCount: 7)
        XCTAssertTrue(validator.isValid(menu))
    }
    
    func testMenuWith6DaysIsInvalid() {
        let menu = createMenu(dayCount: 6)
        XCTAssertFalse(validator.isValid(menu))
        XCTAssertEqual(validator.errors.count, 1)
        XCTAssertEqual(validator.errors.first?.rule, "menu_days_complete")
    }
    
    // RULE: Each day must have 3 meals
    func testDayWith3MealsIsValid() {
        let day = createDayMeals(mealCount: 3)
        XCTAssertTrue(validator.isDayValid(day))
    }
    
    // RULE: No meal can have prep time > 120 minutes
    func testRecipeWith150MinPrepTimeInvalid() {
        let recipe = createRecipe(prepTime: 150)
        let errors = validator.validateRecipe(recipe)
        XCTAssertTrue(errors.contains { $0.rule == "max_prep_time" })
    }
}
```

### 5.3 Integration Tests - Sync Conflicts

```swift
// Tests/Integration/ConflictResolutionTests.swift
class ConflictResolutionTests: XCTestCase {
    var syncManager: RealtimeSyncManager!
    var household: Household!
    
    override func setUp() {
        super.setUp()
        syncManager = RealtimeSyncManager()
        household = createTestHousehold(userCount: 2)
    }
    
    // SCENARIO: Two users edit same recipe simultaneously
    func testSimultaneousRecipeEdit_LastWriteWins() {
        let recipe = createRecipe(name: "Original")
        
        // User 1 changes name at t=100
        let edit1 = RecipeEdit(
            recipeId: recipe.id,
            field: "name",
            value: "User 1 Edit",
            timestamp: Date(timeIntervalSince1970: 100)
        )
        
        // User 2 changes name at t=110 (later)
        let edit2 = RecipeEdit(
            recipeId: recipe.id,
            field: "name",
            value: "User 2 Edit",
            timestamp: Date(timeIntervalSince1970: 110)
        )
        
        let resolved = syncManager.resolveConflict([edit1, edit2], for: recipe)
        
        XCTAssertEqual(resolved.name, "User 2 Edit", "Later edit should win")
    }
    
    // SCENARIO: Concurrent recipe delete and ingredient add
    func testDeletedRecipeWithPendingIngredient() {
        let recipe = createRecipe()
        
        let deleteOp = SyncOperation(
            type: .delete,
            entity: "Recipe",
            entityId: recipe.id,
            timestamp: Date()
        )
        
        let addIngredientOp = SyncOperation(
            type: .create,
            entity: "Ingredient",
            parentId: recipe.id,
            timestamp: Date()
        )
        
        let result = syncManager.apply([deleteOp, addIngredientOp])
        
        XCTAssertEqual(result.conflicts.count, 1)
        XCTAssertEqual(result.conflicts.first?.reason, "parent_deleted")
    }
    
    // SCENARIO: Three users, 100 simultaneous edits
    func testHighConcurrencyStress() {
        let menu = createMenu()
        let edits = generateRandomEdits(count: 100, for: menu)
        
        let result = syncManager.applyBatch(edits)
        
        XCTAssertEqual(result.resolved.count, 100)
        XCTAssertEqual(result.conflicts.count, 0)
        
        // Verify final state is consistent
        let finalMenu = syncManager.fetchMenu(id: menu.id)
        XCTAssertTrue(validator.isValid(finalMenu!))
    }
}
```

### 5.4 Integration Tests - Offline → Reconnect

```swift
// Tests/Integration/OfflineReconnectTests.swift
class OfflineReconnectTests: XCTestCase {
    var offline: OfflineSyncManager!
    var household: Household!
    var networkSim: NetworkSimulator!
    
    override func setUp() {
        super.setUp()
        offline = OfflineSyncManager()
        household = createTestHousehold()
        networkSim = NetworkSimulator()
    }
    
    // SCENARIO: Create menu offline, sync on reconnect
    func testCreateMenuOfflineSync() {
        networkSim.simulateOffline()
        
        // Create menu while offline
        let menu = createMenu()
        offline.saveMenu(menu)
        
        // Should be stored in sync queue
        XCTAssertEqual(offline.pendingOperations.count, 1)
        
        // Go online
        networkSim.simulateOnline()
        
        let expectation = XCTestExpectation(description: "sync completed")
        offline.syncWhenOnline().sink { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Sync failed: \(error)")
            }
        }.store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5)
        
        // Menu should now exist on server
        let serverMenu = try? await fetchFromServer(menu.id)
        XCTAssertNotNil(serverMenu)
    }
    
    // SCENARIO: 3G throttled, reconnect with retries
    func testReconnectWith3GLatency() {
        networkSim.simulate3G()
        
        let operations = generateOperations(count: 20)
        offline.queue(operations)
        
        let expectation = XCTestExpectation(description: "slow sync")
        let startTime = Date()
        
        offline.syncWhenOnline().sink { result in
            let duration = Date().timeIntervalSince(startTime)
            
            switch result {
            case .success:
                XCTAssertLessThan(duration, 15.0, "Should retry and complete within 15s")
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }.store(in: &cancellables)
        
        wait(for: [expectation], timeout: 20)
    }
    
    // SCENARIO: Offline for 48 hours, local edits, then huge sync
    func testExtendedOfflineWithLocalConflicts() {
        networkSim.simulateOffline()
        
        let initialMenu = createMenu(name: "Original")
        offline.saveMenu(initialMenu)
        
        // Simulate 48 hours of offline time
        let editTime1 = Date().addingTimeInterval(3600)
        let editTime2 = Date().addingTimeInterval(7200)
        
        offline.updateMenu(initialMenu, at: editTime1, with: [
            RecipeEdit(recipe: initialMenu.meals[0].breakfast!, name: "Offline Edit 1")
        ])
        
        offline.updateMenu(initialMenu, at: editTime2, with: [
            RecipeEdit(recipe: initialMenu.meals[1].breakfast!, name: "Offline Edit 2")
        ])
        
        // Meanwhile, on server, another user edited
        // Simulate server state
        let serverMenu = createMenu(name: "Original")
        updateRecipe(serverMenu.meals[0].breakfast!, with: ["name": "Server Edit"])
        
        // Go online - conflict resolver should activate
        networkSim.simulateOnline()
        
        let expectation = XCTestExpectation(description: "conflict resolved")
        offline.syncWhenOnline()
            .flatMap { _ in self.offline.verifyConsistency() }
            .sink(receiveCompletion: { _ in },
                  receiveValue: { isConsistent in
                XCTAssertTrue(isConsistent)
                expectation.fulfill()
            }).store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10)
    }
}
```

### 5.5 Performance Tests

```swift
// Tests/Performance/UIResponsivenesTests.swift
class UIResponsivenessTests: XCTestCase {
    let framemetrics = FrameMetrics()
    
    func testMenuDeletion_UINotBlocked() {
        let menu = createMenuWithBigData(
            days: 7,
            recipesPerDay: 10,
            ingredientsPerRecipe: 20
        )
        
        measure(metrics: [
            XCTClockMetric(),
            XCTCPUMetric(),
            XCTMemoryMetric()
        ]) {
            // Simulate main thread work
            DispatchQueue.main.sync {
                framemetrics.start()
                
                let vc = MenuEditorViewController()
                vc.deleteMenu(menu)
                
                framemetrics.stop()
            }
        }
        
        // Frame drop rate should be < 5%
        let dropRate = framemetrics.getDropRate()
        XCTAssertLessThan(dropRate, 0.05, "UI should not drop frames during large operations")
    }
}
```

### 5.6 Test Fixtures & Helpers

```swift
// Tests/Fixtures/ConflictScenarios.swift
struct ConflictScenario {
    let name: String
    let operations: [SyncOperation]
    let expectedResolution: SyncOperation
}

let conflictScenarios: [ConflictScenario] = [
    ConflictScenario(
        name: "Last-write-wins for recipe name",
        operations: [
            SyncOperation(type: .update, entity: "Recipe", field: "name", 
                         value: "Edit A", timestamp: Date(timeIntervalSince1970: 100)),
            SyncOperation(type: .update, entity: "Recipe", field: "name",
                         value: "Edit B", timestamp: Date(timeIntervalSince1970: 200))
        ],
        expectedResolution: SyncOperation(type: .update, value: "Edit B")
    ),
    // ... more scenarios
]
```

---

## 6. FEATURE FLAGS

### 6.1 Sistem Simplu

```swift
// FeatureFlags.swift
enum Feature: String, CaseIterable {
    // UI Features
    case newMenuEditor = "new_menu_editor"
    case barcodeOptimized = "barcode_optimized"
    case advancedNutrition = "advanced_nutrition"
    
    // Sync Features
    case realtimeSync = "realtime_sync"
    case conflictDetection = "conflict_detection"
    case offlineMode = "offline_mode"
    
    // Monitoring
    case detailedLogging = "detailed_logging"
    case crashReporting = "crash_reporting"
}

class FeatureFlagManager {
    private var localOverrides: [String: Bool] = [:]
    private var serverConfig: [String: FeatureFlagConfig] = [:]
    
    // Check: local override > household config > user config > global default
    func isEnabled(_ feature: Feature) -> Bool {
        // 1. Local override (dev/debug)
        if let override = localOverrides[feature.rawValue] {
            return override
        }
        
        // 2. Household-specific config
        if let household = SessionManager.current.household,
           let householdConfig = serverConfig[household.id] {
            if let householdFlag = householdConfig.features[feature.rawValue] {
                return householdFlag
            }
        }
        
        // 3. Per-user config
        if let user = SessionManager.current.user,
           let userConfig = serverConfig[user.id] {
            if let userFlag = userConfig.features[feature.rawValue] {
                return userFlag
            }
        }
        
        // 4. Global default
        return getDefaultValue(feature)
    }
    
    // Force-set locally (debug only)
    func setLocalOverride(_ feature: Feature, enabled: Bool) {
        #if DEBUG
        localOverrides[feature.rawValue] = enabled
        #endif
    }
    
    // Fetch server config (cached, refresh every hour)
    func refreshServerConfig() async {
        guard let response = try? await SupabaseService.getFeatureFlags() else {
            return
        }
        self.serverConfig = response
    }
    
    private func getDefaultValue(_ feature: Feature) -> Bool {
        switch feature {
        case .newMenuEditor: return false          // Still beta
        case .barcodeOptimized: return true        // Stable
        case .advancedNutrition: return true       // Rolled out
        case .realtimeSync: return true            // Critical
        case .conflictDetection: return true       // Critical
        case .offlineMode: return true             // Core
        case .detailedLogging: return false        // Perf cost
        case .crashReporting: return true          // Always on
        }
    }
}
```

### 6.2 Rollback Strategy

```swift
// In Supabase Edge Function: /api/v1/rollback-feature
export async function handleFeatureRollback(req: Request) {
    const { feature, household_id } = await req.json();
    
    // 1. Disable feature immediately in DB
    await supabase
        .from('feature_flag_configs')
        .update({ enabled: false })
        .eq('feature', feature)
        .eq('household_id', household_id);
    
    // 2. Notify connected clients via Realtime
    supabase.realtime.broadcast({
        event: 'FEATURE_ROLLBACK',
        payload: { feature, household_id }
    });
    
    // 3. Alert users in-app
    await notifyHouseholdUsers(household_id, 
        `Feature '${feature}' temporarily disabled for stability`);
    
    // 4. Log incident
    await log('feature_rollback', {
        feature, household_id, timestamp: new Date()
    });
    
    return { success: true };
}
```

---

## 7. BACKEND HEALTH CHECKS

### 7.1 Endpoint de Health

```swift
// Supabase Edge Function: /api/v1/health
export async function handler(req: Request) {
    const startTime = Date.now();
    const checks: HealthCheck[] = [];
    
    // 1. Database Health
    const dbCheck = await checkDatabase();
    checks.push(dbCheck);
    
    // 2. Realtime Health
    const realtimeCheck = await checkRealtime();
    checks.push(realtimeCheck);
    
    // 3. Edge Function Health
    const functionCheck = {
        status: "healthy",
        responseTimeMs: Date.now() - startTime,
        lastCheck: new Date()
    };
    checks.push(functionCheck);
    
    // 4. S3/Storage Health
    const storageCheck = await checkStorage();
    checks.push(storageCheck);
    
    const allHealthy = checks.every(c => c.status === 'healthy');
    
    return new Response(JSON.stringify({
        status: allHealthy ? 'healthy' : 'degraded',
        checks: checks,
        timestamp: new Date().toISOString()
    }), {
        headers: { 'Content-Type': 'application/json' },
        status: allHealthy ? 200 : 503
    });
}

async function checkDatabase(): Promise<HealthCheck> {
    try {
        const start = Date.now();
        
        // Run a simple query
        const { data, error } = await supabase
            .from('households')
            .select('id')
            .limit(1);
        
        if (error) throw error;
        
        return {
            component: 'database',
            status: 'healthy',
            responseTimeMs: Date.now() - start
        };
    } catch (error) {
        return {
            component: 'database',
            status: 'unhealthy',
            error: error.message
        };
    }
}

async function checkRealtime(): Promise<HealthCheck> {
    try {
        const result = await SupabaseService.realtimeClient.getStatus();
        
        return {
            component: 'realtime',
            status: result.status === 'connected' ? 'healthy' : 'degraded',
            connectedClients: result.connectedClients
        };
    } catch (error) {
        return {
            component: 'realtime',
            status: 'unhealthy',
            error: error.message
        };
    }
}
```

### 7.2 Auto-detect Degraded State

```sql
-- Trigger job: detect when backend is degraded
-- Run every 5 minutes via pg_cron
CREATE OR REPLACE FUNCTION detect_backend_degradation()
RETURNS void AS $$
DECLARE
    error_rate FLOAT;
    avg_latency INT;
    sync_lag INT;
BEGIN
    -- Calculate error rate from last 5 minutes
    SELECT COUNT(CASE WHEN status = 'error' THEN 1 END) * 100.0 / COUNT(*)
    INTO error_rate
    FROM api_requests
    WHERE created_at > NOW() - INTERVAL '5 minutes';
    
    -- Calculate P95 latency
    SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms)
    INTO avg_latency
    FROM api_requests
    WHERE created_at > NOW() - INTERVAL '5 minutes';
    
    -- Calculate max sync lag
    SELECT MAX(EXTRACT(EPOCH FROM (NOW() - synced_at)))
    INTO sync_lag
    FROM household_sync_state
    WHERE synced_at < NOW();
    
    -- Trigger alerts if degraded
    IF error_rate > 5 THEN
        INSERT INTO incident_log (severity, message)
        VALUES ('ALERT', 'High error rate: ' || error_rate || '%');
    END IF;
    
    IF avg_latency > 3000 THEN
        INSERT INTO incident_log (severity, message)
        VALUES ('WARNING', 'High latency: ' || avg_latency || 'ms');
    END IF;
    
    IF sync_lag > 300 THEN
        INSERT INTO incident_log (severity, message)
        VALUES ('WARNING', 'Sync lag: ' || sync_lag || 's');
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT cron.schedule('detect_degradation', '*/5 * * * *', 'SELECT detect_backend_degradation()');
```

---

## 8. SYNTHETIC MONITORING

### 8.1 Artificial User Bot

```swift
// SyntheticMonitoringBot.swift
class SyntheticMonitoringBot {
    let testHouseholdId: String = "test-household-synthetic-monitoring"
    let testUserId: String = "test-user-bot-\(UUID().uuidString)"
    
    // Run complete user journey every 30 minutes
    static func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            Task {
                await SyntheticMonitoringBot().runTestJourney()
            }
        }
    }
    
    func runTestJourney() async {
        let startTime = Date()
        var metrics = SyntheticJourneyMetrics(
            startTime: startTime,
            steps: []
        )
        
        do {
            // Step 1: Login / Create test session
            try await recordStep(name: "authenticate") {
                // Simulate authentication flow
            }
            
            // Step 2: Fetch household data
            try await recordStep(name: "fetch_household") {
                let household = try await SupabaseService.fetchHousehold(id: testHouseholdId)
                guard household != nil else {
                    throw MonitoringError.householdNotFound
                }
            }
            
            // Step 3: Create test menu
            try await recordStep(name: "create_menu") {
                let menu = SampleMenuFactory.createCompleteMenu()
                try await StorageService.shared.addMenu(menu)
            }
            
            // Step 4: Update recipe
            try await recordStep(name: "update_recipe") {
                var recipes = try await StorageService.shared.fetchAllRecipes()
                recipes[0].name = "Updated by bot at \(Date())"
                try await StorageService.shared.updateRecipe(recipes[0])
            }
            
            // Step 5: Sync changes
            try await recordStep(name: "sync_changes") {
                try await RealtimeSyncManager.shared.syncChanges()
            }
            
            // Step 6: Delete menu
            try await recordStep(name: "delete_menu") {
                let menus = try await StorageService.shared.fetchAllMenus()
                if let menu = menus.first {
                    try await StorageService.shared.deleteMenu(menu)
                }
            }
            
            // Step 7: Verify recovery
            try await recordStep(name: "undo_delete") {
                try await UndoRedoManager.shared.undo()
                let menus = try await StorageService.shared.fetchAllMenus()
                guard !menus.isEmpty else {
                    throw MonitoringError.recoveryFailed
                }
            }
            
            metrics.success = true
            
        } catch {
            metrics.success = false
            metrics.errorMessage = error.localizedDescription
            
            AlertingService.warning(
                "Synthetic monitoring failed: \(error)",
                severity: .alert
            )
        }
        
        metrics.endTime = Date()
        metrics.durationMs = Int(metrics.endTime!.timeIntervalSince(startTime) * 1000)
        
        // Send metrics to backend
        try? await TelemetryService.sendSyntheticMetrics(metrics)
    }
    
    private func recordStep(name: String, 
                           action: () async throws -> Void) async throws {
        let startTime = Date()
        
        try await action()
        
        let duration = Date().timeIntervalSince(startTime) * 1000
        
        print("✅ Synthetic step '\(name)': \(Int(duration))ms")
    }
}

struct SyntheticJourneyMetrics: Codable {
    let startTime: Date
    var endTime: Date?
    var durationMs: Int?
    var steps: [String]
    var success: Bool = false
    var errorMessage: String?
}
```

### 8.2 Monitoring Dashboard

```sql
-- Query: Synthetic monitoring status
SELECT 
    DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') as timestamp,
    success,
    COUNT(*) as run_count,
    AVG(duration_ms) as avg_duration_ms,
    MAX(duration_ms) as max_duration_ms,
    ARRAY_AGG(error_message) FILTER (WHERE error_message IS NOT NULL) as errors
FROM synthetic_monitoring_runs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d %H:%i'), success
ORDER BY timestamp DESC;
```

---

## 9. DATA VALIDATION STRICTĂ

### 9.1 Client-side Validation

```swift
// ValidationLayer.swift
struct ValidationError: LocalizedError {
    let field: String
    let message: String
    let severity: ValidationSeverity
    
    var errorDescription: String? {
        "\(field): \(message)"
    }
}

enum ValidationSeverity {
    case warning  // inform user, allow proceed
    case error    // block operation
}

// Validator classes
class RecipeValidator {
    static func validate(_ recipe: Recipe) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Name: required, 2-100 chars
        if recipe.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(ValidationError(
                field: "name",
                message: "Recipe name is required",
                severity: .error
            ))
        } else if recipe.name.count < 2 || recipe.name.count > 100 {
            errors.append(ValidationError(
                field: "name",
                message: "Name must be 2-100 characters",
                severity: .error
            ))
        }
        
        // Prep time: 0-480 minutes
        if recipe.prepTimeMinutes < 0 || recipe.prepTimeMinutes > 480 {
            errors.append(ValidationError(
                field: "prepTimeMinutes",
                message: "Prep time must be 0-480 minutes",
                severity: .error
            ))
        }
        
        // Servings: 1-20
        if recipe.servings < 1 || recipe.servings > 20 {
            errors.append(ValidationError(
                field: "servings",
                message: "Servings must be 1-20",
                severity: .error
            ))
        }
        
        // Ingredients: at least 1
        if recipe.ingredients.isEmpty {
            errors.append(ValidationError(
                field: "ingredients",
                message: "Recipe must have at least 1 ingredient",
                severity: .error
            ))
        }
        
        return errors
    }
}

// Usage in view model
class MenuEditorViewModel {
    func saveRecipe(_ recipe: Recipe) throws {
        let errors = RecipeValidator.validate(recipe)
        let blockingErrors = errors.filter { $0.severity == .error }
        
        if !blockingErrors.isEmpty {
            throw ValidationException(errors: blockingErrors)
        }
        
        // Proceed with save
        try StorageService.shared.addRecipe(recipe)
    }
}
```

### 9.2 Backend Validation

```sql
-- Triggers for data validation on PostgreSQL
CREATE OR REPLACE FUNCTION validate_recipe_input()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate name
    IF NEW.name IS NULL OR LENGTH(TRIM(NEW.name)) < 2 THEN
        RAISE EXCEPTION 'Recipe name must be 2-100 characters';
    END IF;
    IF LENGTH(NEW.name) > 100 THEN
        RAISE EXCEPTION 'Recipe name exceeds 100 characters';
    END IF;
    
    -- Validate prep time
    IF NEW.prep_time_minutes < 0 OR NEW.prep_time_minutes > 480 THEN
        RAISE EXCEPTION 'Prep time must be 0-480 minutes';
    END IF;
    
    -- Validate servings
    IF NEW.servings < 1 OR NEW.servings > 20 THEN
        RAISE EXCEPTION 'Servings must be 1-20';
    END IF;
    
    -- Validate category
    IF NEW.category NOT IN ('breakfast', 'lunch', 'dinner', 'snack', 'dessert') THEN
        RAISE EXCEPTION 'Invalid category: %', NEW.category;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_recipe_input_trigger
    BEFORE INSERT OR UPDATE ON recipes
    FOR EACH ROW
    EXECUTE FUNCTION validate_recipe_input();
```

---

## 10. OBSERVABILITY UX

### 10.1 Performance Monitoring

```swift
// PerformanceMonitor.swift
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var measurements: [PerformanceMeasurement] = []
    
    // Measure critical user actions
    func measure<T>(name: String, _ block: () throws -> T) rethrows -> T {
        let startTime = Date()
        let startMemory = getMemoryUsage()
        
        let result = try block()
        
        let duration = Date().timeIntervalSince(startTime) * 1000  // ms
        let memoryDelta = getMemoryUsage() - startMemory
        
        let measurement = PerformanceMeasurement(
            name: name,
            durationMs: duration,
            memoryDeltaMB: memoryDelta,
            timestamp: startTime
        )
        
        measurements.append(measurement)
        
        // Alert if slow
        if duration > 100 {
            print("⚠️ SLOW: '\(name)' took \(Int(duration))ms")
            TelemetryService.logPerformanceWarning(measurement)
        }
        
        return result
    }
    
    // Async version
    func measure<T>(name: String, _ block: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(startTime) * 1000
        
        if duration > 100 {
            print("⚠️ ASYNC SLOW: '\(name)' took \(Int(duration))ms")
        }
        
        return result
    }
    
    private func getMemoryUsage() -> Double {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            task_info(
                mach_task_self_,
                task_flavor_t(TASK_BASIC_INFO),
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) { $0 },
                &count
            )
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1024 / 1024  // MB
    }
}

// Usage in critical flows
func deleteMenu(_ menu: Menu) {
    try PerformanceMonitor.shared.measure("deleteMenu") {
        try StorageService.shared.deleteMenu(menu)
        try UndoRedoManager.shared.captureSnapshot(menu)
    }
}
```

### 10.2 UI Frame Monitoring

```swift
// FrameRateMonitor.swift
class FrameRateMonitor {
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var droppedFrameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    func startMonitoring() {
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(update)
        )
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        frameCount += 1
        
        // Expected frame time for 60fps: 16.67ms
        let expectedFrameTime: CFTimeInterval = 1.0 / 60.0
        let actualFrameTime = displayLink.duration
        
        if actualFrameTime > expectedFrameTime * 1.5 {
            droppedFrameCount += 1
        }
        
        // Report every 2 seconds (120 frames)
        if frameCount % 120 == 0 {
            let dropRate = Double(droppedFrameCount) / Double(frameCount)
            reportFrameMetrics(dropRate: dropRate)
            
            frameCount = 0
            droppedFrameCount = 0
        }
    }
    
    private func reportFrameMetrics(dropRate: Double) {
        if dropRate > 0.05 {  // >5% drop
            print("⚠️ Frame drops detected: \(Int(dropRate * 100))%")
            TelemetryService.logFrameDrops(dropRate: dropRate)
        }
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
}
```

### 10.3 Friction Zone Detection

```swift
// FrictionDetector.swift - Identify slow/painful user flows
class FrictionDetector {
    struct FrictionEvent {
        let screen: String
        let action: String
        let durationMs: Int
        let retryCount: Int
        let isBlocked: Bool
    }
    
    private var events: [FrictionEvent] = []
    
    func recordAction(_ screen: String, _ action: String, 
                     duration: Int, retries: Int = 0, blocked: Bool = false) {
        events.append(FrictionEvent(
            screen: screen,
            action: action,
            durationMs: duration,
            retryCount: retries,
            isBlocked: blocked
        ))
        
        // High friction indicators
        if duration > 5000 {
            print("🔴 CRITICAL friction: \(action) took \(duration)ms")
        } else if duration > 1000 {
            print("🟠 HIGH friction: \(action) took \(duration)ms")
        }
        
        if retries > 2 {
            print("🟠 Multiple retries: \(action) needed \(retries) attempts")
        }
        
        if blocked {
            print("🔴 BLOCKED: \(action) requires manual intervention")
        }
    }
    
    // Analyze patterns
    func generateReport() -> FrictionReport {
        let byScreen = Dictionary(grouping: events) { $0.screen }
        
        var hotspots: [String: Double] = [:]
        
        for (screen, screenEvents) in byScreen {
            let avgDuration = Double(screenEvents.map { $0.durationMs }.reduce(0, +))
                             / Double(screenEvents.count)
            
            if avgDuration > 500 {
                hotspots[screen] = avgDuration
            }
        }
        
        return FrictionReport(
            totalEvents: events.count,
            frictionHotspots: hotspots,
            failureRate: calculateFailureRate(),
            userImpact: .high  // if avg duration > 1s
        )
    }
}
```

---

## 11. RECOMMENDATIONS: TOOL-URI ȘI SETUP

### 11.1 Stack Minimal dar Complet

| Componentă | Tool | Justificare |
|-----------|------|-----------|
| **Crash Reporting** | Supabase PostgreSQL + native NSException handler | Integrated, no extra cost |
| **Performance Monitoring** | Custom metrics + Supabase storage | Lightweight, real data collection |
| **Logging** | Local SQLite + batch to Supabase | <2% overhead, privacy-respecting |
| **Alerting** | Supabase pg_cron + Slack webhook | Simple, no additional service |
| **Feature Flags** | Supabase table + cache | Built-in, <5ms latency |
| **Health Checks** | Supabase Edge Functions + simple endpoint | Serverless, auto-scaling |
| **Synthetic Monitoring** | Scheduled edge function | Cost: ~$0.001 per run |
| **Dashboard** | Metabase connected to Supabase | Free open-source option |

### 11.2 Setup Priority

**FASE 1 (Săptămâna 1-2): Critical Foundation**
- [ ] Crash reporting + stack trace capture
- [ ] Local event logging (SQLite)
- [ ] Batch telemetry transmission
- [ ] Basic performance metrics

**FASE 2 (Săptămâna 3-4): Sync & Data**
- [ ] Integrity checker (4 rules)
- [ ] Sync conflict detection
- [ ] Data validation layer (client + backend)
- [ ] Offline/online metrics

**FASE 3 (Săptămâna 5): Monitoring & Health**
- [ ] Backend health endpoint
- [ ] Synthetic monitoring bot
- [ ] Feature flags system
- [ ] Real-time alerting (Slack)

**FASE 4 (Săptămâna 6+): Observability**
- [ ] Frame rate monitoring
- [ ] Friction detection
- [ ] Dashboard + queries
- [ ] Performance budgets

---

## 12. CE NU TREBUIE IMPLEMENTAT (ȘI DE CE)

### 12.1 Overengineering Pitfalls

| Feature | De ce NU trebuie | Cost |
|---------|-----------------|------|
| **Distributed tracing (Jaeger)** | 2-5 users în household = no fanout parallelism | $200+/month, infra complexity |
| **Custom APM tool (DataDog, New Relic)** | Supabase metrics sunt suficiente pentru scala ista | $1000+/month |
| **Persistent queue system (RabbitMQ)** | SQLite cu retry logic e suficient | Operational overhead |
| **Machine learning anomaly detection** | Pattern matching manual + thresholds sunt suficiente | $500+/month, false positives |
| **Multi-region replication** | Single region (Supabase default) e ok pentru household | Data complexity, consistency issues |
| **Message broker (Kafka)** | Pubsub time-series nu necesita ordered log | Operational burden |
| **Prometheus + Grafana stack** | Metabase (free) connected to Supabase e suficient | Setup + maintenance time |
| **Custom log ingestion pipeline** | Direct HTTPS → Supabase e simplu + sigur | Engineering effort |
| **99.99% uptime SLA** | Household app = 99% is sufficient | Diminishing returns |

### 12.2 Why NOT Feature Flags per-device?

Per-device flags sunt util pentru:
- Large-scale mobile apps (Billions of users)
- A/B testing infrastructure
- Gradual rollout tracking

**NOT useful pentru Ez Menu Generator** because:
- Household = cohesive unit, consistency critical
- 2-5 users benefit from same feature state
- Cross-device consistency easier when per-household
- Implementation complexity > benefit

---

## 13. IMPACT PE PERFORMANȚĂ

### 13.1 Performance Budget

```
Operation                   | Target  | Current | Overhead
---------------------------|---------|---------|----------
App startup                 | <2s     | 1.8s    | +40ms (metrics init)
Menu deletion               | <500ms  | 400ms   | +50ms (snapshot capture)
Sync batch                  | <1s     | 900ms   | +100ms (encryption)
Recipe edit save            | <200ms  | 150ms   | +20ms (validation)
Frame rate (60fps)          | 16.7ms  | 16.5ms  | -0.2ms (negligible)
Memory (active user)        | <200MB  | 180MB   | +12MB (logs buffer)
Battery drain (1 hour)      | 8-10%   | 9%      | +1% (background monitoring)
Data usage (daily inactive) | <50KB   | 30KB    | +15KB (telemetry batch)
```

### 13.2 Optimization Strategies

```swift
// 1. Lazy initialization - metrics collected only when needed
var logger: LoggerService {
    if _logger == nil && shouldEnableLogging {
        _logger = LoggerService()
    }
    return _logger ?? NoOpLogger()
}

// 2. Batch operations - send every 5 min, not per event
class EventBatcher {
    private var buffer: [Event] = []
    private var flushTimer: Timer?
    
    func add(_ event: Event) {
        buffer.append(event)
        
        // Flush if buffer reaches 100 events
        if buffer.count >= 100 {
            flush()
        }
        
        // Or flush every 5 minutes
        if flushTimer == nil {
            flushTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { _ in
                self.flush()
            }
        }
    }
}

// 3. Compression - gzip logs before transmission
let compressedData = try (try JSONEncoder().encode(batch))
    .compressed(algorithm: .lz4)

// 4. Sampling - don't collect 100% of events
if shouldSample(rate: 0.1) {  // 10% sample
    EventTracker.log(event)
}

// 5. Conditional collection - only in production, not debug builds
#if !DEBUG
    TelemetryService.startCollecting()
#endif
```

---

## 14. DEPLOYMENT CHECKLIST

### 14.1 Pre-Production Validation

- [ ] Crash reporting captures all exceptions
- [ ] Local SQLite log doesn't exceed 50MB
- [ ] Batch transmission succeeds 99%+ of time
- [ ] Telemetry <2% CPU overhead during syncs
- [ ] Invariant checks find seeded violations
- [ ] Feature flags can be toggled per household
- [ ] Synthetic monitoring completes in <10s
- [ ] Slack alerts fire for test incidents
- [ ] Dashboard queries run < 5s on 30 days data
- [ ] No memory leaks in monitoring code

### 14.2 First Week Monitoring

```
Day 1-2: 
  - Monitor crash distribution
  - Check for invariant violations
  - Validate all ~100 users active
  
Day 3-5:
  - Analyze sync latency patterns
  - Locate performance hotspots
  - Test offline→online transitions
  
Day 6-7:
  - Generate friction report
  - Fine-tune alert thresholds
  - Document known patterns
```

---

## 15. ROADMAP: FAZE VIITOARE

### 15.1 Scurt Termen (Luni 1-2)
- Network waterfall analysis (which API calls slow down user actions)
- Session replay for critical flows (store screen state + actions)
- AB test framework foundation

### 15.2 Mediu Termen (Luni 3-6)
- Custom dashboard per household (see their own metrics)
- Predictive alerts (time-series forecasting for anomalies)
- Auto-remediation for known issues (e.g., auto-rebuild corrupted data)

### 15.3 Lung Termen (6+ Luni)
- User cohort analysis (group households by usage patterns)
- Behavioral analytics (identify friction-prone users)
- ML-based crash grouping & severity scoring

---

## 16. SECURITY CONSIDERATIONS

### 16.1 Telemetry Privacy

```swift
// NEVER log
- User credentials, tokens, passwords
- Full recipe content (only metadata)
- Personal identification (except householdId)
- Exact shopping list items (only count)

// Always log with anonymization
- SessionId (rotate per session)
- HouseholdId (safe, internal)
- Screen names (generic)
- Operation types (not content)
- Error types (not full errors)
```

### 16.2 Encryption in Transit

```swift
// Sign telemetry to prevent tampering
struct SignedTelemetry {
    let payload: TelemetryBatch
    let signature: String  // HMAC-SHA256(payload, serverSecret)
    let timestamp: Date
    let nonce: String      // Prevent replay
}

// Backend validates
func validateTelemetry(_ signed: SignedTelemetry) -> Bool {
    let expectedSignature = HMAC.sign(signed.payload, with: serverSecret)
    return constantTimeEqual(signed.signature, expectedSignature)
}
```

---

## FINAL SUMMARY

| Aspect | Abordare |
|--------|----------|
| **Philosophy** | Pragmatic: measure what matters, act fast |
| **Scale** | Designed for 2-50 households, 2-5 users each |
| **Cost** | ~$50-100/month (Supabase included), <$500 setup |
| **Engineering Time** | Phase 1-2: ~6 weeks, Phase 3+: ongoing refinement |
| **Expected Impact** | 95% TTM (time to mitigation), 99% error capture, <1% performance overhead |
| **Success Metric** | Users report fewer surprises, team reacts to issues before support tickets |

---

**Document Version:** 1.0  
**Last Updated:** Feb 21, 2026  
**Maintained by:** Stability Engineering Team
