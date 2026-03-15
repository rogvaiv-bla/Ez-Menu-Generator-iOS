# 📁 Structura Concretă de Implementare

## Folder Structure

```
Ez Menu Generator/
│
├── Monitoring/                          # NEW: All monitoring + stability
│   ├── Core/
│   │   ├── EventCollector.swift        # Captures events (crashes, timings, network)
│   │   ├── EventAggregator.swift       # Groups + batches events
│   │   ├── TelemetryService.swift      # Transmits to backend
│   │   └── TelemetryModels.swift       # Codable structs for all telemetry
│   │
│   ├── Crash/
│   │   ├── CrashHandler.swift          # NSException + SwiftError catching
│   │   ├── CrashReport.swift           # Complete crash metadata
│   │   └── StackTraceParser.swift      # Parse + symbolicate stack traces
│   │
│   ├── Integrity/
│   │   ├── IntegrityManager.swift      # Orchestrator for all checks
│   │   ├── IntegrityRules.swift        # Define all 4+ domain rules
│   │   ├── IntegrityViolation.swift    # Violation struct
│   │   └── DataRepair.swift            # Auto-repair logic
│   │
│   ├── Performance/
│   │   ├── PerformanceMonitor.swift    # measure() wrapper
│   │   ├── FrameRateMonitor.swift      # CADisplayLink frame detection
│   │   └── MemoryMonitor.swift         # Track memory footprint
│   │
│   ├── Network/
│   │   ├── NetworkEventLogger.swift    # Log HTTP requests/responses
│   │   ├── SyncMetrics.swift           # Latency, retry rate, conflicts
│   │   └── ReconnectWatcher.swift      # Measure offline→online transition
│   │
│   ├── Storage/
│   │   ├── TelemetryStore.swift        # SQLite backing for local logs
│   │   ├── CrashStore.swift            # Persist crash reports locally
│   │   └── MetricsQuery.swift          # Query local metrics
│   │
│   ├── FeatureFlags/
│   │   ├── FeatureFlagManager.swift    # Check + override logic
│   │   ├── FeatureFlags+Defaults.swift # All feature definitions
│   │   └── FeatureFlagSync.swift       # Fetch from server
│   │
│   └── Dashboard/
│       ├── HealthCheckView.swift       # Show app health status
│       └── TelemetryDebugView.swift    # Dev: see local telemetry (DEBUG only)
│
├── Services/
│   ├── StorageService.swift            # (existing, but with validation)
│   ├── RealtimeSyncManager.swift       # (existing, but with metrics)
│   ├── OfflineSyncManager.swift        # (existing, but with reconnect tracking)
│   └── IntegrityChecker.swift          # NEW: runs periodically
│
├── Tests/
│   ├── Unit/
│   │   ├── Monitoring/
│   │   │   ├── EventCollectorTests.swift
│   │   │   ├── IntegrityRulesTests.swift
│   │   │   └── PerformanceMonitorTests.swift
│   │   └── Domain/
│   │       ├── MealPlanValidatorTests.swift
│   │       └── RecipeValidatorTests.swift
│   │
│   ├── Integration/
│   │   ├── Sync/
│   │   │   ├── ConflictResolutionTests.swift
│   │   │   └── SyncIntegrationTests.swift
│   │   ├── Offline/
│   │   │   └── OfflineReconnectTests.swift
│   │   └── EndToEnd/
│   │       └── HouseholdWorkflowTests.swift
│   │
│   ├── Performance/
│   │   ├── UIResponsivenessTests.swift
│   │   └── MemoryLeakTests.swift
│   │
│   └── Fixtures/
│       ├── SampleMenus.swift
│       ├── ConflictScenarios.swift
│       └── NetworkSimulators.swift
│
├── Backend/ (Supabase Edge Functions)
│   ├── functions/
│   │   ├── api/v1/telemetry.ts         # Receive + validate telemetry batches
│   │   ├── api/v1/health.ts            # Backend health endpoint
│   │   ├── cron/aggregate-metrics.ts   # pg_cron triggered
│   │   ├── cron/check-thresholds.ts    # Detect alert conditions
│   │   └── webhooks/slack-alert.ts     # Send Slack notifications
│   │
│   ├── sql/
│   │   ├── 001-telemetry-schema.sql    # Tables for events + crashes
│   │   ├── 002-integrity-triggers.sql  # Validation triggers
│   │   └── 003-metrics-views.sql       # Pre-aggregated metrics views
│   │
│   └── docker-compose.yml              # Local Supabase dev setup
│
└── Docs/
    ├── STABILITY_SYSTEM_ARCHITECTURE.md # You are here
    ├── ONBOARDING_MONITORING.md        # How to add new metrics
    ├── DEBUGGING_GUIDE.md              # How to find + triage bugs
    └── DEPLOYMENT_CHECKLIST.md         # Pre-prod validation
```

## File Sizes (estimates)

| File | LOC | Purpose |
|------|-----|---------|
| `EventCollector.swift` | 200 | Capture events with minimal overhead |
| `CrashHandler.swift` | 150 | Setup exception handlers |
| `IntegrityManager.swift` | 250 | Run periodic checks |
| `PerformanceMonitor.swift` | 180 | Measure critical operations |
| `TelemetryService.swift` | 300 | Batch + transmit telemetry |
| `FeatureFlagManager.swift` | 150 | Check flags with caching |
| All Tests | 2000+ | Comprehensive coverage |
| **Total Service Code** | ~2500 LOC | ~2% overhead on app |

## Initialization Sequence

```swift
// In AppDelegate or main App

// 1. Early: Setup crash handling ASAP
CrashHandler.setupCrashReporting()

// 2. After session init: Start monitoring
EventCollector.shared.start()
PerformanceMonitor.shared.start()
FrameRateMonitor.shared.startMonitoring()

// 3. After household loads: Start integrity checks
IntegrityManager.shared.runScheduledChecks()

// 4. On sync init: Track sync metrics
RealtimeSyncManager.shared.enableMetrics()

// 5. Background task: Periodic telemetry batch
DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 30) {
    TelemetryService.shared.flushBatchIfNeeded()
}
```

## Metrics Collection Points

```swift
// Where to instrument:

// 1. Menu operations
func deleteMenu(_ menu: Menu) -> Bool {
    return PerformanceMonitor.shared.measure("deleteMenu") {
        // ... save snapshot, delete, etc
    }
}

// 2. Network requests
URLSession.shared.dataTask { data, response, error in
    NetworkEventLogger.log(
        path: request.url?.path,
        method: request.httpMethod,
        statusCode: (response as? HTTPURLResponse)?.statusCode,
        durationMs: Int(Date().timeIntervalSince(requestStart) * 1000)
    )
}

// 3. Sync operations
func applyRecipeUpdate(_ update: RecipeUpdate) {
    let syncStart = Date()
    // ... apply update
    SyncMetrics.record(latency: Date().timeIntervalSince(syncStart))
}

// 4. Invariant checks
func validateMenuConsistency(_ menu: Menu) {
    if menu.meals.count != 7 {
        IntegrityManager.shared.recordViolation(
            rule: "menu_days_complete",
            entity: menu
        )
    }
}

// 5. Memory pressure
func onMemoryWarning() {
    MemoryMonitor.logMemoryPressure()
}
```

## Configuration (Environment)

```swift
// Config/MonitoringConfig.swift
struct MonitoringConfig {
    static let isEnabled = !DEBUG_BUILD
    static let telemetryBatchSize = 100
    static let telemetryFlushIntervalSec = 300
    static let integrityCheckIntervalSec = 300
    static let performanceWarnThresholdMs = 100
    static let crashReportingEnabled = PRODUCTION_BUILD
    static let syntheticMonitoringEnabled = PRODUCTION_BUILD
}
```

## Feature Flags - Concrete Examples

```swift
// Usage examples

if FeatureFlagManager.shared.isEnabled(.newMenuEditor) {
    // Show new UI
} else {
    // Show old UI
}

// Can be overridden locally in DEBUG:
#if DEBUG
FeatureFlagManager.shared.setLocalOverride(.realtimeSync, enabled: false)
// This will disable realtime sync for testing offline mode
#endif

// Per-household override via Supabase:
INSERT INTO feature_flag_configs (household_id, feature, enabled)
VALUES ('hh-123', 'advanced_nutrition', true);

// Result: Only household 'hh-123' sees it
```

