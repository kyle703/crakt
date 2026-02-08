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
    
    /// DI value at midpoint of grade range
    var midpointDI: Int? {
        guard let minDI = DifficultyIndex.normalizeToDI(grade: minGrade, 
                                                        system: baseGradeSystem, 
                                                        climbType: baseGradeSystem.climbType),
              let maxDI = DifficultyIndex.normalizeToDI(grade: maxGrade, 
                                                        system: baseGradeSystem, 
                                                        climbType: baseGradeSystem.climbType) else {
            return nil
        }
        return (minDI + maxDI) / 2
    }
    
    /// SwiftUI Color from hex
    var swiftUIColor: Color {
        Color(hex: color)
    }
    
    // MARK: - Validation
    
    func validate() throws {
        // Validate color is not empty
        guard !color.isEmpty else {
            throw CircuitValidationError.emptyColor
        }
        
        // Validate hex format
        guard isValidHexColor(color) else {
            throw CircuitValidationError.invalidHexColor(color)
        }
        
        // Validate grade range (min <= max)
        let proto = GradeSystemFactory.safeProtocol(for: baseGradeSystem)
        let minIndex = proto.gradeIndex(for: minGrade)
        let maxIndex = proto.gradeIndex(for: maxGrade)
        
        guard minIndex <= maxIndex else {
            throw CircuitValidationError.invalidGradeRange(min: minGrade, max: maxGrade)
        }
    }
    
    private func isValidHexColor(_ hex: String) -> Bool {
        let pattern = "^#[0-9A-Fa-f]{6}$"
        return hex.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Validation Errors

enum CircuitValidationError: LocalizedError {
    case emptyName
    case emptyColor
    case invalidHexColor(String)
    case invalidGradeRange(min: String, max: String)
    case duplicateColor(String)
    case noMappings
    case invalidSortOrder
    case invalidGymConfiguration
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Circuit name cannot be empty"
        case .emptyColor:
            return "Color cannot be empty"
        case .invalidHexColor(let color):
            return "Invalid hex color format: \(color)"
        case .invalidGradeRange(let min, let max):
            return "Grade range invalid: \(min) must be ≤ \(max)"
        case .duplicateColor(let color):
            return "Duplicate color: \(color)"
        case .noMappings:
            return "Circuit must have at least one color"
        case .invalidSortOrder:
            return "Sort order must be sequential starting from 0"
        case .invalidGymConfiguration:
            return "Gym grade configuration is invalid"
        }
    }
}

