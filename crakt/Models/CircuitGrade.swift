//
//  CircuitGrade.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import Foundation
import SwiftUI

/// Runtime GradeProtocol implementation for circuit grades.
/// Wraps a CustomCircuitGrade to provide GradeProtocol conformance.
struct CircuitGrade: GradeProtocol {
    let system: GradeSystem = .circuit
    let customCircuit: CustomCircuitGrade
    
    init(customCircuit: CustomCircuitGrade) {
        self.customCircuit = customCircuit
    }
    
    // MARK: - GradeProtocol Conformance
    
    /// Returns stable UUID strings as grade identifiers
    var grades: [String] {
        customCircuit.orderedMappings.map { $0.id.uuidString }
    }
    
    /// Maps UUID string to current display color
    var colorMap: [String: Color] {
        customCircuit.orderedMappings.reduce(into: [:]) { result, mapping in
            result[mapping.id.uuidString] = mapping.swiftUIColor
        }
    }
    
    /// Get color(s) for a grade (UUID string)
    func colors(for grade: String) -> [Color] {
        if let mapping = customCircuit.mapping(forGrade: grade) {
            return [mapping.swiftUIColor]
        }
        return [.gray]
    }
    
    /// Get description for a grade - returns "Color Name (Grade Range)"
    func description(for grade: String) -> String? {
        guard let mapping = customCircuit.mapping(forGrade: grade) else {
            return nil
        }
        return "\(mapping.displayName) (\(mapping.gradeRangeDescription))"
    }
    
    // MARK: - Circuit-Specific Methods
    
    /// Get mapping for a grade (UUID string)
    func mapping(for grade: String) -> CircuitColorMapping? {
        customCircuit.mapping(forGrade: grade)
    }
    
    /// Get just the color name for a grade
    func colorName(for grade: String) -> String? {
        customCircuit.mapping(forGrade: grade)?.displayName
    }
    
    /// Get just the grade range for a grade
    func gradeRange(for grade: String) -> String? {
        customCircuit.mapping(forGrade: grade)?.gradeRangeDescription
    }
    
    /// Get the DI value for a grade
    func difficultyIndex(for grade: String) -> Int? {
        customCircuit.mapping(forGrade: grade)?.midpointDI
    }
    
    // MARK: - Equatable
    
    static func == (lhs: CircuitGrade, rhs: CircuitGrade) -> Bool {
        lhs.customCircuit.id == rhs.customCircuit.id
    }
}

// MARK: - DifficultyIndex Circuit Extension

extension DifficultyIndex {
    /// Normalize circuit color mapping directly to DI using midpoint
    static func normalizeToDI(circuitMapping mapping: CircuitColorMapping) -> Int? {
        return mapping.midpointDI
    }
    
    /// Normalize circuit grade (UUID string) to DI
    static func normalizeToDI(circuitGrade: String, circuit: CustomCircuitGrade) -> Int? {
        guard let mapping = circuit.mapping(forGrade: circuitGrade) else {
            return nil
        }
        return normalizeToDI(circuitMapping: mapping)
    }
    
    /// Get human-readable grade range description for a circuit grade
    static func gradeRangeDescription(circuitGrade: String, circuit: CustomCircuitGrade) -> String? {
        circuit.mapping(forGrade: circuitGrade)?.gradeRangeDescription
    }
    
    /// Convert from circuit grade to another system via DI
    static func convertFromCircuit(circuitGrade: String,
                                   circuit: CustomCircuitGrade,
                                   toSystem: GradeSystem,
                                   toType: ClimbType) -> String? {
        guard let di = normalizeToDI(circuitGrade: circuitGrade, circuit: circuit) else {
            return nil
        }
        return gradeForDI(di, system: toSystem, climbType: toType)
    }
}

