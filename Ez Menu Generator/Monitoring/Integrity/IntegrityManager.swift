// IntegrityManager.swift
// Define and enforce data integrity rules

import Foundation
import SwiftData
import OSLog

let integrityLog = OSLog(subsystem: "com.ezmenu.monitoring", category: "integrity")

// MARK: - Models

struct IntegrityViolation: Codable, Identifiable {
    let id: UUID
    let rule: String
    let severity: ValidationType
    let entity: String
    let entityId: String
    let detail: String
    let timestamp: Date
    
    init(rule: String, severity: ValidationType, entity: String, 
         entityId: String, detail: String) {
        self.id = UUID()
        self.rule = rule
        self.severity = severity
        self.entity = entity
        self.entityId = entityId
        self.detail = detail
        self.timestamp = Date()
    }
}

enum ValidationType: String, Codable {
    case warning   // Log, continue
    case error     // Log, reject operation
    case fatal     // Force data rebuild
}

// MARK: - IntegrityManager

class IntegrityManager {
    static let shared = IntegrityManager()
    
    private let queue = DispatchQueue(label: "com.ezmenu.integrity", qos: .utility)
    private var lastRunTimes: [String: Date] = [:]
    private var violations: [IntegrityViolation] = []
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func initialize(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public API
    
    func runScheduledChecks() {
        queue.async { [weak self] in
            self?.executeChecks()
        }
    }
    
    func forceCheck(_ ruleName: String) {
        queue.async { [weak self] in
            self?.lastRunTimes[ruleName] = Date.distantPast
            self?.executeChecks()
        }
    }
    
    func getViolations() -> [IntegrityViolation] {
        var result: [IntegrityViolation] = []
        queue.sync {
            result = violations
        }
        return result
    }
    
    // MARK: - Rule Execution
    
    private func executeChecks() {
        guard let context = modelContext else {
            os_log("❌ No model context available", log: integrityLog, type: .error)
            return
        }
        
        // Run all rules with their configured intervals
        checkMenuCompleteness(context)
        checkRecipeValidity(context)
        checkSyncStateConsistency(context)
        checkHouseholdUserConsistency(context)
    }
    
    // MARK: - Rule 1: Menu must have exactly 7 days
    
    private func checkMenuCompleteness(_ context: ModelContext) {
        let ruleName = "menu_days_complete"
        
        guard shouldRunRule(ruleName, intervalSeconds: 300) else { return }
        
        do {
            var newViolations: [IntegrityViolation] = []
            
            let menus = try context.fetch(FetchDescriptor<Menu>())
            
            for menu in menus {
                if menu.meals.count != 7 {
                    let violation = IntegrityViolation(
                        rule: ruleName,
                        severity: .error,
                        entity: "Menu",
                        entityId: menu.id.uuidString,
                        detail: "Menu '\(menu.name)' has \(menu.meals.count) days, expected 7"
                    )
                    newViolations.append(violation)
                    
                    // Auto-repair
                    autoRepairMenuDays(menu)
                }
            }
            
            recordViolations(newViolations, rule: ruleName)
            lastRunTimes[ruleName] = Date()
            
        } catch {
            os_log("❌ Error checking menu completeness: %{public}@", log: integrityLog, type: .error, error.localizedDescription)
        }
    }
    
    private func autoRepairMenuDays(_ menu: Menu) {
        while menu.meals.count < 7 {
            menu.meals.append(DayMeals())
        }
        while menu.meals.count > 7 {
            menu.meals.removeLast()
        }
        
        try? modelContext?.save()
    }
    
    // MARK: - Rule 2: Recipe consistency - no orphaned ingredients
    
    private func checkRecipeValidity(_ context: ModelContext) {
        let ruleName = "recipe_ingredient_consistency"
        
        guard shouldRunRule(ruleName, intervalSeconds: 600) else { return }
        
        do {
            var newViolations: [IntegrityViolation] = []
            
            let recipes = try context.fetch(FetchDescriptor<Recipe>())
            
            for recipe in recipes {
                // Check required fields
                if recipe.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    newViolations.append(IntegrityViolation(
                        rule: ruleName,
                        severity: .warning,
                        entity: "Recipe",
                        entityId: recipe.id.uuidString,
                        detail: "Recipe has empty name, ID: \(recipe.id)"
                    ))
                }
                
                if recipe.prepTimeMinutes < 0 || recipe.prepTimeMinutes > 480 {
                    newViolations.append(IntegrityViolation(
                        rule: ruleName,
                        severity: .warning,
                        entity: "Recipe",
                        entityId: recipe.id.uuidString,
                        detail: "Recipe '\(recipe.name)' has invalid prep time: \(recipe.prepTimeMinutes)"
                    ))
                }
                
                if recipe.servings < 1 || recipe.servings > 20 {
                    newViolations.append(IntegrityViolation(
                        rule: ruleName,
                        severity: .warning,
                        entity: "Recipe",
                        entityId: recipe.id.uuidString,
                        detail: "Recipe '\(recipe.name)' has invalid servings: \(recipe.servings)"
                    ))
                }
                
                // Check ingredients
                if recipe.ingredients.isEmpty {
                    newViolations.append(IntegrityViolation(
                        rule: ruleName,
                        severity: .error,
                        entity: "Recipe",
                        entityId: recipe.id.uuidString,
                        detail: "Recipe '\(recipe.name)' has no ingredients"
                    ))
                }
            }
            
            recordViolations(newViolations, rule: ruleName)
            lastRunTimes[ruleName] = Date()
            
        } catch {
            os_log("❌ Error checking recipe validity: %{public}@", log: integrityLog, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Rule 3: Sync state consistency
    
    private func checkSyncStateConsistency(_ context: ModelContext) {
        let ruleName = "sync_state_consistency"
        
        guard shouldRunRule(ruleName, intervalSeconds: 300) else { return }
        
        let newViolations: [IntegrityViolation] = []
        
        // TODO: Check if pending sync operations count matches UI state
        // Note: SyncOperation type reference removed - needs to be implemented
        // let pendingOps = try context.fetch(...)
        // let estimatedCount = RealtimeSyncManager.shared.pendingOperationCount
        
        // TODO: Implement mismatch detection when types are available
        // if pendingOps.count != estimatedCount {
        //     newViolations.append(...)
        //     RealtimeSyncManager.shared.updatePendingCount(pendingOps.count)
        // }
        
        recordViolations(newViolations, rule: ruleName)
        lastRunTimes[ruleName] = Date()
    }
    
    // MARK: - Rule 4: Household user consistency
    
    private func checkHouseholdUserConsistency(_ context: ModelContext) {
        let ruleName = "household_user_consistency"
        
        guard shouldRunRule(ruleName, intervalSeconds: 3600) else { return }  // Hourly
        
        // This rule checks against Supabase state asynchronously
        Task {
            do {
                // TODO: Implement household user consistency check
                // Note: SessionManager reference removed - needs implementation
                // guard let household = SessionManager.current?.household else { return }
                
                // TODO: Uncomment when household and types are available
                // let serverUsers = try await SupabaseService.fetchHouseholdUsers(householdId: household.id.uuidString)
                // let localUsers = household.users
                // 
                // if serverUsers.count != localUsers.count {
                //     let violation = IntegrityViolation(...)
                //     self.recordViolations([violation], rule: ruleName)
                //     try await SupabaseService.syncHouseholdState()
                // }
                
                self.queue.async {
                    self.lastRunTimes[ruleName] = Date()
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func shouldRunRule(_ ruleName: String, intervalSeconds: Int) -> Bool {
        if let lastRun = lastRunTimes[ruleName] {
            return Date().timeIntervalSince(lastRun) >= TimeInterval(intervalSeconds)
        }
        return true  // First time always runs
    }
    
    private func recordViolations(_ violations: [IntegrityViolation], rule: String) {
        queue.async { [weak self] in
            self?.violations.append(contentsOf: violations)
            
            // Keep only recent violations (last 100)
            if self?.violations.count ?? 0 > 100 {
                self?.violations.removeFirst()
            }
        }
        
        // Log each violation
        for violation in violations {
            let severity = violation.severity == .error ? "ERROR" : "WARNING"
            os_log("[%{public}@] %{public}@: %{public}@", log: integrityLog, type: .error, 
                   severity, violation.rule, violation.detail)
            
            // Send to telemetry
            if violation.severity == .error || violation.severity == .fatal {
                EventCollector.shared.logEvent(
                    "integrity_violation",
                    tags: [
                        "rule": violation.rule,
                        "severity": violation.severity.rawValue,
                        "entity": violation.entity
                    ]
                )
            }
        }
    }
}

// MARK: - Convenience

extension IntegrityManager {
    /// Start periodic checking (call this after app initialization)
    func startPeriodicChecks() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.runScheduledChecks()
        }
    }
}
