# ARCHITECTURE DIAGRAMS - VISUAL OVERVIEW

## 1. Complete System Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        iOS App (Swift 6)                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │  CorrelationIDManager                                               │  │
│  │  ├─ sessionId: generates at app launch                              │  │
│  │  ├─ requestId: generates per API call                              │  │
│  │  ├─ userId + householdId: set on login                            │  │
│  │  └─ deviceId: from UIDevice.identifierForVendor                   │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│           │                                                                 │
│           ├────────────────────────────────────────────────────────────┐  │
│           │                                                            │   │
│           ▼                                                            ▼   │
│  ┌────────────────────────┐  ┌──────────────────────────────────────┐   │
│  │ StorageService         │  │ SupabaseService                      │   │
│  │ (Local SwiftData)      │  │ (Network API)                        │   │
│  ├────────────────────────┤  ├──────────────────────────────────────┤   │
│  │ addRecipe()            │  │ request()                             │   │
│  │ addMenu()              │  │ ├─ Extract correlationId              │   │
│  │ deleteRecipe()         │  │ ├─ Add to X-Correlation-ID header     │   │
│  │ deleteMenu()           │  │ ├─ Track timing (network + server)    │   │
│  │ └─ Logger.logOp()      │  │ └─ Logger.logPerformance()            │   │
│  └────────────────────────┘  └──────────────────────────────────────┘   │
│           │                                    │                          │
│           │                                    │                          │
│           └────────────────┬───────────────────┘                          │
│                            │                                              │
│           ┌────────────────▼────────────────┐                            │
│           │  Logger Facade                  │                            │
│           │ (Public API for logging)         │                            │
│           ├─────────────────────────────────┤                            │
│           │ logOperation()                  │                            │
│           │ logError()                      │                            │
│           │ logSync()                       │                            │
│           │ logPerformance()                │                            │
│           │ logRealtime()                   │                            │
│           │ logInfo()                       │                            │
│           │ trackRequest()                  │                            │
│           └─────────────┬────────────────────┘                           │
│                         │                                                 │
│                         ▼                                                 │
│           ┌─────────────────────────────────┐                            │
│           │ LocalLogger                     │                            │
│           │ (In-memory buffer + SQLite)     │                            │
│           ├─────────────────────────────────┤                            │
│           │ • Queue: async dispatch         │                            │
│           │ • Batch writes every 100 logs   │                            │
│           │ • Persist critical (error+)    │                            │
│           │ • Auto-cleanup (7 day rotation) │                            │
│           └─────────────┬────────────────────┘                           │
│                         │                                                 │
│                         ▼                                                 │
│           ┌─────────────────────────────────┐                            │
│           │ LogDatabase (SQLite)            │                            │
│           │ ~/Documents/Logs/logs.sqlite    │                            │
│           ├─────────────────────────────────┤                            │
│           │ • ~50MB max size per session     │                            │
│           │ • 7 day retention               │                            │
│           │ • Indexed: timestamp, user, hh  │                            │
│           │ • WAL mode for concurrency      │                            │
│           └─────────────────────────────────┘                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
         │                                                    │
         │                                                    │
         │ HTTP + X-Correlation-ID header                  │ Export JSON
         │                                                    │
         ▼                                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Supabase Backend                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  Edge Function Middleware                                            │  │
│  │  ├─ Extract X-Correlation-ID from request header                    │  │
│  │  ├─ Log operation (timestamp, duration, status)                     │  │
│  │  ├─ Handle errors → log stack trace                                 │  │
│  │  └─ Return response with correlation ID header                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│           │                                                                 │
│           ▼                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  PostgreSQL Database                                                 │  │
│  │                                                                      │  │
│  │  Tables:                                                             │  │
│  │  ├─ recipes (primary data)                                          │  │
│  │  ├─ menus (primary data)                                            │  │
│  │  │                                                                   │  │
│  │  └─ audit_logs ─────────────────────────────────────┐              │  │
│  │     (Immutable: INSERT only, RLS enabled)           │              │  │
│  │     ├─ user_id, household_id, correlation_id       │              │  │
│  │     ├─ event_type, level, category                 │              │  │
│  │     ├─ operation details, error details            │              │  │
│  │     ├─ performance metrics (timing)                │              │  │
│  │     ├─ sync conflict info                          │              │  │
│  │     └─ realtime latency measurements               │              │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│           │                                                                 │
│           └─────────────────┬───────────────────────────────────────┐     │
│                             │                                       │     │
│                             ▼                                       ▼     │
│                  ┌────────────────────────┐  ┌─────────────────────────┐   │
│                  │ Realtime Trigger       │  │ Extract Transform Load   │   │
│                  │ (postgres_changes)     │  │ (Batch to remote)        │   │
│                  ├────────────────────────┤  ├─────────────────────────┤   │
│                  │ • Detect INSERT/UPDATE │  │ • Sample (10% in prod)   │   │
│                  │ • Measure latency      │  │ • Compress                │   │
│                  │ • Log sequence #       │  │ • Batch upload every 5m  │   │
│                  │ • Detect missing msgs  │  │ • Dumb logs > 30 days    │   │
│                  └────────────────────────┘  └─────────────────────────┘   │
│                             │                             │                │
└─────────────────────────────│─────────────────────────────│────────────────┘
                              │                             │
                              │ Postgres LISTEN            │ HTTPS POST
                              │ → iOS realtime             │ → Sentry/LogFlare
                              │                             │
                              ▼                             ▼
                    ┌──────────────────────┐   ┌─────────────────────────┐
                    │ iOS RealtimeSyncMgr  │   │ Observability Stack     │
                    │ ├─ Receive UPDATE    │   ├─────────────────────────┤
                    │ ├─ Measure latency   │   │ Sentry                  │
                    │ └─ Log realtime      │   │ ├─ Error tracking       │
                    │    events            │   │ ├─ Performance profiling│
                    └──────────────────────┘   │ └─ Alerts               │
                                              │                         │
                                              │ LogFlare                │
                                              │ ├─ Real-time search     │
                                              │ ├─ Saved queries        │
                                              │ └─ Custom dashboards    │
                                              │                         │
                                              │ Grafana + Loki          │
                                              │ ├─ Metrics visualization│
                                              │ ├─ Trends & patterns    │
                                              │ └─ Alert rules          │
                                              └─────────────────────────┘
```text

---

## 2. Event Flow: Adding a Recipe

```text
User taps "Add Recipe"
        │
        ▼
┌──────────────────────────┐
│ generateRequestId()      │
│ ├─ new request_id        │
│ └─ update context        │
└──────────────────────────┘
        │
        ▼
┌──────────────────────────┐
│ LOCAL LOG #1             │
│ event: addRecipe         │
│ status: form_opened      │
│ offline: true/false      │
└──────────────────────────┘
        │
        ▼
User fills form + submits
        │
        ▼
┌──────────────────────────┐
│ Validation               │
│ ├─ name not empty        │
│ ├─ category selected     │
│ └─ other fields OK       │
└──────────────────────────┘
        │
        ▼
┌──────────────────────────┐
│ LOCAL LOG #2             │
│ event: addRecipe         │
│ status: validating       │
└──────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ StorageService.addRecipe()                               │
│ ├─ context.insert(recipe)                                │
│ ├─ context.save()                                        │
│ └─ Logger.logOperation()                                 │
│    ├─ correlationId: sid_abc|rid_123|uid_xyz|hid_def    │
│    ├─ event: addRecipe                                   │
│    ├─ entity: recipe_uuid                                │
│    ├─ duration: 12ms                                     │
│    └─ status: success                                    │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ LOCAL LOG #3 (in-memory buffer)                          │
│ {timestamp, correlation_id, level: info,                │
│  category: sync, event_type: addRecipe,                 │
│  operation: {...}, performance: {...}}                  │
└──────────────────────────────────────────────────────────┘
        │
        ├─ Batch to SQLite every 100 logs
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ SQLite INSERT                                            │
│ INSERT INTO logs (timestamp, correlation_id, ..., data) │
│ VALUES (...)                                             │
└──────────────────────────────────────────────────────────┘
        │
        ├─ If online: also send to Sentry
        │  (async, background, sampled 10%)
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ POST /rest/v1/recipes (SupabaseService)                  │
│                                                          │
│ Request:                                                 │
│ ├─ Header: X-Correlation-ID: sid_abc|rid_123|uid_xyz   │
│ ├─ Body: {name, category, servings, ...}                │
│ └─ Timing: starts at T0                                  │
└──────────────────────────────────────────────────────────┘
        │
        ▼ Network latency (156ms example)
        │
┌──────────────────────────────────────────────────────────┐
│ Edge Function (Supabase)                                 │
│ ├─ Receives request at T1 (T0 + 156ms)                  │
│ ├─ Extracts correlation_id header                       │
│ ├─ Validates recipe data                                │
│ ├─ INSERT INTO recipes (...)  [45ms database]           │
│ ├─ INSERT INTO audit_logs (...) [5ms]                   │
│ │  ├─ user_id, household_id, correlation_id            │
│ │  ├─ operation: create recipe_uuid                     │
│ │  └─ before/after values                               │
│ └─ Returns 201 + response                               │
└──────────────────────────────────────────────────────────┘
        │
        ▼ Network latency (150ms example)
        │
┌──────────────────────────────────────────────────────────┐
│ iOS Response Handler (T2 = T0 + 306ms)                  │
│ ├─ Receive 201 + recipe_id                              │
│ ├─ Logger.logPerformance()                              │
│ │  ├─ networkLatencyMs: 156                             │
│ │  ├─ serverProcessingMs: 45                            │
│ │  └─ totalEndToEndMs: 306                              │
│ └─ Update UI: "Recipe created"                          │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Realtime Subscription triggers UPDATE                    │
│ ├─ Postgres publishes to realtime channel               │
│ ├─ iOS receives INSERT notification                     │
│ ├─ Latency: 87ms (broadcast)                            │
│ └─ Logger.logRealtime()                                 │
│    ├─ channel: household_def:recipes                    │
│    ├─ event: INSERT                                     │
│    └─ latencyMs: 87                                     │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ UI Updated (Realtime)                                    │
│ └─ Recipe appears in list instantly                      │
└──────────────────────────────────────────────────────────┘

Timeline Visualization:
T0  ────────────────────────────────────────────────────────────────
    User taps                                      UI updates
    │ 12ms (local)                                   │ 87ms (realtime)
    ├─────────────────────────────────────────────────┼─────────────
    │ 156ms (network to server)                       │
    │                                                 │
    T1 ──────────────────────────────────────────────────────────
       Edge Function                    Response received
       │ 45ms (database)                  │
       ├─────────────────────────────────┼──────────────
       │ 150ms (network back)             │ Total: 306ms
       │
       ├─────────────────────────────────┤
       T2 (T0 + 306ms)
```text

---

## 3. Sync Conflict Resolution Flow

```text
Offline: User modifies recipe
        │
        ▼
┌──────────────────────────────────┐
│ Device Status: OFFLINE           │
│ Logger.logSync(offline: true)    │
│ ├─ event: Recipe modified       │
│ ├─ offline: true                 │
│ └─ network_status: no connection │
└──────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────┐
│ Offline Queue                    │
│ ├─ Store in CoreData            │
│ └─ Mark for sync when online    │
└──────────────────────────────────┘
        │
   (30 seconds later)
        │
        ▼
Connected!
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ SyncManager.syncOfflineChanges()                         │
│ └─ Logger.logSync(                                       │
│    event: "Sync started",                               │
│    eventType: .syncStart                                │
│    )                                                     │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Check: Is there a server version newer than local?      │
│                                                          │
│ Local version:                  Server version:         │
│ ├─ modified_at: 20:25:00       ├─ modified_at: 20:27:00│
│ ├─ name: "My Recipe (edited)"  ├─ name: "My Recipe"    │
│ └─ version: 2                  └─ version: 3           │
│                                                          │
│ → 20:27:00 > 20:25:00 → SERVER WINS                    │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Logger.logSync(                                          │
│   event: "Sync conflict: last write wins",              │
│   eventType: .syncConflict,                             │
│   conflict: "version_mismatch",                         │
│   mergeStrategy: "last_write_wins",                     │
│   dataLoss: true,                                       │
│   lostFields: ["name"]                                 │
│ )                                                        │
│                                                          │
│ SQL: INSERT INTO audit_logs (                           │
│   conflict_detected: true,                              │
│   conflict_type: "version_mismatch",                    │
│   conflict_resolution: "server_wins",                   │
│   data_loss_detected: true                              │
│ )                                                        │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Discard Local Changes                                   │
│ └─ Delete local edited version                          │
│ └─ Fetch latest from server                             │
│ └─ Update local database                                │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Notify User                                              │
│ ├─ 🔔 "Your changes were overwritten by server version" │
│ ├─ Show what was lost                                   │
│ └─ Logger.logInfo(                                       │
│    message: "User notified of data loss"                │
│    )                                                     │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Sync Completed                                           │
│ └─ Logger.logSync(                                       │
│    event: "Sync completed",                             │
│    eventType: .syncSuccess                              │
│    )                                                     │
└──────────────────────────────────────────────────────────┘
```text

---

## 4. Error + Retry Sequence

```text
API Request Starts
        │
        ▼
POST /rest/v1/recipes (30s timeout)
        │
  (25 seconds pass)
        │
        ▼
❌ URLError -1001: Request timed out
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Logger.logError(                                         │
│   code: "NETWORK_TIMEOUT",                              │
│   message: "Request timed out after 30 seconds",        │
│   domain: "URLSession",                                 │
│   error: error,                                         │
│   willRetry: true,                                      │
│   retryCount: 0                                         │
│ )                                                        │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Add to Retry Queue                                       │
│ ├─ backoff_delay: 1000ms (exponential)                  │
│ ├─ max_retries: 3                                       │
│ └─ current_attempt: 1/3                                 │
└──────────────────────────────────────────────────────────┘
        │
   (wait 1000ms)
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Retry Attempt #1                                         │
│ └─ Logger.logInfo(                                       │
│    event: "Retry attempt 1/3",                          │
│    backoff_ms: 1000                                     │
│    )                                                     │
└──────────────────────────────────────────────────────────┘
        │
        ▼
POST /rest/v1/recipes (30s timeout)
        │
   (2 seconds pass)
        │
        ▼
✅ 201 Created + Response
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Logger.logPerformance(                                   │
│   name: "/rest/v1/recipes",                             │
│   totalEndToEndMs: 2000,                                │
│   retryAttempt: 1,                                      │
│   finalSuccess: true                                    │
│ )                                                        │
└──────────────────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────┐
│ Sentry (if sampled)                                      │
│ └─ Record: "Network timeout recovered after 1 retry"    │
└──────────────────────────────────────────────────────────┘
```text

---

## 5. Data Storage Locations

```text
CLIENT DEVICE (iOS)
├── ~/Documents/logs.sqlite          [~50MB max]
│   ├─ sqlite index on timestamp DESC
│   ├─ sqlite index on user_id
│   ├─ sqlite index on correlation_id
│   └─ 7-day auto retention
│
└── os_log (system unified logs)
    ├─ Used by Xcode console
    ├─ Filterable by subsystem
    └─ Persisted by OS (~50GB total per device)

SERVER (Supabase PostgreSQL)
├── audit_logs table
│   ├─ indexed: timestamp DESC
│   ├─ indexed: user_id, timestamp
│   ├─ indexed: entity_type, entity_id
│   ├─ RLS: audit trail immutable
│   ├─ 30-day hot (indexed)
│   ├─ 30-365 day cold (archived)
│   └─ >1 year deleted (GDPR)
│
└── pg_trgm index for full-text search

REMOTE (Observability Stacks)
├── Sentry
│   ├─ Errors only (sampled 10%)
│   ├─ Stack traces + breadcrumbs
│   ├─ Performance profiling
│   └─ 30-day retention
│
├── LogFlare
│   ├─ All logs (1GB/month)
│   ├─ Real-time search
│   └─ Custom dashboards
│
└── Grafana Loki (self-hosted, optional)
    ├─ Metrics + traces
    ├─ Trend analysis
    └─ Custom alert rules
```text

---

## 6. Query Paths (How to Find Information)

```text
Question: "What happened when user X added a recipe?"
│
├─ LOCAL: LocalLogger.getLogs(userId: X)
│  └─ Result: [LogEntry] with all local operations
│
├─ SERVER: SELECT * FROM audit_logs WHERE user_id = X
│  └─ Result: Complete server-side timeline
│
└─ REALTIME: Follow correlation_id from request
   └─ Result: Full trace across all systems

Question: "Was there a sync conflict in household Y?"
│
├─ LOCAL: getLogs(householdId: Y).filter { $0.sync?.conflict != nil }
│
├─ SERVER: SELECT * FROM audit_logs 
│          WHERE household_id = Y AND conflict_detected = true
│
└─ SENTRY: Search for "syncConflict" events in household Y
   └─ Result: Visual timeline with impact

Question: "Why is the app slow?"
│
├─ LOCAL: Export logs, sort by totalEndToEndMs DESC
│
├─ SERVER: SELECT event_type, AVG(total_duration_ms) 
│          FROM audit_logs WHERE timestamp > now() - '24h'
│          GROUP BY event_type
│
├─ GRAFANA: View p50, p90, p99 percentiles
│
└─ SENTRY: Check performance alerting dashboard
   └─ Result: Slowest operations identified

Question: "Are we losing data?"
│
├─ LOCAL: getLogs().filter { $0.sync?.dataLoss == true }
│
├─ SERVER: SELECT * FROM audit_logs 
│          WHERE data_loss_detected = true
│
├─ SENTRY: Critical alert triggered automatically
│
└─ ACTION: Immediate investigation + incident response
   └─ Result: Root cause identified + fixed
```text

---

## 7. Performance Impact Matrix

```text
Operation               Local ms   Network ms   Server ms   Total ms   Impact
────────────────────────────────────────────────────────────────────────────────
Log operation           <0.5       0            0           <0.5       negligible
Log error               5-10       0            0           5-10       minor
Serialize to JSON       2-5        0            0           2-5        minor
SQLite batch write      3-8        0            0           3-8        minor
Send to Sentry          0          100-500      20          150-500    background
Request + log + track   0.5        156          45          201        expected

Combined overhead per API call: 5-10ms local + 100-500ms network logging
                               = <3% impact on 3-5 second operations
                               = imperceptible for user

Target: < 5% overhead maintained by:
├─ Async batch writes
├─ Sampling in production
├─ Background network uploads
└─ No blocking on main thread
```text

---

## 8. Deployment Topology

```text
                    ┌─────────────────────────────┐
                    │   App Store / TestFlight    │
                    │  (Contains 3 logging files) │
                    └──────────────┬──────────────┘
                                  │
                        ┌─────────┴────────┐
                        │                  │
                        ▼                  ▼
                 ┌──────────────┐  ┌──────────────┐
                 │  User Device │  │  User Device │
                 │  [iOS 17.3]  │  │  [iOS 17.4]  │
                 │               │  │               │
                 │ LocalLogger   │  │ LocalLogger   │
                 │ + SQLite      │  │ + SQLite      │
                 └────────┬──────┘  └───────┬───────┘
                          │                 │
                          └────────┬────────┘
                                   │
                                   │ HTTPS POST
                                   │ (async, batched)
                                   │
                    ┌──────────────▼───────────────┐
                    │   Supabase Backend          │
                    │                             │
                    │ ├─ Edge Functions           │
                    │ ├─ PostgreSQL DB            │
                    │ │  └─ audit_logs table      │
                    │ └─ Realtime (websockets)    │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
         ┌────────────────────┐     ┌──────────────────┐
         │ Sentry (if sampled)│     │ LogFlare/Loki    │
         │ - Errors           │     │ - All logs       │
         │ - Performance      │     │ - Real-time      │
         │ - Alerts           │     │ - Dashboards     │
         └────────────────────┘     └──────────────────┘
                    │                             │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │   On-Call Dashboard      │
                    │  + Alert Notifications   │
                    └──────────────────────────┘
```text

These diagrams visualize the complete architecture, data flows, and integration points for your logging system.
