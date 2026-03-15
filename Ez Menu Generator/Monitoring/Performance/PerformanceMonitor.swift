// PerformanceMonitor.swift
// Measure critical operations with minimal overhead

import Foundation
import OSLog

let performanceLog = OSLog(subsystem: "com.ezmenu.monitoring", category: "performance")

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let queue = DispatchQueue(label: "com.ezmenu.performance", qos: .utility)
    private var measurements: [PerformanceMeasurement] = []
    
    // Thresholds for warnings
    private let slowThresholdMs = 100
    private let verySlowThresholdMs = 500
    private let criticalThresholdMs = 1000
    
    private init() {}
    
    // MARK: - Synchronous Measurement
    
    /// Measure a synchronous operation
    /// - Parameters:
    ///   - name: Operation name for logging
    ///   - block: The code to measure
    /// - Returns: The result of the block
    func measure<T>(name: String, _ block: () throws -> T) rethrows -> T {
        let startTime = Date()
        let startMemory = getMemoryUsageMB()
        
        let result = try block()
        
        let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
        let memoryDeltaMB = getMemoryUsageMB() - startMemory
        
        recordMeasurement(
            name: name,
            durationMs: durationMs,
            memoryDeltaMB: memoryDeltaMB,
            isAsync: false
        )
        
        return result
    }
    
    // MARK: - Asynchronous Measurement
    
    /// Measure an async operation
    /// - Parameters:
    ///   - name: Operation name for logging
    ///   - block: The async code to measure
    /// - Returns: The result of the block
    func measure<T>(name: String, _ block: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        
        let result = try await block()
        
        let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
        
        recordMeasurement(
            name: name,
            durationMs: durationMs,
            memoryDeltaMB: 0,  // Skip memory tracking for async
            isAsync: true
        )
        
        return result
    }
    
    // MARK: - Manual Timing
    
    func startTimer(name: String) -> TimerHandle {
        TimerHandle(name: name, startTime: Date())
    }
    
    func stopTimer(_ handle: TimerHandle) {
        let durationMs = Int(Date().timeIntervalSince(handle.startTime) * 1000)
        recordMeasurement(name: handle.name, durationMs: durationMs, memoryDeltaMB: 0)
    }
    
    // MARK: - Query Measurements
    
    func getRecentMeasurements(limit: Int = 50) -> [PerformanceMeasurement] {
        var result: [PerformanceMeasurement] = []
        queue.sync {
            result = Array(measurements.suffix(limit))
        }
        return result
    }
    
    func getMeasurementStats(for operation: String) -> PerformanceStats? {
        var stats: PerformanceStats?
        queue.sync {
            let filtered = measurements.filter { $0.name == operation }
            guard !filtered.isEmpty else { return }
            
            let durations = filtered.map { $0.durationMs }
            let sorted = durations.sorted()
            
            stats = PerformanceStats(
                operation: operation,
                count: filtered.count,
                minMs: sorted.first ?? 0,
                maxMs: sorted.last ?? 0,
                avgMs: Int(Double(durations.reduce(0, +)) / Double(durations.count)),
                medianMs: sorted[sorted.count / 2],
                p95Ms: sorted[Int(Double(sorted.count) * 0.95)],
                p99Ms: sorted[Int(Double(sorted.count) * 0.99)]
            )
        }
        return stats
    }
    
    // MARK: - Private Methods
    
    private func recordMeasurement(name: String, 
                                  durationMs: Int, 
                                  memoryDeltaMB: Double,
                                  isAsync: Bool = false) {
        let measurement = PerformanceMeasurement(
            id: UUID(),
            name: name,
            durationMs: durationMs,
            memoryDeltaMB: memoryDeltaMB,
            isAsync: isAsync,
            timestamp: Date()
        )
        
        queue.async { [weak self] in
            self?.measurements.append(measurement)
            
            // Keep only last 500 measurements
            if self?.measurements.count ?? 0 > 500 {
                self?.measurements.removeFirst()
            }
        }
        
        // Log warnings - only for critical issues
        if durationMs > criticalThresholdMs {
            os_log("🔴 CRITICAL: %{public}@ took %dms", log: performanceLog, type: .error, name, durationMs)
            EventCollector.shared.logEvent("performance_critical", value: Double(durationMs), 
                                         tags: ["operation": name])
        } else if durationMs > verySlowThresholdMs {
            EventCollector.shared.logEvent("performance_very_slow", value: Double(durationMs), 
                                         tags: ["operation": name])
        } else if durationMs > slowThresholdMs {
            // Track slow operations as telemetry only, no os_log
        }
    }
    
    private func getMemoryUsageMB() -> Double {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            task_info(
                mach_task_self_,
                task_flavor_t(TASK_BASIC_INFO),
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) { $0 },
                &count
            )
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1024 / 1024
    }
}

// MARK: - Models

struct PerformanceMeasurement: Codable, Identifiable {
    let id: UUID
    let name: String
    let durationMs: Int
    let memoryDeltaMB: Double
    let isAsync: Bool
    let timestamp: Date
}

struct PerformanceStats {
    let operation: String
    let count: Int
    let minMs: Int
    let maxMs: Int
    let avgMs: Int
    let medianMs: Int
    let p95Ms: Int
    let p99Ms: Int
}

class TimerHandle {
    let name: String
    let startTime: Date
    
    init(name: String, startTime: Date) {
        self.name = name
        self.startTime = startTime
    }
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    /// Wrap a ViewModifier or State update with timing
    func withTiming<T>(name: String, _ value: T) -> T {
        measure(name: name) { value }
    }
}
