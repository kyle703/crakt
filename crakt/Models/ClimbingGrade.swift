//
//  ClimbingGrade.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

// MARK: - Difficulty Index (DI) System

/// Difficulty Index (DI) - A unified scale for cross-grade-system conversions
/// French grades serve as the canonical axis with DI = index × 10
struct DifficultyIndex {
    /// Canonical French grade sequence (ordered list for DI calculation)
    static let canonicalFrenchGrades: [String] = [
        "4a", "4b", "4c",
        "5a", "5b", "5c",
        "6a", "6a+", "6b", "6b+", "6c", "6c+",
        "7a", "7a+", "7b", "7b+", "7c", "7c+",
        "8a", "8a+", "8b", "8b+", "8c", "8c+",
        "9a", "9a+", "9b", "9b+", "9c"
    ]

    /// Table A: YDS ↔ French conversions
    static let ydsToFrench: [String: String] = [
        "5.6": "4c", "5.7": "5a", "5.8": "5b", "5.9": "5c",
        "5.10a": "6a", "5.10b": "6a+", "5.10c": "6b", "5.10d": "6b+",
        "5.11a": "6c", "5.11b": "6c+", "5.11c": "7a", "5.11d": "7a+",
        "5.12a": "7b", "5.12b": "7b+", "5.12c": "7c", "5.12d": "7c+",
        "5.13a": "8a", "5.13b": "8a+", "5.13c": "8b", "5.13d": "8b+",
        "5.14a": "8c", "5.14b": "8c+", "5.14c": "9a", "5.14d": "9a+",
        "5.15a": "9b", "5.15b": "9b+", "5.15c": "9c"
    ]

    /// Table B: V-scale ↔ Font conversions
    static let vToFont: [String: String] = [
        "VB": "3–4", "V0": "5", "V1": "5+", "V2": "6A", "V3": "6A+",
        "V4": "6B", "V5": "6C", "V6": "7A", "V7": "7A+", "V8": "7B",
        "V9": "7B+", "V10": "7C+", "V11": "8A", "V12": "8A+", "V13": "8B",
        "V14": "8B+", "V15": "8C", "V16": "8C+", "V17": "9A"
    ]

    /// Table C: V-scale ↔ French anchor points for boulder-route bridge
    static let vToFrenchAnchors: [String: String] = [
        "V0": "6a", "V1": "6a+", "V2": "6b", "V3": "6b+", "V4": "6c",
        "V5": "7a", "V6": "7a+", "V7": "7b", "V8": "7b+", "V9": "7c",
        "V10": "7c+", "V11": "8a", "V12": "8a+", "V13": "8b", "V14": "8b+",
        "V15": "8c", "V16": "8c+", "V17": "9a"
    ]

    /// Get DI for a French grade
    static func diForFrenchGrade(_ grade: String) -> Int? {
        guard let index = canonicalFrenchGrades.firstIndex(of: grade) else { return nil }
        return index * 10
    }

    /// Get French grade for a DI value
    static func frenchGradeForDI(_ di: Int) -> String {
        let index = max(0, min(canonicalFrenchGrades.count - 1, di / 10))
        return canonicalFrenchGrades[index]
    }

    /// Normalize any grade to DI
    static func normalizeToDI(grade: String, system: GradeSystem, climbType _: ClimbType) -> Int? {
        switch system {
        case .french:
            return diForFrenchGrade(grade)
        case .yds:
            if let frenchGrade = ydsToFrench[grade] {
                return diForFrenchGrade(frenchGrade)
            }
        case .vscale:
            if let frenchGrade = vToFrenchAnchors[grade] {
                return diForFrenchGrade(frenchGrade)
            }
        case .font:
            if let vGrade = vToFont.first(where: { $0.value == grade })?.key {
                if let frenchGrade = vToFrenchAnchors[vGrade] {
                    return diForFrenchGrade(frenchGrade)
                }
            }
        case .circuit:
            // Circuit grades don't have DI conversion
            return nil
        }
        return nil
    }

    /// Convert from DI to target system
    static func gradeForDI(_ di: Int, system: GradeSystem, climbType _: ClimbType) -> String? {
        let frenchGrade = frenchGradeForDI(di)

        switch system {
        case .french:
            return frenchGrade
        case .yds:
            return ydsToFrench.first(where: { $0.value == frenchGrade })?.key
        case .vscale:
            return vToFrenchAnchors.first(where: { $0.value == frenchGrade })?.key
        case .font:
            if let vGrade = vToFrenchAnchors.first(where: { $0.value == frenchGrade })?.key {
                return vToFont[vGrade]
            }
        case .circuit:
            return nil
        }
        return nil
    }

    /// Convert between any two grade systems
    static func convertGrade(fromGrade: String, fromSystem: GradeSystem, fromType: ClimbType,
                           toSystem: GradeSystem, toType: ClimbType) -> String? {
        guard let di = normalizeToDI(grade: fromGrade, system: fromSystem, climbType: fromType) else {
            return nil
        }
        return gradeForDI(di, system: toSystem, climbType: toType)
    }
}

struct AnyGradeProtocol: GradeProtocol {
    static func == (lhs: AnyGradeProtocol, rhs: AnyGradeProtocol) -> Bool {
        lhs.system == rhs.system
    }
    
    private var _system: () -> GradeSystem
    private var _grades: () -> [String]
    private var _colorMap: () -> [String: Color]

    private var _colorsForGrade: (String) -> [Color]
    private var _descriptionForGrade: (String) -> String?
    
    init<GP: GradeProtocol>(_ gradeSystem: GP) {
        _system = { gradeSystem.system }
        _grades = { gradeSystem.grades }
        _colorMap = { gradeSystem.colorMap }

        _colorsForGrade = gradeSystem.colors(for:)
        _descriptionForGrade = gradeSystem.description(for:)
    }
    
    var colorMap: [String : Color]  {
        return _colorMap()
    }
    
    var system: GradeSystem {
        return _system()
    }

    var grades: [String] {
        return _grades()
    }

    func colors(for grade: String) -> [Color] {
        return _colorsForGrade(grade)
    }

    func description(for grade: String) -> String? {
        return _descriptionForGrade(grade)
    }
    
    
}
import Charts
protocol GradeProtocol: Equatable {
    var system: GradeSystem { get }
    var grades: [String] { get }
    var colorMap: [String: Color] { get }
    func colors(for grade: String) -> [Color]
    func description(for grade: String) -> String?
    func normalizedDifficulty(for grade: String) -> Double
    func grade(forNormalizedDifficulty difficulty: Double) -> String

}

extension GradeProtocol {

    func normalizedDifficulty(for grade: String) -> Double {
        // Use DI system for proper cross-grade-system normalization
        guard let di = DifficultyIndex.normalizeToDI(grade: grade, system: system, climbType: system.climbType) else {
            // Fallback to simple index-based normalization if DI conversion fails
            guard let gradeIndex = grades.firstIndex(of: grade), grades.count > 1 else { return 0.0 }
            return Double(gradeIndex) / Double(grades.count - 1)
        }

        // Normalize DI to 0-1 range (DI range is roughly 0-280)
        return Double(di) / 280.0
    }

    func grade(forNormalizedDifficulty difficulty: Double) -> String {
        // Convert normalized difficulty back to DI
        let di = Int(difficulty * 280.0)

        // Try to get grade using DI system
        if let grade = DifficultyIndex.gradeForDI(di, system: system, climbType: system.climbType) {
            return grade
        }

        // Fallback to simple index-based lookup if DI conversion fails
        let gradeIndex = Int(difficulty * Double(grades.count - 1))
        let clampedIndex = max(0, min(grades.count - 1, gradeIndex))
        return grades[clampedIndex]
    }
    
    func gradeIndex(for grade: String?) -> Int {
        if let grade = grade {
            return grades.firstIndex(of: grade) ?? 0
        }
        return 0
    }
}


// MARK: FrenchGrade
struct FrenchGrade: GradeProtocol {
    
    
    
    func colors(for grade: String) -> [Color] {
        return [colorMap[grade] ?? .gray]  // default to gray color in case the grade is not found in the map
    }
    

    
    static func == (lhs: FrenchGrade, rhs: FrenchGrade) -> Bool {
        lhs.system == rhs.system
    }
    
    let system: GradeSystem = .french
    let grades = ["1", "2", "3",
                  "4a", "4b", "4c",
                  "5a", "5b", "5c",
                  "6a", "6b", "6c",
                  "7a", "7b", "7c",
                  "8a", "8b", "8c",
                  "9a", "9b", "9c"
    ]
    
    let colorMap: [String: Color] = [
        "1": Color.blue,
        "2": Color.blue,
        "3": Color.blue,
        "4a": Color.blue,
        "4b": Color.green,
        "4c": Color.green,
        "5a": Color.green,
        "5b": Color.yellow,
        "5c": Color.yellow,
        "6a": Color.yellow,
        "6b": Color.orange,
        "6c": Color.orange,
        "7a": Color.orange,
        "7b": Color.red,
        "7c": Color.red,
        "8a": Color.purple,
        "8b": Color.purple,
        "8c": Color.purple,
        "9a": Color.black,
        "9b": Color.black,
        "9c": Color.black
    ]
    
    func description(for grade: String) -> String? {
        return grade
    }
}

//MARK: VGrade
struct VGrade: GradeProtocol {
    
    
    let system: GradeSystem = .vscale
    let grades: [String] = ["B", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17"]
    
    

    let colorMap: [String: Color] = [
        "B": Color.blue,
        "0": Color.blue, // Previously [Color.blue, Color.green]
        "1": Color.green,
        "2": Color.green, // Previously [Color.green, Color.yellow]
        "3": Color.yellow,
        "4": Color.yellow, // Previously [Color.yellow, Color.orange]
        "5": Color.orange,
        "6": Color.orange, // Previously [Color.orange, Color.red]
        "7": Color.red,
        "8": Color.red, // Previously [Color.red, Color.purple]
        "9": Color.purple,
        "10": Color.purple, // Previously [Color.purple, Color.black]
        "11": Color.black,
        "12": Color.black,
        "13": Color.black,
        "14": Color.black,
    ]


    func colors(for grade: String) -> [Color] {
        if let color = colorMap[grade] {
                return [color]
            } else {
                return [Color.gray]
            }
    }
    
    func description(for grade: String) -> String? {
        return "v\(grade)"
    }
    
    static func == (lhs: VGrade, rhs: VGrade) -> Bool {
        lhs.system == rhs.system
    }

}

//MARK: Font grade
struct FontGrade: GradeProtocol {
    let system: GradeSystem = .font
    let grades: [String] = ["1", "2", "3", "4", "5", "6a", "6b", "6c", "6d", "7a", "7b", "7c", "7d", "8a", "8b", "8c", "8d"]
    let colorMap: [String: Color] = [
        "1": Color.blue,
        "2": Color.blue,
        "3": Color.blue,
        "4": Color.blue,
        "5": Color.green,
        "6a": Color.yellow,
        "6b": Color.yellow,
        "6c": Color.orange,
        "6d": Color.orange,
        "7a": Color.red,
        "7b": Color.red,
        "7c": Color.purple,
        "7d": Color.purple,
        "8a": Color.black,
        "8b": Color.black,
        "8c": Color.black,
        "8d": Color.black
    ]
 
    func colors(for grade: String) -> [Color] {
        return [colorMap[grade] ?? Color.gray]
    }
    
    func description(for grade: String) -> String? {
        return grade
    }
    
    static func == (lhs: FontGrade, rhs: FontGrade) -> Bool {
        lhs.system == rhs.system
    }
}

//MARK: YDS
struct YDS: GradeProtocol {
    let system: GradeSystem = .yds
    let grades: [String] = ["5.5", "5.6", "5.7", "5.8", "5.9",
                            "5.10a", "5.10b", "5.10c", "5.10d",
                            "5.11a", "5.11b", "5.11c", "5.11d",
                            "5.12a", "5.12b", "5.12c", "5.12d",
                            "5.13a", "5.13b", "5.13c", "5.13d",
                            "5.14a", "5.14b", "5.14c", "5.14d"]

    let colorMap: [String: Color] = [
        "5.5": .blue, "5.6": .blue,
        "5.7": .green, "5.8": .green,
        "5.9": .yellow, "5.10a": .yellow, "5.10b": .yellow,
        "5.10c": .orange, "5.10d": .orange, "5.11a": .orange,
        "5.11b": .orange, "5.11c": .orange, "5.11d": .orange,
        "5.12a": .red, "5.12b": .red, "5.12c": .red, "5.12d": .red,
        "5.13a": .purple, "5.13b": .purple, "5.13c": .purple, "5.13d": .purple,
        "5.14a": .black, "5.14b": .black, "5.14c": .black, "5.14d": .black
    ]

    func colors(for grade: String) -> [Color] {
        if let color = colorMap[grade] {
                return [color]
            } else {
                return [Color.gray]
            }
    }
    
    func description(for grade: String) -> String? {
        return grade
    }
    
    static func == (lhs: YDS, rhs: YDS) -> Bool {
        lhs.system == rhs.system
    }
}



// MARK: - Circuit Grade Support
// See: CustomCircuitGrade.swift, CircuitColorMapping.swift, CircuitGrade.swift for new implementation
