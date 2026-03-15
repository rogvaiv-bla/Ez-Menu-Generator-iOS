import Foundation
import SQLite3
import Combine
import UIKit

// Define SQLITE_TRANSIENT for Swift compatibility
let SQLITE_TRANSIENT = unsafeBitCast((-1 as Int), to: sqlite3_destructor_type?.self)

// MARK: - Logger Database

class LogDatabase {
    private let dbPath: String
    private let maxDatabaseSizeMB = 50
    private let retentionDays = 7
    private let serialQueue = DispatchQueue(label: "com.ezmenu.logging.db", qos: .utility)
    
    private var db: OpaquePointer?
    
    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let logsDir = paths[0].appendingPathComponent("Logs")
        
        // Create logs directory if needed
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        
        self.dbPath = logsDir.appendingPathComponent("logs.sqlite").path
        
        setupDatabase()
    }
    
    private func setupDatabase() {
        serialQueue.sync {
            // Open database
            guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
                #if DEBUG
                print("❌ Failed to open logs database")
                #endif
                return
            }
            
            // Create table
            let sql = """
            CREATE TABLE IF NOT EXISTS logs (
                id INTEGER PRIMARY KEY,
                timestamp REAL NOT NULL,
                correlation_id TEXT NOT NULL,
                session_id TEXT,
                request_id TEXT,
                user_id TEXT,
                household_id TEXT,
                level TEXT NOT NULL,
                category TEXT NOT NULL,
                event_type TEXT NOT NULL,
                message TEXT NOT NULL,
                data BLOB NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE INDEX IF NOT EXISTS idx_timestamp ON logs(timestamp DESC);
            CREATE INDEX IF NOT EXISTS idx_correlation ON logs(correlation_id);
            CREATE INDEX IF NOT EXISTS idx_user ON logs(user_id);
            CREATE INDEX IF NOT EXISTS idx_household ON logs(household_id);
            CREATE INDEX IF NOT EXISTS idx_level ON logs(level);
            """
            
            var errorMessage: UnsafeMutablePointer<Int8>?
            if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
                if let error = errorMessage {
                    #if DEBUG
                    print("❌ Database setup failed: \(String(cString: error))")
                    #endif
                    sqlite3_free(error)
                }
            }
            
            // Enable WAL mode for better concurrency
            sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil)
        }
    }
    
    func insert(_ entry: LogEntry) {
        // Encode on main thread before dispatching to background queue
        guard let data = try? JSONEncoder().encode(entry) else {
            #if DEBUG
            print("❌ Failed to encode log entry")
            #endif
            return
        }
        
        serialQueue.async { [weak self] in
            guard let self, let db = self.db else { return }
            
            let sql = """
            INSERT INTO logs (timestamp, correlation_id, session_id, request_id, 
                             user_id, household_id, level, category, event_type, 
                             message, data)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                #if DEBUG
                print("❌ Failed to prepare SQL statement")
                #endif
                return
            }
            
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_double(statement, 1, entry.timestamp.timeIntervalSince1970)
            sqlite3_bind_text(statement, 2, entry.correlationId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, entry.sessionId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, entry.requestId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, entry.userId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 6, entry.householdId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 7, entry.level.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 8, entry.category.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 9, entry.eventType.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 10, entry.message, -1, SQLITE_TRANSIENT)
            sqlite3_bind_blob(statement, 11, (data as NSData).bytes, Int32(data.count), SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                #if DEBUG
                print("❌ Failed to insert log entry")
                #endif
            }
        }
    }
    
    func deleteOldLogs(before date: Date) {
        serialQueue.async { [weak self] in
            guard let self, let db = self.db else { return }
            
            let sql = "DELETE FROM logs WHERE timestamp < ?"
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return
            }
            
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_double(statement, 1, date.timeIntervalSince1970)
            sqlite3_step(statement)
        }
    }
    
    func getLogs(
        correlationId: String? = nil,
        userId: String? = nil,
        householdId: String? = nil,
        level: LogLevel? = nil,
        limit: Int = 1000
    ) -> [LogEntry] {
        var logs: [LogEntry] = []
        
        serialQueue.sync { [weak self] in
            guard let self, let db = self.db else { return }
            
            var sql = "SELECT data FROM logs WHERE 1=1"
            var params: [String] = []
            
            if let correlationId {
                sql += " AND correlation_id = ?"
                params.append(correlationId)
            }
            if let userId {
                sql += " AND user_id = ?"
                params.append(userId)
            }
            if let householdId {
                sql += " AND household_id = ?"
                params.append(householdId)
            }
            if let level {
                sql += " AND level = ?"
                params.append(level.rawValue)
            }
            
            sql += " ORDER BY timestamp DESC LIMIT ?"
            params.append(String(limit))
            
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                return
            }
            
            defer { sqlite3_finalize(statement) }
            
            for (index, param) in params.enumerated() {
                sqlite3_bind_text(statement, Int32(index + 1), param, -1, SQLITE_TRANSIENT)
            }
            
            let decoder = JSONDecoder()
            while sqlite3_step(statement) == SQLITE_ROW {
                let dataBytes = sqlite3_column_blob(statement, 0)
                let dataLength = sqlite3_column_bytes(statement, 0)
                
                if let dataBytes, dataLength > 0 {
                    let data = Data(bytes: dataBytes, count: Int(dataLength))
                    if let log = try? decoder.decode(LogEntry.self, from: data) {
                        logs.append(log)
                    }
                }
            }
        }
        
        return logs
    }
    
    func deleteAll() {
        serialQueue.async { [weak self] in
            guard let self, let db = self.db else { return }
            sqlite3_exec(db, "DELETE FROM logs", nil, nil, nil)
        }
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
}

// MARK: - Correlation ID Manager

@MainActor
class CorrelationIDManager: ObservableObject {
    static let shared = CorrelationIDManager()
    
    @Published private(set) var currentContext: CorrelationContext
    private let sessionStartTime = Date()
    
    init() {
        let sessionId = UUID().uuidString.prefix(12).lowercased()
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        self.currentContext = CorrelationContext(
            sessionId: sessionId,
            requestId: "",
            userId: nil,
            householdId: nil,
            deviceId: deviceId
        )
        
        #if DEBUG
        print("🔵 [CorrelationIDManager] Session started: \(sessionId)")
        #endif
    }
    
    func generateRequestId() -> String {
        let uuid = UUID().uuidString
        let requestId = String(uuid.prefix(8))
        
        var newContext = currentContext
        newContext.requestId = requestId
        self.currentContext = newContext
        
        return requestId
    }
    
    func setUser(_ userId: UUID?, household: UUID?) {
        var newContext = currentContext
        newContext.userId = userId
        newContext.householdId = household
        self.currentContext = newContext
        
        if let userId, let household {
            #if DEBUG
            print("🔵 [CorrelationIDManager] User set: \(userId.uuidString.prefix(8))... for household \(household.uuidString.prefix(8))...")
            #endif
        }
    }
    
    func getCurrentCorrelationId() -> String {
        currentContext.correlationHeader
    }
}

// MARK: - Local Logger

class LocalLogger {
    static let shared = LocalLogger()
    
    private let db = LogDatabase()
    private var logBuffer: [LogEntry] = []
    private let maxBufferSize = 100
    private let queue = DispatchQueue(label: "com.ezmenu.logging", qos: .utility)
    
    private init() {}
    
    func log(_ entry: LogEntry) {
        queue.async { [weak self] in
            self?.logBuffer.append(entry)
            
            // Persist critical logs immediately
            if entry.level.priority >= LogLevel.error.priority {
                self?.flushBuffer()
            }
            
            // Flush periodically
            if (self?.logBuffer.count ?? 0) >= (self?.maxBufferSize ?? 100) {
                self?.flushBuffer()
            }
        }
    }
    
    func flush() {
        queue.async { [weak self] in
            self?.flushBuffer()
        }
    }
    
    private func flushBuffer() {
        for entry in logBuffer {
            db.insert(entry)
        }
        logBuffer.removeAll()
    }
    
    func cleanup() {
        queue.async { [weak self] in
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
            self?.db.deleteOldLogs(before: sevenDaysAgo)
        }
    }
    
    func getLogs(
        correlationId: String? = nil,
        userId: String? = nil,
        householdId: String? = nil,
        limit: Int = 1000
    ) -> [LogEntry] {
        queue.sync {
            db.getLogs(
                correlationId: correlationId,
                userId: userId,
                householdId: householdId,
                limit: limit
            )
        }
    }
    
    func exportLogsAsJSON() -> Data? {
        let logs = getLogs(limit: 10000)
        return try? JSONEncoder().encode(logs)
    }
}
