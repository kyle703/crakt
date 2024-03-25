//
//  AppState.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import Foundation
import SwiftUI
import SwiftData
import Combine



enum ClimbType: Int16, CustomStringConvertible, Codable {
    case boulder = 0
    case toprope = 1
    case lead = 2
    
    var description: String {
        switch self {
        case .boulder:
            return "Boulder"
        case .toprope:
            return "Toprope"
        case .lead:
            return "Lead"
        }
    }
    
    static let allCases: [ClimbType] = [.boulder, .toprope, .lead]
}

enum GradeSystem: Int16, CustomStringConvertible, Codable {
    case circuit = 0
    case vscale = 1
    case font = 2
    case french = 3
    case yds = 4
    
    var description: String {
        switch self {
        case .circuit:
            return "Circuit"
        case .vscale:
            return "V-Scale"
        case .font:
            return "Font grade"
        case .french:
            return "French grade"
        case .yds:
            return "Yosemite Decimal System"
        }
    }
    
    var climbType : ClimbType {
        switch self {
        case .circuit, .vscale, .font:
            return .boulder
        case .french, .yds:
            return .lead
        }
    }
    
    static let allCases: [GradeSystem] = [.circuit, .vscale, .font, .french, .yds]
    
    var _protocol : Any{
        switch self {
        case.circuit:
            return UserConfiguredCircuitGrade()
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

enum RouteAttemptStatus: Int16, Codable {
    case fail = 0
    case top = 1
}
