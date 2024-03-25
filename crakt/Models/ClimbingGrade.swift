//
//  ClimbingGrade.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI


struct AnyGradeProtocol: GradeProtocol {
    static func == (lhs: AnyGradeProtocol, rhs: AnyGradeProtocol) -> Bool {
        lhs.system == rhs.system
    }
    
    private var _system: () -> GradeSystem
    private var _grades: () -> [String]
    private var _colorsForGrade: (String) -> [Color]
    private var _descriptionForGrade: (String) -> String
    
    init<GP: GradeProtocol>(_ gradeSystem: GP) {
        _system = { gradeSystem.system }
        _grades = { gradeSystem.grades }
        _colorsForGrade = gradeSystem.colors(for:)
        _descriptionForGrade = gradeSystem.description(for:)
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

    func description(for grade: String) -> String {
        return _descriptionForGrade(grade)
    }
}

protocol GradeProtocol: Equatable {
    var system: GradeSystem { get }
    var grades: [String] { get }
    func colors(for grade: String) -> [Color]
    func description(for grade: String) -> String
}


// MARK: FrenchGrade
struct FrenchGrade: GradeProtocol {
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
    
    func colors(for grade: String) -> [Color] {
        return [colorMap[grade] ?? Color.gray]  // default to gray color in case the grade is not found in the map
    }
    
    func description(for grade: String) -> String {
        return grade
    }
}

//MARK: VGrade
struct VGrade: GradeProtocol {
    let system: GradeSystem = .vscale
    let grades: [String] = ["B", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17"]

    let colorMap: [String: [Color]] = [
        "B": [Color.blue],
        "0": [Color.blue, Color.green],
        "1": [Color.green],
        "2": [Color.green, Color.yellow],
        "3": [Color.yellow],
        "4": [Color.yellow, Color.orange],
        "5": [Color.orange],
        "6": [Color.orange, Color.red],
        "7": [Color.red],
        "8": [Color.red, Color.purple],
        "9": [Color.purple],
        "10": [Color.purple, Color.black],
        "11": [Color.black],
        "12":  [Color.black],
        "13":  [Color.black],
        "14":  [Color.black],
    ]

    func colors(for grade: String) -> [Color] {
        return colorMap[grade] ?? [Color.gray]  // default to gray color in case the grade is not found in the map
    }
    
    func description(for grade: String) -> String {
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
    
    func description(for grade: String) -> String {
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

    let colorMap: [String: [Color]] = [
        "5.5": [Color.blue], "5.6": [Color.blue],
        "5.7": [Color.green], "5.8": [Color.green],
        "5.9": [Color.yellow], "5.10a": [Color.yellow], "5.10b": [Color.yellow],
        "5.10c": [Color.orange], "5.10d": [Color.orange], "5.11a": [Color.orange],
        "5.11b": [Color.orange], "5.11c": [Color.orange],
        "5.11d": [Color.red], "5.12a": [Color.red], "5.12b": [Color.red],
        "5.12c": [Color.red], "5.12d": [Color.red],
        "5.13a": [Color.purple], "5.13b": [Color.purple], "5.13c": [Color.purple], "5.13d": [Color.purple],
        "5.14a": [Color.black], "5.14b": [Color.black], "5.14c": [Color.black], "5.14d": [Color.black]
    ]

    func colors(for grade: String) -> [Color] {
        return colorMap[grade] ?? [Color.gray] // default to gray color in case the grade is not found in the map
    }
    
    func description(for grade: String) -> String {
        return grade
    }
    
    static func == (lhs: YDS, rhs: YDS) -> Bool {
        lhs.system == rhs.system
    }
}



protocol CircuitGradeProtocol: GradeProtocol {
    var orderedColors: [Color] { get set }
}

let DEFAULT_CIRCUIT = [Color.blue, Color.green, Color.yellow, Color.orange, Color.red, Color.purple, Color.black]
class UserConfiguredCircuitGrade: CircuitGradeProtocol {
    static func == (lhs: UserConfiguredCircuitGrade, rhs: UserConfiguredCircuitGrade) -> Bool {
        lhs.system == rhs.system
    }
    
    let system: GradeSystem = .circuit
    var orderedColors: [Color]
    
    var grades: [String] {
        // Convert Colors to their String names as grades
        return orderedColors.map { "\($0.description)" }
    }
    
    init(orderedColors: [Color] = DEFAULT_CIRCUIT) {
        self.orderedColors = orderedColors
    }
    
    func colors(for grade: String) -> [Color] {
        // Convert the grade back to Color
        if let color = Color(colorName: grade) {
            return [color]
        }
        return [Color.clear]  // Default if grade is not found
    }
    
    func description(for grade: String) -> String {
        return ""
    }
}
