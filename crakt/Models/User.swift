//
//  User.swift
//  crakt
//
//  Created by Kyle Thompson on 3/21/24.
//
//

import Foundation
import SwiftData




@Model 
class User {
    var id: UUID
    var createdAt: Date

    var name: String
    
    var climbType: ClimbType
    var gradeSystem: GradeSystem
    
    init(name: String = "Test User",
         climbStyle: ClimbType = .boulder,
         gradeSystem: GradeSystem = .vscale) {
        self.id = UUID()
        self.createdAt = Date()

        self.name = name
        self.climbType = climbStyle
        self.gradeSystem = gradeSystem
    }
}


