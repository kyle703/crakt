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
    
    // MARK: - Equatable
    
    static func == (lhs: CircuitGrade, rhs: CircuitGrade) -> Bool {
        lhs.customCircuit.id == rhs.customCircuit.id
    }
}
