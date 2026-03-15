import Foundation

// MARK: - Core Logging Structures

enum LogLevel: String, Codable, Comparable {
    case debug, info, warning, error, critical
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.priority < rhs.priority
    }
}

enum LogCategory: String, Codable {
    case sync, api, realtime, offline, ui, validation, cache, error, audit
}

enum EventType: String, Codable {
    case addRecipe, updateRecipe, deleteRecipe
    case addMenu, updateMenu, deleteMenu
    case addShoppingItem, updateShoppingItem, deleteShoppingItem
    case syncStart, syncSuccess, syncFailed, syncConflict
    case subscribe, unsubscribe, reconnect, disconnect
    case offlineChange, offlineSync
    case apiCall, apiError, apiSuccess
    case uiEvent, navigation, userInteraction
    case conflictResolved, dataLoss, retryAttempt
    case errorDetected, errorRecovered
}

// MARK: - Helper Wrapper for Codable heterogeneous types

enum AnyCodable: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case dict([String: AnyCodable])
    
    init(_ value: Any?) {
        if value == nil {
            self = .null
        } else if let bool = value as? Bool {
            self = .bool(bool)
        } else if let int = value as? Int {
            self = .int(int)
        } else if let double = value as? Double {
            self = .double(double)
        } else if let string = value as? String {
            self = .string(string)
        } else if let array = value as? [Any] {
            self = .array(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            self = .dict(dict.mapValues { AnyCodable($0) })
        } else {
            self = .null
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self = .dict(dict)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dict(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Detailed Log Structures

struct OperationLog: Codable {
    let name: String
    let entityType: String
    let entityId: String
    let action: String  // create, update, delete
    let status: String  // pending, success, failed
    let durationMs: Int?
    let rowsAffected: Int
    
    enum CodingKeys: String, CodingKey {
        case name, entityType = "entity_type", entityId = "entity_id"
        case action, status, durationMs = "duration_ms", rowsAffected = "rows_affected"
    }
}

struct ErrorLog: Codable {
    let code: String
    let message: String
    let stackTrace: [String]?
    let domain: String
    let retryCount: Int
    let willRetry: Bool
    let underlyingError: String?
    
    enum CodingKeys: String, CodingKey {
        case code, message, stackTrace = "stack_trace", domain
        case retryCount = "retry_count", willRetry = "will_retry"
        case underlyingError = "underlying_error"
    }
}

struct PerformanceLog: Codable {
    let clientLocalMs: Int?
    let networkLatencyMs: Int?
    let serverProcessingMs: Int?
    let serverDatabaseMs: Int?
    let serverResponseMs: Int?
    let clientDeserializationMs: Int?
    let totalEndToEndMs: Int?
    let queueWaitMs: Int?
    
    enum CodingKeys: String, CodingKey {
        case clientLocalMs = "client_local_ms"
        case networkLatencyMs = "network_latency_ms"
        case serverProcessingMs = "server_processing_ms"
        case serverDatabaseMs = "server_database_ms"
        case serverResponseMs = "server_response_ms"
        case clientDeserializationMs = "client_deserialization_ms"
        case totalEndToEndMs = "total_end_to_end_ms"
        case queueWaitMs = "queue_wait_ms"
    }
}

struct RealtimeLog: Codable {
    let channel: String
    let event: String  // INSERT, UPDATE, DELETE
    let latencyMs: Int?
    let messageId: String?
    let sequenceNumber: Int?
    
    enum CodingKeys: String, CodingKey {
        case channel, event, latencyMs = "latency_ms"
        case messageId = "message_id", sequenceNumber = "sequence_number"
    }
}

struct SyncLog: Codable {
    let conflict: String?
    let mergeStrategy: String?
    let offlineChangesQueued: Int?
    let offlineChangesSynced: Int?
    let conflictId: String?
    let dataLoss: Bool?
    let lostFields: [String]?
    
    enum CodingKeys: String, CodingKey {
        case conflict, mergeStrategy = "merge_strategy"
        case offlineChangesQueued = "offline_changes_queued"
        case offlineChangesSynced = "offline_changes_synced"
        case conflictId = "conflict_id", dataLoss = "data_loss"
        case lostFields = "lost_fields"
    }
}

struct LogEntry: Codable {
    let timestamp: Date
    let correlationId: String
    let level: LogLevel
    let category: LogCategory
    let eventType: EventType
    let message: String
    
    let sessionId: String?
    let requestId: String?
    let userId: String?
    let householdId: String?
    let deviceId: String?
    
    let operation: OperationLog?
    let error: ErrorLog?
    let performance: PerformanceLog?
    let realtime: RealtimeLog?
    let sync: SyncLog?
    
    // optional details json
    let details: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case timestamp, correlationId = "correlation_id", level, category
        case eventType = "event_type", message
        case sessionId = "session_id", requestId = "request_id"
        case userId = "user_id", householdId = "household_id"
        case deviceId = "device_id"
        case operation, error, performance, realtime, sync, details
    }
}

// MARK: - Correlation Context

struct CorrelationContext {
    var sessionId: String
    var requestId: String
    var userId: UUID?
    var householdId: UUID?
    var deviceId: String
    
    var correlationHeader: String {
        var parts: [String] = []
        parts.append("sid_\(sessionId)")
        if !requestId.isEmpty {
            parts.append("rid_\(requestId)")
        }
        if let userId {
            parts.append("uid_\(userId.uuidString.prefix(8))")
        }
        if let householdId {
            parts.append("hid_\(householdId.uuidString.prefix(8))")
        }
        return parts.joined(separator: "|")
    }
}