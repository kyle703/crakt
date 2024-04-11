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
        case .topped:
            return "Topped"
        case .flash:
            return "Flash"
        }
    }
    
    
    var color: Color {
        switch self {
        case .fall:
            return .red
        case .send:
            return .green
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
        case .topped:
            return "flag.circle.fill"
        case .flash:
            return "bolt.circle.fill"
        }
    }
}
