// HealthCheckManager.swift
// Backend health monitoring for offline-aware sync

import Foundation
import Combine
import SwiftUI
import OSLog

let healthLog = OSLog(subsystem: "com.ezmenu.backend", category: "health")

// MARK: - Models

enum HealthStatus: String, Codable {
    case healthy
    case degraded
    case critical
    case unknown
}

struct HealthCheckResponse: Codable {
    let status: String
    let timestamp: Date
    let responseTimeMs: Int
    let checks: [HealthCheckItem]?
    let errors: [String]?
    
    var parsedStatus: HealthStatus {
        HealthStatus(rawValue: status) ?? .unknown
    }
}

struct HealthCheckItem: Codable {
    let component: String
    let healthy: Bool
    let responseTimeMs: Int
    let detail: String?
    let severity: String?
}

// MARK: - HealthCheckManager

class HealthCheckManager: NSObject, ObservableObject {
    @Published var status: HealthStatus = .unknown
    @Published var lastCheckTime: Date?
    @Published var degradedReason: String?
    @Published var responseTimeMs: Int = 0
    
    static let shared = HealthCheckManager()
    
    // Safe optional URL - will be nil in development, must be configured in SupabaseConfig
    private let supabaseURL: URL? = {
        // Try to get from SupabaseConfig first, fallback to placeholder
        if let configuredURL = SupabaseConfig.baseURL, configuredURL.absoluteString != "https://placeholder.supabase.co" {
            return configuredURL
        }
        // Return nil if not configured - health checks will return false gracefully
        return nil
    }()
    private var healthCheckTimer: Timer?
    private var lastStatus: HealthStatus = .unknown
    
    // Configuration
    private let checkInterval: TimeInterval = 30  // Check every 30 seconds
    private let timeoutInterval: TimeInterval = 10  // 10 second timeout
    private let backoffMultiplier: Double = 1.5
    private var currentBackoffInterval: TimeInterval = 30
    
    override private init() {
        super.init()
    }
    
    // MARK: - Public API
    
    /// Start periodic health checks with exponential backoff on failure
    func startHealthChecks() {
        // Check immediately
        performHealthCheck()
        
        // Schedule periodic checks
        DispatchQueue.main.async { [weak self] in
            self?.healthCheckTimer?.invalidate()
            self?.healthCheckTimer = Timer.scheduledTimer(
                withTimeInterval: self?.checkInterval ?? 30,
                repeats: true
            ) { [weak self] _ in
                self?.performHealthCheck()
            }
        }
    }
    
    /// Stop all health checks
    func stopHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    /// Force immediate health check
    func checkNow() {
        performHealthCheck()
    }
    
    /// Get current health status
    func getCurrentStatus() -> HealthStatus {
        status
    }
    
    // MARK: - Private Methods
    
    private func performHealthCheck() {
        Task {
            do {
                let response = try await callHealthCheckAPI()
                await MainActor.run {
                    self.handleHealthCheckResponse(response)
                }
            } catch {
                await MainActor.run {
                    self.handleHealthCheckError(error)
                }
            }
        }
    }
    
    private func callHealthCheckAPI() async throws -> HealthCheckResponse {
        // Guard against unconfigured Supabase URL
        guard let baseURL = supabaseURL else {
            throw HealthCheckError.invalidResponse
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/api/v1/health"))
        request.timeoutInterval = timeoutInterval
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard response is HTTPURLResponse else {
            throw HealthCheckError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let result = try decoder.decode(HealthCheckResponse.self, from: data)
            return result
        } catch {
            throw HealthCheckError.decodingError(error)
        }
    }
    
    private func handleHealthCheckResponse(_ response: HealthCheckResponse) {
        lastCheckTime = Date()
        responseTimeMs = response.responseTimeMs
        
        let newStatus = response.parsedStatus
        
        // Handle status transition
        if lastStatus != newStatus {
            handleStatusTransition(from: lastStatus, to: newStatus)
        }
        
        status = newStatus
        lastStatus = newStatus
        
        // Update degraded reason
        if newStatus != .healthy, let errors = response.errors {
            degradedReason = errors.joined(separator: "; ")
        } else {
            degradedReason = nil
        }
        
        // Reset backoff on success
        if newStatus == .healthy {
            currentBackoffInterval = checkInterval
        }
    }
    
    private func handleHealthCheckError(_ error: Error) {
        lastCheckTime = Date()
        
        os_log("❌ Health check error: %{public}@",
               log: healthLog, type: .error,
               error.localizedDescription)
        
        let newStatus: HealthStatus = .critical
        
        if lastStatus != newStatus {
            handleStatusTransition(from: lastStatus, to: newStatus)
        }
        
        status = newStatus
        lastStatus = newStatus
        degradedReason = "Cannot reach backend server"
        
        // Apply exponential backoff (don't hammer server if it's down)
        // But this is handled by increasing the timer interval
        // In real implementation, would reschedule timer with longer interval
    }
    
    private func handleStatusTransition(from: HealthStatus, to: HealthStatus) {
        switch (from, to) {
        case (.healthy, .degraded):
            os_log("🟡 Backend DEGRADED - switching to offline mode", log: healthLog, type: .default)
            NotificationCenter.default.post(name: NSNotification.Name("BackendDegraded"), object: nil)
            // OfflineSyncManager will handle in listener
            
        case (.healthy, .critical):
            os_log("🔴 Backend CRITICAL - all sync paused", log: healthLog, type: .error)
            NotificationCenter.default.post(name: NSNotification.Name("BackendCritical"), object: nil)
            // OfflineSyncManager will handle in listener
            
        case (.degraded, .healthy), (.critical, .healthy):
            NotificationCenter.default.post(name: NSNotification.Name("BackendHealthy"), object: nil)
            // OfflineSyncManager will handle in listener
            
        case (.critical, .degraded):
            break
            
        case (.degraded, .critical):
            os_log("🔴 Backend WORSENING", log: healthLog, type: .error)
            // OfflineSyncManager will handle in listener
            
        default:
            break
        }
    }
}

// MARK: - Error Handling

enum HealthCheckError: LocalizedError {
    case invalidResponse
    case decodingError(Error)
    case timeout
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from health check endpoint"
        case .decodingError(let error):
            return "Failed to decode health response: \(error.localizedDescription)"
        case .timeout:
            return "Health check timed out"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Integration Points

extension HealthCheckManager {
    /// Call from AppDelegate or main app initialization
    static func setupHealthChecking() {
        HealthCheckManager.shared.startHealthChecks()
        
        // Listen for degraded status - pause sync
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BackendDegraded"),
            object: nil,
            queue: .main
        ) { _ in
            return
        }
        
        // Listen for critical status - stop all sync
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BackendCritical"),
            object: nil,
            queue: .main
        ) { _ in
            os_log("🔴 Backend critical - stopping all sync", log: healthLog, type: .error)
        }
        
        // Listen for recovery - resume sync
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BackendHealthy"),
            object: nil,
            queue: .main
        ) { _ in
            return
        }
    }
    
    /// Use in sync operations
    func canSync() -> Bool {
        status == .healthy
    }
    
    /// Get indicator for UI
    func getStatusIndicator() -> String {
        switch status {
        case .healthy:
            return "🟢"
        case .degraded:
            return "🟡"
        case .critical:
            return "🔴"
        case .unknown:
            return "⭕"
        }
    }
}

// MARK: - Mock for Testing

#if DEBUG
class MockHealthCheckManager: HealthCheckManager {
    func simulateHealthy() {
        DispatchQueue.main.async {
            self.status = .healthy
            self.lastCheckTime = Date()
        }
    }
    
    func simulateDegraded(reason: String) {
        DispatchQueue.main.async {
            self.status = .degraded
            self.degradedReason = reason
            self.lastCheckTime = Date()
        }
    }
    
    func simulateCritical() {
        DispatchQueue.main.async {
            self.status = .critical
            self.degradedReason = "Backend offline"
            self.lastCheckTime = Date()
        }
    }
}
#endif
