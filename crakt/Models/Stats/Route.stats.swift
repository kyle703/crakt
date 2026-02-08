//
//  Route.stats.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI

extension Route {
    var normalizedGrade: Double {
        guard let grade = grade else {
            return 0.0 // Return default normalized value when grade is nil
        }
        
        // For circuit grades, use the circuit's protocol
        if gradeSystem == .circuit, let circuit = customCircuit {
            return CircuitGrade(customCircuit: circuit).normalizedDifficulty(for: grade)
        }
        
        return GradeSystemFactory.safeProtocol(for: gradeSystem).normalizedDifficulty(for: grade)
    }

    func getConvertedGrade(system: GradeSystem) -> String {
        // For circuit target system, this needs context - return empty if no context available
        if system == .circuit {
            // Without context, return a placeholder
            return ""
        }
        return GradeSystemFactory.safeProtocol(for: system).grade(forNormalizedDifficulty: self.normalizedGrade)
    }
}
