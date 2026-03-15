// EventCollector.swift
// Core telemetry collection - minimal overhead, local-first

import Foundation
import UIKit
import OSLog

let osLog = OSLog(subsystem: "com.ezmenu.monitoring", category: "telemetry")

// MARK: - Models

struct TelemetryEvent: Codable, Identifiable {
    let id: UUID
    let type: String
    let value: Double?
    let tags: [String: String]
    let timestamp: Date
    let sessionId: String
    let householdId: String?
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, value, tags, timestamp
        case sessionId = "session_id"
        case householdId = "household_id"
        case userId = "user_id"
    }
}

struct TelemetryBatch: Codable {
    let batchId: UUID
    let events: [TelemetryEvent]
    let appVersion: String
    let osVersion: String
    let device: String
    let deviceId: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case batchId = "batch_id"
        case events, appVersion, osVersion, device, deviceId, timestamp
    }
}

// MARK: - EventCollector

class EventCollector {
    static let shared = EventCollector()
    
    private let queue = DispatchQueue(label: "com.ezmenu.event-collector", qos: .utility)
    private var buffer: [TelemetryEvent] = []
    private var flushTimer: Timer?
    private var sessionId: String = UUID().uuidString
    
    /// Configuration
    private let maxBufferSize = 100
    private let flushIntervalSeconds = 300  // 5 minutes
    
    private init() {
        setupCrashReporting()
    }
    
    // MARK: - Public API
    
    func start() {
        queue.async { [weak self] in
            self?.setupFlushTimer()
        }
    }
    
    func stop() {
        queue.async { [weak self] in
            self?.flushTimer?.invalidate()
            self?.flush()
        }
    }
    
    func logEvent(_ type: String, 
                  value: Double? = nil,
                  tags: [String: String] = [:]) {
        let event = TelemetryEvent(
            id: UUID(),
            type: type,
            value: value,
            tags: tags,
            timestamp: Date(),
            sessionId: sessionId,
            householdId: nil,  // Will be set by sync managers when context available
            userId: nil  // Will be set by sync managers when context available
        )
        
        queue.async { [weak self] in
            self?.buffer.append(event)
            
            // Auto-flush if buffer full
            if self?.buffer.count ?? 0 >= self?.maxBufferSize ?? 100 {
                self?.flush()
            }
        }
    }
    
    func flushBatch() {
        queue.async { [weak self] in
            self?.flush()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(flushIntervalSeconds), repeats: true) { [weak self] _ in
            self?.flush()
        }
    }
    
    private func flush() {
        guard !buffer.isEmpty else { return }
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        _ = TelemetryBatch(
            batchId: UUID(),
            events: buffer,
            appVersion: appVersion,
            osVersion: UIDevice.current.systemVersion,
            device: UIDevice.current.model,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            timestamp: Date()
        )
        
        buffer.removeAll()
    }
    
    private func setupCrashReporting() {
        #if !DEBUG
        NSSetUncaughtExceptionHandler { exception in
            os_log("💥 Crash reported: %{public}@", log: osLog, type: .error, exception.name.rawValue)
        }
        #endif
    }
}

// MARK: - Quick Logging Functions

func logPerformance(_ name: String, durationMs: Int, tags: [String: String] = [:]) {
    var allTags = tags
    allTags["operation"] = name
    
    if durationMs > 100 {
        allTags["severity"] = "slow"
    }
    
    EventCollector.shared.logEvent("performance", value: Double(durationMs), tags: allTags)
}

func logSyncLatency(_ latencyMs: Int, householdId: String) {
    var tags: [String: String] = ["household": householdId, "type": "latency"]
    
    if latencyMs > 3000 {
        tags["severity"] = "high"
    }
    
    EventCollector.shared.logEvent("sync_latency", value: Double(latencyMs), tags: tags)
}

func logNetworkError(_ errorType: String, statusCode: Int? = nil) {
    var tags: [String: String] = ["error_type": errorType]
    if let code = statusCode {
        tags["status_code"] = String(code)
    }
    
    EventCollector.shared.logEvent("network_error", tags: tags)
}

func logDataValidationFailure(_ entity: String, reason: String) {
    let tags: [String: String] = ["entity": entity, "reason": reason]
    EventCollector.shared.logEvent("validation_failure", tags: tags)
}

func logSyncConflict(entity: String, count: Int) {
    let tags: [String: String] = ["entity": entity, "conflict_count": String(count)]
    EventCollector.shared.logEvent("sync_conflict", value: Double(count), tags: tags)
}
