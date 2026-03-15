# 🚀 IMPLEMENTATION QUICKSTART

## Step 1: Add Monitoring Folder to Xcode (Today)

```bash
# In terminal
mkdir -p "Ez Menu Generator/Monitoring/"{Core,Crash,Integrity,Performance,Network,Storage,FeatureFlags,Dashboard}

# Add the 3 files already created:
# - Ez Menu Generator/Monitoring/Core/EventCollector.swift
# - Ez Menu Generator/Monitoring/Performance/PerformanceMonitor.swift
# - Ez Menu Generator/Monitoring/Integrity/IntegrityManager.swift
```

1. Drag folders into Xcode
2. New Group "Monitoring" (yellow folder)
3. Add existing files (CMD+E)

## Step 2: Initialize in App Startup (This Week)

```swift
// EzMenuGeneratorApp.swift
import SwiftUI

@main
struct EzMenuGeneratorApp: App {
    @StateObject private var session = SessionManager()
    
    var body: some Scene {
        WindowGroup {
            if session.isAuthenticated {
                MainView()
                    .onAppear {
                        setupMonitoring()  // NEW
                    }
            } else {
                LoginView()
            }
        }
    }
    
    private func setupMonitoring() {
        // 1. Start event collection (very early)
        EventCollector.shared.start()
        
        // 2. Setup crash reporting
        CrashHandler.setupCrashReporting()
        
        // 3. Start performance monitoring
        PerformanceMonitor.shared.start()
        FrameRateMonitor.shared.startMonitoring()
        
        // 4. Initialize integrity manager
        if let modelContext = session.modelContext {
            IntegrityManager.shared.initialize(with: modelContext)
            IntegrityManager.shared.startPeriodicChecks()
        }
        
        // 5. Enable sync metrics
        RealtimeSyncManager.shared.enableMetrics()
        OfflineSyncManager.shared.enableMetrics()
        
        // 6. Log session start
        EventCollector.shared.logEvent("session_start", tags: [
            "user": session.user?.id.uuidString ?? "unknown",
            "household": session.household?.id.uuidString ?? "unknown",
            "app_version": Bundle.main.appVersion ?? "unknown"
        ])
    }
}
```

## Step 3: Instrument Critical Paths (This Sprint)

### A. Menu Operations

```swift
// MenuListViewModel.swift
func deleteMenu(_ menu: Menu) async {
    return await PerformanceMonitor.shared.measure("deleteMenu") {
        // Create snapshot (for undo)
        if let snapshot = MenuSnapshot.from(menu) {
            UndoRedoManager.shared.captureSnapshot(snapshot)
        }
        
        // Delete from DB
        try await StorageService.shared.deleteMenu(menu)
        
        logPerformance("deleteMenu", durationMs: 0)
    }
}
```

### B. Network Requests

```swift
// In URLSession extension or NetworkService
let startTime = Date()

let (data, response) = try await URLSession.shared.data(from: url)

let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

if statusCode >= 400 {
    logNetworkError("http_\(statusCode)", statusCode: statusCode)
}

if durationMs > 3000 {
    logPerformance("network_request", durationMs: durationMs, tags: [
        "url": url.path,
        "status": String(statusCode)
    ])
}
```

### C. Sync Operations

```swift
// RealtimeSyncManager.swift
func syncChanges() async throws {
    let startTime = Date()
    
    try await applySyncBatch()
    
    let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
    logSyncLatency(latencyMs, householdId: householdId)
    
    if latencyMs > 5000 {
        AlertingService.warning(
            "Slow sync detected: \(latencyMs)ms",
            severity: .warning
        )
    }
}
```

### D. Validation Failures

```swift
// StorageService.swift
func addRecipe(_ recipe: Recipe) throws {
    let errors = RecipeValidator.validate(recipe)
    
    if !errors.isEmpty {
        logDataValidationFailure("Recipe", reason: errors.map { $0.message }.joined(separator: "; "))
        throw ValidationError(errors: errors)
    }
    
    // Proceed...
}
```

## Step 4: Create Test Suite (Week 2)

```bash
# Create test files
mkdir -p "Ez Menu GeneratorTests/Stability"
```

```swift
// Tests/Stability/IntegrityRulesTests.swift
import XCTest
@testable import Ez_Menu_Generator

class IntegrityRulesTests: XCTestCase {
    var manager: IntegrityManager!
    
    override func setUp() {
        super.setUp()
        manager = IntegrityManager()
    }
    
    func testMenuMustHave7Days() {
        // Create menu with 6 days
        let menu = createTestMenu(dayCount: 6)
        
        // Should report violation
        let violations = manager.checkMenuCompleteness()
        
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].rule, "menu_days_complete")
    }
}
```

## Step 5: Backend Setup (Week 3)

### Create Telemetry Tables

```sql
-- Run in Supabase SQL Editor

-- 1. Events table
CREATE TABLE IF NOT EXISTS telemetry_events (
    id UUID PRIMARY KEY,
    type TEXT NOT NULL,
    value FLOAT,
    tags JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    session_id TEXT,
    household_id UUID REFERENCES households(id),
    user_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_telemetry_household_time ON telemetry_events(household_id, created_at);
CREATE INDEX idx_telemetry_type_time ON telemetry_events(type, created_at);

-- 2. Crash reports table
CREATE TABLE IF NOT EXISTS crash_reports (
    id UUID PRIMARY KEY,
    exception_type TEXT NOT NULL,
    message TEXT,
    stack_trace JSONB,
    session_id TEXT,
    household_id UUID REFERENCES households(id),
    user_id UUID,
    app_version TEXT,
    device TEXT,
    memory_used_mb INT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_crashes_household_time ON crash_reports(household_id, created_at);
```

### Create Edge Function for Telemetry

```typescript
// supabase/functions/api/v1/telemetry/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const cors = {
    headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
}

serve(async (req) => {
    // CORS
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: cors.headers })
    }
    
    try {
        const batch = await req.json()
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )
        
        // Validate batch
        if (!batch.events || !Array.isArray(batch.events)) {
            return new Response(JSON.stringify({ error: 'Invalid batch' }), { 
                status: 400,
                headers: cors.headers
            })
        }
        
        // Insert events
        const { error } = await supabase
            .from('telemetry_events')
            .insert(batch.events)
        
        if (error) {
            console.error('Insert error:', error)
            return new Response(JSON.stringify({ error: error.message }), { 
                status: 500,
                headers: cors.headers
            })
        }
        
        return new Response(JSON.stringify({ success: true }), {
            status: 200,
            headers: cors.headers
        })
        
    } catch (error) {
        console.error('Function error:', error)
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: cors.headers
        })
    }
})
```

### Deploy Edge Function

```bash
supabase functions deploy api/v1/telemetry
```

## Step 6: Connect Client to Backend (Week 3)

```swift
// TelemetryService.swift (Create this)
import Foundation

class TelemetryService {
    static let shared = TelemetryService()
    
    private let supabaseURL = URL(string: "https://YOUR-PROJECT.supabase.co")!
    private let apiFunction = "api/v1/telemetry"
    
    func sendBatch(_ batch: TelemetryBatch) {
        Task {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                
                let data = try encoder.encode(batch)
                
                var request = URLRequest(url: supabaseURL.appendingPathComponent(apiFunction))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = data
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    os_log("✅ Telemetry batch sent successfully", log: OSLog.telemetry)
                } else {
                    os_log("❌ Telemetry batch failed", log: OSLog.telemetry)
                }
            } catch {
                os_log("❌ Error sending telemetry: %{public}@", log: OSLog.telemetry, type: .error, error.localizedDescription)
            }
        }
    }
    
    func flushBatchIfNeeded() {
        EventCollector.shared.flushBatch()
    }
}
```

## Step 7: Setup Dashboard Queries (Week 4)

```sql
-- View: Recent crashes by household
SELECT 
    household_id,
    COUNT(*) as crash_count,
    COUNT(DISTINCT exception_type) as unique_types,
    MAX(timestamp) as last_crash,
    ARRAY_AGG(DISTINCT exception_type) as exception_types
FROM crash_reports
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY household_id
ORDER BY crash_count DESC;
```

## Validation Checklist

- [ ] App starts without crashes
- [ ] EventCollector buffers events locally
- [ ] Performance metrics captured for critical operations
- [ ] Telemetry batch sends to backend (check Supabase logs)
- [ ] Integrity check runs without errors
- [ ] Dashboard queries return data
- [ ] Can manually force a "test error" and see it reported

## Performance Impact Validation

```swift
// Add to test suite
func testMonitoringOverhead() {
    let monitor = PerformanceMonitor.shared
    
    // Baseline: operation without monitoring
    let noMonitoringTime = measure { 
        // Simulate 100 menu operations
        for _ in 0..<100 {
            createMenu()
        }
    }
    
    // With monitoring
    let withMonitoringTime = measure {
        for _ in 0..<100 {
            _ = try PerformanceMonitor.shared.measure("createMenu") {
                createMenu()
            }
        }
    }
    
    let overhead = Double(withMonitoringTime - noMonitoringTime) / Double(noMonitoringTime) * 100
    
    // Should be <2% overhead
    XCTAssertLessThan(overhead, 2.0, "Monitoring overhead is \(overhead)%")
}
```

## Next Steps

1. **Week 1-2**: Core infrastructure (EventCollector, PerformanceMonitor, IntegrityManager)
2. **Week 3**: Backend telemetry endpoint + test transmission
3. **Week 4**: Add more instrumentation points + fix data validation
4. **Week 5**: Feature flags implementation
5. **Week 6+**: Advanced features (synthetic monitoring, friction detection, dashboard)

---

## Questions?

Reference sections in STABILITY_SYSTEM_ARCHITECTURE.md for:
- Detailed implementation patterns
- Threshold configurations
- Alerting setup
- Data validation strategies
