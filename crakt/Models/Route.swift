//
//  Route.swift
//  crakt
//
//  Created by Kyle Thompson on 3/21/24.
//
//

import Foundation
import SwiftData
import Charts
import SwiftUI


enum RouteStatus: Int, Codable {
    case active = 0
    case inactive = 1
}

enum RouteStyle: String, Codable, CaseIterable {
    case slab = "Slab"
    case vertical = "Vertical"
    case overhang = "Overhang"
    case roof = "Roof"
    case compression = "Compression"
    case crimp = "Crimp-heavy"
    case sloper = "Sloper-heavy"
    case pinch = "Pinch-heavy"
    case pocket = "Pocket-heavy"
    case dynamic = "Dynamic"

    var description: String {
        return self.rawValue
    }

    var iconName: String {
        switch self {
        case .slab: return "mountain.2"
        case .vertical: return "arrow.up"
        case .overhang: return "arrow.down"
        case .roof: return "arrow.down.circle"
        case .compression: return "hand.point.up"
        case .crimp: return "hand.point.up.fill"
        case .sloper: return "hand.point.down"
        case .pinch: return "hand.point.left"
        case .pocket: return "circle"
        case .dynamic: return "bolt.horizontal"
        }
    }

    var color: Color {
        switch self {
        case .slab: return .blue
        case .vertical: return .green
        case .overhang: return .orange
        case .roof: return .red
        case .compression: return .purple
        case .crimp: return .yellow
        case .sloper: return .pink
        case .pinch: return .mint
        case .pocket: return .cyan
        case .dynamic: return .indigo
        }
    }

    static var style: RouteStyle.Type {
        return RouteStyle.self
    }
}

enum DifficultyRating: String, Codable, CaseIterable {
    case easy = "Easy"
    case justRight = "Just Right"
    case hard = "Hard"

    var description: String {
        return self.rawValue
    }

    var iconName: String {
        switch self {
        case .easy: return "hand.thumbsup"
        case .justRight: return "checkmark.circle"
        case .hard: return "hand.thumbsdown"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .justRight: return .blue
        case .hard: return .orange
        }
    }
}

enum ClimbExperience: String, Codable, CaseIterable {
    case fun = "Fun"
    case pumpy = "Pumpy"
    case technical = "Technical"
    case powerful = "Powerful"
    case balance = "Balance"
    case endurance = "Endurance"
    case sandbag = "Sandbag"
    case soft = "Soft"

    var description: String {
        return self.rawValue
    }

    var iconName: String {
        switch self {
        case .fun: return "face.smiling"
        case .pumpy: return "drop"
        case .technical: return "brain"
        case .powerful: return "bolt"
        case .balance: return "figure.stand"
        case .endurance: return "clock"
        case .sandbag: return "arrow.up.circle"
        case .soft: return "arrow.down.circle"
        }
    }

    var color: Color {
        switch self {
        case .fun: return .yellow
        case .pumpy: return .blue
        case .technical: return .purple
        case .powerful: return .red
        case .balance: return .green
        case .endurance: return .orange
        case .sandbag: return .red
        case .soft: return .green
        }
    }
}



@Model class Route: Identifiable {
    
    var id: UUID
    
    var climbType: ClimbType = ClimbType.boulder
    
    var grade: String?
    var gradeSystem: GradeSystem = GradeSystem.circuit
    
    var gradeDescription: String? {
        if let grade = grade {
            return gradeSystem._protocol.description(for: grade)
        }
        return nil
    }
    
    var gradeColor: Color {
        if let grade = grade {
            return gradeSystem._protocol.colorMap[grade] ?? Color.gray
        } else {
            return Color.gray
        }
    }
    
    var gradeIndex: Int {
        gradeSystem._protocol.gradeIndex(for: grade)
    }
    
    var firstAttemptDate: Date? {
        if let _min = attempts.min(by: { $0.date < $1.date }) {
            return _min.date
        }
        return nil
    }
    
    var lastAttemptDate: Date? {
        if let _max = attempts.max(by: { $0.date < $1.date }) {
            return _max.date
        }
        return nil
    }
    
    var attemptDateRange: ClosedRange<Date> {
        return (firstAttemptDate!...lastAttemptDate!)
    }
    
    

    
    var status: RouteStatus = RouteStatus.inactive

    
    @Relationship(deleteRule: .cascade, inverse: \RouteAttempt.route)
    var attempts: [RouteAttempt] = []
    
    var session: Session?

    // Route timer state (for persistence across navigation)
    var routeStartElapsed: TimeInterval?
    var lastAttemptElapsed: TimeInterval?
    var totalRestTime: TimeInterval = 0

    // Route style tags (for categorization and filtering)
    var styles: [RouteStyle] = []
    var experiences: [ClimbExperience] = []

    public init(gradeSystem: GradeSystem) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
    }
    
    public init(gradeSystem: GradeSystem, attempts: [RouteAttempt] = []) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.attempts = attempts
    }
    
    public init(gradeSystem: GradeSystem, grade: String, attempts: [RouteAttempt] = []) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.attempts = attempts
        self.grade =  grade
    }
    
    public init(gradeSystem: GradeSystem, grade: String, attempts: [RouteAttempt] = [], session: Session) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.attempts = attempts
        self.grade =  grade
        self.session = session
    }
    
    public init(gradeSystem: GradeSystem, grade: String) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.grade =  grade
    }
    
}

extension Route {
    var actionCounts: [ClimbStatus: Int] {
        var counts: [ClimbStatus: Int] = [:]
        
        for attempt in attempts {
            counts[attempt.status, default: 0] += 1
        }
        
        return counts
    }
    
    func addAttempt(status: ClimbStatus) {
        attempts.append(RouteAttempt(status: status))
    }
}
