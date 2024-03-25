//
//  Route.swift
//  crakt
//
//  Created by Kyle Thompson on 3/21/24.
//
//

import Foundation
import SwiftData

enum RouteStatus: Int, Codable {
    case active = 0
    case inactive = 1
}


@Model class Route {
    
    var id: UUID
    
    

    var climbType: ClimbType = ClimbType.boulder
    
    var grade: String?
    var gradeSystem: GradeSystem = GradeSystem.circuit
    
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
