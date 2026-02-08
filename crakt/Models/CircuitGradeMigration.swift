//
//  CircuitGradeMigration.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import Foundation
import SwiftData
import SwiftUI

/// Migration helper for circuit grade data from V1 (color names) to V2 (UUID-based)
struct CircuitGradeMigration {
    
    // MARK: - Migration State
    
    /// Key for storing migration completion status in UserDefaults
    private static let migrationCompletedKey = "CircuitGradeMigration_V1toV2_Completed"
    
    /// Check if migration has already been completed
    static var isMigrationCompleted: Bool {
        UserDefaults.standard.bool(forKey: migrationCompletedKey)
    }
    
    /// Mark migration as completed
    private static func markMigrationCompleted() {
        UserDefaults.standard.set(true, forKey: migrationCompletedKey)
    }
    
    // MARK: - Color Name Mapping
    
    /// Maps old color name strings to hex codes for migration
    private static let colorNameToHex: [String: String] = [
        // Standard SwiftUI color descriptions
        "blue": "#007AFF",
        "green": "#34C759",
        "yellow": "#FFCC00",
        "orange": "#FF9500",
        "red": "#FF3B30",
        "purple": "#AF52DE",
        "black": "#1C1C1E",
        "pink": "#FF2D55",
        "gray": "#8E8E93",
        "white": "#F2F2F7",
        "cyan": "#00C7BE",
        "mint": "#00C7BE",
        "teal": "#30B0C7",
        "indigo": "#5856D6",
        "brown": "#A2845E",
        
        // Additional variations that might appear in data
        "Blue": "#007AFF",
        "Green": "#34C759",
        "Yellow": "#FFCC00",
        "Orange": "#FF9500",
        "Red": "#FF3B30",
        "Purple": "#AF52DE",
        "Black": "#1C1C1E",
        "Pink": "#FF2D55",
        
        // SwiftUI Color.description format variations
        "SystemBlueColor": "#007AFF",
        "SystemGreenColor": "#34C759",
        "SystemYellowColor": "#FFCC00",
        "SystemOrangeColor": "#FF9500",
        "SystemRedColor": "#FF3B30",
        "SystemPurpleColor": "#AF52DE",
        
        // Clear/unknown fallback
        "clear": "#808080",
    ]
    
    /// Default V-scale grade ranges for each color in the old system
    private static let defaultColorGradeRanges: [(color: String, min: String, max: String)] = [
        ("#007AFF", "B", "0"),     // Blue
        ("#34C759", "1", "2"),     // Green
        ("#FFCC00", "3", "4"),     // Yellow
        ("#FF9500", "5", "6"),     // Orange
        ("#FF3B30", "7", "8"),     // Red
        ("#AF52DE", "9", "10"),    // Purple
        ("#1C1C1E", "11", "17"),   // Black
    ]
    
    // MARK: - Migration Entry Point
    
    /// Performs the V1 to V2 migration if needed
    /// - Parameter context: The model context to use for migration
    /// - Returns: Migration result with details
    @discardableResult
    static func migrateIfNeeded(_ context: ModelContext) -> MigrationResult {
        // Check if already migrated
        guard !isMigrationCompleted else {
            print("📦 Circuit grade migration: Already completed, skipping")
            return MigrationResult(status: .skipped, message: "Migration already completed")
        }
        
        print("📦 Circuit grade migration: Starting V1 to V2 migration...")
        
        do {
            let result = try performMigration(context)
            markMigrationCompleted()
            print("✅ Circuit grade migration: Complete - \(result.message)")
            return result
        } catch {
            print("❌ Circuit grade migration: Failed - \(error)")
            return MigrationResult(status: .failed, message: "Migration failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Migration Implementation
    
    private static func performMigration(_ context: ModelContext) throws -> MigrationResult {
        var migratedRoutesCount = 0
        var createdDefaultCircuit = false
        
        // Step 1: Ensure default circuit exists
        let defaultCircuit = ensureDefaultCircuitExists(context)
        if defaultCircuit.colorMappings.isEmpty {
            createdDefaultCircuit = true
        }
        
        // Step 2: Build color name to UUID mapping from the default circuit
        let colorNameToUUID = buildColorNameToUUIDMapping(from: defaultCircuit)
        
        // Step 3: Fetch all routes and filter for circuit grade system
        // Note: SwiftData predicates can't use enum cases directly, so we filter manually
        let allRoutesDescriptor = FetchDescriptor<Route>()
        let allRoutes = try context.fetch(allRoutesDescriptor)
        let circuitRoutes = allRoutes.filter { $0.gradeSystem == .circuit }
        print("📦 Found \(circuitRoutes.count) routes with circuit grade system")
        
        // Step 4: Migrate each route
        for route in circuitRoutes {
            if migrateRoute(route, colorMapping: colorNameToUUID, circuit: defaultCircuit) {
                migratedRoutesCount += 1
            }
        }
        
        // Step 5: Save changes
        try context.save()
        
        let message = "Migrated \(migratedRoutesCount) routes" + 
                     (createdDefaultCircuit ? ", created default circuit" : "")
        
        return MigrationResult(
            status: .success,
            message: message,
            migratedRoutesCount: migratedRoutesCount,
            createdDefaultCircuit: createdDefaultCircuit
        )
    }
    
    /// Ensures a default circuit exists, creating one if necessary
    private static func ensureDefaultCircuitExists(_ context: ModelContext) -> CustomCircuitGrade {
        // Try to find existing default
        let descriptor = FetchDescriptor<CustomCircuitGrade>(
            predicate: #Predicate { $0.isDefault == true }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        
        // Create new default circuit
        return GradeSystemFactory.defaultCircuit(context)
    }
    
    /// Builds a mapping from old color names to new UUID strings
    private static func buildColorNameToUUIDMapping(from circuit: CustomCircuitGrade) -> [String: String] {
        var mapping: [String: String] = [:]
        
        for colorMapping in circuit.orderedMappings {
            // Get the color name from the hex
            let colorName = Color(hex: colorMapping.color).colorName.lowercased()
            mapping[colorName] = colorMapping.id.uuidString
            
            // Also map the hex value directly (in case it was stored that way)
            mapping[colorMapping.color.lowercased()] = colorMapping.id.uuidString
        }
        
        // Add standard color name variations
        for (name, hex) in colorNameToHex {
            if let matchingMapping = circuit.colorMappings.first(where: { 
                $0.color.uppercased() == hex.uppercased() 
            }) {
                mapping[name.lowercased()] = matchingMapping.id.uuidString
            }
        }
        
        return mapping
    }
    
    /// Migrates a single route from old color name to new UUID format
    private static func migrateRoute(_ route: Route, 
                                    colorMapping: [String: String], 
                                    circuit: CustomCircuitGrade) -> Bool {
        guard let oldGrade = route.grade else { return false }
        
        // Skip if already a valid UUID
        if UUID(uuidString: oldGrade) != nil {
            // Already migrated, just ensure circuit reference is set
            if route.customCircuit == nil {
                route.customCircuit = circuit
                route.customCircuitId = circuit.id
            }
            return false
        }
        
        // Try to find matching UUID for the old grade
        let normalizedOldGrade = oldGrade.lowercased()
            .replacingOccurrences(of: "color(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        if let newGradeUUID = colorMapping[normalizedOldGrade] {
            route.grade = newGradeUUID
            route.customCircuit = circuit
            route.customCircuitId = circuit.id
            print("  📝 Migrated route \(route.id): '\(oldGrade)' → '\(newGradeUUID)'")
            return true
        }
        
        // Try to match by position in ordered colors
        let oldColors = ["blue", "green", "yellow", "orange", "red", "purple", "black"]
        if let index = oldColors.firstIndex(of: normalizedOldGrade),
           index < circuit.orderedMappings.count {
            let newMapping = circuit.orderedMappings[index]
            route.grade = newMapping.id.uuidString
            route.customCircuit = circuit
            route.customCircuitId = circuit.id
            print("  📝 Migrated route \(route.id) by position: '\(oldGrade)' → '\(newMapping.id.uuidString)'")
            return true
        }
        
        // Fallback: assign to first mapping if we can't determine the correct one
        if let firstMapping = circuit.orderedMappings.first {
            route.grade = firstMapping.id.uuidString
            route.customCircuit = circuit
            route.customCircuitId = circuit.id
            print("  ⚠️ Migrated route \(route.id) with fallback: '\(oldGrade)' → '\(firstMapping.id.uuidString)'")
            return true
        }
        
        print("  ❌ Could not migrate route \(route.id): '\(oldGrade)'")
        return false
    }
    
    // MARK: - Force Reset (Developer Use Only)
    
    /// Resets migration state - USE WITH CAUTION
    static func resetMigrationState() {
        UserDefaults.standard.removeObject(forKey: migrationCompletedKey)
        print("🔄 Circuit grade migration state reset")
    }
}

// MARK: - Migration Result

struct MigrationResult {
    enum Status {
        case success
        case skipped
        case failed
    }
    
    let status: Status
    let message: String
    var migratedRoutesCount: Int = 0
    var createdDefaultCircuit: Bool = false
    
    var isSuccess: Bool { status == .success }
    var wasSkipped: Bool { status == .skipped }
    var didFail: Bool { status == .failed }
}

