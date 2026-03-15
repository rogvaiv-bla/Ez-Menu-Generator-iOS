# IMPLEMENTATION ROADMAP & CHECKLIST

## Phase 1: Core Infrastructure (Week 1)

### Step 1.1: Add Logging Structures

- [ ] Copy `LoggingStructures.swift` to Services/
- [ ] Review enums: LogLevel, LogCategory, EventType
- [ ] Verify AnyCodable wrapper works
- [ ] Test: Compile without errors

### Step 1.2: Add LocalLogger Database

- [ ] Copy `LocalLogger.swift` to Services/
- [ ] Review SQLite setup (pragma, indexes)
- [ ] Verify database initialization
- [ ] Test: Create dummy logs, verify SQLite file created

### Step 1.3: Add Logger Facade

- [ ] Copy `Logger.swift` to Services/
- [ ] Review logging convenience methods
- [ ] Add request tracker RAII pattern
- [ ] Test: Call Logger.logOperation(), verify logs appear

### Step 1.4: App Initialization

- [ ] Update `EzMenuGeneratorApp.swift` to initialize CorrelationIDManager
- [ ] Add `.onAppear { Logger.correlation.setUser(...) }`
- [ ] Add cleanup task `Logger.cleanupOldLogs()`
- [ ] Test: App launches, no crashes

### Testing Week 1

```bash
✅ Compile without errors
✅ App launches successfully  
✅ Can call Logger.logOperation() - no crashes
✅ SQLite file created in Documents/Logs/
✅ Verify 10K logs don't leak memory
✅ Startup time < 50ms added overhead
```text

---

## Phase 2: Integration in Existing Code (Week 2)

### Step 2.1: StorageService Integration

- [ ] Update `StorageService.addRecipe()`
  ```swift
  let startTime = Date()
  // ... existing code ...
  Logger.logOperation(name: "addRecipe", ...)
```json
- [ ] Update `StorageService.addMenu()`
- [ ] Update `StorageService.deleteRecipe()` 
- [ ] Update `StorageService.deleteMenu()`
- [ ] Test: Each operation logs without errors

### Step 2.2: SupabaseService Integration

- [ ] Update `SupabaseService.request()` - add request tracking
  ```swift
  let tracker = Logger.trackRequest(url: url, method: method, ...)
  // ... request ...
  tracker.success() or tracker.failure()
```json
- [ ] Update error handling - call `Logger.logError()`
- [ ] Test: All API calls now logged

### Step 2.3: ViewModels Integration
- [ ] Update `MenuListViewModel.deleteMenu()` - log user action
- [ ] Update `MenuEditorViewModel.saveMenu()` - log operation
- [ ] Update `ProductSearchViewModel` - log search events
- [ ] Test: UI interactions logged

### Step 2.4: Error Paths
- [ ] Add error logging to all catch blocks
- [ ] Add retry logging to retry mechanisms
- [ ] Verify all errors have correlation IDs
- [ ] Test: Trigger intentional errors, verify logged

### Testing Week 2
```bash
✅ Add recipe - logged with timing
✅ Delete menu - logged with user context
✅ API request timeout - logged with error
✅ Sync operation - logged with status
✅ Correlation IDs propagate correctly
✅ No regression in app performance
```text

---

## Phase 3: Realtime & Sync Logging (Week 3)

### Step 3.1: Realtime Subscriptions
- [ ] Update `RealtimeSyncManager.subscribe()`
  ```swift
  Logger.logRealtime(
      channel: "household_...:recipes",
      event: "INSERT,UPDATE,DELETE",
      action: "subscribe"
  )
```json
- [ ] Add message receive logging with latency
- [ ] Add disconnect logging (reconnect attempts)
- [ ] Test: Subscribe logs appear

### Step 3.2: Sync Conflict Detection
- [ ] Update `OfflineSyncManager.syncOfflineChanges()`
- [ ] Add conflict detection logging
  ```swift
  Logger.logSync(
      event: "Conflict: server version newer",
      eventType: .syncConflict,
      conflict: "version_mismatch",
      mergeStrategy: "last_write_wins"
  )
```json
- [ ] Log resolution strategy and data loss
- [ ] Test: Create conflict, verify logged

### Step 3.3: Offline Tracking
- [ ] Log when device goes offline
- [ ] Log each offline change as it's queued
- [ ] Log sync moment when reconnected
- [ ] Log offline queue status
- [ ] Test: Make changes offline, sync online

### Testing Week 3
```bash
✅ Subscribe to channel - logged
✅ Realtime message received - latency measured
✅ Conflict detected - logged with resolution
✅ Offline changes queued - logged
✅ Reconnection handled - logged
✅ Multi-message sequence verified for data loss
```text

---

## Phase 4: Remote Backends & Dashboards (Week 4)

### Step 4.1: Sentry Integration
- [ ] Create Sentry account (free tier)
- [ ] Get DSN from dashboard
- [ ] Add Sentry SDK to app
  ```swift
  import Sentry
  
  SentrySDK.start { options in
      options.dsn = "YOUR_DSN"
      options.tracesSampleRate = 0.1
  }
```json
- [ ] Test: Log error, see in Sentry dashboard

### Step 4.2: PostgreSQL Audit Log Table
- [ ] Create `audit_logs` table in Supabase
  ```sql
  CREATE TABLE audit_logs ( ... )
```json
- [ ] Create indexes for performance
- [ ] Enable RLS for security
- [ ] Test: Query audit logs from Supabase

### Step 4.3: Edge Function Logging
- [ ] Create `supabase/functions/shared/logging.ts`
- [ ] Wrap Edge Functions with logging middleware
- [ ] Extract correlation ID from headers
- [ ] Insert logs into audit_logs table
- [ ] Test: Make API call, see in audit_logs

### Step 4.4: Dashboards
- [ ] Create Sentry dashboard for error trends
- [ ] Create SQL queries for audit analysis
  ```sql
  SELECT error_code, COUNT(*) as frequency
  FROM audit_logs
  WHERE timestamp > now() - interval '24 hours'
  GROUP BY error_code
  ORDER BY frequency DESC;
```json
- [ ] Setup alert rules (error rate > 5%)
- [ ] Create daily digest view
- [ ] Test: Verify dashboards update

### Testing Week 4
```bash
✅ Error logged to Sentry
✅ API call headers include correlation ID
✅ Edge function logs to audit_logs
✅ Sentry dashboards display metrics
✅ SQL queries return expected results
✅ Alert rules trigger on error threshold
```text

---

## Phase 5: Polish & Documentation (Week 5)

### Step 5.1: Error Handling Edge Cases
- [ ] Deep crashes (OutOfMemory, etc.)
- [ ] Network completely down
- [ ] Database corruption
- [ ] Malformed JSON responses
- [ ] Test: Each edge case gracefully logged

### Step 5.2: Performance Optimization
- [ ] Enable sampling for debug logs in production
- [ ] Verify < 5% performance overhead
- [ ] Test with 1000 concurrent logs
- [ ] Monitor memory usage
- [ ] Test: App still responsive with heavy logging

### Step 5.3: Security Review
- [ ] Verify no passwords logged
- [ ] Verify no tokens logged
- [ ] Verify RLS on audit_logs table
- [ ] Mask sensitive fields (emails, etc.)
- [ ] Test: Export logs, verify clean

### Step 5.4: Documentation
- [ ] README updated with logging setup
- [ ] Troubleshooting guide for common issues
- [ ] Team training on log querying
- [ ] On-call runbook with log-based debugging
- [ ] Test: New dev can query logs in < 5 min

### Step 5.5: Runbook & Alerts
- [ ] Setup Slack integration for critical errors
- [ ] Create on-call dashboards
- [ ] Document alert escalation
- [ ] Create incident response templates
- [ ] Test: Trigger alert, verify notification

### Testing Week 5
```bash
✅ All edge cases handled
✅ Performance overhead < 5%
✅ No PII in logs
✅ Documentation complete
✅ Team trained
✅ Alerts working
✅ Incident runbook ready
```text

---

## Post-Launch Monitoring

### Week 6+ Ongoing

```text
Daily:
  ├─ Check error rate (target: < 1%)
  ├─ Review performance metrics (target: API < 500ms)
  └─ Monitor realtime latency (target: < 200ms)

Weekly:
  ├─ Conflict frequency analysis
  ├─ Offline sync success rate
  ├─ Data loss incidents
  └─ Top error codes

Monthly:
  ├─ Trend analysis (is error rate improving?)
  ├─ User impact analysis
  ├─ Performance regression detection
  └─ Capacity planning (is disk usage OK?)
```text

---

## Critical Milestones

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| Core logging working | End Week 1 | 🔲 |
| All app code instrumented | End Week 2 | 🔲 |
| Sync/conflict logging | End Week 3 | 🔲 |
| Remote backends operational | End Week 4 | 🔲 |
| Production ready | End Week 5 | 🔲 |

---

## Success Criteria

After implementation, you should be able to:

✅ **Find errors in < 2 minutes**
- Click correlation ID → see entire trace

✅ **Understand sync conflicts**
- Query: "conflicts in household X last week"
- Result: who, what, when, resolution

✅ **Debug network problems**
- See network latency per request
- Identify timeout patterns
- Spot performance degradation

✅ **Track data loss**
- Automatic detection of missing sequences
- Alerts when data loss detected
- Recovery process logged

✅ **Audit trail complete**
- WHO modified what, WHEN, and old vs new values
- Immutable (audit trail never deleted)
- GDPR compliant (1 year retention max)

✅ **Performance insights**
- Average API latency: 156ms
- Average sync time: 234ms
- Realtime latency: 87ms
- All tracked with percentiles (p50, p90, p99)

---

## Files Created

```text
Services/
├── LoggingStructures.swift      (Core types)
├── LocalLogger.swift            (SQLite persistence)
└── Logger.swift                 (Public API)

Root/
├── LOGGING_ARCHITECTURE.md      (Complete design)
├── LOGGING_INTEGRATION_GUIDE.md (How to use)
├── LOGGING_SERVER_SETUP.md      (Backend setup)
├── LOGGING_QUICK_REFERENCE.md   (Cheat sheet)
└── LOGGING_IMPLEMENTATION.md    (This file)
```text

---

## Team Onboarding

### For Swift Developers
1. Read LOGGING_QUICK_REFERENCE.md (5 min)
2. Review Logger.swift source (10 min)
3. Follow LOGGING_INTEGRATION_GUIDE.md (20 min)
4. Try logging in your next feature (hands-on)

### For Backend Engineers
1. Read LOGGING_SERVER_SETUP.md (15 min)
2. Review SQL schema + Edge Function examples (20 min)
3. Setup audit_logs table in your dev environment (10 min)
4. Query audit_logs for your first feature (hands-on)

### For DevOps
1. Review LOGGING_ARCHITECTURE.md oversight (10 min)
2. Setup Sentry/LogFlare accounts (15 min)
3. Create dashboards in chosen tool (20 min)
4. Configure alerts and escalation (15 min)

---

## Troubleshooting During Implementation

**Problem: "Logs not appearing"**
- Check: `Logger.correlation.getCurrentCorrelationId()` returns value
- Check: Device has free disk space (logs need ~50MB)
- Check: `Logger.flushAll()` called before checking

**Problem: "Logging is slow"**
- Solution: Use sampling in production
- Verify: Batch writes enabled (should be default)
- Check: Not logging too-large objects

**Problem: "SQLite file missing"**
- Check: `~/Documents/Logs/logs.sqlite` path
- Check: App has Documents write permission
- Check: Not in sandbox with restricted access

**Problem: "Correlation IDs not propagating"**
- Check: `CorrelationIDManager.shared.getCurrentCorrelationId()` in API headers
- Check: Edge Functions extracting from headers correctly
- Verify: Format is correct (sid_abc|rid_def|...)

---

## Final Checklist Before Launch

- [ ] All 3 Swift files compile without warnings
- [ ] App launches and logs appear in SQLite
- [ ] StorageService fully integrated
- [ ] SupabaseService fully integrated
- [ ] ViewModels fully integrated
- [ ] Error handling fully integrated
- [ ] Realtime logging working
- [ ] Sync conflict detection working
- [ ] Offline tracking working
- [ ] PostgreSQL audit_logs table created
- [ ] Edge Functions log to database
- [ ] Sentry account configured
- [ ] Dashboards created
- [ ] Alert rules configured
- [ ] Documentation complete
- [ ] Team trained
- [ ] Performance tested (< 5% overhead)
- [ ] Security reviewed (no PII logged)
- [ ] RLS enabled on audit_logs
- [ ] Retention policy configured
- [ ] On-call runbook created

---

**Status: Ready to implement! 🚀**
