//
//  Route.stats.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI

extension Route {
    var normalizedGrade: Double {
        self.gradeSystem._protocol.normalizedDifficulty(for: grade!)
    }
    
    func getConvertedGrade(system: GradeSystem) -> String {
        return system._protocol.grade(forNormalizedDifficulty: self.normalizedGrade)
    }
}
