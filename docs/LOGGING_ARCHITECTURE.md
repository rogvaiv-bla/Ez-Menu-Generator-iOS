# SISTEM AVANSAT DE LOGGING ȘI OBSERVABILITY

## EXECUTIVE SUMMARY

Acesta este un sistem enterprise-grade de observabilitate proiectat pentru:

- **Diagnosticare rapidă** a oricărui incident în <2 minute
- **Traseabilitate completă** a fluxurilor user-to-database
- **Detectare automată** a erorilor silențioase și conflictelor
- **Minimul impact pe performance** (<5ms overhead per operație)

## 1. ARHITECTURA SISTEMULUI

### Componentele principale

```text
CLIENT (iOS)                BACKEND (Supabase)          OBSERVABILITY
├─ LocalLogger              ├─ RequestLogger            ├─ Sentry
├─ CorrelationIDManager     ├─ RealtimeLogger           ├─ LogFlare
├─ EventTracker             ├─ SyncLogger               └─ Prometheus
└─ ErrorCapturer            └─ AuditLogger
```text

### Fluxul unei operații cu logging complet

```text
1. USER ACTION (iOS)
   └─→ generateRequestId()
       └─→ correlationId = sid_abc|rid_def|uid_123|hid_456
   
2. LOCAL LOG (before network)
   └─→ 📝 event_type: addRecipe
       └─→ status: pending
       └─→ timestamp: T0
       └─→ stored in SQLite locally
   
3. OFFLINE DETECTION
   └─→ if offline: store locally + retry queue
       if online: continue
   
4. HTTP REQUEST
   └─→ Header: X-Correlation-ID: sid_abc|rid_def|uid_123|hid_456
       └─→ Body: { recipe_data... }
   
5. EDGE FUNCTION LOGGING
   └─→ 📝 entry_time: T0 + network_latency
       └─→ extract correlation_id from header
       └─→ operation_id: unique per execution
   
6. DATABASE OPERATION
   └─→ 📝 INSERT INTO recipes (...)
       └─→ rows_affected: 1
       └─→ execution_time: 45ms
   
7. AUDIT LOG
   └─→ 📝 WHO: user_12345
       └─→ WHAT: created recipe_xyz
       └─→ WHEN: T_op
       └─→ BEFORE: {}
       └─→ AFTER: { name, category, ... }
   
8. REALTIME BROADCAST
   └─→ 📝 channel: household_456:recipes
       └─→ latency: 87ms between update & broadcast
       └─→ subscribers: 3
   
9. RESPONSE TO CLIENT
   └─→ includes idempotency_key + operation_id
       for client-side correlation
   
10. LOCAL LOG UPDATE (iOS)
    └─→ 📝 event_type: addRecipe
        └─→ status: success
        └─→ server_response_time: 156ms
        └─→ total_duration: 201ms
        └─→ timestamp: T0 + duration
```text

---

## 2. STRUCTURA EXACTĂ A LOG ENTRY-ULUI

### Format JSON complet pe firul de execuție

```json
{
  "log_metadata": {
    "version": "1.0",
    "timestamp": "2026-02-20T20:30:45.123Z",
    "epoch_ms": 1708447845123
  },
  
  "correlation": {
    "correlation_id": "sid_abc123_rid_45678_uid_user12_hid_hh67890",
    "session_id": "sid_abc123",
    "request_id": "rid_45678",
    "operation_id": "op_xyz789_t20_30_45",
    "trace_id": "trace_complete_flow"
  },
  
  "identity": {
    "user_id": "user_12345",
    "household_id": "household_67890",
    "device_id": "device_iphone_a1b2c3d4",
    "app_version": "1.2.3",
    "os": "iOS",
    "os_version": "17.3"
  },
  
  "event": {
    "level": "info",
    "category": "sync",
    "event_type": "addRecipe",
    "message": "Recipe created successfully",
    "source": "ios_app"
  },
  
  "operation": {
    "name": "StorageService.addRecipe()",
    "entity_type": "Recipe",
    "entity_id": "recipe_001_uuid",
    "action": "create",
    "status": "success",
    "changes_count": 1
  },
  
  "data_changes": {
    "before": null,
    "after": {
      "id": "recipe_001_uuid",
      "name": "Meniu din Februarie",
      "category": "Diverse",
      "servings": 4,
      "created_at": "2026-02-20T20:30:44.000Z"
    },
    "fields_changed": [
      "id",
      "name",
      "category",
      "servings",
      "created_at"
    ]
  },
  
  "network": {
    "type": "wifi",
    "connectivity_status": "online",
    "was_offline": false,
    "sync_pending": false
  },
  
  "timing": {
    "client_local_ms": 12,
    "network_latency_ms": 156,
    "server_processing_ms": 45,
    "server_database_ms": 28,
    "server_response_ms": 9,
    "client_deserialization_ms": 8,
    "total_end_to_end_ms": 201,
    "queue_wait_ms": 0
  },
  
  "performance": {
    "memory_before_mb": 145.2,
    "memory_after_mb": 146.8,
    "cpu_usage_percent": 12.5,
    "battery_impact_percent": 0.1
  },
  
  "error": null,
  
  "realtime": null,
  
  "sync": {
    "conflict": null,
    "merge_strategy": null,
    "offline_changes_queued": 0,
    "offline_changes_synced": 0
  },
  
  "security": {
    "pii_redacted": true,
    "sensitive_fields_masked": ["password", "auth_token"],
    "encryption_status": "client_side_encrypted"
  },
  
  "metadata": {
    "retry_count": 0,
    "retry_backoff_ms": 0,
    "idempotency_key": "idem_abc123_recipe_001",
    "idempotent": true
  }
}
```text

### Error Log Complet

```json
{
  "log_metadata": {
    "version": "1.0",
    "timestamp": "2026-02-20T20:31:15.456Z"
  },
  
  "correlation": {
    "correlation_id": "sid_abc123_rid_45679_uid_user12_hid_hh67890",
    "session_id": "sid_abc123",
    "request_id": "rid_45679",
    "operation_id": "op_error_failed_001"
  },
  
  "identity": {
    "user_id": "user_12345",
    "household_id": "household_67890"
  },
  
  "event": {
    "level": "error",
    "category": "api",
    "event_type": "apiError",
    "message": "Failed to sync menu: Network timeout"
  },
  
  "error": {
    "code": "NETWORK_TIMEOUT",
    "domain": "SupabaseService",
    "message": "Network request timed out after 30 seconds",
    "description": "Failed to fetch menu updates from server",
    
    "stack_trace": [
      "MenuEditorViewModel.syncMenu() -> line 234",
      "StorageService.fetchAllMenus() -> line 89",
      "SupabaseService.request() -> line 156",
      "URLSession.dataTask(with:) -> network layer"
    ],
    
    "underlying_error": {
      "type": "URLError",
      "code": -1001,
      "description": "The request timed out."
    },
    
    "context": {
      "operation": "fetchMenus",
      "request_url": "https://[project].supabase.co/rest/v1/menus",
      "http_method": "GET",
      "timeout_seconds": 30,
      "attempt": 1,
      "total_attempts": 3
    },
    
    "recovery": {
      "will_retry": true,
      "retry_delay_ms": 1000,
      "retry_backoff": "exponential",
      "max_retries": 3,
      "retry_count_so_far": 0
    },
    
    "user_impact": {
      "feature_affected": "menu_sync",
      "user_can_continue": true,
      "offline_fallback_available": true,
      "data_loss_risk": false
    }
  },
  
  "timing": {
    "error_detected_ms": 30000,
    "total_time_ms": 30156
  },
  
  "sync": {
    "offline_changes_at_error": 2,
    "will_retry_offline_queue": true
  },
  
  "metadata": {
    "error_tracking_id": "sentry_abc123def456",
    "should_alert": false,
    "alert_priority": "info"
  }
}
```text

### Sync Conflict Log

```json
{
  "log_metadata": {
    "timestamp": "2026-02-20T20:32:00.789Z"
  },
  
  "correlation": {
    "correlation_id": "sid_abc123_rid_45680_uid_user12_hid_hh67890"
  },
  
  "event": {
    "level": "warning",
    "category": "sync",
    "event_type": "syncConflict",
    "message": "Sync conflict detected: local vs server recipe versions"
  },
  
  "sync": {
    "conflict_type": "last_write_wins",
    "entity_type": "Recipe",
    "entity_id": "recipe_001_uuid",
    
    "local": {
      "version": 2,
      "last_modified": "2026-02-20T20:25:00.000Z",
      "modified_by": "user_12345",
      "data": {
        "name": "Meniu Feb Local",
        "category": "Local Edit"
      }
    },
    
    "server": {
      "version": 3,
      "last_modified": "2026-02-20T20:27:00.000Z",
      "modified_by": "user_99999",
      "data": {
        "name": "Meniu Feb Server",
        "category": "Server Edit"
      }
    },
    
    "resolution": {
      "strategy": "last_write_wins",
      "won_by": "server",
      "reason": "Server timestamp (20:27) > local (20:25)",
      "result": {
        "name": "Meniu Feb Server",
        "category": "Server Edit"
      },
      "local_changes_discarded": [
        "category"
      ]
    },
    
    "impact": {
      "user_might_lose_data": true,
      "notification_sent": true,
      "notification_type": "conflict_warning",
      "user_can_revert": false
    }
  },
  
  "metadata": {
    "conflict_id": "conflict_001_20260220_202000"
  }
}
```text

### Offline Changes Log

```json
{
  "log_metadata": {
    "timestamp": "2026-02-20T20:33:30.100Z"
  },
  
  "event": {
    "level": "info",
    "category": "offline",
    "event_type": "offlineChange",
    "message": "Recipe modified while offline - queued for sync"
  },
  
  "network": {
    "connectivity_status": "offline",
    "was_online": true,
    "went_offline_at": "2026-02-20T20:30:00.000Z"
  },
  
  "operation": {
    "entity_type": "Recipe",
    "entity_id": "recipe_local_uuid",
    "action": "create",
    "offline": true
  },
  
  "data": {
    "change": {
      "name": "New Recipe Offline",
      "category": "Diverse"
    },
    "pending_sync": true,
    "added_to_queue": 1,
    "queue_position": 5
  },
  
  "metadata": {
    "offline_change_id": "offline_001_recipe_create",
    "will_retry_on_connection": true
  }
}
```text

### Realtime Latency Log

```json
{
  "log_metadata": {
    "timestamp": "2026-02-20T20:34:45.321Z"
  },
  
  "event": {
    "level": "info",
    "category": "realtime",
    "event_type": "subscribe",
    "message": "Subscribed to household realtime updates"
  },
  
  "realtime": {
    "channel": "household_67890:recipes",
    "event": "INSERT",
    "action": "subscribe",
    
    "broadcast_timing": {
      "database_write_time": "2026-02-20T20:34:44.500Z",
      "broadcast_time": "2026-02-20T20:34:45.100Z",
      "client_receive_time": "2026-02-20T20:34:45.321Z",
      
      "db_to_broadcast_ms": 600,
      "broadcast_to_client_ms": 221,
      "total_latency_ms": 821
    },
    
    "message": {
      "id": "msg_realtime_001",
      "sequence_number": 45,
      "format": "postgres_changes_v1"
    },
    
    "subscribers": {
      "active_count": 3,
      "user_ids": ["user_12345", "user_67890", "user_11111"]
    }
  }
}
```text

---

## 3. RECOMANDĂRI DE TOOL-URI

### Pentru o aplicație senoasă dar mică

| Tool | Cazul de utilizare | Cost | Complexitate |
|------|-------------------|------|--------------|
| **Sentry** | Error tracking + perf monitoring | Free tier suficient (5K events/month) | Low - one library init |
| **LogFlare** | Real-time log search + alerts | $49/month (1GB/month) | Medium - custom parsing |
| **Grafana Loki** | Self-hosted log aggregation | Free (but need server) | High - DevOps knowledge |
| **Firebase Crashlytics** | Crashes + ANRs | Free | Very low - integrated iOS |
| **Custom PostgreSQL** | Audit log complete | $0 | Medium - your backend |
| **Datadog** | All-in-one | €15-30/day | High - enterprise |

### RECOMANDARE PENTRU TINE

**"Hybrid minimal" approach:**

```text
┌─ Sentry (free tier)
│  └─ Errors + performance issues
│
├─ LogFlare (pay-as-you-go)
│  └─ Real-time debugging
│
├─ Custom PostgreSQL audit_logs table
│  └─ Business logic audit trail
│
└─ Local SQLite
   └─ Offline queue + failed retry tracking
```text

**Cost estimat: $50-100/month**

---

## 4. EXEMPLE CONCRETE DE LOGĂRI

### 1. ADD RECIPE HAPPY PATH

```text
⏱️  T0: User taps "Add Recipe" button
├─ 📝 generateRequestId() → rid_abc123
├─ 🔵 LOCAL LOG: event_type=addRecipe status=pending
├─ ✍️  Navigate to form
│
⏱️  T0+5s: User fills form + submits
├─ 🔵 LOCAL LOG: form validation started
├─ ✅ Validation passed
├─ 🔵 LOCAL LOG: ready to send
│
⏱️  T0+6s: Network request sent
├─ 📡 POST /rest/v1/rpc/add_recipe
│   Header: X-Correlation-ID: sid_xyz|rid_abc123
│   Body: { name, category, ... }
├─ 🔴 Edge Function receives
│   ├─ Extracts correlation_id
│   ├─ 📝 edge_log: "Recipe creation started"
│   ├─ Validates data
│   ├─ INSERT INTO recipes (...)
│   ├─ 📝 edge_log: "Database INSERT completed (45ms)"
│   ├─ 📝 audit_log: WHO=user_12345 WHAT=created WHEN=T record={...}
│   └─ Success response
│
⏱️  T0+6.2s: Response received on iOS
├─ 🔵 LOCAL LOG: response received
├─ ✅ Response validation passed
├─ 📝 Update UI state
├─ 🔘 UI: "Recipe created"
├─ 🔵 LOCAL LOG: total_time_ms=200 network_latency_ms=156
│
⏱️  T0+6.3s: Realtime subscription receives INSERT
├─ 📡 Postgres LISTEN notification
├─ 🔴 Edge Function publishes to realtime
├─ 📝 realtime_log: latency=87ms
├─ 🔵 iOS app receives via subscription
├─ ✅ Local recipe list updated
├─ 🔵 LOCAL LOG: realtime_update received latency=87
└─ ✅ UI updated
```text

**Log-urile generate (simplificat):**

```json
// LOCAL LOG 1 (iOS)
{
  "timestamp": "2026-02-20T20:35:00.100Z",
  "level": "info",
  "event_type": "addRecipe",
  "status": "pending"
}

// LOCAL LOG 2 (iOS)
{
  "timestamp": "2026-02-20T20:35:00.200Z",
  "level": "info",
  "event_type": "addRecipe",
  "status": "submitted",
  "network": "online"
}

// EDGE FUNCTION LOG
{
  "timestamp": "2026-02-20T20:35:00.356Z",
  "correlation_id": "sid_xyz|rid_abc123",
  "event_type": "addRecipe",
  "source": "edge_function",
  "status": "success",
  "timing": {
    "network_latency_ms": 156,
    "processing_ms": 45
  }
}

// AUDIT LOG (PostgreSQL)
{
  "timestamp": "2026-02-20T20:35:00.350Z",
  "user_id": "user_12345",
  "household_id": "household_67890",
  "action": "INSERT",
  "table": "recipes",
  "row_id": "recipe_001_uuid",
  "old_values": null,
  "new_values": { "name": "Meniu Feb", "category": "Diverse" }
}

// LOCAL LOG 3 (iOS - final)
{
  "timestamp": "2026-02-20T20:35:00.400Z",
  "level": "info",
  "event_type": "addRecipe",
  "status": "success",
  "total_duration_ms": 300,
  "network_latency_ms": 156
}
```text

---

### 2. SYNC CONFLICT RESOLUTION

```text
⏱️  T0: User offline, locally edits recipe
├─ 📝 LOCAL LOG: offline_change entity=recipe_001 action=UPDATE
├─ 📝 QUEUE: mark for sync
│
⏱️  T0+1m: Network reconnects
├─ 🟢 Connectivity restored
├─ 📝 LOCAL LOG: connectivity_status=online
│
⏱️  T0+1.5m: Sync manager wakes up
├─ 📝 LOCAL LOG: sync_start pending_changes=1
├─ Check if server version is newer
├─ Server version: 3 (modified 20:27) > local: 2 (modified 20:25)
├─ 📝 LOCAL LOG: conflict_detected strategy=last_write_wins
│
Decision: Server wins (more recent)
├─ 📝 LOCAL LOG: conflict_resolution won_by=server
├─ Discard local changes
├─ Fetch latest from server
├─ Update local database
├─ 📝 CONFLICT LOG: conflict_id=001 strategy=LWW
│
⏱️  T0+1.6m: Notification to user
├─ 🔔 Show: "Your changes were overwritten by server version"
├─ 📱 UI: Show "Undo" button (not functional, logged intent)
├─ 📝 LOCAL LOG: user_notified_of_conflict
└─ 🟢 Sync complete
```text

**Log-urile:**

```json
// OFFLINE CHANGE LOG
{
  "level": "info",
  "event_type": "offlineChange",
  "entity": "recipe_001",
  "action": "UPDATE",
  "network_status": "offline"
}

// CONFLICT DETECTED LOG
{
  "level": "warning",
  "event_type": "syncConflict",
  "conflict_type": "last_write_wins",
  "local_version": 2,
  "server_version": 3,
  "local_modified_at": "2026-02-20T20:25:00Z",
  "server_modified_at": "2026-02-20T20:27:00Z",
  "resolution": "server_wins"
}

// CONFLICT RESOLUTION LOG
{
  "level": "info",
  "event_type": "conflictResolved",
  "strategy": "last_write_wins",
  "user_notified": true,
  "data_loss":yes,
  "lost_fields": ["category_changed"]
}
```text

---

### 3. ERROR API TIMEOUT + RETRY

```text
⏱️  T0: User syncs menu
├─ 📝 LOCAL LOG: sync_start
├─ 📡 POST /rest/v1/menus timeout=30s
│
⏱️  T0+30s: Network timeout
├─ ❌ Error: URLError -1001 (timeout)
├─ 📝 ERROR LOG: code=NETWORK_TIMEOUT attempt=1/3
├─ 📝 Queue: mark for retry
│
⏱️  T0+31s: Retry logic (exponential backoff)
├─ Wait 1000ms
├─ 📝 LOCAL LOG: retry_attempt=1 retry_delay=1000ms
│
⏱️  T0+32s: Retry #1
├─ 📡 POST /rest/v1/menus timeout=30s
├─ ✅ Success
├─ 📝 LOCAL LOG: retry_success attempt_number=1
└─ 🟢 Data synced
```text

**Logurile:**

```json
// ERROR LOG 1
{
  "timestamp": "2026-02-20T20:36:00.000Z",
  "level": "error",
  "event_type": "apiError",
  "code": "NETWORK_TIMEOUT",
  "message": "Request timed out after 30 seconds",
  "domain": "URLSession",
  "retry_count": 0,
  "will_retry": true,
  "retry_delay_ms": 1000
}

// RETRY ATTEMPT LOG
{
  "timestamp": "2026-02-20T20:36:01.000Z",
  "level": "info",
  "event_type": "retryAttempt",
  "attempt_number": 1,
  "total_attempts": 3,
  "backoff_strategy": "exponential"
}

// SUCCESS LOG
{
  "timestamp": "2026-02-20T20:36:02.000Z",
  "level": "info",
  "event_type": "apiSuccess",
  "attempt_number": 1,
  "total_attempts_needed": 1
}
```text

---

### 4. DATA LOSS DETECTION

```text
⏱️  T0: Realtime UPDATE received
├─ 📝 REALTIME LOG: channel=household event=UPDATE
├─ Data: recipe_001 category changed
├─ Message ID: msg_001 sequence: 45
│
⏱️  T0+1ms: Next message expected
├─ 📝 REALTIME LOG: expecting seq=46
│
⏱️  T0+200ms: Message received
├─ ❌ Sequence jump! msg_002 seq=48 (missing seq=46,47)
├─ 📝 ALERT LOG: messages_lost=2 missing_seqs=[46,47]
├─ 📝 Initiate full sync to recovery
│
⏱️  T0+500ms: Full sync complete
├─ ✅ Database verified
├─ 📝 DATA_LOSS_DETECTED: false (data verified present)
├─ 📝 LOG: "Dropped messages but no data loss detected"
└─ 🟢 Realtime stream resumed
```text

**Logurile:**

```json
// MESSAGE LOSS DETECTION LOG
{
  "level": "critical",
  "event_type": "dataLoss",
  "issue": "missing_realtime_messages",
  "expected_sequence": [46, 47],
  "received_sequence": 48,
  "messages_lost_count": 2
}

// DATA LOSS VERIFICATION LOG
{
  "level": "info",
  "event_type": "dataLossRecovery",
  "messages_were_lost": true,
  "data_loss_confirmed": false,
  "full_sync_triggered": true,
  "recovery_time_ms": 300
}
```text

---

## 5. CE NU TREBUIE LOGAT ȘI DE CE

### FORBIDDEN (Never log)

```text
❌ Passwords, API keys, tokens
   Reason: Security risk, GDPR violation
   
❌ Full credit card numbers
   Reason: PCI-DSS compliance
   
❌ SSN, national IDs
   Reason: Identity theft risk
   
❌ Full email addresses (sometimes)
   Alternative: Log only domain, hash first 3 chars
   
❌ Full names in error messages
   Alternative: Log user_id instead
   
❌ Precise geolocation
   Alternative: Log city/region only
   
❌ Device IMEI or hardware serial
   Reason: Can fingerprint users
   
❌ Search queries if user-identifiable
   Reason: Can reveal confidential info
```text

### Masking Strategy

```swift
// ✅ DO THIS
"email": "u***@gmail.com"  // mask middle
"phone": "+1(***) *** 4567"  // show only last 4
"credit_card": "****-****-****-1234"  // last 4 only

// ❌ DON'T DO THIS
"email": "password123@gmail.com"
"phone": "+14155552671"
"credit_card": "4532-1234-5678-9876"
```text

---

## 6. IMPACT PE PERFORMANCE

### Benchmark-uri pentru fiecare operație

```text
Operation                      Overhead    Impact        Mitigation
─────────────────────────────────────────────────────────────────
generateRequestId()            < 0.1ms     negligible   ✅
log write to memory            < 0.2ms     negligible   ✅
log serialize to JSON          2-5ms       minor        Async queue
log write to SQLite            3-8ms       minor        Batch writes
  (local)
realtime message log           < 1ms       negligible   ✅
error capture + stack trace    5-15ms      noticeable   Sample 1%
Sentry/LogFlare send           100-500ms   significant  Background thread
```text

### Optimization Techniques

```swift
// 1. BATCH WRITES (not every log individually)
// ❌ SLOW: Each log = SQLite fsync
for log in 1000 logs {
    db.insert(log)  // 1000 fsyncs!
}

// ✅ FAST: Batch transactions
db.batch(logs: 1000)  // 1 fsync

// 2. ASYNC QUEUE (don't block UI thread)
// ❌ SLOW: Blocking
Logger.log(entry)  // blocks main thread

// ✅ FAST: Background queue
DispatchQueue.utility.async {
    LocalLogger.shared.log(entry)
}

// 3. SAMPLING (reduce observability overhead)
// ❌ SLOW: Log everything
if let error = error { Logger.logError(error) }

// ✅ FAST: Probabilistic sampling (10% of errors)
if Int.random(0..<100) < 10 {  // 10% chance
    Logger.logError(error)
}

// 4. LOCAL FILTERING (don't send unimportant stuff)
// ❌ SLOW: Send all debug logs to backend
Logger.debug("Button tapped")  // 100K times/day!

// ✅ FAST: Filter at source
#if DEBUG
    Logger.debug("Button tapped")  // local only
#endif

// 5. DATA COMPRESSION
// ❌ SLOW: Full JSON payloads
let json = try JSONEncoder().encode(logs)  // 10MB

// ✅ FAST: Compressed + sampled
let compressed = try gzip(jsonData)  // 1MB
```text

### Performance Budget

```text
Total logging overhead per sync: < 50ms
├─ Local logging: < 5ms (batch)
├─ Network logging headers: < 1ms
├─ Remote logging upload: 20-40ms (async)
└─ Realtime logging: < 5ms

User won't notice if < 100ms total overhead.
```text

---

## 7. STRATEGIE DE STOCARE

### Local (Device)

```text
Location: ~/Documents/logs.sqlite
Max size: 50MB
Retention: 7 days auto-delete
Format: Structured JSON in BLOB

Queries:
├─ Find all errors in last 24h: instant
├─ Find all requests with correlation_id: instant
├─ Find conflicts for specific household: < 100ms
└─ Export for Sentry: < 1s
```text

### Backend (PostgreSQL)

```text
Table: audit_logs
Indexing:
├─ CREATE INDEX idx_user_timestamp ON audit_logs(user_id, timestamp DESC)
├─ CREATE INDEX idx_household ON audit_logs(household_id)
├─ CREATE INDEX idx_correlation ON audit_logs(correlation_id)
└─ CREATE INDEX idx_level ON audit_logs(level)

Retention:
├─ Keep 30 days hot (indexes)
├─ Archive to cold storage after 30 days
└─ Delete after 1 year (GDPR)

Query examples:
├─ "What changed in recipe_001 in last 24h?" → 10ms
├─ "All changes by user_12345 in February?" → 50ms
└─ "Find conflicts in household_67890?" → 100ms
```text

### Remote (Sentry/LogFlare)

```text
Volume: ~1-5K errors/month (should be low!)
Cost: Free tier sufficient
Retention: 30 days free

What to send:
├─ Errors
├─ Critical warnings  
├─ Performance issues (>1s)
└─ Data loss events

What NOT to send:
├─ Debug logs
├─ Info messages
├─ Success states
└─ Offline queue items
```text

---

## 8. IMPLEMENTARE STEP-BY-STEP

### FAZA 1 (Week 1) Core Infrastructure

```swift
// ✅ Implement
├─ LogEntry struct + Codable
├─ LocalLogger (in-memory buffer)
├─ CorrelationIDManager
├─ Basic SQLite storage
└─ Logger convenience facade

// Test:
├─ Log 10K entries, verify no memory leak
├─ Verify SQLite persists correctly
├─ Check startup time < 50ms
```text

### FAZA 2 (Week 2): Integration

```swift
// ✅ Add logging to existing code
├─ StorageService.addRecipe() → logOperation()
├─ MenuListViewModel.deleteMenu() → logOperation()
├─ SupabaseService.request() → logPerformance()
├─ ErrorHandler → logError()
└─ RealtimeManager → logRealtime()

// Test:
├─ Verify correlation IDs propagate
├─ Check no regression in speed
├─ Manual testing with Xcode logs
```text

### FAZA 3 (Week 3): Remote Backends

```swift
// ✅ Configure
├─ Sentry integration + DSN
├─ LogFlare setup + API key
├─ PostgreSQL audit_logs table
└─ Batch uploader (background)

// Test:
├─ Simulate error, see in Sentry
├─ Check LogFlare dashboard
├─ Verify audit logs in PostgreSQL
```text

### FAZA 4 (Week 4): Dashboards & Alerts

```swift
// ✅ Create
├─ Grafana dashboard (real-time metrics)
├─ Sentry alert rules (errors > 5/min)
├─ LogFlare saved queries
└─ Daily email digest
```text

---

## 9. ALERTE CRITICE


Setup pentru a fi notificat rapid:

```text
| Alert | Threshold | Action |
|-------|-----------|--------|
| Error rate > 5% | immediate | Slack + SMS |
| Sync failures > 10 in 5min | high | Slack |
| Network latency > 5s | warning | Slack |
| Data loss detected | critical | SMS + page |
| Offline queue > 1000 | warning | Slack |
| Realtime disconnects > 3/min | warning | Slack |
| Database > 90% CPU | critical | page me |
```text

---

## 10. QUERIES UTILE PENTRU DEBUGGING

```sql
-- Find all operations for a user in last 24h
SELECT * FROM audit_logs 
WHERE user_id = 'user_12345' 
AND timestamp > now() - interval '1 day'
ORDER BY timestamp DESC;

-- Find conflicts in specific household
SELECT * FROM audit_logs 
WHERE household_id = 'hh_67890'
AND data->>'event_type' = 'syncConflict'
ORDER BY timestamp DESC;

-- Performance outliers (requests > 1 second)
SELECT correlation_id, 
       (data->>'total_end_to_end_ms')::int as duration_ms
FROM audit_logs 
WHERE (data->>'total_end_to_end_ms')::int > 1000
ORDER BY duration_ms DESC
LIMIT 10;

-- Error patterns in last 7 days
SELECT data->>'code' as error_code,
       COUNT(*) as frequency,
       MAX(timestamp) as latest
FROM audit_logs 
WHERE level = 'error'
AND timestamp > now() - interval '7 days'
GROUP BY error_code
ORDER BY frequency DESC;

-- User experienced data loss?
SELECT * FROM audit_logs 
WHERE data->>'event_type' = 'dataLoss'
AND user_id = 'user_12345'
ORDER BY timestamp DESC;
```text

---

## CONCLUZIE

Acest sistem oferă:
✅ **Visibility** - poți vedea exact ce se întâmplă
✅ **Auditability** - compliance-ready (GDPR, SOC2)
✅ **Debuggability** - poți găsi bugs în < 5 minute
✅ **Performance** - < 5% overhead
✅ **Cost-effective** - $50-100/month
✅ **Scalable** - prêt să crească

Implementează în 4 săptămâni = production-ready observability.
