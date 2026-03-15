//
// EzMenuGeneratorApp.swift
// Ez Menu Generator
//
// MARK: - Purpose
// Application entry point and initialization:
// - SwiftData ModelContainer setup with local storage
// - Sample data seeding on first launch
// - StorageService initialization
// - ContentView wrapper with model container injection
//
// MARK: - Architecture
// @main attribute marks this as app entry point
// Uses @ObservableObject pattern for data flow
// Models: Recipe, Ingredient, Menu, DayMeals, ShoppingItem
//
// MARK: - Data Flow
// 1. ModelContainer initialized with SwiftData
// 2. SampleDataService seeds initial recipes (if needed)
// 3. StorageService.shared set up with container
// 4. ContentView rendered with .modelContainer modifier
//
// MARK: - Debugging
// Check logs for initialization steps:
// "✅ ModelContainer initialized"
// "✅ SwiftData initialized successfully"
//

import SwiftUI
import SwiftData
import Combine
import os.log

// Logging via system os_log

@main
struct EzMenuGeneratorApp: App {
    let modelContainer: ModelContainer
    @StateObject private var barcodeScanner = BarcodeScanner()
    @StateObject private var householdManager = HouseholdManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(barcodeScanner)
                .environmentObject(householdManager)
        }
    }
    
    init() {
        // Suppress CoreData/SQLite warnings
        UserDefaults.standard.set(false, forKey: "com.apple.CoreData.SQLDebug")
        
        // MARK: - Theme & UI Debug Setup
        // Force dark mode globally to prevent theme-switching issues
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .forEach { windowScene in
                    windowScene.windows.forEach { window in
                        window.overrideUserInterfaceStyle = .dark
                    }
                }
        }
        
        // Setup debug breakpoint for UIColor out-of-range detection
        DebugBreakpoints.setupUIColorDebugger()
        
        self.modelContainer = Self.createModelContainer()
        initializeData(container: self.modelContainer)
    }
    
    private static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            Ingredient.self,
            Recipe.self,
            Menu.self,
            DayMeals.self,
            ShoppingItem.self,
            // Household system models
            Household.self,
            HouseholdUser.self,
            ShoppingListV2.self,
            ShoppingItemV2.self,
            ActivityLog.self,
            // Offline-first models
            ShoppingListHistory.self,
            SyncQueueItem.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        // Check if we already recovered in this session
        let recoveryKey = "dbRecoveryAttempted"
        let hasRecoveredThisSession = UserDefaults.standard.bool(forKey: recoveryKey)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            // logger.info("✅ ModelContainer initialized")
            // Clear recovery flag on success
            UserDefaults.standard.set(false, forKey: recoveryKey)
            return container
        } catch {
            // Only attempt recovery once per app launch
            guard !hasRecoveredThisSession else {
                // CRITICAL: Show alert to user instead of crashing
                print("❌ CRITICAL: ModelContainer failed after recovery. Error: \(error)")
                // Last resort: create in-memory container to prevent crash
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                return (try? ModelContainer(for: schema, configurations: [memoryConfig])) ?? {
                    fatalError("Could not initialize ModelContainer even in-memory after recovery attempt: \(error)")
                }()
            }
            
            // Check if this is a migration error (specific to corrupted database)
            let errorDescription = error.localizedDescription
            guard errorDescription.contains("134110") || errorDescription.contains("migration") else {
                // Not a migration error - log and attempt in-memory fallback
                print("❌ CRITICAL: ModelContainer initialization failed with unknown error: \(error)")
                print("⚠️ Attempting in-memory fallback...")
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                return (try? ModelContainer(for: schema, configurations: [memoryConfig])) ?? {
                    fatalError("Could not initialize ModelContainer: \(error)")
                }()
            }
            
            // logger.error("⚠️ Migration error detected")
            
            do {
                // Mark recovery attempted
                UserDefaults.standard.set(true, forKey: recoveryKey)
                
                // Delete corrupted database files
                let dbPath = Self.getApplicationSupportDirectory().appendingPathComponent("default.store")
                if FileManager.default.fileExists(atPath: dbPath.path) {
                    try FileManager.default.removeItem(at: dbPath)
                    // logger.info("✅ Corrupted database deleted")
                }
                
                // Delete associated SQLite files
                for ext in ["-shm", "-wal", "-journal"] {
                    let altPath = URL(fileURLWithPath: dbPath.path + ext)
                    if FileManager.default.fileExists(atPath: altPath.path) {
                        try? FileManager.default.removeItem(at: altPath)
                    }
                }
                
                // Retry ModelContainer creation
                let container = try ModelContainer(for: schema, configurations: [config])
                // logger.info("✅ ModelContainer recovered")
                UserDefaults.standard.set(false, forKey: recoveryKey)
                return container
            } catch {
                print("❌ CRITICAL: Recovery failed. Creating in-memory container to prevent crash.")
                print("⚠️ User data will not persist until app is reinstalled. Error: \(error)")
                // Last resort: in-memory database to prevent crash
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                return (try? ModelContainer(for: schema, configurations: [memoryConfig])) ?? {
                    fatalError("Could not recover from database corruption or create in-memory fallback: \(error)")
                }()
            }
        }
    }
    
    private static func getApplicationSupportDirectory() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func initializeData(container: ModelContainer) {
        do {
            let seedContext = ModelContext(container)
            SampleDataService.seedDataIfNeeded(context: seedContext)
            try seedContext.save()
            
            StorageService.shared.setupContainer(container)
            StorageService.shared.fetchAllRecipes()
            
            HouseholdManager.shared.setupContainer(container)

            Task {
                _ = await SupabaseService.shared.checkHealth()
            }
        } catch {
            // Initialization error - app may have limited functionality
        }
    }
}
