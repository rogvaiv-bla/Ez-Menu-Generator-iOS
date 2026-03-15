# 🔧 SISTEM MONITORIZARE BACKEND SUPABASE

**Vers. 1.0** | Ez Menu Generator Backend Monitoring | Feb 21, 2026

---

## EXECUTIVE SUMMARY

### Principii
1. **Backend as Blackbox**: Monitor behavior, not internals we can't control
2. **Household-first**: Each household should know their own backend health
3. **Offline graceful**: Client knows when backend is degraded, adapts behavior
4. **Pgn + Realtime focused**: Most issues are either query latency or sync delay
5. **Minimal overhead**: <1 extra connection per check, <100ms per health call

### Stack Implemented
- **Health Checks**: Edge Function at `/api/v1/health`
- **Synthetic Transactions**: Scheduled task every 5 minutes
- **Metrics**: SQL views pre-aggregating critical data
- **Alerting**: pg_cron + webhook to external service
- **Client-side**: Detect degradation, show UI indicator, queue offline

---

## 1. HEALTH CHECK ARCHITECTURE

### 1.1 What Gets Checked?

```
┌─ Database Layer
│  ├─ TCP connection (can connect?)
│  ├─ Query execution (SELECT 1 - 10ms max)
│  ├─ App table access (households table - 50ms max)
│  └─ RLS policies work (user can query their household)
│
├─ Realtime Layer
│  ├─ WebSocket connection possible
│  ├─ Can subscribe to channel
│  ├─ Broadcast works (publish + receive)
│  └─ <5 second round-trip
│
├─ Edge Functions
│  ├─ Can invoke function
│  ├─ Function responds (<2s)
│  └─ Response format valid
│
└─ Data Consistency
   ├─ No orphan records detected
   ├─ Sync operations queue status
   └─ Last successful sync age
```

### 1.2 Health Check Endpoint

```swift
// Supabase Edge Function: /api/v1/health
// Called every 30 seconds from client (when online)
// Also called by synthetic monitor every 5 minutes

export async function handler(req: Request) {
    const startTime = Date.now()
    const checks: HealthCheck[] = []
    const errors: string[] = []
    
    try {
        // 1. Database connectivity
        const dbCheck = await checkDatabaseHealth()
        checks.push(dbCheck)
        if (!dbCheck.healthy) errors.push("Database unhealthy")
        
        // 2. Critical table access
        const tableCheck = await checkCriticalTables()
        checks.push(tableCheck)
        if (!tableCheck.healthy) errors.push("Cannot access tables")
        
        // 3. Realtime channel
        const realtimeCheck = await checkRealtimeChannel()
        checks.push(realtimeCheck)
        if (!realtimeCheck.healthy) errors.push("Realtime channel down")
        
        // 4. Data consistency
        const integrityCheck = await checkDataIntegrity()
        checks.push(integrityCheck)
        
        // 5. Edge function health
        const functionCheck = {
            component: "edge_function",
            healthy: true,
            responseTimeMs: Date.now() - startTime,
            timestamp: new Date().toISOString()
        }
        checks.push(functionCheck)
        
        // Determine overall status
        const overallHealthy = checks.every(c => c.healthy || c.component === "data_integrity")
        const overallStatus = overallHealthy ? "healthy" : 
                             checks.some(c => c.severity === "critical") ? "critical" :
                             "degraded"
        
        return new Response(JSON.stringify({
            status: overallStatus,
            checks: checks,
            timestamp: new Date().toISOString(),
            responseTimeMs: Date.now() - startTime,
            errors: errors
        }), {
            headers: { 'Content-Type': 'application/json' },
            status: overallHealthy ? 200 : 503
        })
        
    } catch (error) {
        return new Response(JSON.stringify({
            status: "critical",
            error: error.message,
            timestamp: new Date().toISOString(),
            checks: checks
        }), {
            status: 503,
            headers: { 'Content-Type': 'application/json' }
        })
    }
}
```

### 1.3 Example Response - Healthy

```json
{
  "status": "healthy",
  "timestamp": "2026-02-21T14:30:00Z",
  "responseTimeMs": 87,
  "checks": [
    {
      "component": "database",
      "healthy": true,
      "responseTimeMs": 3,
      "detail": "SELECT 1 executed"
    },
    {
      "component": "critical_tables",
      "healthy": true,
      "responseTimeMs": 12,
      "detail": "households, recipes, menus accessible",
      "recordCount": {
        "households": 42,
        "recipes": 1203,
        "menus": 156
      }
    },
    {
      "component": "realtime",
      "healthy": true,
      "responseTimeMs": 45,
      "detail": "WebSocket connected, broadcast success",
      "channelLatencyMs": 42
    },
    {
      "component": "data_integrity",
      "healthy": true,
      "responseTimeMs": 25,
      "issues": [],
      "detail": "No integrity violations detected"
    },
    {
      "component": "edge_function",
      "healthy": true,
      "responseTimeMs": 87,
      "detail": "Function responding normally"
    }
  ],
  "errors": []
}
```

### 1.4 Example Response - Degraded

```json
{
  "status": "degraded",
  "timestamp": "2026-02-21T14:31:15Z",
  "responseTimeMs": 1823,
  "checks": [
    {
      "component": "database",
      "healthy": true,
      "responseTimeMs": 1205,
      "detail": "SELECT 1 slow but responded",
      "severity": "warning"
    },
    {
      "component": "critical_tables",
      "healthy": true,
      "responseTimeMs": 612,
      "detail": "Query took longer than expected"
    },
    {
      "component": "realtime",
      "healthy": false,
      "responseTimeMs": 5000,
      "detail": "WebSocket timeout exceeded",
      "severity": "critical"
    },
    {
      "component": "data_integrity",
      "healthy": false,
      "responseTimeMs": 8,
      "issues": [
        {
          "type": "orphan_ingredient",
          "count": 3,
          "detail": "Ingredients referencing deleted recipes"
        }
      ],
      "severity": "warning"
    },
    {
      "component": "edge_function",
      "healthy": true,
      "responseTimeMs": 1823
    }
  ],
  "errors": [
    "Realtime channel down",
    "Database query latency high",
    "Data integrity issues detected"
  ]
}
```

### 1.5 Example Response - Critical

```json
{
  "status": "critical",
  "timestamp": "2026-02-21T14:32:45Z",
  "responseTimeMs": 9847,
  "checks": [
    {
      "component": "database",
      "healthy": false,
      "responseTimeMs": 9847,
      "detail": "Connection timeout",
      "severity": "critical"
    },
    {
      "component": "critical_tables",
      "healthy": false,
      "responseTimeMs": null,
      "detail": "Cannot check (database down)"
    },
    {
      "component": "realtime",
      "healthy": false,
      "detail": "Cannot check (database down)"
    },
    {
      "component": "edge_function",
      "healthy": true,
      "responseTimeMs": 12,
      "detail": "Function alive but cannot reach database"
    }
  ],
  "errors": [
    "Database down - TCP connection failed",
    "Cannot access application data"
  ]
}
```

### 1.6 Health Check Implementation Details

```typescript
// Detailed implementation of each check

async function checkDatabaseHealth(): Promise<HealthCheck> {
    const start = Date.now()
    try {
        const { error } = await supabase.from('households').select('count').limit(1)
        
        if (error) {
            return {
                component: 'database',
                healthy: false,
                responseTimeMs: Date.now() - start,
                detail: error.message,
                severity: 'critical'
            }
        }
        
        const responseTime = Date.now() - start
        
        return {
            component: 'database',
            healthy: true,
            responseTimeMs: responseTime,
            detail: responseTime < 50 ? 'Fast' : 'Slow but responsive',
            severity: responseTime > 100 ? 'warning' : 'info'
        }
    } catch (error) {
        return {
            component: 'database',
            healthy: false,
            responseTimeMs: Date.now() - start,
            detail: error.message,
            severity: 'critical'
        }
    }
}

async function checkCriticalTables(): Promise<HealthCheck> {
    const start = Date.now()
    const tables = ['households', 'recipes', 'menus', 'shopping_items']
    const results: Record<string, number> = {}
    
    try {
        for (const table of tables) {
            try {
                const { count, error } = await supabase
                    .from(table)
                    .select('id', { count: 'exact' })
                    .limit(0)
                
                if (error) throw error
                results[table] = count || 0
            } catch (e) {
                return {
                    component: 'critical_tables',
                    healthy: false,
                    responseTimeMs: Date.now() - start,
                    detail: `Cannot access ${table}: ${e.message}`,
                    severity: 'critical'
                }
            }
        }
        
        return {
            component: 'critical_tables',
            healthy: true,
            responseTimeMs: Date.now() - start,
            detail: 'All critical tables accessible',
            recordCount: results
        }
    } catch (error) {
        return {
            component: 'critical_tables',
            healthy: false,
            responseTimeMs: Date.now() - start,
            detail: error.message,
            severity: 'critical'
        }
    }
}

async function checkRealtimeChannel(): Promise<HealthCheck> {
    const start = Date.now()
    
    try {
        const channel = supabase.channel('health_check_' + Date.now())
        
        let received = false
        
        channel.on('broadcast', { event: 'health_check' }, () => {
            received = true
        })
        
        channel.subscribe(status => {
            if (status === 'SUBSCRIBED') {
                channel.send({
                    type: 'broadcast',
                    event: 'health_check',
                    payload: { timestamp: Date.now() }
                })
            }
        })
        
        // Wait max 5 seconds for message
        await new Promise(resolve => setTimeout(resolve, 5000))
        
        channel.unsubscribe()
        
        const responseTime = Date.now() - start
        
        return {
            component: 'realtime',
            healthy: received || responseTime < 2000,  // Lenient: even if no broadcast, connection OK
            responseTimeMs: responseTime,
            detail: received ? 'Realtime working' : 'Realtime slow but connected',
            severity: responseTime > 3000 ? 'warning' : 'info'
        }
    } catch (error) {
        return {
            component: 'realtime',
            healthy: false,
            responseTimeMs: Date.now() - start,
            detail: error.message,
            severity: 'warning'  // Realtime can be slow but not cause app death
        }
    }
}

async function checkDataIntegrity(): Promise<HealthCheck> {
    const start = Date.now()
    const issues: Array<{type: string, count: number, detail: string}> = []
    
    try {
        // Check 1: Orphan ingredients (no recipe)
        const { data: orphanIngredients } = await supabase
            .from('ingredients')
            .select('id')
            .filter('recipe_id', 'is', null)
        
        if (orphanIngredients && orphanIngredients.length > 0) {
            issues.push({
                type: 'orphan_ingredient',
                count: orphanIngredients.length,
                detail: 'Ingredients with no recipe'
            })
        }
        
        // Check 2: Recipes with no household (if applicable)
        const { data: orphanRecipes } = await supabase
            .from('recipes')
            .select('id')
            .filter('household_id', 'is', null)
        
        if (orphanRecipes && orphanRecipes.length > 0) {
            issues.push({
                type: 'orphan_recipe',
                count: orphanRecipes.length,
                detail: 'Recipes not assigned to household'
            })
        }
        
        return {
            component: 'data_integrity',
            healthy: issues.length === 0,
            responseTimeMs: Date.now() - start,
            issues: issues,
            detail: issues.length === 0 ? 'No issues' : `${issues.length} integrity issues found`,
            severity: issues.length > 10 ? 'warning' : 'info'
        }
    } catch (error) {
        return {
            component: 'data_integrity',
            healthy: false,
            responseTimeMs: Date.now() - start,
            detail: error.message,
            severity: 'warning'
        }
    }
}
```

### 1.7 Health Check Frequency & Timeouts

```
┌─ CLIENT-INITIATED CHECKS
│  ├─ Frequency: Every 30 seconds (when online)
│  ├─ Timeout: 10 seconds (fail and move to offline mode)
│  ├─ On failure: Show "server degraded" indicator
│  ├─ On recovery: Resume normal sync
│  └─ Backoff: Exponential (30s → 60s → 120s if failing)
│
├─ SYNTHETIC TRANSACTION MONITOR
│  ├─ Frequency: Every 5 minutes
│  ├─ Timeout: 30 seconds per operation
│  ├─ Operations: Insert → Read → Delete
│  ├─ Alert if any exceeds 10 seconds
│  └─ Record latency metrics
│
└─ DASHBOARD / ON-CALL CHECKS
   ├─ Frequency: Every 2 minutes (manual dashboard viewing)
   ├─ Timeout: 15 seconds
   ├─ Response time tracked
   └─ Aggregated into metrics view
```

---

## 2. SYNTHETIC TRANSACTION MONITOR

### 2.1 What It Tests

```sql
-- Simulated user journey:
-- 1. INSERT a test recipe
-- 2. READ it back (verify)
-- 3. DELETE it

-- Measures end-to-end latency including:
-- - RLS policy evaluation
-- - Query planning
-- - Network roundtrip
-- - Trigger execution (if any)
```

### 2.2 Implementation (Edge Function)

```typescript
// Supabase Edge Function: /api/v1/synthetic-test
// Run via pg_cron every 5 minutes

export async function handler(req: Request) {
    const testId = 'synthetic_' + Date.now()
    const results: SyntheticTestResult = {
        testId,
        startTime: Date.now(),
        operations: [],
        success: false
    }
    
    try {
        // 1. INSERT test recipe
        const insertStart = Date.now()
        const { data: inserted, error: insertError } = await supabase
            .from('recipes')
            .insert({
                id: testId,
                household_id: 'synthetic-test-household-id',
                name: `Test Recipe ${Date.now()}`,
                category: 'lunch',
                servings: 2,
                prep_time_minutes: 30,
                cook_time_minutes: 20,
                instructions: 'Test recipe'
            })
            .select()
        
        results.operations.push({
            op: 'insert',
            durationMs: Date.now() - insertStart,
            success: !insertError,
            error: insertError?.message
        })
        
        if (insertError) throw insertError
        
        // 2. READ it back
        const readStart = Date.now()
        const { data: read, error: readError } = await supabase
            .from('recipes')
            .select('*')
            .eq('id', testId)
            .single()
        
        results.operations.push({
            op: 'read',
            durationMs: Date.now() - readStart,
            success: !readError,
            error: readError?.message
        })
        
        if (readError) throw readError
        if (!read) throw new Error('Read returned empty')
        
        // 3. DELETE it
        const deleteStart = Date.now()
        const { error: deleteError } = await supabase
            .from('recipes')
            .delete()
            .eq('id', testId)
        
        results.operations.push({
            op: 'delete',
            durationMs: Date.now() - deleteStart,
            success: !deleteError,
            error: deleteError?.message
        })
        
        if (deleteError) throw deleteError
        
        // Calculate totals
        results.totalDurationMs = Date.now() - results.startTime
        results.success = true
        
        // Check thresholds
        const anyOperationSlow = results.operations.some(op => op.durationMs > 5000)
        const totalSlow = results.totalDurationMs > 15000
        
        if (totalSlow || anyOperationSlow) {
            results.severity = 'warning'
            results.message = 'Synthetic test completed but was slow'
            
            // Alert on slow synthetics
            await notifySlowSynthetic(results)
        }
        
        // Log results
        await logSyntheticResult(results)
        
        return new Response(JSON.stringify(results), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        })
        
    } catch (error) {
        results.success = false
        results.error = error.message
        results.totalDurationMs = Date.now() - results.startTime
        results.severity = 'critical'
        
        // Alert on failure
        await alertSyntheticFailure(results)
        await logSyntheticResult(results)
        
        return new Response(JSON.stringify(results), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        })
    }
}

interface SyntheticTestResult {
    testId: string
    startTime: number
    totalDurationMs?: number
    operations: Array<{
        op: string
        durationMs: number
        success: boolean
        error?: string
    }>
    success: boolean
    error?: string
    severity?: 'info' | 'warning' | 'critical'
    message?: string
}
```

### 2.3 Success Criteria

```
✅ INSERT < 2 seconds
✅ READ < 1 second
✅ DELETE < 2 seconds
✅ Total < 10 seconds
✅ ZERO errors

⚠️ Any operation > 5 seconds → Warning alert
❌ Any operation fails → Critical alert
❌ Total > 20 seconds → Critical alert
```

### 2.4 Scheduling

```sql
-- In Supabase SQL Editor:

-- Schedule synthetic test every 5 minutes
SELECT cron.schedule(
    'synthetic-health-test-5min',
    '*/5 * * * *',  -- Every 5 minutes
    'select http_post(
        ''https://YOUR-PROJECT.supabase.co/functions/v1/synthetic-test'',
        json_build_object(''type'', ''synthetic_test'')::text
    )'
);

-- Alternative: use http_get if function is publicly callable
```

---

## 3. DATABASE METRICS & QUERIES

### 3.1 Critical Metrics to Track

| Metric | Query | Threshold | Alert |
|--------|-------|-----------|-------|
| Active Connections | `SELECT count from pg_stat_activity` | >30 | Warn >25 |
| Query Latency P95 | See below | <500ms | Warn >500ms, Alert >2s |
| Slow Queries | `SELECT query FROM pg_stat_statements WHERE mean_time > 1000` | 0 slow | Alert immediately |
| Index Usage | See below | All used | Check daily |
| Error Rate | Application telemetry | 0% | Alert >1% |
| Replication Lag | `SELECT extract(epoch from (now() - pg_last_xact_replay_timestamp()))` | <100ms | Warn >500ms |
| Deadlocks | `SELECT deadlocks FROM pg_stat_database` | 0 | Alert > 0 |

### 3.2 Queries for Metrics

```sql
-- Query 1: Active connections by user
SELECT 
    usename,
    count(*) as connection_count,
    max(query_start) as oldest_query_start
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY usename
ORDER BY connection_count DESC;

-- Query 2: Query latency percentiles (last 1 hour)
SELECT 
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_time) as p50_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_time) as p95_ms,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_time) as p99_ms,
    MAX(total_time) as max_ms,
    COUNT(*) as query_count
FROM pg_stat_statements
WHERE query_period > NOW() - INTERVAL '1 hour';

-- Query 3: Table sizes (what's growing?)
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Query 4: Long-running queries (current)
SELECT 
    pid,
    usename,
    application_name,
    state,
    query_start,
    NOW() - query_start as duration,
    query
FROM pg_stat_activity
WHERE query_start IS NOT NULL
  AND state != 'idle'
ORDER BY query_start ASC
LIMIT 10;

-- Query 5: Index usage stats
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0  -- Unused indexes
ORDER BY pg_total_relation_size(schemaname||'.'||indexname) DESC;

-- Query 6: Bloat (dead tuples)
SELECT 
    schemaname,
    tablename,
    ROUND(n_dead_tup::numeric / n_live_tup * 100, 2) as dead_ratio
FROM pg_stat_user_tables
WHERE n_live_tup > 0
  AND n_dead_tup > 0
ORDER BY dead_ratio DESC
LIMIT 10;
```

### 3.3 Create Metrics View

```sql
CREATE OR REPLACE VIEW metrics_db_health AS
SELECT 
    'database_health' as category,
    'active_connections' as metric,
    count(*)::text as value,
    NOW() as measured_at
FROM pg_stat_activity
WHERE state = 'active'

UNION ALL

SELECT 
    'database_health',
    'slow_queries',
    count(*)::text,
    NOW()
FROM pg_stat_statements
WHERE mean_time > 1000

UNION ALL

SELECT 
    'database_health',
    'unused_indexes',
    count(*)::text,
    NOW()
FROM pg_stat_user_indexes
WHERE idx_scan = 0

UNION ALL

SELECT 
    'database_health',
    'table_bloat_high',
    count(*)::text,
    NOW()
FROM pg_stat_user_tables
WHERE n_live_tup > 0 
  AND n_dead_tup > n_live_tup * 0.2;

-- Query metrics
SELECT * FROM metrics_db_health;
```

### 3.4 Store Metrics in Application Table

```sql
-- Create metrics log table
CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name TEXT NOT NULL,
    metric_value FLOAT NOT NULL,
    tags JSONB,
    measured_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_metrics_name_time ON system_metrics(metric_name, measured_at DESC);

-- Scheduled job to collect metrics every 5 minutes
SELECT cron.schedule(
    'collect-db-metrics-5min',
    '*/5 * * * *',
    'INSERT INTO system_metrics (metric_name, metric_value, tags)
    SELECT 
        ''active_connections'',
        count(*)::float,
        jsonb_build_object(''source'', ''pg_stat_activity'')
    FROM pg_stat_activity
    WHERE state = ''active'''
);
```

---

## 4. REALTIME MONITORING (Specific)

### 4.1 Realtime-Specific Checks

```typescript
// Track realtime subscription health

interface RealtimeMetric {
    channel: string
    subscriptionCount: number
    messagesSent: number
    messagesReceived: number
    lastMessageAt: Date
    averageLatencyMs: number
    reconnectionCount: number
    reconnectionReasonCounts: {
        network_error: number
        subscription_error: number
        timeout: number
        other: number
    }
}

// Metrics to track:
// 1. How many subscriptions active per household
// 2. How many messages flowing through realtime
// 3. Reconnection frequency (should be <1 per hour per household)
// 4. Message delivery latency (P95 < 500ms)
// 5. Any lost messages detected
```

### 4.2 Detect Realtime Issues

```typescript
// Client-side (Swift) - send metrics to backend

struct RealtimeMetrics: Codable {
    let householdId: String
    let reconnectCount: Int
    let averageLatencyMs: Int
    let lostMessageCount: Int
    let lastIssueAt: Date?
}

// If reconnect_count > 3 in 1 hour → alert
// If latency > 1000ms → warning
// If any lost messages → alert
```

### 4.3 SQL to Monitor Realtime Usage

```sql
-- Monitor realtime subscriptions from server logs
-- (Supabase provides this in dashboard)

-- Queries to run:
-- 1. Total active subscriptions
-- 2. Subscriptions per table
-- 3. Broadcast message frequency
-- 4. Client disconnection rate
```

---

## 5. ALERTING STRATEGY

### 5.1 Alert Levels

```
CRITICAL (Immediate Action Required)
├─ Database down (TCP connection fails)
├─ Health check returns 503
├─ Synthetic test fails completely
├─ >10% error rate
├─ Query latency P95 > 5 seconds
└─ Data integrity check finds critical issues

ALERT (Investigate Soon)
├─ Query latency P95 > 2 seconds
├─ >5% error rate
├─ Realtime latency > 2 seconds
├─ >3 reconnections per household in 1 hour
├─ Unused indexes accumulating
└─ Table bloat > 50%

WARNING (Monitor)
├─ Query latency P95 > 500ms
├─ >2% error rate
├─ Realtime latency > 500ms
├─ Active connections > 25
├─ Any slow query detected (>1s)
└─ Dead tuples > 20% of table
```

### 5.2 Notification Channels

```
CRITICAL:
├─ Slack: @channel in #incidents
├─ Email: on-call engineer
├─ SMS: (for truly critical)
└─ Dashboard: Red alert box (30s refresh)

ALERT:
├─ Slack: #database-alerts channel
├─ Email: team notification
└─ Dashboard: Yellow warning

WARNING:
├─ Slack: thread in #database-alerts (daily digest)
├─ Dashboard: Blue info section
└─ Log for review
```

### 5.3 Alerting Rule Examples

```sql
-- Alert on high error rate
SELECT cron.schedule(
    'alert-high-error-rate',
    '*/2 * * * *',  -- Every 2 minutes
    'SELECT alert_if_condition(
        (SELECT COUNT(*) FROM telemetry_events 
         WHERE type = ''error'' AND created_at > NOW() - INTERVAL ''5 minutes'')
        > 50,
        ''CRITICAL: High error rate detected'',
        ''critical''
    )'
);

-- Alert on slow synthetic test
SELECT cron.schedule(
    'alert-slow-synthetic',
    '*/5 * * * *',
    'SELECT alert_if_condition(
        (SELECT total_duration_ms FROM synthetic_test_results 
         ORDER BY created_at DESC LIMIT 1)
        > 15000,
        ''ALERT: Synthetic test took too long'',
        ''alert''
    )'
);

-- Alert on database disk space (if available)
SELECT cron.schedule(
    'alert-disk-space',
    '0 * * * *',  -- Every hour
    'SELECT alert_if_condition(
        (SELECT pg_database_size(current_database()) / 1024 / 1024 / 1024) > 5,
        ''WARNING: Database approaching size limit'',
        ''warning''
    )'
);
```

---

## 6. CLIENT-SIDE FAILOVER BEHAVIOR

### 6.1 When Backend is Degraded

```
HEALTH CHECK RESULT: Degraded (HTTP 200, status="degraded")
       ↓
CLIENT ACTION:
├─ Show yellow banner: "Server is slow, operating in offline mode"
├─ Queue all writes to local database
├─ Stop trying to sync (retry every 30 seconds)
├─ Cache reads (don't fetch from network)
├─ Disable real-time updates (stop listening)
└─ Show queue badge: "3 pending changes"

USER SEES:
├─ Yellow indicator in top right
├─ "Changes pending" indicator
├─ Can still view menu (cached)
├─ Can still edit (queued locally)
└─ Syncs will happen when network recovers
```

### 6.2 When Backend is Critical

```
HEALTH CHECK REQUEST: Timeout or HTTP 503
       ↓
CLIENT ACTION:
├─ Assume completely offline
├─ Show red banner: "Server unavailable, offline mode active"
├─ Queue ALL new operations
├─ Use last known data
├─ Stop background syncs
├─ Stop health checks (too aggressive)
└─ Retry health check every 60 seconds

USER SEES:
├─ Red indicator + "Offline" message
├─ Can navigate menu (cached)
├─ Can edit (all queued)
├─ Sync attempts paused
└─ Will retry automatically
```

### 6.3 Recovery Behavior

```
HEALTH CHECK: "healthy" after degraded/critical
       ↓
CLIENT ACTION:
├─ Remove degraded indicator
├─ Execute all queued operations
├─ Sync changes to server
├─ Re-enable real-time subscriptions
├─ Resume normal polling (30 seconds)
└─ Show toast: "Connection restored, syncing..."

USER SEES:
├─ Green indicator
├─ Changes being synced
├─ Real-time updates resume
└─ Full functionality restored
```

### 6.4 Swift Implementation Sketch

```swift
class HealthCheckManager {
    enum HealthStatus {
        case healthy
        case degraded
        case critical
        case unknown
    }
    
    private var currentStatus: HealthStatus = .unknown
    
    func startHealthChecks(interval: TimeInterval = 30) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }
    
    private func performHealthCheck() {
        Task {
            do {
                let response = try await healthCheckAPI.check()
                let newStatus = parseStatus(response)
                self.handleStatusChange(from: self.currentStatus, to: newStatus)
                self.currentStatus = newStatus
            } catch {
                // Timeout or error = treat as critical
                self.handleStatusChange(from: self.currentStatus, to: .critical)
                self.currentStatus = .critical
            }
        }
    }
    
    private func handleStatusChange(from: HealthStatus, to: HealthStatus) {
        switch (from, to) {
        case (.healthy, .degraded), (.healthy, .critical):
            // Transition to bad state
            showDegradedBanner()
            stopRealtimeSubs()
            switchToOfflineQueueing()
            
        case (.degraded, .healthy), (.critical, .healthy):
            // Recovery
            hideDegradedBanner()
            flushQueue()
            resumeSyncOperations()
            resumeRealtimeSubs()
            
        default:
            // No change
            break
        }
    }
}
```

---

## 7. DATA INTEGRITY MONITORING

### 7.1 Automated Integrity Checks

```sql
-- Run every hour via pg_cron

CREATE OR REPLACE FUNCTION check_data_integrity()
RETURNS TABLE(check_type TEXT, issue_count INT, details JSONB) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'orphan_ingredients'::TEXT,
        COUNT(*)::INT,
        jsonb_build_object(
            'description', 'Ingredients with no recipe',
            'table', 'ingredients',
            'severity', 'medium'
        )
    FROM ingredients i
    WHERE i.recipe_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM recipes r WHERE r.id = i.recipe_id);
      
    RETURN QUERY
    SELECT 
        'orphan_recipes'::TEXT,
        COUNT(*)::INT,
        jsonb_build_object(
            'description', 'Recipes with no household',
            'table', 'recipes',
            'severity', 'high'
        )
    FROM recipes r
    WHERE r.household_id IS NULL;
    
    RETURN QUERY
    SELECT 
        'duplicate_shopping_items'::TEXT,
        COUNT(*)::INT,
        jsonb_build_object(
            'description', 'Multiple shopping items with same content',
            'table', 'shopping_items',
            'severity', 'low'
        )
    FROM (
        SELECT product_name, household_id, COUNT(*) as cnt
        FROM shopping_items
        GROUP BY product_name, household_id
        HAVING COUNT(*) > 1
    ) dupes;
    
    RETURN QUERY
    SELECT 
        'missing_household_user_link'::TEXT,
        COUNT(*)::INT,
        jsonb_build_object(
            'description', 'Users with no household assignment',
            'table', 'household_users',
            'severity', 'high'
        )
    FROM users u
    WHERE NOT EXISTS (
        SELECT 1 FROM household_users hu WHERE hu.user_id = u.id
    );
END;
$$ LANGUAGE plpgsql;

-- Schedule check
SELECT cron.schedule(
    'check-data-integrity-hourly',
    '0 * * * *',  -- Every hour
    'INSERT INTO integrity_check_logs (check_results)
     SELECT to_jsonb(array_agg(row_to_json(t))) 
     FROM (SELECT * FROM check_data_integrity()) t'
);
```

### 7.2 Store Results

```sql
CREATE TABLE IF NOT EXISTS integrity_check_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_results JSONB,
    total_issues INT,
    severity_level TEXT,
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_integrity_severity ON integrity_check_logs(severity_level, checked_at);

-- Auto-calculate severity
CREATE OR REPLACE TRIGGER set_integrity_severity
BEFORE INSERT ON integrity_check_logs
FOR EACH ROW
EXECUTE FUNCTION (
    SELECT CASE 
        WHEN (check_results -> 'high')::INT > 0 THEN 'critical'
        WHEN (check_results -> 'medium')::INT > 5 THEN 'warning'
        ELSE 'info'
    END
);
```

### 7.3 Alert on Issues

```sql
SELECT cron.schedule(
    'alert-integrity-issues',
    '0 * * * *',  -- Every hour
    'SELECT alert_if_condition(
        (SELECT total_issues FROM integrity_check_logs 
         ORDER BY created_at DESC LIMIT 1) > 10,
        ''WARNING: Data integrity issues detected'',
        ''warning''
    )'
);
```

---

## 8. WHAT NOT TO IMPLEMENT (YET)

### Too Much for a Household App

❌ **Custom metrics backend (Prometheus, InfluxDB)**
- Why: Overly complex for <5 users. Supabase + PostgreSQL + dashboard is enough.
- Cost: $500+ setup, ongoing operational burden
- Better: Use Supabase views + Metabase queries

❌ **Distributed tracing (Jaeger, Datadog)**
- Why: Single Supabase instance, no service mesh complexity
- Cost: $1000+/month
- Better: Query-level timing from pg_stat_statements

❌ **Real-time dashboards with <5s updates**
- Why: Excessive polling. Hourly metrics are sufficient.
- Cost: Network + database overhead
- Better: 5-minute aggregates with click-to-detail

❌ **Multi-region failover**
- Why: Single household, single region is fine. Failover adds complexity.
- Cost: Operational + data replication overhead
- Better: Regular backups, focus on availability within region

❌ **ML-based anomaly detection**
- Why: Threshold-based rules are clear and predictable
- Cost: $500+/month, false positives
- Better: Manual threshold tuning as you learn patterns

❌ **Custom log aggregation pipeline**
- Why: Supabase logs + PostgreSQL views are sufficient
- Cost: Infrastructure setup + maintenance
- Better: Structured SQL queries on telemetry tables

### Low Priority Now

⏱️ **Advanced security monitoring** (DDoS detection, SQL injection patterns)
- Why: Household app, not public API. Fix when needed.
- Implementation time: 2-3 weeks
- Better priority: Operational stability first

⏱️ **Custom alerting workflows** (auto-remediation, escalation policies)
- Why: Manual response sufficient for team size. Add when reactive becomes painful.
- Implementation time: 3-4 weeks
- Better priority: Simple Slack alerts first

⏱️ **Detailed query profiling** (execution plans, index suggestions)
- Why: pg_stat_statements + visual tools sufficient for now
- Implementation time: 2-3 weeks
- Better priority: Monitor before profiling

⏱️ **Cost optimization** (resource utilization reports)
- Why: Bills are small now. Add when they start growing.
- Implementation time: 1-2 weeks
- Better priority: Functionality > cost savings

---

## 9. IMPLEMENTATION PHASES

### Phase 1: Foundation (Week 1-2)
```
✅ Health check endpoint /api/v1/health
✅ Client calls health check every 30 seconds
✅ Basic degraded/critical state detection
✅ Show degraded banner in UI
✅ Queue operations when offline
Time: 8-10 hours
Impact: Detect basic backend issues
```

### Phase 2: Synthetic Monitoring (Week 2-3)
```
✅ Synthetic transaction edge function
✅ Schedule every 5 minutes via pg_cron
✅ Store results in database
✅ Alert on failures
Time: 4-5 hours
Impact: Proactive detection of crud failures
```

### Phase 3: Metrics & Alerting (Week 3-4)
```
✅ Create metrics views (active connections, latency, errors)
✅ Setup pg_cron for metric collection
✅ Slack webhook for alerts
✅ Threshold-based alerting rules
Time: 6-8 hours
Impact: Dashboard visibility + team notifications
```

### Phase 4: Advanced (Week 5+)
```
❌ (Not now) Data integrity checks → later
❌ (Not now) Realtime-specific monitoring → later
❌ (Not now) Custom dashboard UI → later
```

---

## 10. SUCCESS METRICS

### After Phase 1
```
✅ Health check returns <100ms (healthy) or times out
✅ UI shows degraded indicator when backend slow
✅ Client queues operations during outages
✅ No crashes due to network issues
```

### After Phase 2
```
✅ Synthetic test completes in <10 seconds
✅ Can identify which CRUD operation is slow
✅ Alert sent when synthetic fails
```

### After Phase 3
```
✅ Dashboard shows current metrics (5-10 min old)
✅ Slack receives alert on threshold breach
✅ Can see latency trends over 7 days
✅ Team knows immediately if DB has issue
```

---

## 11. DEPLOYMENT CHECKLIST

### Pre-Deploy
- [ ] Health check tested manually (curl)
- [ ] Health check returns 200 when everything OK, 503 when DB down
- [ ] Synthetic transaction tested end-to-end
- [ ] Client code tested: degraded state, queue operations
- [ ] Alert thresholds reviewed by team
- [ ] Slack webhook configured and tested
- [ ] Database has pg_cron enabled

### Day 1 Production
- [ ] Health check monitored (check Slack for alerts)
- [ ] Verify client is calling health check
- [ ] Verify queue working when health check fails
- [ ] Check dashboard metrics (should have baseline)

### Week 1
- [ ] Review metrics patterns
- [ ] Adjust thresholds if too noisy
- [ ] Ensure no false positives
- [ ] Team familiar with alerts

---

**Total Implementation Time:** 3-4 weeks  
**Ongoing Maintenance:** 2-3 hours/week  
**Cost:** Included in Supabase plan ($25/month base)
