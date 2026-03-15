# 🧠 BACKEND MONITORING - IMPLEMENTATION QUICKSTART

---

## PHASE 1: Health Check Endpoint (Day 1-2)

### Step 1: Create Edge Function

```bash
# In terminal, from your supabase project root

supabase functions new api/v1/health
```

### Step 2: Implement Function

Copy this into `supabase/functions/api/v1/health/index.ts`:

```typescript
// supabase/functions/api/v1/health/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const cors = {
    headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: cors.headers })
    }
    
    const startTime = Date.now()
    const checks: any[] = []
    
    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )
        
        // 1. Check database
        try {
            const checkStart = Date.now()
            const { error } = await supabase.from('households').select('id').limit(1)
            
            checks.push({
                component: 'database',
                healthy: !error,
                responseTimeMs: Date.now() - checkStart,
                detail: error ? error.message : 'Database responding'
            })
        } catch (e) {
            checks.push({
                component: 'database',
                healthy: false,
                responseTimeMs: Date.now() - startTime,
                detail: e.message,
                severity: 'critical'
            })
        }
        
        // 2. Check tables
        try {
            const checkStart = Date.now()
            const tables = ['households', 'recipes', 'menus']
            const results: Record<string, boolean> = {}
            
            for (const table of tables) {
                try {
                    const { error } = await supabase.from(table).select('id').limit(1)
                    results[table] = !error
                } catch {
                    results[table] = false
                }
            }
            
            checks.push({
                component: 'critical_tables',
                healthy: Object.values(results).every(v => v),
                responseTimeMs: Date.now() - checkStart,
                tables: results
            })
        } catch (e) {
            checks.push({
                component: 'critical_tables',
                healthy: false,
                detail: e.message
            })
        }
        
        // Overall status
        const dbHealthy = checks.some(c => c.component === 'database' && c.healthy)
        const tablesHealthy = checks.some(c => c.component === 'critical_tables' && c.healthy)
        const overallHealthy = dbHealthy && tablesHealthy
        
        const status = overallHealthy ? 'healthy' : 'degraded'
        const httpStatus = overallHealthy ? 200 : 503
        
        return new Response(JSON.stringify({
            status,
            timestamp: new Date().toISOString(),
            responseTimeMs: Date.now() - startTime,
            checks
        }), {
            status: httpStatus,
            headers: {
                'Content-Type': 'application/json',
                ...cors.headers
            }
        })
        
    } catch (error) {
        return new Response(JSON.stringify({
            status: 'critical',
            error: error.message,
            timestamp: new Date().toISOString(),
            checks
        }), {
            status: 503,
            headers: {
                'Content-Type': 'application/json',
                ...cors.headers
            }
        })
    }
})
```

### Step 3: Deploy

```bash
supabase functions deploy api/v1/health
```

### Step 4: Test

```bash
# Test the endpoint
curl https://YOUR-PROJECT.supabase.co/functions/v1/api/v1/health

# Should return something like:
# {"status":"healthy","timestamp":"2026-02-21T15:00:00Z","responseTimeMs":87,"checks":[...]}
```

---

## PHASE 2: Client Integration (Swift)

### Create HealthCheckManager

```swift
// Services/HealthCheckManager.swift
import Foundation

class HealthCheckManager: NSObject, ObservableObject {
    @Published var status: HealthStatus = .unknown
    @Published var lastCheckTime: Date?
    @Published var degradedReason: String?
    
    enum HealthStatus {
        case healthy
        case degraded
        case critical
        case unknown
    }
    
    static let shared = HealthCheckManager()
    
    private let supabaseURL = URL(string: "https://YOUR-PROJECT.supabase.co")!
    private var healthCheckTimer: Timer?
    
    override private init() {
        super.init()
    }
    
    func startHealthChecks(interval: TimeInterval = 30) {
        // Stop existing timer
        healthCheckTimer?.invalidate()
        
        // Check immediately
        performHealthCheck()
        
        // Then check periodically
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }
    
    func stopHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    private func performHealthCheck() {
        Task {
            do {
                let response = try await callHealthCheckAPI()
                await handleHealthCheckResponse(response)
            } catch {
                await handleHealthCheckError(error)
            }
        }
    }
    
    private func callHealthCheckAPI() async throws -> HealthCheckResponse {
        var request = URLRequest(url: supabaseURL.appendingPathComponent("functions/v1/api/v1/health"))
        request.timeoutInterval = 10  // 10 second timeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "HealthCheck", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let result = try decoder.decode(HealthCheckResponse.self, from: data)
        return result
    }
    
    @MainActor
    private func handleHealthCheckResponse(_ response: HealthCheckResponse) {
        let previousStatus = status
        
        switch response.status {
        case "healthy":
            status = .healthy
            degradedReason = nil
            
        case "degraded":
            status = .degraded
            degradedReason = response.errors?.joined(separator: ", ") ?? "Server degraded"
            
        case "critical":
            status = .critical
            degradedReason = "Backend unavailable"
            
        default:
            status = .unknown
        }
        
        lastCheckTime = Date()
        
        // Handle status transitions
        if previousStatus != status {
            handleStatusTransition(from: previousStatus, to: status)
        }
    }
    
    @MainActor
    private func handleHealthCheckError(_ error: Error) {
        let previousStatus = status
        status = .critical
        degradedReason = "Cannot reach backend"
        lastCheckTime = Date()
        
        if previousStatus != status {
            handleStatusTransition(from: previousStatus, to: status)
        }
    }
    
    @MainActor
    private func handleStatusTransition(from: HealthStatus, to: HealthStatus) {
        switch (from, to) {
        case (.healthy, .degraded), (.healthy, .critical):
            print("🟡 Backend degraded, switching to offline mode")
            NotificationCenter.default.post(name: NSNotification.Name("BackendDegraded"), object: nil)
            
        case (.degraded, .healthy), (.critical, .healthy):
            print("🟢 Backend recovered, resuming sync")
            NotificationCenter.default.post(name: NSNotification.Name("BackendHealthy"), object: nil)
            
        case (.critical, .degraded):
            print("🟡 Backend still degraded")
            
        default:
            break
        }
    }
}

// MARK: - Response Models

struct HealthCheckResponse: Decodable {
    let status: String
    let timestamp: Date
    let responseTimeMs: Int
    let checks: [HealthCheckItem]?
    let errors: [String]?
}

struct HealthCheckItem: Decodable {
    let component: String
    let healthy: Bool
    let responseTimeMs: Int
    let detail: String?
}
```

### Use in Views

```swift
// In your main app view

@StateObject private var healthCheck = HealthCheckManager.shared

var body: some View {
    ZStack {
        VStack {
            // Your main content
            MainMenuView()
        }
        
        // Show degraded banner if needed
        if healthCheck.status == .degraded || healthCheck.status == .critical {
            VStack {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading) {
                        Text("Server \(healthCheck.status == .critical ? "Unavailable" : "Slow")")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        if let reason = healthCheck.degradedReason {
                            Text(reason)
                                .font(.caption2)
                                .opacity(0.7)
                        }
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(healthCheck.status == .critical ? Color.red : Color.yellow)
                .foregroundColor(.white)
            }
            .padding()
        }
    }
    .onAppear {
        healthCheck.startHealthChecks(interval: 30)
    }
    .onDisappear {
        healthCheck.stopHealthChecks()
    }
}
```

---

## PHASE 3: Synthetic Transaction (Week 2)

### Create Edge Function

```bash
supabase functions new api/v1/synthetic-test
```

### Implement

Copy into `supabase/functions/api/v1/synthetic-test/index.ts`:

```typescript
// supabase/functions/api/v1/synthetic-test/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
    const testId = 'synthetic_' + Date.now()
    const startTime = Date.now()
    const operations: any[] = []
    
    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )
        
        // INSERT
        const insertStart = Date.now()
        const { data: inserted, error: insertError } = await supabase
            .from('recipes')
            .insert({
                id: testId,
                household_id: 'synthetic-test-hh',
                name: `Test ${Date.now()}`,
                category: 'lunch',
                servings: 2,
                prep_time_minutes: 30,
                cook_time_minutes: 20,
                instructions: 'Test'
            })
            .select()
        
        operations.push({
            op: 'insert',
            durationMs: Date.now() - insertStart,
            success: !insertError
        })
        
        if (insertError) throw insertError
        
        // READ
        const readStart = Date.now()
        const { data: read, error: readError } = await supabase
            .from('recipes')
            .select('*')
            .eq('id', testId)
            .single()
        
        operations.push({
            op: 'read',
            durationMs: Date.now() - readStart,
            success: !readError
        })
        
        if (readError) throw readError
        
        // DELETE
        const deleteStart = Date.now()
        const { error: deleteError } = await supabase
            .from('recipes')
            .delete()
            .eq('id', testId)
        
        operations.push({
            op: 'delete',
            durationMs: Date.now() - deleteStart,
            success: !deleteError
        })
        
        if (deleteError) throw deleteError
        
        const totalDuration = Date.now() - startTime
        
        return new Response(JSON.stringify({
            success: true,
            testId,
            totalDurationMs: totalDuration,
            operations,
            timestamp: new Date().toISOString()
        }), { status: 200, headers: { 'Content-Type': 'application/json' } })
        
    } catch (error) {
        return new Response(JSON.stringify({
            success: false,
            testId,
            totalDurationMs: Date.now() - startTime,
            error: error.message,
            operations,
            timestamp: new Date().toISOString()
        }), { status: 500, headers: { 'Content-Type': 'application/json' } })
    }
})
```

### Schedule Execution

In Supabase SQL Editor:

```sql
-- Enable pg_cron if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule synthetic test every 5 minutes
SELECT cron.schedule(
    'synthetic-health-test',
    '*/5 * * * *',
    $$
    SELECT http_post(
        'https://YOUR-PROJECT.supabase.co/functions/v1/api/v1/synthetic-test',
        '{}',
        'application/json'
    )
    $$
);

-- Verify it scheduled
SELECT * FROM cron.job WHERE jobname = 'synthetic-health-test';
```

---

## PHASE 3: Database Metrics (Week 3)

### Create Metrics Table

```sql
-- Run in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name TEXT NOT NULL,
    metric_value FLOAT NOT NULL,
    tags JSONB DEFAULT '{}',
    measured_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_metrics_name_time ON system_metrics(metric_name, measured_at DESC);
```

### Create Metrics Collection Job

```sql
-- Collect active connection count every 5 minutes
SELECT cron.schedule(
    'collect-active-connections',
    '*/5 * * * *',
    $$
    INSERT INTO system_metrics (metric_name, metric_value, tags)
    SELECT 
        'active_connections',
        (SELECT count(*)::float FROM pg_stat_activity WHERE state = 'active'),
        jsonb_build_object('source', 'pg_stat_activity')
    $$
);

-- Collect table sizes every hour
SELECT cron.schedule(
    'collect-table-sizes',
    '0 * * * *',
    $$
    INSERT INTO system_metrics (metric_name, metric_value, tags)
    WITH table_sizes AS (
        SELECT 
            schemaname || '.' || tablename as table_name,
            pg_total_relation_size(schemaname||'.'||tablename)::float as size_bytes
        FROM pg_tables
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    )
    SELECT 
        'table_size_' || table_name,
        size_bytes,
        jsonb_build_object('table', table_name)
    FROM table_sizes
    $$
);
```

### Query Metrics

```sql
-- View latest metrics
SELECT 
    metric_name,
    metric_value,
    measured_at
FROM system_metrics
ORDER BY measured_at DESC
LIMIT 20;

-- Latency over time
SELECT 
    date_trunc('5 minutes', measured_at) as time_bucket,
    AVG(metric_value) as avg_value,
    MAX(metric_value) as max_value,
    COUNT(*) as samples
FROM system_metrics
WHERE metric_name = 'query_latency'
GROUP BY time_bucket
ORDER BY time_bucket DESC
LIMIT 100;
```

---

## PHASE 3: Alerting & Slack (Week 3)

### Create Slack Webhook

1. Go to your Slack workspace
2. Create incoming webhook: https://api.slack.com/messaging/webhooks
3. Copy webhook URL
4. Store in Supabase: `Settings → Edge Functions → Secrets → SLACK_WEBHOOK_URL`

### Create Alert Function

```typescript
// supabase/functions/api/v1/alert/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
    const { severity, message, details } = await req.json()
    
    const slackWebhookUrl = Deno.env.get('SLACK_WEBHOOK_URL')
    if (!slackWebhookUrl) {
        return new Response('No webhook configured', { status: 400 })
    }
    
    const colors: Record<string, string> = {
        'critical': '#FF0000',
        'alert': '#FFA500',
        'warning': '#FFFF00'
    }
    
    const payload = {
        attachments: [
            {
                color: colors[severity] || '#808080',
                title: `${severity.toUpperCase()}: ${message}`,
                text: details,
                ts: Math.floor(Date.now() / 1000)
            }
        ]
    }
    
    try {
        const response = await fetch(slackWebhookUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        })
        
        return new Response('Alert sent', { status: response.ok ? 200 : 500 })
    } catch (error) {
        return new Response(`Error: ${error.message}`, { status: 500 })
    }
})
```

### Setup Alert Rules

```sql
-- Alert on high error rate
SELECT cron.schedule(
    'alert-high-error-rate',
    '*/2 * * * *',
    $$
    SELECT CASE 
        WHEN (
            SELECT COUNT(*) FROM system_metrics 
            WHERE metric_name = 'error_count'
            AND measured_at > NOW() - INTERVAL '5 minutes'
        ) > 50
        THEN http_post(
            'https://YOUR-PROJECT.supabase.co/functions/v1/api/v1/alert',
            json_build_object(
                'severity', 'critical',
                'message', 'High error rate detected',
                'details', 'Error count exceeded threshold in last 5 minutes'
            )::text,
            'application/json'
        )
    END
    $$
);
```

---

## Testing Checklist

- [ ] Health check endpoint returns 200 (healthy)
- [ ] Health check returns 503 if you manually stop DB (simulate down)
-[ ] Client calls health check every 30 seconds (check network tab)
- [ ] Degraded banner shows when health check returns "degraded"
- [ ] Synthetic test completes in <10 seconds
- [ ] Synthetic test failure triggers alert
- [ ] Metrics table gets populated every 5 minutes
- [ ] Slack webhook receives test message

---

## Deployment

```bash
# Deploy both functions
supabase functions deploy api/v1/health
supabase functions deploy api/v1/synthetic-test
supabase functions deploy api/v1/alert

# Verify scheduled jobs running
SELECT * FROM cron.job WHERE jobname LIKE 'synthetic%' OR jobname LIKE 'collect%';
```

---

## Quick Reference: Thresholds

```
HEALTHY:
  - Response time < 100ms
  - Active connections < 15
  - Error rate < 1%
  - Synthetic test < 10s

DEGRADED:
  - Response time 100-2000ms
  - Active connections 15-25
  - Error rate 1-5%
  - Synthetic test 10-15s

CRITICAL:
  - Response time > 2000ms (timeout)
  - Active connections > 25
  - Error rate > 5%
  - Synthetic test > 15s or fails
  - Database offline
```

---

**Time to implement:** 
- Phase 1: 2-3 hours
- Phase 2: 2-3 hours  
- Phase 3: 3-4 hours
- **Total: ~8-10 hours**
