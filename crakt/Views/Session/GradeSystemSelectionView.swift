//
//  GradeSystemSelectionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/24/23.
//

import SwiftUI



// Use of protocol 'GradeProtocol' as a type must be written 'any GradeProtocol'
struct GradeSystems {
    private static let _systems: [GradeSystem: any GradeProtocol] = [
        .circuit: UserConfiguredCircuitGrade(),
        .vscale: VGrade(),
        .font: FontGrade(),
        .yds: YDS(),
        .french: FrenchGrade()
    ]
    
    static var systems: [GradeSystem: AnyGradeProtocol] {
        return _systems.reduce(into: [:]) { (result, entry) in
            result[entry.key] = AnyGradeProtocol(entry.value)
        }
    }
}

struct GradeSystemSelectionView: View {
    @Binding var selectedClimbType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem
    
    var validGradeSystems: [GradeSystem] {
        switch selectedClimbType {
        case .boulder:
            return [.circuit, .vscale, .font]
        case .toprope, .lead:
            return [.yds, .french]
        }
    }

    func validateGradeSystem() {
        if !validGradeSystems.contains(selectedGradeSystem) {
            selectedGradeSystem = selectedClimbType == .boulder ? .vscale : .yds
        }
    }

    
    var body: some View {
        HStack {
            ClimbTypePicker(selectedClimbType: $selectedClimbType)
                .onChange(of: selectedClimbType) { _ in
                    validateGradeSystem()
                }
            Spacer()
            GradeSystemPicker(selectedGradeSystem: $selectedGradeSystem, climbType: selectedClimbType)
        }
    }
}
