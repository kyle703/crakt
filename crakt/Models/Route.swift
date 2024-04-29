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
