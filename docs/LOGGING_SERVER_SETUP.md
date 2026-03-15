# SERVER-SIDE LOGGING - EDGE FUNCTIONS & DATABASE

## 1. PostgreSQL Audit Log Table

```sql
-- Create audit logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    correlation_id TEXT NOT NULL,
    session_id TEXT,
    request_id TEXT,
    user_id UUID NOT NULL,
    household_id UUID NOT NULL,
    
    level TEXT NOT NULL,  -- debug, info, warning, error, critical
    category TEXT NOT NULL,  -- sync, api, realtime, offline, audit
    event_type TEXT NOT NULL,
    message TEXT NOT NULL,
    
    -- Operation details
    operation_name TEXT,
    entity_type TEXT,
    entity_id UUID,
    action TEXT,  -- create, update, delete
    rows_affected INT DEFAULT 0,
    
    -- Error details
    error_code TEXT,
    error_domain TEXT,
    error_message TEXT,
    
    -- Performance metrics (in milliseconds)
    network_latency_ms INT,
    server_processing_ms INT,
    database_ms INT,
    total_duration_ms INT,
    
    -- Realtime tracking
    realtime_channel TEXT,
    realtime_event TEXT,
    realtime_latency_ms INT,
    
    -- Sync conflict tracking
    conflict_detected BOOLEAN DEFAULT false,
    conflict_type TEXT,
    conflict_resolution TEXT,
    data_loss_detected BOOLEAN DEFAULT false,
    
    -- Raw JSON data
    data JSONB,
    
    -- Indexes for fast querying
    CONSTRAINT valid_level CHECK (level IN ('debug', 'info', 'warning', 'error', 'critical'))
);

-- Indexes for performance
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX idx_audit_user ON audit_logs(user_id, timestamp DESC);
CREATE INDEX idx_audit_household ON audit_logs(household_id, timestamp DESC);
CREATE INDEX idx_audit_correlation ON audit_logs(correlation_id);
CREATE INDEX idx_audit_level ON audit_logs(level);
CREATE INDEX idx_audit_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id) WHERE entity_id IS NOT NULL;

-- Enable RLS for security
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see logs for their household
CREATE POLICY "Users can see household logs" ON audit_logs
    FOR SELECT USING (
        household_id IN (
            SELECT household_id FROM household_members 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: only inserts allowed (immutable audit trail)
CREATE POLICY "Audit logs are immutable" ON audit_logs
    FOR ALL USING (false);  -- No direct modifications via client

-- Special role for server-side inserts
CREATE ROLE audit_logger NOINHERIT;
GRANT INSERT ON audit_logs TO audit_logger;
```text

---

## 2. Edge Function Middleware for Logging

```typescript
// supabase/functions/shared/logging.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface LogEntry {
  correlation_id: string;
  session_id?: string;
  request_id?: string;
  user_id?: string;
  household_id?: string;
  
  level: "debug" | "info" | "warning" | "error" | "critical";
  category: "sync" | "api" | "realtime" | "offline" | "audit";
  event_type: string;
  message: string;
  
  operation?: {
    name: string;
    entity_type: string;
    entity_id?: string;
    action: string;
    rows_affected: number;
  };
  
  error?: {
    code: string;
    message: string;
  };
  
  performance?: {
    network_latency_ms: number;
    processing_ms: number;
    database_ms: number;
    total_ms: number;
  };
}

export async function logToDatabase(
  supabaseClient: SupabaseClient,
  entry: LogEntry
) {
  try {
    const { error } = await supabaseClient
      .rpc("insert_audit_log", {
        p_correlation_id: entry.correlation_id,
        p_session_id: entry.session_id,
        p_request_id: entry.request_id,
        p_user_id: entry.user_id,
        p_household_id: entry.household_id,
        p_level: entry.level,
        p_category: entry.category,
        p_event_type: entry.event_type,
        p_message: entry.message,
        p_data: JSON.stringify(entry),
      });

    if (error) {
      console.error("Failed to log to database:", error);
    }
  } catch (err) {
    console.error("Logging error:", err);
  }
}

export async function withLogging(
  req: Request,
  handler: (
    req: Request,
    correlationId: string
  ) => Promise<Response>,
  functionName: string
): Promise<Response> {
  const startTime = Date.now();
  
  // Extract correlation ID from headers
  const correlationId = 
    req.headers.get("X-Correlation-ID") || 
    crypto.randomUUID();
  
  const [sessionId, requestId, userId, householdId] = 
    correlationId.split("|").slice(1);

  console.log(`[${functionName}] ${correlationId} - Request START`);

  try {
    const response = await handler(req, correlationId);
    
    const duration = Date.now() - startTime;
    
    // Log success
    console.log(
      `[${functionName}] ${correlationId} - Request SUCCESS (${duration}ms)`
    );

    return response;
    
  } catch (error) {
    const duration = Date.now() - startTime;
    
    console.error(
      `[${functionName}] ${correlationId} - Request ERROR (${duration}ms)`,
      error
    );

    return new Response(
      JSON.stringify({
        error: "Internal Server Error",
        correlation_id: correlationId,
      }),
      {
        status: 500,
        headers: { 
          "Content-Type": "application/json",
          "X-Correlation-ID": correlationId 
        },
      }
    );
  }
}
```text

---

## 3. Example: Recipe Creation with Logging

```typescript
// supabase/functions/recipes/create/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import { withLogging, logToDatabase } from "../shared/logging.ts";

serve(async (req) => {
  return withLogging(req, handleCreateRecipe, "create_recipe");
});

async function handleCreateRecipe(
  req: Request,
  correlationId: string
): Promise<Response> {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const startTime = Date.now();
  const { name, category, household_id, user_id } = await req.json();

  try {
    // Validate
    if (!name || !household_id) {
      logToDatabase(supabase, {
        correlation_id: correlationId,
        level: "error",
        category: "api",
        event_type: "apiError",
        message: "Validation failed: missing required fields",
        error: {
          code: "VALIDATION_FAILED",
          message: "Missing name or household_id",
        },
      });

      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "X-Correlation-ID": correlationId } }
      );
    }

    // Database operation
    const dbStartTime = Date.now();
    const { data: recipe, error } = await supabase
      .from("recipes")
      .insert({
        name,
        category,
        household_id,
        created_by: user_id,
      })
      .select()
      .single();

    const databaseMs = Date.now() - dbStartTime;

    if (error) throw error;

    const totalMs = Date.now() - startTime;

    // Log success
    await logToDatabase(supabase, {
      correlation_id: correlationId,
      user_id,
      household_id,
      level: "info",
      category: "api",
      event_type: "apiSuccess",
      message: `Recipe created: ${name}`,
      operation: {
        name: "createRecipe",
        entity_type: "Recipe",
        entity_id: recipe.id,
        action: "create",
        rows_affected: 1,
      },
      performance: {
        network_latency_ms: 0,  // Will be filled by client
        processing_ms: databaseMs,
        database_ms: databaseMs,
        total_ms: totalMs,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        data: recipe,
        correlation_id: correlationId,
      }),
      {
        status: 201,
        headers: {
          "Content-Type": "application/json",
          "X-Correlation-ID": correlationId,
        },
      }
    );

  } catch (error) {
    const duration = Date.now() - startTime;

    // Log error
    await logToDatabase(supabase, {
      correlation_id: correlationId,
      user_id,
      household_id,
      level: "error",
      category: "api",
      event_type: "apiError",
      message: `Failed to create recipe: ${error.message}`,
      error: {
        code: "DATABASE_ERROR",
        message: error.message,
      },
      performance: {
        network_latency_ms: 0,
        processing_ms: duration,
        database_ms: duration,
        total_ms: duration,
      },
    });

    return new Response(
      JSON.stringify({
        error: error.message,
        correlation_id: correlationId,
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "X-Correlation-ID": correlationId,
        },
      }
    );
  }
}
```text

---

## 4. Realtime Conflict Detection

```sql
-- Function to detect and log conflicts
CREATE OR REPLACE FUNCTION detect_realtime_conflicts()
RETURNS TRIGGER AS $$
BEGIN
  -- Log the realtime event
  INSERT INTO audit_logs (
    correlation_id,
    user_id,
    household_id,
    level,
    category,
    event_type,
    message,
    entity_type,
    entity_id,
    action,
    realtime_event,
    data
  ) VALUES (
    'realtime_' || gen_random_uuid(),
    NEW.created_by,
    NEW.household_id,
    'info',
    'realtime',
    'update',
    'Realtime event: ' || TG_OP || ' on ' || TG_TABLE_NAME,
    TG_TABLE_NAME,
    NEW.id,
    TG_OP,
    TG_OP,
    jsonb_build_object(
      'old_row', ROW(OLD.*),
      'new_row', ROW(NEW.*),
      'table', TG_TABLE_NAME,
      'timestamp', NOW()
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to important tables
CREATE TRIGGER recipe_realtime_log
AFTER INSERT OR UPDATE OR DELETE ON recipes
FOR EACH ROW
EXECUTE FUNCTION detect_realtime_conflicts();
```text

---

## 5. Audit Trail Queries

```sql
-- Get all changes to a specific recipe
SELECT timestamp, user_id, action, data
FROM audit_logs
WHERE entity_id = 'recipe_uuid_here'
AND entity_type = 'Recipe'
ORDER BY timestamp DESC;

-- Get all operations by a user in a household
SELECT timestamp, event_type, message, action, rows_affected
FROM audit_logs
WHERE user_id = 'user_uuid'
AND household_id = 'household_uuid'
AND DATE(timestamp) >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY timestamp DESC;

-- Find conflicts in last 24 hours
SELECT timestamp, user_id, entity_id, conflict_type, conflict_resolution
FROM audit_logs
WHERE conflict_detected = true
AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

-- Performance analysis: slow operations
SELECT 
  event_type, 
  AVG(total_duration_ms) as avg_duration,
  MAX(total_duration_ms) as max_duration,
  COUNT(*) as frequency
FROM audit_logs
WHERE category = 'api'
AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY event_type
ORDER BY avg_duration DESC;

-- Error frequency
SELECT 
  error_code,
  COUNT(*) as frequency,
  MAX(timestamp) as latest_error
FROM audit_logs
WHERE level = 'error'
AND timestamp > NOW() - INTERVAL '7 days'
GROUP BY error_code
ORDER BY frequency DESC;
```text

---

## 6. Real-time Monitoring Dashboard (SQL)

```sql
-- Create view for real-time dashboard
CREATE VIEW dashboard_metrics AS
SELECT 
  NOW() as current_time,
  (SELECT COUNT(*) FROM audit_logs WHERE timestamp > NOW() - INTERVAL '1 hour' AND level = 'error') as errors_last_hour,
  (SELECT COUNT(*) FROM audit_logs WHERE timestamp > NOW() - INTERVAL '1 minute' AND level = 'error') as errors_last_minute,
  (SELECT AVG(total_duration_ms) FROM audit_logs WHERE timestamp > NOW() - INTERVAL '1 hour' AND category = 'api') as avg_api_duration_ms,
  (SELECT COUNT(DISTINCT user_id) FROM audit_logs WHERE timestamp > NOW() - INTERVAL '1 hour') as active_users_1h,
  (SELECT COUNT(DISTINCT correlation_id) FROM audit_logs WHERE timestamp > NOW() - INTERVAL '1 hour') as unique_requests_1h;
```text

---

## 7. Alerting Rules

```yaml
# Example: Prometheus rules for alerting
name: EzMenuAlerting
rules:

  - alert: HighErrorRate
    expr: rate(audit_logs[level="error"][5m]) > 0.05
    for: 5m
    annotations:
      summary: "Error rate > 5% in last 5 minutes"
      
  - alert: DatabaseSlow
    expr: database_ms > 1000
    for: 10m
    annotations:
      summary: "Database queries > 1s"
      
  - alert: DataLossDetected
    expr: data_loss_detected = true
    for: 1m
    annotations:
      summary: "CRITICAL: Data loss detected!"
      severity: critical
      action: "Immediate investigation required"
```text

---

## 8. Retention Policy

```sql
-- Delete logs older than 1 year (GDPR compliance)
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM audit_logs
  WHERE timestamp < NOW() - INTERVAL '1 year';
  
  VACUUM ANALYZE audit_logs;
END;
$$ LANGUAGE plpgsql;

-- Schedule daily at 02:00 UTC
SELECT cron.schedule('cleanup_logs', '0 2 * * *', 'SELECT cleanup_old_logs()');
```text

---

## Performance Considerations

- Index on `timestamp DESC` for fast recent log queries
- Index on `user_id, timestamp` for user-specific queries
- Index on `household_id` for household-scoped queries
- Batch inserts for high-volume scenarios
- Archive old logs to cold storage after 30 days
- Use JSONB for flexible schema without migrations

## Security

- Enable RLS to prevent cross-tenant data leaks
- Never log passwords, tokens, or sensitive PII
- Audit log table is append-only (no deletes/updates)
- Service role only for server-side inserts
- Client cannot directly insert into audit_logs
