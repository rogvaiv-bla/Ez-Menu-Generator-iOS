# QUICK REFERENCE - LOGGING CHEAT SHEET

## 📋 Copy-Paste Examples

### 1️⃣ Log a Successful Operation

```swift
let startTime = Date()
// ... do operation ...
Logger.logOperation(
    name: "addRecipe",
    entityType: "Recipe",
    entityId: recipe.id,
    action: "create",
    duration: Date().timeIntervalSince(startTime),
    status: "success"
)
```text

**Result:** ✅ Operation logged with timing info

---

### 2️⃣ Log an Error

```swift
Logger.logError(
    code: "NETWORK_TIMEOUT",
    message: "Request timed out after 30 seconds",
    domain: "URLSession",
    error: error,
    willRetry: true
)
```text

**Result:** ❌ Error captured with stack trace + retry intent

---

### 3️⃣ Log a Sync Conflict

```swift
Logger.logSync(
    event: "Conflict resolved: server version newer",
    eventType: .syncConflict,
    conflict: "version_mismatch",
    mergeStrategy: "last_write_wins",
    dataLoss: true,
    lostFields: ["modified_category"]
)
```text

**Result:** ⚠️ Conflict logged with resolution strategy

---

### 4️⃣ Log a Network Request

```swift
let startTime = Date()
let tracker = Logger.trackRequest(
    url: "https://api.supabase.io/rest/v1/recipes",
    method: "POST",
    startTime: startTime
)

// ... make request ...

if success {
    tracker.success(statusCode: 201)
} else {
    tracker.failure(error: error)
}
```text

**Result:** 📤 HTTP request timing + status captured

---

### 5️⃣ Log Realtime Subscription

```swift
// Subscribe
Logger.logRealtime(
    channel: "household_abc:recipes",
    event: "INSERT,UPDATE,DELETE",
    action: "subscribe"
)

// Message received with latency
Logger.logRealtime(
    channel: "household_abc:recipes",
    event: "UPDATE",
    action: "received",
    latencyMs: 87
)
```text

**Result:** 📡 Realtime latency tracked

---

### 6️⃣ Log Offline Change

```swift
Logger.logSync(
    event: "Recipe modified while offline",
    eventType: .offlineChange,
    offline: true
)
```text

**Result:** 📵 Offline operation queued for sync

---

### 7️⃣ Log with Custom Details

```swift
Logger.logInfo(
    category: .ui,
    eventType: .userInteraction,
    message: "User tapped delete menu button",
    details: [
        "menu_id": menu.id.uuidString,
        "menu_name": menu.name,
        "recipe_count": menu.meals.count
    ]
)
```text

**Result:** 📝 Custom context captured as JSON

---

### 8️⃣ Flush Logs Before Crash

```swift
func applicationWillTerminate() {
    Logger.flushAll()  // Ensure all logs written to disk
}
```text

**Result:** 💾 All pending logs persisted

---

### 9️⃣ Export Logs for Debugging

```swift
if let logsJSON = Logger.exportLogs() {
    let logsUrl = FileManager.default
        .temporaryDirectory
        .appendingPathComponent("logs.json")
    try? logsJSON.write(to: logsUrl)
    // Share or upload to server
}
```text

**Result:** 📤 All logs exported as JSON

---

### 🔟 Set User Context

```swift
Logger.correlation.setUser(userId, household: householdId)
```text

**Result:** 👤 All subsequent logs tagged with user/household

---

## 🎯 Logging Decision Tree

```text
Something happened?
├─ ✅ Success?
│  └─ logOperation() → timing info
│
├─ ❌ Error?
│  ├─ Will retry?
│  │  └─ logError(..., willRetry: true)
│  └─ Won't retry?
│     └─ logError(..., willRetry: false)
│
├─ 🔄 Sync conflict?
│  └─ logSync(..., conflict: "type")
│
├─ 📵 Offline?
│  └─ logSync(..., offline: true)
│
├─ 📡 Realtime event?
│  └─ logRealtime(event: "UPDATE")
│
└─ 🎬 UI event?
   └─ logInfo(category: .ui, eventType: .userInteraction)
```text

---

## 🚀 Performance Tips

```swift
// ✅ DO: Async batch writes (no UI lag)
Logger.logOperation(...)  // Queued + batched

// ❌ DON'T: Sync direct writes
synchronousLogger.write(...)  // Blocks UI!

// ✅ DO: Sample errors in production (reduce overhead)
#if DEBUG
    Logger.logError(...)  // Always log
#else
    if Int.random(in: 0..<100) < 10 {  // 10%
        Logger.logError(...)
    }
#endif

// ❌ DON'T: Log passwords, tokens, PII
Logger.logInfo(message: "Password: \(password)")  // NEVER!

// ✅ DO: Mask sensitive data
Logger.logInfo(message: "User: u***@gmail.com")  // Safe
```text

---

## 🔍 Debugging with Logs

### Find All Requests for a User

```swift
let userLogs = LocalLogger.shared.getLogs(
    userId: userId.uuidString,
    limit: 1000
)
```text

### Find All Conflicts in Household

```swift
let logs = LocalLogger.shared.getLogs(householdId: householdId.uuidString)
let conflicts = logs.filter { $0.sync?.conflict != nil }
```text

### Export Logs as JSON

```swift
if let json = Logger.exportLogs() {
    let string = String(data: json, encoding: .utf8)
    print(string)
}
```text

---

## 📊 What Gets Logged Where

| What | Client | Backend | Sentry |
|------|--------|---------|--------|
| Success operations | ✅ Local | ✅ Batch | ❌ |
| Errors | ✅ Local | ✅ Real-time | ✅ |
| Conflicts | ✅ Local | ✅ Real-time | ⚠️ |
| API calls | ✅ Timing | ✅ Full | ⚠️ Slow |
| Passwords | ❌ Never | ❌ Never | ❌ Never |
| User email | ⚠️ Hash | ✅ | ⚠️ Hash |

---

## 🛡️ Security Checklist

- [ ] No passwords logged
- [ ] No API keys logged
- [ ] No auth tokens logged
- [ ] User emails masked or hashed
- [ ] Sensitive fields redacted
- [ ] Audit logs immutable (only INSERT, no UPDATE/DELETE)
- [ ] Row-level security enabled on audit_logs
- [ ] Logs stored encrypted at rest (iOS handles this)
- [ ] Old logs auto-deleted after retention period
- [ ] GDPR compliance: 1-year retention max

---

## 📈 Sample Metrics

### Error Rate Alert Pattern

```swift
// Enable alerting when error rate > 5% in 5 minutes
let recentLogs = LocalLogger.shared.getLogs(limit: 1000)
let errors = recentLogs.filter { $0.level == .error }
let errorRate = Double(errors.count) / Double(recentLogs.count)

if errorRate > 0.05 {
    // Alert: error rate critical
}
```text

### Performance Degradation Pattern

```swift
// Alert when API latency > 1s average
let apiLogs = recentLogs.filter { $0.category == .api }
let avgLatency = apiLogs
    .compactMap { $0.performance?.totalEndToEndMs }
    .reduce(0, +) / apiLogs.count

if avgLatency > 1000 {
    // Alert: API slow
}
```text

---

## 🔗 Correlation ID Format

```text
sid_abc123 | rid_def456 | uid_user78 | hid_hh90
   │          │            │           └─ Household
   │          │            └─────────────── User ID
   │          └────────────────────────── Request ID  
   └──────────────────────────────────── Session ID
```text

**Use in HTTP Headers:**

```swift
request.setValue(
    Logger.correlation.getCurrentCorrelationId(),
    forHTTPHeaderField: "X-Correlation-ID"
)
```text

---

## 📞 Support

### Troubleshooting

**Logs not appearing:**
- Check: `Logger.correlation.getCurrentCorrelationId()`
- Check: Device has disk space (logs need ~50MB)
- Check: Timestamps are correct on device

**Logging too slow:**
- Use sampling: `Int.random(in: 0..<100) < 10`
- Reduce detail level in production
- Batch operations when possible

**Logs too large:**
- Enable auto-cleanup: `Logger.cleanupOldLogs()`
- Reduce retention from 7 to 3 days
- Use sampling more aggressively

---

## 🎓 Learning Path

1. **Day 1**: Copy files, integrate into app startup
2. **Day 2**: Add logging to StorageService, ViewModels
3. **Day 3**: Test with sample app actions
4. **Day 4**: Setup Sentry/LogFlare accounts
5. **Day 5**: Create dashboards, alerts

---

## 📚 References

- **Full Architecture**: See `LOGGING_ARCHITECTURE.md`
- **Integration Guide**: See `LOGGING_INTEGRATION_GUIDE.md`
- **Server Setup**: See `LOGGING_SERVER_SETUP.md`
- **Source Code**: See `Services/Logger.swift`, `Services/LocalLogger.swift`

---

**Remember:** Good logging is the difference between "something's broken" and "here's exactly what went wrong."

🚀 Ship with confidence!
