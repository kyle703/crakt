//
//  CircuitColorMapping.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a single color in a circuit grade system.
/// Each mapping connects a color to a grade range from a concrete grade system.
@Model
class CircuitColorMapping: Identifiable {
    /// Unique identifier - also serves as the stable grade ID for routes
    var id: UUID
    
    /// Hex color code (e.g., "#FF5733")
    var color: String
    
    /// Position in difficulty progression (0 = easiest)
    var sortOrder: Int
    
    /// The concrete grade system this color maps to
    var baseGradeSystem: GradeSystem
    
    /// Minimum grade in the range (from baseGradeSystem)
    var minGrade: String
    
    /// Maximum grade in the range (from baseGradeSystem)
    var maxGrade: String
    
    /// Parent circuit
    @Relationship(deleteRule: .nullify)
    var circuit: CustomCircuitGrade?
    
    init(id: UUID = UUID(),
         color: String,
         sortOrder: Int,
         baseGradeSystem: GradeSystem,
         minGrade: String,
         maxGrade: String) {
        self.id = id
        self.color = color
        self.sortOrder = sortOrder
        self.baseGradeSystem = baseGradeSystem
        self.minGrade = minGrade
        self.maxGrade = maxGrade
    }
    
    // MARK: - Computed Properties
    
    /// Display name auto-derived from color (e.g., "Green", "Blue")
    var displayName: String {
        Color(hex: color).colorName
    }
    
    /// Human-readable grade range (e.g., "V2 - V4")
    var gradeRangeDescription: String {
        let proto = GradeSystemFactory.safeProtocol(for: baseGradeSystem)
        let minDesc = proto.description(for: minGrade) ?? minGrade
        let maxDesc = proto.description(for: maxGrade) ?? maxGrade
        
        if minGrade == maxGrade {
            return minDesc
        }
        return "\(minDesc) - \(maxDesc)"
    }
    
    /// SwiftUI Color from hex
    var swiftUIColor: Color {
        Color(hex: color)
    }
}
