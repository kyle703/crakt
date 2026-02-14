//
//  craktApp.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI
import SwiftData

@main
struct MainApp: App {
    
    let modelContainer: ModelContainer
    
    /// Helper function to guarantee exactly one `User` in the local store.
    private func ensureSingleUserExists(in context: ModelContext) throws {
        let fetchRequest = FetchDescriptor<User>()
        let existingUsers = try context.fetch(fetchRequest)

        // No users found -> create one
        if existingUsers.isEmpty {
            let newUser = User()
            context.insert(newUser)
            try context.save()
            print("Inserted new user: \(newUser.name)")
        }
        
        // If exactly one user exists, do nothing
    }
        
    init() {
        do {
            // Register all models including new circuit grade system models
            modelContainer = try ModelContainer(
                for: User.self,
                     Session.self,
                     Route.self,
                     RouteAttempt.self,
                     CustomCircuitGrade.self,
                     CircuitColorMapping.self,
                     GymGradeConfiguration.self
            )
            try ensureSingleUserExists(in: modelContainer.mainContext)
            
            // Ensure default circuit exists
            _ = GradeSystemFactory.defaultCircuit(modelContainer.mainContext)
            
            // Run circuit grade migration if needed
            let migrationResult = CircuitGradeMigration.migrateIfNeeded(modelContainer.mainContext)
            if migrationResult.isSuccess {
                print("📦 Migration completed: \(migrationResult.message)")
            }
        } catch {
            print("ModelContainer initialization failed: \(error)")
            print("This is likely due to a data model mismatch from a previous app version.")
            print("To fix this:")
            print("1. Delete the app from your device")
            print("2. Reinstall the app from Xcode")
            print("3. Or use the nuclear option below...")

            // Nuclear option: Force delete the app's data store
            // Uncomment the lines below if you want to clear all data programmatically
            /*
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let storeURL = appSupportURL.appendingPathComponent("default.store")

            do {
                // Remove the existing store file if it exists
                if fileManager.fileExists(atPath: storeURL.path) {
                    try fileManager.removeItem(at: storeURL)
                    print("✅ SwiftData store cleared successfully!")
                }

                // Also clear any backup stores
                let backupURLs = [
                    appSupportURL.appendingPathComponent("default.store-shm"),
                    appSupportURL.appendingPathComponent("default.store-wal")
                ]

                for backupURL in backupURLs {
                    if fileManager.fileExists(atPath: backupURL.path) {
                        try fileManager.removeItem(at: backupURL)
                    }
                }

                print("🔄 Restarting with fresh data...")
                // Force re-initialization with fresh container
                fatalError("Data store cleared. Please restart the app to continue with fresh data.")
            } catch {
                print("Could not clear SwiftData store: \(error)")
                fatalError("Could not clear data store. Please delete and reinstall the app. Error: \(error)")
            }
            */

            fatalError("Could not initialize ModelContainer. Please delete and reinstall the app, or clear app data. Error: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            LaunchScreenWrapper()
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - Launch Screen Wrapper

struct LaunchScreenWrapper: View {
    @State private var showLaunchScreen = true
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreen {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLaunchScreen = false
                    }
                }
                .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
    }
}

