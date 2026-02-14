//
//  GymGradeConfiguration.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import Foundation
import SwiftData

/// Associates grade systems with a gym, including support for custom circuits.
/// Enables regional defaults (US uses V-Scale/YDS, Europe uses Font/French).
@Model
class GymGradeConfiguration: Identifiable {
    /// Unique identifier
    var id: UUID
    
    /// Associated gym ID
    var gymId: UUID
    
    /// Boulder grade system for this gym
    var boulderGradeSystem: GradeSystem
    
    /// Rope grade system for this gym
    var ropeGradeSystem: GradeSystem
    
    /// If boulder system is circuit, this links to the circuit configuration
    @Relationship(deleteRule: .nullify)
    var boulderCircuit: CustomCircuitGrade?
    
    /// When this configuration was created
    var createdDate: Date
    
    /// Last modification timestamp
    var lastModifiedDate: Date
    
    init(id: UUID = UUID(),
         gymId: UUID,
         boulderGradeSystem: GradeSystem = .vscale,
         ropeGradeSystem: GradeSystem = .yds) {
        self.id = id
        self.gymId = gymId
        self.boulderGradeSystem = boulderGradeSystem
        self.ropeGradeSystem = ropeGradeSystem
        self.createdDate = Date()
        self.lastModifiedDate = Date()
    }
    
    // MARK: - Update Methods
    
    func setBoulderSystem(_ system: GradeSystem, circuit: CustomCircuitGrade? = nil) {
        boulderGradeSystem = system
        boulderCircuit = (system == .circuit) ? circuit : nil
        lastModifiedDate = Date()
    }
    
    func setRopeSystem(_ system: GradeSystem) {
        ropeGradeSystem = system
        lastModifiedDate = Date()
    }
}
