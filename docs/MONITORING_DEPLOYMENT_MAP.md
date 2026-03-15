# Monitoring Deployment Map
## Application vs Backend Layer Monitoring

This document clarifies what gets deployed where and how the two monitoring systems work together.

---

## The Two-Layer Monitoring Architecture

### Layer 1: **APPLICATION MONITORING** (Client-Side, Swift)
**Purpose:** Detect issues from user's perspective
- Crashes and exceptions
- Performance degradation
- UI unresponsiveness
- Data consistency problems
- Network/sync issues
- User-visible errors

**Runs In:** iOS app process
**Collects:** Local events → SQLite → HTTP batches to backend
**Latency:** Immediate (milliseconds)

### Layer 2: **BACKEND MONITORING** (Server-Side, TypeScript/PostgreSQL)
**Purpose:** Detect issues from server's perspective
- Database unavailability
- Query performance degradation
- Connection pool exhaustion
- Realtime sync failures
- Data corruption
- Edge function errors

**Runs In:** Supabase infrastructure
**Collects:** Health checks, synthetic tests, metrics → HTTP webhooks to alerting
**Latency:** 5-30 second samples

---

## Deployment Map

### WHERE EACH FILE GOES

```
YOUR EZ MENU GENERATOR WORKSPACE

Ez Menu Generator/                          [APPLICATION LAYER]
├── Services/
│   ├── HealthCheckManager.swift            ← NEW: Polls backend health
│   ├── EventCollector.swift                ← NEW: Captures local events
│   ├── PerformanceMonitor.swift            ← NEW: Measures operation timing
│   ├── IntegrityManager.swift              ← NEW: Validates data consistency
│   ├── TelemetryService.swift              ← NEW: Sends batches to backend
│   ├── CrashHandler.swift                  ← NEW: Exception reporting
│   ├── FeatureFlagManager.swift            ← NEW: Per-household features
│   └── ...existing services...
├── ViewModels/
│   ├── ...add telemetry calls...           ← Instrument critical operations
│   └── ...add integrity checks...          ← Validate before sync
└── Views/
    ├── ...show degraded indicator...       ← Use HealthCheckManager status
    └── ...graceful offline handling...     ← Use OfflineSyncManager state

supabase/                                   [BACKEND LAYER]
├── functions/
│   ├── api/v1/health.ts                    ← NEW: Health check endpoint
│   ├── api/v1/synthetic-test.ts            ← NEW: CRUD stress test
│   └── api/v1/alert.ts                     ← NEW: Slack alerting
└── migrations/
    ├── add_telemetry_tables.sql            ← NEW: Events, crashes, metrics
    ├── add_metrics_tables.sql              ← NEW: Latency, connections, etc.
    ├── add_cron_jobs.sql                   ← NEW: Scheduled checks
    └── add_integrity_checks.sql            ← NEW: Data validation functions
```

---

## Data Flow

### APPLICATION MONITORING FLOW
```
iOS App
  ↓
[EventCollector] captures: crash, slow operation, sync error, validation failure
  ↓
Local SQLite queue (batches events)
  ↓
Every 60 seconds: [TelemetryService] sends batch
  ↓
Supabase: telemetry_events table
  ↓
Alerting: Slack notification if error_rate > threshold
```

**Example:** Recipe sync hangs for 5 seconds
1. PerformanceMonitor detects timeout
2. EventCollector logs: {event: "sync_timeout", duration_ms: 5000, household_id: "abc"}
3. Queued locally
4. Batch sent to backend
5. Aggregated in dashboard
6. If >50 timeouts in 5 minutes → Slack alert

### BACKEND MONITORING FLOW
```
Backend Health Check (triggered every 30 sec from client)
  ↓
[HealthCheckManager] calls: GET /api/v1/health
  ↓
Edge Function checks:
  - Database connectivity (SELECT 1)
  - Table access speed (households, recipes, etc.)
  - Realtime channel responsiveness
  - Data integrity (orphan records)
  - Edge function latency
  ↓
Returns: {status: "healthy|degraded|critical", responseTimeMs: 87}
  ↓
Client displays indicator 🟢/🟡/🔴
  ↓
If degraded: Pause sync, show banner, queue operations
  ↓
If recovered: Resume sync, flush queue
```

**Example:** Database slow due to long-running query
1. SELECT on households takes 2 seconds (vs normal <50ms)
2. Health check detects degraded (overall latency >1500ms)
3. Client receives status: "degraded"
4. UI shows 🟡 banner: "Server responding slowly"
5. Sync pauses automatically
6. pg_cron job finds slow query in pg_stat_statements
7. Alert fires: "Query <query_id> taking >5s"

### INTEGRATION: HOW THEY TALK
```
App Problem Detected          Backend Problem Detected
        ↓                              ↓
  [EventCollector]             [Health Check API]
        ↓                              ↓
   Local queue                  [HealthCheckManager]
        ↓                              ↓
   [TelemetryService]          Change status 🔴
        ↓                              ↓
   Backend metrics          [OfflineSyncManager]
        ↓                              ↓
   Correlate by time:     Pause/Resume sync
   "iOS event @ T1       Queue for retry
    Backend alert @ T2"   Flush on recovery
        ↓
   Understand causality
```

---

## Implementation Sequence

### PHASE 1: Backend Health (Days 1-2) 
**Goal:** Client can detect backend problems

| Component | Location | Effort | Dependency |
|-----------|----------|--------|-----------|
| `/api/v1/health` endpoint | supabase/functions | 2h | None |
| HealthCheckManager | Services/ | 1.5h | health endpoint |
| Degraded banner view | Views/ | 1h | HealthCheckManager |
| **Total** | | **4.5h** | |

**Success Criteria:**
- ✅ Health endpoint returns {status, responseTimeMs}
- ✅ HealthCheckManager polls every 30 seconds
- ✅ UI shows 🟢/🟡/🔴 indicator
- ✅ Offline sync pauses when degraded
- ✅ Sync resumes automatically when healthy

---

### PHASE 2: Synthetic Testing (Days 3-4)
**Goal:** Backend can detect CRUD operation failures

| Component | Location | Effort | Dependency |
|-----------|----------|--------|-----------|
| `/api/v1/synthetic-test` | supabase/functions | 2h | Phase 1 |
| pg_cron scheduler | supabase/migrations | 1h | Phase 1 |
| Synthetic test logs table | DB | 0.5h | - |
| **Total** | | **3.5h** | Phase 1 |

**Success Criteria:**
- ✅ Synthetic test runs every 5 minutes
- ✅ CRUD operations complete in <20 seconds
- ✅ Test failures logged with details
- ✅ Health check fails if synthetic test takes >15s

---

### PHASE 3: Metrics & Alerting (Days 5-7)
**Goal:** Team gets advanced warning of problems

| Component | Location | Effort | Dependency |
|-----------|----------|--------|-----------|
| Metrics collection SQL | supabase/migrations | 1.5h | Phase 1-2 |
| pg_cron metric jobs | supabase/migrations | 1h | - |
| `/api/v1/alert` endpoint | supabase/functions | 1.5h | - |
| Slack webhook setup | - | 0.5h | Slack workspace |
| **Total** | | **4.5h** | Phase 1-2 |

**Success Criteria:**
- ✅ Metrics tables populated by cron jobs
- ✅ Query latency percentiles calculated
- ✅ Alert rules fire on threshold breach
- ✅ Slack notifications show severity + details

---

### PHASE 4: Application Monitoring (Week 2)
**Goal:** App can report issues to backend

| Component | Location | Effort | Dependency |
|-----------|----------|--------|-----------|
| EventCollector integration | Services/ | 2h | Phase 1-3 |
| PerformanceMonitor setup | Services/ | 1.5h | - |
| IntegrityManager rules | Services/ | 2h | - |
| TelemetryService transmission | Services/ | 1.5h | - |
| Instrument ViewModels | ViewModels/ | 3h | All above |
| **Total** | | **10h** | Phase 1-3 |

**Success Criteria:**
- ✅ Crashes captured + reported
- ✅ Operations >100ms get flagged
- ✅ Data consistency violations logged
- ✅ Telemetry visible in dashboard

---

## Real-World Example: Recipe Sync Failure

### Scenario: User's recipe sync hangs intermittently

#### WITHOUT Monitoring
```
User: "The app is broken! I can't add recipes!"
Developer: "Hmm, works fine on my machine..."
(3 days later: Someone finally reproduces it)
```

#### WITH Monitoring (System Detects It Automatically)

**Minute 1:** User attempts to add 3 recipes while on cellular
- App: Sync timeout after 5 seconds
- EventCollector logs: sync_timeout, latency=5000ms, network=cellular
- Queued locally (8 events buffer up)

**Minute 2:** Health check runs on client
- Calls /api/v1/health
- Backend responds: {status: "degraded", responseTimeMs: 2847}
- HealthCheckManager shows 🟡
- UI displays banner: "Server responding slowly, will try again"
- OfflineSyncManager pauses outgoing sync

**Minute 3:** Backend metrics collection runs
- Detects: active_connections=45/50 (pool nearly full)
- Detects: avg_query_latency_p95=1823ms (vs normal 87ms)
- pg_cron alert rule triggers

**Minute 4:** Backend health check gets worse
- Synthetic test CREATE fails: 15 seconds
- Health returns: {status: "critical", responseTimeMs: 9847}
- Client receives critical status 🔴
- Sync pauses completely, app queues all operations

**Minute 5-7:** Supabase infrastructure auto-scales
- Connection pool grows
- Queries complete faster
- Health check detects improvement

**Minute 8:** Backend returns to healthy
- Health check: {status: "healthy", responseTimeMs: 92}
- Client 🟢 indicator reappears
- OfflineSyncManager flushes queued operations
- User's 8 buffered recipes sync successfully
- No data loss, user experience graceful

**Result:** Developer receives:
```
🔴 CRITICAL @ 09:04: Backend connection pool exhausted (45/50)
📊 Query latency P95: 1823ms (alert: >500ms)
📋 Synthetic test CREATE: 15000ms (alert: >5s)
📱 App events: 8 sync_timeout events, queued locally
✅ RECOVERED @ 09:08: All metrics normal, sync resumed
```

**Without monitoring:** Debug for 3 hours, never see the problem.
**With monitoring:** See the problem in real-time, data points for debugging.

---

## Integration Checklist

### Before You Deploy Phase 1

- [ ] Create Supabase project (if not exist)
- [ ] Note Project URL and API key
- [ ] Copy HealthCheckManager.swift to Services/
- [ ] Replace "YOUR-PROJECT" with actual Project URL
- [ ] Create telemetry tables SQL migration
- [ ] Deploy /api/v1/health Edge Function
- [ ] Test health endpoint returns valid response
- [ ] Import HealthCheckManager in main app
- [ ] Call HealthCheckManager.setupHealthChecking() in AppDelegate
- [ ] Add observation for BackendDegraded notification
- [ ] Add degraded banner to main view
- [ ] Test full flow: simulate backend unavailable, verify banner shows

### Before You Deploy Phase 2

- [ ] Verify Phase 1 working in production
- [ ] Deploy /api/v1/synthetic-test Edge Function
- [ ] Create synthetic test log table
- [ ] Setup pg_cron job for 5-minute interval
- [ ] Test synthetic test runs and logs results
- [ ] Verify health check incorporates synthetic test results
- [ ] Monitor synthetic test performance in production

### Before You Deploy Phase 3

- [ ] Verify Phases 1-2 stable in production
- [ ] Create metrics tables (latency, connections, etc.)
- [ ] Deploy pg_cron metric collection jobs
- [ ] Deploy /api/v1/alert Edge Function
- [ ] Get Slack webhook URL
- [ ] Store webhook URL in Supabase secrets
- [ ] Setup alert rules in pg_cron
- [ ] Test alert triggers and Slack notifications
- [ ] Configure severity colors and messages

### Before You Deploy Phase 4

- [ ] Verify Phases 1-3 stable in production
- [ ] Copy EventCollector.swift, PerformanceMonitor.swift, IntegrityManager.swift to Services/
- [ ] Setup telemetry event tables in database
- [ ] Create TelemetryService to batch and transmit events
- [ ] Instrument critical operations with PerformanceMonitor.measure()
- [ ] Add EventCollector.logEvent() calls for crashes/errors
- [ ] Add IntegrityManager.checkIntegrity() calls before sync
- [ ] Verify events flowing to backend
- [ ] Setup dashboard to visualize telemetry data

---

## Monitoring Architecture Summary

### Client-Side (Swift files in Services/)
```swift
┌─────────────────────────────────────────────────────────────┐
│                      iOS Application                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [HealthCheckManager]  ← Polls /api/v1/health every 30s    │
│         ↓                                                    │
│  Status: 🟢 Healthy / 🟡 Degraded / 🔴 Critical          │
│         ↓                                                    │
│  [OfflineSyncManager]  ← Pauses/Resumes based on status    │
│         ↓                                                    │
│  [EventCollector]      ← Captures: crashes, timeouts, etc. │
│         ↓                                                    │
│  SQLite local queue    ← Buffered until synced              │
│         ↓                                                    │
│  [TelemetryService]    ← Sends batches to backend           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Backend-Side (TypeScript + PostgreSQL)
```
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [/api/v1/health]        ← Endpoint for health checks       │
│  - Database check         ← SELECT 1 on critical tables     │
│  - Realtime check         ← Broadcast on sync channel       │
│  - Integrity check        ← Find orphan/corrupted records   │
│  - Edge function latency  ← Time the health check itself    │
│         ↓                                                    │
│  Status: healthy/degraded/critical + responseTimeMs         │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [/api/v1/synthetic-test] ← CRUD stress test (every 5min)  │
│  - INSERT test record                                        │
│  - READ test record                                          │
│  - DELETE test record                                        │
│         ↓                                                    │
│  Metrics: operation duration, success/failure, total time   │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [pg_cron jobs] (scheduled SQL)                             │
│  - Every 5 min: Collect query latency percentiles           │
│  - Every 5 min: Count active connections                    │
│  - Every hour: Calculate table bloat/dead tuples            │
│  - Every minute: Check alert thresholds, fire if needed     │
│         ↓                                                    │
│  Metrics stored in: metrics_latency, metrics_connections... │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [/api/v1/alert] ← Send alerts via Slack webhook            │
│  Severity: critical (red) / alert (orange) / warning (yellow)│
│  Content: Metric name, value, threshold, recommendation     │
│         ↓                                                    │
│  Slack notification: "#errors channel"                      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Success Metrics

### Phase 1 Success
✅ Health check endpoint responds in <100ms (healthy state)
✅ Client health status matches actual backend state
✅ UI indicator shows correct status 99% of time
✅ Sync pauses/resumes correctly on status change
✅ No false positives (client shows OK when backend OK)

### Phase 2 Success
✅ Synthetic test runs every 5 minutes
✅ Normal CRUD completes in <5 seconds
✅ Degraded state detected when synthetic takes >15s
✅ Health check incorporates synthetic test result
✅ Critical state triggered if synthetic fails

### Phase 3 Success
✅ Metrics tables populated every 5 minutes
✅ Query latency percentiles tracked and queryable
✅ Connection pool monitoring shows trends
✅ Alert rules fire within 1 minute of threshold breach
✅ Slack notifications correlate with actual backend state

### Phase 4 Success
✅ App captures and reports crashes
✅ Slow operations (>100ms) logged automatically
✅ Data consistency violations detected and escalated
✅ Telemetry visible in dashboard with trends
✅ UI responsiveness monitored for frame drops

---

## Operation: Health Check Example Response

### Healthy State (200 OK)
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T09:30:45Z",
  "responseTimeMs": 87,
  "checks": [
    {
      "component": "database_connection",
      "healthy": true,
      "responseTimeMs": 12,
      "detail": "Connection test passed"
    },
    {
      "component": "households_table",
      "healthy": true,
      "responseTimeMs": 8,
      "detail": "6 records, 2.3 MB"
    },
    {
      "component": "realtime_channel",
      "healthy": true,
      "responseTimeMs": 34,
      "detail": "Broadcast test passed"
    },
    {
      "component": "data_integrity",
      "healthy": true,
      "responseTimeMs": 5,
      "detail": "0 orphan records found"
    }
  ]
}
```

### Degraded State (200 OK, but degraded flag)
```json
{
  "status": "degraded",
  "timestamp": "2024-01-15T09:35:12Z",
  "responseTimeMs": 1823,
  "checks": [
    {
      "component": "database_connection",
      "healthy": true,
      "responseTimeMs": 412,
      "detail": "Connection slow; active connections: 45/50",
      "severity": "warning"
    },
    {
      "component": "households_table",
      "healthy": true,
      "responseTimeMs": 1087,
      "detail": "Query slow; long-running query detected"
    },
    {
      "component": "realtime_channel",
      "healthy": true,
      "responseTimeMs": 234,
      "detail": "Broadcast delayed"
    },
    {
      "component": "synthetic_test",
      "healthy": true,
      "responseTimeMs": 12847,
      "detail": "CREATE test taking 12.8s (threshold: 5s)",
      "severity": "alert"
    }
  ],
  "errors": [
    "high_connection_count: 45/50 connections active",
    "slow_synthetic_test: CREATE operation taking 12.8 seconds"
  ]
}
```

### Critical State (503 Service Unavailable)
```json
{
  "status": "critical",
  "timestamp": "2024-01-15T09:40:33Z",
  "responseTimeMs": 9847,
  "checks": [
    {
      "component": "database_connection",
      "healthy": false,
      "responseTimeMs": 9821,
      "detail": "Connection pool exhausted, getting timeout",
      "severity": "critical"
    }
  ],
  "errors": [
    "database_unavailable: Connection pool exhausted (50/50)",
    "realtime_unreachable: Cannot broadcast to sync channel",
    "synthetic_test_failed: All CRUD operations timing out"
  ]
}
```

---

## Troubleshooting Common Issues

### "Health check always returns unknown"
- [ ] Verify HealthCheckManager.sv
ift imported
- [ ] Confirm HealthCheckManager.setupHealthChecking() called
- [ ] Check Firebase URL is correct (replace "YOUR-PROJECT")
- [ ] Verify /api/v1/health Edge Function deployed
- [ ] Check network connectivity (test with curl)
- [ ] Enable verbose logging: `os_log(..., type: .debug)`

### "UI shows degraded but backend looks fine"
- [ ] Check health endpoint latency (should be <100ms healthy)
- [ ] Verify synthetic test threshold (alert at >5s per operation)
- [ ] Check database connection pool (is it > 80% utilized?)
- [ ] Look for long-running queries in pg_stat_statements
- [ ] Verify pg_cron jobs running on schedule

### "Sync pauses but never resumes"
- [ ] Verify OfflineSyncManager observing BackendHealthy notification
- [ ] Check HealthCheckManager status transitions
- [ ] Confirm health endpoint recovers when backend fixed
- [ ] Test manually: stop health checks, start again

### "Slack alerts not firing"
- [ ] Verify webhook URL in Supabase secrets
- [ ] Test webhook manually with curl + JSON
- [ ] Check pg_cron job exists and scheduled
- [ ] Verify alert rule SQL syntax
- [ ] Check PostgreSQL error logs

---

## Next Steps

1. **Choose your starting point:**
   - Option A: Start with Phase 1 (health checks) if you want immediate backend visibility
   - Option B: Integrate EventCollector first if you want to report app issues
   - Option C: Do both in parallel with separate teams

2. **Document any custom requirements:**
   - Different thresholds for your data?
   - Additional tables to monitor?
   - Different alert channels (email, SMS)?
   - Custom integrity rules for your domain?

3. **Set up your dashboard:**
   - Create a simple Supabase SQL query UI
   - Or use Grafana + PostgreSQL connector
   - Or export metrics to third-party APM tool

4. **Train your team:**
   - What each indicator means (🟢/🟡/🔴)
   - When to investigate alerts
   - How to read error details in dashboard

5. **Iterate based on learnings:**
   - Adjust thresholds after 2 weeks of data
   - Add monitoring for new features
   - Refine alerts to reduce false positives

---

**End of Deployment Map**

---

## Quick Reference: File Locations

| System | Component | File | Language | Deployment |
|--------|-----------|------|----------|-----------|
| **APP** | Health polling | `Services/HealthCheckManager.swift` | Swift | App bundle |
| **APP** | Event capture | `Services/EventCollector.swift` | Swift | App bundle |
| **APP** | Perf timing | `Services/PerformanceMonitor.swift` | Swift | App bundle |
| **APP** | Data validation | `Services/IntegrityManager.swift` | Swift | App bundle |
| **APP** | Telemetry transmission | `Services/TelemetryService.swift` | Swift | App bundle |
| **BACKEND** | Health checks | `supabase/functions/api/v1/health.ts` | TypeScript | Edge Functions |
| **BACKEND** | CRUD testing | `supabase/functions/api/v1/synthetic-test.ts` | TypeScript | Edge Functions |
| **BACKEND** | Alerting | `supabase/functions/api/v1/alert.ts` | TypeScript | Edge Functions |
| **DB** | Metrics/Telemetry | `supabase/migrations/*.sql` | SQL | PostgreSQL |
| **DB** | Scheduled jobs | `supabase/migrations/*_cron.sql` | SQL | pg_cron |
