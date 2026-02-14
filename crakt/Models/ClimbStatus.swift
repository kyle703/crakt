//
//  ClimbStatus.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI
import Charts

enum ClimbStatus: CaseIterable, Codable, Plottable {
    init?(primitivePlottable: String) {
        return nil
    }
    
    typealias PrimitivePlottable = String
    
    
    case fall
    case send
    case highPoint
    case topped
    case flash
    
    var primitivePlottable: PrimitivePlottable {
        return description
    }
    
    var description: String {
        switch self {
        case .fall:
            return "Fall"
        case .send:
            return "Send"
        case .highPoint:
            return "High Point"
        case .topped:
            return "Topped"
        case .flash:
            return "Flash"
        }
    }
    
    /// Whether this status counts as a successful completion
    var isSend: Bool {
        switch self {
        case .send, .topped, .flash:
            return true
        case .fall, .highPoint:
            return false
        }
    }
    
    var color: Color {
        switch self {
        case .fall:
            return .red
        case .send:
            return .green
        case .highPoint:
            return .orange
        case .topped:
            return .orange
        case .flash:
            return .yellow
        }
    }
    
    var iconName: String {
        switch self {
        case .fall:
            return "xmark.circle.fill"
        case .send:
            return "arrow.up.circle.fill"
        case .highPoint:
            return "arrow.up.to.line.circle.fill"
        case .topped:
            return "flag.circle.fill"
        case .flash:
            return "bolt.circle.fill"
        }
    }
}
