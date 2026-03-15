import Foundation
import os.log

// MARK: - Public Logger Facade

class Logger {
    static let local = LocalLogger.shared
    static let correlation = CorrelationIDManager.shared
    
    private static let osLog = OSLog(subsystem: "com.ezmenu.app", category: "Logging")
    
    // MARK: - Operation Logging
    
    static func logOperation(
        name: String,
        entityType: String,
        entityId: UUID = UUID(),
        action: String,
        duration: TimeInterval? = nil,
        rowsAffected: Int = 1,
        status: String = "success"
    ) {
        let durationMs = duration.map { Int($0 * 1000) }
        
        let entry = LogEntry(
            timestamp: Date(),
            correlationId: CorrelationIDManager.shared.getCurrentCorrelationId(),
            level: status == "success" ? .info : .warning,
            category: .sync,
            eventType: mapToEventType(entityType: entityType, action: action),
            message: "Operation \(status): \(name)",
            
            sessionId: CorrelationIDManager.shared.currentContext.sessionId,
            requestId: CorrelationIDManager.shared.currentContext.requestId,
            userId: CorrelationIDManager.shared.currentContext.userId?.uuidString,
            householdId: CorrelationIDManager.shared.currentContext.householdId?.uuidString,
            deviceId: CorrelationIDManager.shared.currentContext.deviceId,
            
            operation: OperationLog(
                name: name,
                entityType: entityType,
                entityId: entityId.uuidString,
                action: action,
                status: status,
                durationMs: durationMs,
                rowsAffected: rowsAffected
            ),
            error: nil,
            performance: nil,
            realtime: nil,
            sync: nil,
            details: nil
        )
        
        LocalLogger.shared.log(entry)
    }
    
    // MARK: - Error Logging
    
    static func logError(
        code: String,
        message: String,
        domain: String = "Unknown",
        error: Error? = nil,
        userImpact: String? = nil,
        willRetry: Bool = false,
        retryCount: Int = 0
    ) {
        let stackTrace = Thread.callStackSymbols.map { $0.trimmingCharacters(in: .whitespaces) }
        
        let errorLog = ErrorLog(
            code: code,
            message: message,
            stackTrace: stackTrace,
            domain: domain,
            retryCount: retryCount,
            willRetry: willRetry,
            underlyingError: error?.localizedDescription
        )
        
        var details: [String: AnyCodable]? = nil
        if let userImpact {
            details = ["user_impact": AnyCodable(userImpact)]
        }
        
        let entry = LogEntry(
            timestamp: Date(),
            correlationId: CorrelationIDManager.shared.getCurrentCorrelationId(),
            level: .error,
            category: .error,
            eventType: .errorDetected,
            message: message,
            
            sessionId: CorrelationIDManager.shared.currentContext.sessionId,
            requestId: CorrelationIDManager.shared.currentContext.requestId,
            userId: CorrelationIDManager.shared.currentContext.userId?.uuidString,
            householdId: CorrelationIDManager.shared.currentContext.householdId?.uuidString,
            deviceId: CorrelationIDManager.shared.currentContext.deviceId,
            
            operation: nil,
            error: errorLog,
            performance: nil,
            realtime: nil,
            sync: nil,
            details: details
        )
        
        LocalLogger.shared.log(entry)
        os_log("❌ %{public}@: %{public}@ [%{public}@]", log: osLog, type: .error,
               domain, code, message)
    }
    
    // MARK: - Sync Logging
    
    static func logSync(
        event: String,
        eventType: EventType,
        conflict: String? = nil,
        mergeStrategy: String? = nil,
        dataLoss: Bool = false,
        lostFields: [String]? = nil,
        offline: Bool = false
    ) {
        let syncLog = SyncLog(
            conflict: conflict,
            mergeStrategy: mergeStrategy,
            offlineChangesQueued: nil,
            offlineChangesSynced: nil,
            conflictId: nil,
            dataLoss: dataLoss,
            lostFields: lostFields
        )
        
        let entry = LogEntry(
            timestamp: Date(),
            correlationId: CorrelationIDManager.shared.getCurrentCorrelationId(),
            level: dataLoss ? .critical : (conflict != nil ? .warning : .info),
            category: offline ? .offline : .sync,
            eventType: eventType,
            message: event,
            
            sessionId: CorrelationIDManager.shared.currentContext.sessionId,
            requestId: CorrelationIDManager.shared.currentContext.requestId,
            userId: CorrelationIDManager.shared.currentContext.userId?.uuidString,
            householdId: CorrelationIDManager.shared.currentContext.householdId?.uuidString,
            deviceId: CorrelationIDManager.shared.currentContext.deviceId,
            
            operation: nil,
            error: nil,
            performance: nil,
            realtime: nil,
            sync: syncLog,
            details: nil
        )
        
        LocalLogger.shared.log(entry)
        
        if dataLoss {
            os_log("⚠️ DATA LOSS: %{public}@", log: osLog, type: .error, event)
        } else if conflict != nil {
            os_log("⚠️ SYNC CONFLICT: %{public}@", log: osLog, type: .error, event)
        }
    }
    
    // MARK: - Performance Logging
    
    static func logPerformance(
        name: String,
        clientLocalMs: Int? = nil,
        networkLatencyMs: Int? = nil,
        serverProcessingMs: Int? = nil,
        serverDatabaseMs: Int? = nil,
        serverResponseMs: Int? = nil,
        clientDeserializationMs: Int? = nil,
        totalEndToEndMs: Int? = nil
    ) {
        let performanceLog = PerformanceLog(
            clientLocalMs: clientLocalMs,
            networkLatencyMs: networkLatencyMs,
            serverProcessingMs: serverProcessingMs,
            serverDatabaseMs: serverDatabaseMs,
            serverResponseMs: serverResponseMs,
            clientDeserializationMs: clientDeserializationMs,
            totalEndToEndMs: totalEndToEndMs,
            queueWaitMs: nil
        )
        
        let entry = LogEntry(
            timestamp: Date(),
            correlationId: CorrelationIDManager.shared.getCurrentCorrelationId(),
            level: (totalEndToEndMs ?? 0) > 1000 ? .warning : .info,
            category: .api,
            eventType: .apiSuccess,
            message: "Performance tracked: \(name)",
            
            sessionId: CorrelationIDManager.shared.currentContext.sessionId,
            requestId: CorrelationIDManager.shared.currentContext.requestId,
            userId: CorrelationIDManager.shared.currentContext.userId?.uuidString,
            householdId: CorrelationIDManager.shared.currentContext.householdId?.uuidString,
            deviceId: CorrelationIDManager.shared.currentContext.deviceId,
            
            operation: nil,
            error: nil,
            performance: performanceLog,
            realtime: nil,
            sync: nil,
            details: nil
        )
        
        LocalLogger.shared.log(entry)
        
        if let total = totalEndToEndMs, total > 3000 {
            os_log("⏱️ VERY SLOW: %{public}@ took %dms", log: osLog, type: .error, name, total)
        }
    }
    
    // MARK: - Realtime Logging
    
    static func logRealtime(
        channel: String,
        event: String,
        action: String,
        latencyMs: Int? = nil,
        messageId: String? = nil
    ) {
        let realtimeLog = RealtimeLog(
            channel: channel,
            event: event,
            latencyMs: latencyMs,
            messageId: messageId,
            sequenceNumber: nil
        )
        
        let eventType: EventType = action == "subscribe" ? .subscribe : 
                                   action == "unsubscribe" ? .unsubscribe : 
                                   .reconnect
        
        let entry = LogEntry(
            timestamp: Date(),
            correlationId: CorrelationIDManager.shared.getCurrentCorrelationId(),
            level: .info,
            category: .realtime,
            eventType: eventType,
            message: "Realtime \(action): \(channel)",
            
            sessionId: CorrelationIDManager.shared.currentContext.sessionId,
            requestId: CorrelationIDManager.shared.currentContext.requestId,
            userId: CorrelationIDManager.shared.currentContext.userId?.uuidString,
            householdId: CorrelationIDManager.shared.currentContext.householdId?.uuidString,
            deviceId: CorrelationIDManager.shared.currentContext.deviceId,
            
            operation: nil,
            error: nil,
            performance: nil,
            realtime: realtimeLog,
            sync: nil,
            details: nil
        )
        
        LocalLogger.shared.log(entry)
    }
    
    // MARK: - Info Logging
    
    static func logInfo(
        category: LogCategory,
        eventType: EventType,
        message: String,
        details: [String: Any]? = nil
    ) {
        let detailsAnyCodable = details.map { dict in
            dict.mapValues { AnyCodable($0) }
        }
        
        let entry = LogEntry(
            timestamp: Date(),
            correlationId: CorrelationIDManager.shared.getCurrentCorrelationId(),
            level: .info,
            category: category,
            eventType: eventType,
            message: message,
            
            sessionId: CorrelationIDManager.shared.currentContext.sessionId,
            requestId: CorrelationIDManager.shared.currentContext.requestId,
            userId: CorrelationIDManager.shared.currentContext.userId?.uuidString,
            householdId: CorrelationIDManager.shared.currentContext.householdId?.uuidString,
            deviceId: CorrelationIDManager.shared.currentContext.deviceId,
            
            operation: nil,
            error: nil,
            performance: nil,
            realtime: nil,
            sync: nil,
            details: detailsAnyCodable
        )
        
        LocalLogger.shared.log(entry)
    }
    
    // MARK: - Utility Methods
    
    static func flushAll() {
        LocalLogger.shared.flush()
    }
    
    static func cleanupOldLogs() {
        LocalLogger.shared.cleanup()
    }
    
    static func exportLogs() -> Data? {
        LocalLogger.shared.exportLogsAsJSON()
    }
    
    private static func mapToEventType(entityType: String, action: String) -> EventType {
        let key = "\(action)\(entityType)"
        switch key {
        case "createRecipe": return .addRecipe
        case "updateRecipe": return .updateRecipe
        case "deleteRecipe": return .deleteRecipe
        case "createMenu": return .addMenu
        case "updateMenu": return .updateMenu
        case "deleteMenu": return .deleteMenu
        case "createShoppingItem": return .addShoppingItem
        case "updateShoppingItem": return .updateShoppingItem
        case "deleteShoppingItem": return .deleteShoppingItem
        default: return .apiCall
        }
    }
}

// MARK: - Convenience Extensions

extension Logger {
    static func trackRequest(
        url: String,
        method: String = "GET",
        startTime: Date
    ) -> RequestTracker {
        RequestTracker(url: url, method: method, startTime: startTime)
    }
}

// MARK: - Request Tracker (RAII pattern)

class RequestTracker {
    private let url: String
    private let method: String
    private let startTime: Date
    private let correlationId: String
    
    init(url: String, method: String, startTime: Date) {
        self.url = url
        self.method = method
        self.startTime = startTime
        self.correlationId = CorrelationIDManager.shared.getCurrentCorrelationId()
    }
    
    func success(statusCode: Int? = nil) {
        let duration = Date().timeIntervalSince(startTime)
        
        Logger.logPerformance(
            name: url,
            networkLatencyMs: Int(duration * 1000)
        )
    }
    
    func failure(error: Error?, status: Int? = nil) {
        let duration = Date().timeIntervalSince(startTime)
        
        Logger.logError(
            code: "API_FAILURE",
            message: "API request failed: \(url)",
            domain: "URLSession",
            error: error
        )
        
        Logger.logPerformance(
            name: url,
            networkLatencyMs: Int(duration * 1000)
        )
    }
    
    deinit {
        // Optional: auto-log if not manually logged
    }
}
