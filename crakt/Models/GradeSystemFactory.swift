//
//  GradeSystemFactory.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import Foundation
import SwiftData
import SwiftUI

/// Factory for creating grade protocol instances with proper context handling.
/// Replaces direct use of GradeSystem._protocol for circuit grades.
struct GradeSystemFactory {
    
    // MARK: - Grade Protocol Creation
    
    /// Get grade protocol for a system
    /// - Parameters:
    ///   - system: The grade system
    ///   - circuit: Optional circuit to use directly
    ///   - modelContext: Model context for fetching circuits
    ///   - customCircuitId: Optional circuit ID to fetch (takes precedence over default)
    static func gradeProtocol(for system: GradeSystem,
                              circuit: CustomCircuitGrade? = nil,
                              modelContext: ModelContext? = nil,
                              customCircuitId: UUID? = nil) -> any GradeProtocol {
        switch system {
        case .circuit:
            // Priority 1: Explicit circuit
            if let circuit = circuit {
                return CircuitGrade(customCircuit: circuit)
            }
            // Priority 2: Fetch by ID if provided
            if let context = modelContext, let circuitId = customCircuitId {
                if let circuit = self.circuit(forId: circuitId, modelContext: context) {
                    return CircuitGrade(customCircuit: circuit)
                }
            }
            // Priority 3: Default circuit
            if let context = modelContext {
                return CircuitGrade(customCircuit: defaultCircuit(context))
            }
            // Fallback: return a placeholder circuit
            return CircuitGrade(customCircuit: createInMemoryDefaultCircuit())
        case .vscale:
            return VGrade()
        case .font:
            return FontGrade()
        case .yds:
            return YDS()
        case .french:
            return FrenchGrade()
        }
    }
    
    // MARK: - Default Circuit Management
    
    /// Get or create the default circuit
    static func defaultCircuit(_ modelContext: ModelContext) -> CustomCircuitGrade {
        // Try to fetch existing default
        let descriptor = FetchDescriptor<CustomCircuitGrade>(
            predicate: #Predicate { $0.isDefault == true }
        )
        
        if let circuit = try? modelContext.fetch(descriptor).first {
            return circuit
        }
        
        // Create and save default circuit
        return createAndSaveDefaultCircuit(modelContext)
    }
    
    // MARK: - Circuit Creation
    
    /// Create and save the standard V-scale based default circuit
    private static func createAndSaveDefaultCircuit(_ modelContext: ModelContext) -> CustomCircuitGrade {
        let circuit = createVScaleDefaultCircuit()
        circuit.isDefault = true
        
        modelContext.insert(circuit)
        try? modelContext.save()
        
        return circuit
    }
    
    /// Create a V-scale based circuit (US default)
    static func createVScaleDefaultCircuit() -> CustomCircuitGrade {
        let circuit = CustomCircuitGrade(name: "Default Circuit")
        
        // Standard V-scale mapping:
        // Blue(VB-V0), Green(V1-V2), Yellow(V3-V4),
        // Orange(V5-V6), Red(V7-V8), Purple(V9-V10), Black(V11+)
        let defaultMappings: [(color: String, min: String, max: String)] = [
            ("#007AFF", "B", "0"),     // Blue
            ("#34C759", "1", "2"),     // Green
            ("#FFCC00", "3", "4"),     // Yellow
            ("#FF9500", "5", "6"),     // Orange
            ("#FF3B30", "7", "8"),     // Red
            ("#AF52DE", "9", "10"),    // Purple
            ("#000000", "11", "17")    // Black
        ]
        
        for (index, mapping) in defaultMappings.enumerated() {
            let colorMapping = CircuitColorMapping(
                color: mapping.color,
                sortOrder: index,
                baseGradeSystem: .vscale,
                minGrade: mapping.min,
                maxGrade: mapping.max
            )
            circuit.addMapping(colorMapping)
        }
        
        return circuit
    }
    
    /// Create a Font-based circuit (European default)
    static func createFontDefaultCircuit() -> CustomCircuitGrade {
        let circuit = CustomCircuitGrade(name: "European Circuit")
        
        let defaultMappings: [(color: String, min: String, max: String)] = [
            ("#007AFF", "1", "3"),       // Blue
            ("#34C759", "4", "5"),       // Green
            ("#FFCC00", "6a", "6b"),     // Yellow
            ("#FF9500", "6c", "6d"),     // Orange
            ("#FF3B30", "7a", "7b"),     // Red
            ("#AF52DE", "7c", "7d"),     // Purple
            ("#000000", "8a", "8d")      // Black
        ]
        
        for (index, mapping) in defaultMappings.enumerated() {
            let colorMapping = CircuitColorMapping(
                color: mapping.color,
                sortOrder: index,
                baseGradeSystem: .font,
                minGrade: mapping.min,
                maxGrade: mapping.max
            )
            circuit.addMapping(colorMapping)
        }
        
        return circuit
    }
    
    /// Create an in-memory default circuit (for when no context is available)
    private static func createInMemoryDefaultCircuit() -> CustomCircuitGrade {
        return createVScaleDefaultCircuit()
    }
    
    // MARK: - Circuit Lookup
    
    /// Find a circuit by ID
    static func circuit(forId id: UUID, modelContext: ModelContext) -> CustomCircuitGrade? {
        let descriptor = FetchDescriptor<CustomCircuitGrade>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Safe Protocol Access (no warning for non-circuit)
    
    /// Get grade protocol safely - only logs warning for circuit without context
    /// Use this when you're certain the system isn't circuit, or when you have no context
    static func safeProtocol(for system: GradeSystem) -> any GradeProtocol {
        switch system {
        case .circuit:
            // Return fallback without warning - caller should use gradeProtocol() with context for circuit
            return CircuitGrade(customCircuit: createVScaleDefaultCircuit())
        case .vscale:
            return VGrade()
        case .font:
            return FontGrade()
        case .yds:
            return YDS()
        case .french:
            return FrenchGrade()
        }
    }
    
}
