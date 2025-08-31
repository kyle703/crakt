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
        guard let gradeIndex = grades.firstIndex(of: grade), grades.count > 1 else { return 0.0 }
        
        // Define the base difficulty factor (this could be adjusted for each grading system if needed)
        let baseDifficultyFactor = 1.5
        
        // Calculate the exponent for the current grade based on its position
        let gradeExponent = Double(gradeIndex)
        
        // Calculate the maximum exponent possible within this system for normalization
        let maxExponent = Double(grades.count - 1)
        
        // Apply the exponential formula to get a normalized value between 0 and 1
        return (pow(baseDifficultyFactor, gradeExponent) - 1) / (pow(baseDifficultyFactor, maxExponent) - 1)
    }
    
    func grade(forNormalizedDifficulty difficulty: Double) -> String {
            var closestGrade: String = grades.first ?? ""
            var smallestDifference: Double = Double.infinity
            
            for grade in grades {
                let normalizedDifficulty = self.normalizedDifficulty(for: grade)
                let difference = abs(normalizedDifficulty - difficulty)
                
                if difference < smallestDifference {
                    smallestDifference = difference
                    closestGrade = grade
                }
            }
            
            return closestGrade
        }
    
    func color(forNormalizedDifficulty difficulty: Double) -> Color {
            // Use the reverse lookup function to get the closest grade for the normalized difficulty
            // Default to gray if no color is found
            return colors(for: grade(forNormalizedDifficulty: difficulty)).first ?? .gray
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
    
    var colorMap: [String : Color] {
            var map = [String: Color]()
            for color in orderedColors {
                let colorName = "\(color.description)" // Simplification
                map[colorName] = color
            }
            return map
        }
    
    func description(for grade: String) -> String? {
        return nil
    }
}
