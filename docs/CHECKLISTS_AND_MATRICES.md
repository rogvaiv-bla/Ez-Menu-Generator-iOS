# 📋 DECISION MATRIX & CHECKLISTS

---

## 1. Which Phase to Start With?

### Decision Tree

```
Are you in production with real users?
│
├─ YES
│  ├─ Do you have >3 crashes/week?
│  │  ├─ YES → START PHASE 1 IMMEDIATELY (this week)
│  │  └─ NO → Phase 1 is still recommended (preventive)
│  │
│  ├─ Have users complained about sync latency?
│  │  ├─ YES → Prioritize performance monitoring (Phase 1 + network section)
│  │  └─ NO → Standard Phase 1 is fine
│  │
│  └─ Do you trust your data consistency?
│     ├─ NO → Phase 1 + IntegrityManager (critical first)
│     └─ YES → Standard Phase 1
│
└─ NO (Still in beta/testing)
   ├─ Do you want to catch bugs before real users see them?
   │  ├─ YES → Phase 1 (local) + Phase 2 when shipping
   │  └─ NO → Wait until production
   │
   └─ Do you have a team to maintain backend monitoring?
      ├─ YES → Plan all phases
      └─ NO → Phase 1 only for now
```

### Result Matrix

| Scenario | Start With | Timeline |
|----------|-----------|----------|
| Production, crashes, no team | Phase 1 only | Start immediately |
| Production, crashes, have team | Phase 1→2→3 | Week 1-4 |
| Production, stable, small team | Phase 1→2 | Start Week 3 |
| Beta, preparing launch | Phase 1→2 | Before launch |
| Early stage, < 100 users | Phase 1 local | Whenever you want |

---

## 2. Phase 1 Checklist (Local Monitoring)

### Day 1: Setup
- [ ] Create folder structure in Xcode
  ```
  Monitoring/
  ├── Core/
  ├── Crash/
  ├── Integrity/
  ├── Performance/
  ├── Network/
  ├── Storage/
  ├── FeatureFlags/
  └── Dashboard/
  ```

- [ ] Add 3 provided Swift files to Monitoring/Core/ and Monitoring/Performance/
  - [ ] EventCollector.swift
  - [ ] PerformanceMonitor.swift
  - [ ] IntegrityManager.swift

- [ ] Create placeholder files for sections not yet implemented
  ```swift
  // CrashHandler.swift (stub)
  import Foundation
  
  class CrashHandler {
      static func setupCrashReporting() {
          // TODO: Implement
      }
  }
  ```

- [ ] Build and verify: Xcode should compile without errors

### Day 2: Initialize in App
- [ ] Create AppDelegate or open existing one
- [ ] Add in `application(_:didFinishLaunchingWithOptions:)`
  ```swift
  EventCollector.shared.start()
  CrashHandler.setupCrashReporting()
  PerformanceMonitor.shared.start()
  IntegrityManager.shared.initialize(with: modelContext)
  IntegrityManager.shared.startPeriodicChecks()
  ```

- [ ] Build and test app startup
- [ ] Verify no crashes on launch

### Day 3-4: Instrument Critical Paths
- [ ] Add performance monitoring to these operations:
  - [ ] `MenuListViewModel.deleteMenu()` - wrap with `PerformanceMonitor.measure()`
  - [ ] `RecipeEditorViewModel.saveRecipe()` - wrap with `PerformanceMonitor.measure()`
  - [ ] `RealtimeSyncManager.syncChanges()` - add latency logging
  - [ ] Network requests - log errors + timing

- [ ] Test each instrumentation point:
  ```swift
  // In debug view or test
  let measurements = PerformanceMonitor.shared.getRecentMeasurements()
  print(measurements)  // Should show timing data
  ```

### Day 5: Validation
- [ ] Run app through typical user flow (create menu, edit recipe, delete, undo)
- [ ] Check EventCollector buffer: `EventCollector.shared.buffer.count` (should grow)
- [ ] Check PerformanceMonitor: `PerformanceMonitor.shared.getRecentMeasurements()` (should have entries)
- [ ] Verify IntegrityManager runs: Check console logs "Integrity manager initialized"
- [ ] Memory check: App memory should not exceed 250MB during normal use
- [ ] Build and test on real device (if possible)

**Phase 1 Done:** You now have local visibility into crashes, performance, and data integrity.

---

## 3. Phase 2 Checklist (Backend Connection)

### Backend Setup (Day 1-2)
- [ ] Create Supabase account (if not done)
- [ ] Open Supabase SQL editor

- [ ] Create telemetry tables:
```sql
-- Copy from IMPLEMENTATION_QUICKSTART.md and run
CREATE TABLE telemetry_events (...)
CREATE TABLE crash_reports (...)
```

- [ ] Verify tables created
  ```sql
  SELECT * FROM telemetry_events LIMIT 1;
  ```

- [ ] Create indexes (SQL in IMPLEMENTATION_QUICKSTART.md)

### Deploy Edge Function (Day 2)
- [ ] Install Supabase CLI (if not done)
  ```bash
  npm install -g supabase
  supabase login
  ```

- [ ] Create function
  ```bash
  supabase functions new api/v1/telemetry
  ```

- [ ] Copy TypeScript code from IMPLEMENTATION_QUICKSTART.md into `index.ts`

- [ ] Deploy
  ```bash
  supabase functions deploy api/v1/telemetry
  ```

- [ ] Test with curl
  ```bash
  curl -X POST https://YOUR-PROJECT.supabase.co/functions/v1/api/v1/telemetry \
    -H "Content-Type: application/json" \
    -d '{"events": [], "appVersion": "1.0"}'
  ```

### Connect Mobile (Day 3)
- [ ] Create TelemetryService.swift in Monitoring/Core/
  - [ ] Copy code from IMPLEMENTATION_QUICKSTART.md
  - [ ] Update Supabase URL to your project

- [ ] Modify EventCollector to call TelemetryService
  ```swift
  // In flush() method
  TelemetryService.shared.sendBatch(batch)
  ```

- [ ] Build app, run, and perform 5 actions (delete menu, edit recipe, etc.)

- [ ] Check Supabase:
  ```sql
  SELECT COUNT(*) as total FROM telemetry_events;
  ```
  Should show > 0 events

- [ ] Verify app doesn't crash if Supabase is down (offline handling)

**Phase 2 Done:** Events are flowing from mobile app to backend database.

---

## 4. Phase 3 Checklist (Alerting & Dashboard)

### Create Metrics View (Day 1)
- [ ] Query crash trends
  ```sql
  -- Copy from STABILITY_SYSTEM_ARCHITECTURE.md section 3.3
  SELECT fingerprint, COUNT(*) as count
  FROM crash_reports
  WHERE created_at > NOW() - INTERVAL '7 days'
  GROUP BY fingerprint
  ORDER BY count DESC;
  ```

- [ ] Query latency percentiles
  ```sql
  SELECT 
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY value) as p50,
      PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY value) as p95,
      PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY value) as p99
  FROM telemetry_events
  WHERE type = 'sync_latency'
  AND created_at > NOW() - INTERVAL '24 hours';
  ```

### Setup Health Endpoint (Day 1-2)
- [ ] Create /api/v1/health function
  ```bash
  supabase functions new api/v1/health
  ```

- [ ] Copy TypeScript from IMPLEMENTATION_QUICKSTART.md

- [ ] Deploy
  ```bash
  supabase functions deploy api/v1/health
  ```

- [ ] Test
  ```bash
  curl https://YOUR-PROJECT.supabase.co/functions/v1/api/v1/health
  ```

### Setup Alerting (Day 2-3)
- [ ] Create Slack workspace (if not done)
- [ ] Create Slack app webhook
  - [ ] Go to api.slack.com
  - [ ] Create new app
  - [ ] Enable Webhook
  - [ ] Copy webhook URL

- [ ] Create pg_cron job
  ```sql
  -- Schedule check every 5 minutes
  SELECT cron.schedule('check-thresholds', '*/5 * * * *', 'SELECT check_thresholds()');
  ```

- [ ] Create function that triggers Slack (TypeScript in Phase 2 section)

- [ ] Test alerting by manually triggering function

### Dashboard (Day 3-4)
- [ ] Install Metabase (free)
  ```bash
  docker run -d -p 3000:3000 metabase/metabase
  ```

- [ ] Connect to Supabase (Data → Add Database → PostgreSQL)
- [ ] Create 3 saved questions:
  - [ ] Crash trends (last 7 days)
  - [ ] Latency P95 (last 24 hours)
  - [ ] Error rate (last 24 hours)

- [ ] Create dashboard combining these 3

**Phase 3 Done:** You have real-time alerts and visibility dashboard.

---

## 5. Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| App won't build after adding Monitoring/ | Check import cycles, verify Swift syntax |
| Telemetry batches not sending | Check Supabase URL, verify network permission, test URL in browser |
| No events in database | Enable logging in EventCollector, verify app runs long enough to batch |
| Alerts firing constantly | Thresholds too low, adjust in STABILITY_SYSTEM_ARCHITECTURE.md Section 2.1 |
| Performance monitor shows high overhead | Reduce instrumentation points, use sampling instead of 100% |
| Database getting too large | Add table cleanup: `DELETE FROM telemetry_events WHERE created_at < NOW() - INTERVAL '30 days'` |

---

## 6. Security Checklist

### Before Production

- [ ] **Data Privacy**
  - [ ] Don't log recipe content (only counts/types)
  - [ ] Don't log user emails (use user_id only)
  - [ ] Don't log passwords or tokens
  - [ ] Enable encryption for sensitive events

- [ ] **Network**
  - [ ] All telemetry over HTTPS only
  - [ ] Validate telemetry server certificates
  - [ ] Sign telemetry batches with HMAC-SHA256

- [ ] **Access Control**
  - [ ] Telemetry database readable only by analytics team
  - [ ] Edge functions only callable from authorized sources
  - [ ] Supabase RLS enabled for telemetry tables

### Code Review

- [ ] [ ] EventCollector doesn't capture sensitive data
- [ ] [ ] All logging statements reviewed for PII
- [ ] [ ] Crash reports sanitized
- [ ] [ ] Network calls use HTTPS

---

## 7. Performance Targets

| Metric | Target | How to Test |
|--------|--------|-----------|
| EventCollector startup | <5ms | Time `EventCollector.shared.start()` |
| Event logging latency | <1ms | `PerformanceMonitor.measure("log_event")` with 100 logs |
| PerformanceMonitor overhead | <2% | Compare operation time with/without wrapping |
| Memory footprint | <50MB | Check Settings → App Storage |
| Battery impact | <2% per hour | Run synthetic monitoring 1 hour, check battery |

---

## 8. Post-Implementation Maintenance

### Weekly (15 min)
- [ ] Check dashboard for anomalies
- [ ] Review Slack alerts
- [ ] Note any trends

### Monthly (1 hour)
- [ ] Summarize metrics for team
- [ ] Adjust thresholds if needed
- [ ] Plan instrumentation improvements
- [ ] Review new bugs caught

### Quarterly (2 hours)
- [ ] Full review of monitoring ROI
- [ ] Plan Phase 4 features (flags, synthetic, etc)
- [ ] Update documentation with learnings

---

## 9. Success Criteria (How to Know It's Working)

### After Phase 1
```
✅ App starts without crashes
✅ Can see logged events locally (console or debug view)
✅ PerformanceMonitor shows timing data
✅ IntegrityManager reports no violations for healthy menu
✅ <2% performance overhead
```

### After Phase 2
```
✅ Events appear in Supabase within 5 minutes
✅ Crash reports include full stack trace
✅ No transmission failures for batches
✅ Dashboard queries return data
```

### After Phase 3
```
✅ Slack receives alert when intentionally triggering high error rate
✅ On-call person acknowledges alarm within 5 minutes
✅ Health endpoint shows backend operational
✅ Can see trends over 7 days
```

---

## 10. Quick Reference: Where to Add Instrumentation

### In ViewModels
```swift
// Before saving
try PerformanceMonitor.shared.measure("save_recipe") {
    try StorageService.shared.addRecipe(recipe)
}
```

### In Services
```swift
// Network
let start = Date()
let (data, response) = try await URLSession.shared.data(from: url)
logPerformance("network_\(path)", durationMs: Int(Date().timeIntervalSince(start) * 1000))
```

### In SwiftData operations
```swift
// Before delete
try PerformanceMonitor.shared.measure("delete_menu") {
    context.delete(menu)
    try context.save()
}
```

### In Sync operations
```swift
let latency = Int(Date().timeIntervalSince(startTime) * 1000)
logSyncLatency(latency, householdId: household.id.uuidString)
```

---

## 11. Emergency Playbook

### If Crash Rate Spikes to >10%

```
1. Check latest changes
   - What shipped in last build?
   - Any new dependencies?

2. Enable verbose logging
   - Phase 1: Check local logs
   - Phase 2: Query crash_reports with latest exceptions

3. Disable affected feature
   - Feature flag → false (if Phase 4 complete)
   - Or direct: release hotfix

4. Investigate root cause
   - Stack traces in dashboard
   - User flow leading to crash

5. Fix + verify
   - Unit test for crash scenario
   - Verify fix in test build
   - Roll out with monitoring enabled
```

### If Sync Never Completes

```
1. Check network
   - Is device online?
   - Can ping server?

2. Check backend health
   - Call /api/v1/health endpoint
   - Check Supabase status page

3. Check local sync queue
   - How many pending operations?
   - Any errors in queue?

4. Force reset
   - Clear local sync queue
   - Re-sync household state from server
   - Test single operation
```

### If Database Gets Too Large

```
1. Check size
   ```sql
   SELECT 
       pg_size_pretty(pg_total_relation_size('telemetry_events')) as size
   ```

2. Add retention policy
   ```sql
   DELETE FROM telemetry_events 
   WHERE created_at < NOW() - INTERVAL '30 days'
   ```

3. Setup automated cleanup
   ```sql
   SELECT cron.schedule('cleanup-old-telemetry', '0 2 * * *', 
       'DELETE FROM telemetry_events WHERE created_at < NOW() - INTERVAL ''30 days''')
   ```
```

---

**Final Note:** This is a living system. Update checklists as you discover patterns and best practices specific to your app.
