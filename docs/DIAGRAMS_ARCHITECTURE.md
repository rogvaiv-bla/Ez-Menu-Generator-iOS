# 📊 Diagrame Arhitecurii

## 1. Fluxul Complet de Detecție și Alertare

```mermaid
graph TD
    A["🔴 EVENT OCCURS<br/>Crash | Timeout | Sync Fail | Data Mismatch"] -->|Capture| B["📸 IMMEDIATE CAPTURE<br/>- Exception + Stack Trace<br/>- Context: user, household, app version<br/>- Device state: memory, disk, network<br/>- Activity: last screen + action"]
    
    B -->|Local Store| C["💾 SQLite Event Log<br/>Rotating log: 50MB max<br/>Keep: 7 days | 10,000 events"]
    
    C -->|Buffer| D["🔄 In-Memory Buffer<br/>Last 50 events<br/>Instant access for <br/>troubleshooting"]
    
    D -->|Schedule| E{"Flush Trigger?<br/>- Every 5 min<br/>- Buffer full 100 events<br/>- Critical error<br/>- App exit"}
    
    E -->|Yes| F["📦 Batch Creation<br/>- Compress gzip<br/>- Sign HMAC-SHA256<br/>- Add timestamp + nonce<br/>- Encrypt TLS"]
    
    F -->|Network Check| G{"Online?"}
    
    G -->|No| H["⏳ Queue for Retry<br/>Persist in SQLite<br/>Retry on reconnect"]
    
    G -->|Yes| I["🚀 POST /api/v1/telemetry<br/>HTTPS to Supabase<br/>Retry: exponential backoff"]
    
    I -->|Response| J{"Batch<br/>Validated?"}
    
    J -->|No| K["❌ Reject<br/>Log validation error<br/>May retry modified"]
    
    J -->|Yes| L["✅ Accept<br/>Parse + Deduplicate<br/>Enrich metadata"]
    
    L -->|Aggregate| M["📊 Metrics Aggregation<br/>PostgreSQL transforms<br/>- Count events/type<br/>- Percentiles P50/P95/P99<br/>- Rate calculations"]
    
    M -->|Real-time| N["⚡ Threshold Check<br/>Run every 2 min<br/>pg_cron triggers"]
    
    N -->|Breach?| O{"Severity?"}
    
    O -->|WARNING| P["📝 Log Incident<br/>Tag with metric"]
    
    O -->|ALERT| Q["🔔 Slack/Email<br/>Notify team<br/>Include: impact, affected<br/>users, trending"]
    
    O -->|CRITICAL| R["🚨 Wake On-Call<br/>Phone + push<br/>Auto-disable feature<br/>if needed"]
    
    O -->|CATASTROPHIC| S["💥 Auto-Rollback<br/>Feature flag off<br/>Force client refresh"]
    
    P --> T["📈 Dashboard Update<br/>Metabase queries run<br/>Real-time charts"]
    Q --> T
    R --> T
    S --> T
    
    T --> U["👀 On-Call Views<br/>- Live incident board<br/>- Affected households<br/>- Suggested actions"]
    
    style A fill:#ff6b6b
    style F fill:#4ecdc4
    style L fill:#95e1d3
    style O fill:#ffe66d
    style T fill:#a8dadc
