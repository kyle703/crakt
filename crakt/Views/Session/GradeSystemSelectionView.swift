//
//  GradeSystemSelectionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/24/23.
//

import SwiftUI
import SwiftData

// Explicitly import the models to ensure GradeSystem is available
import Foundation



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
            return [GradeSystem.circuit, GradeSystem.vscale, GradeSystem.font]
        case .toprope, .lead:
            return [GradeSystem.yds, GradeSystem.french]
        }
    }

    func validateGradeSystem() {
        if !validGradeSystems.contains(selectedGradeSystem) {
            let newGradeSystem = selectedClimbType == .boulder ? GradeSystem.vscale : GradeSystem.yds
            print("🔄 GradeSystemSelectionView - Invalid grade system detected:")
            print("  - Current: \(selectedGradeSystem)")
            print("  - Valid options: \(validGradeSystems)")
            print("  - Switching to: \(newGradeSystem)")
            selectedGradeSystem = newGradeSystem
        }
    }

    
    var body: some View {
        HStack {
            ClimbTypePicker(selectedClimbType: $selectedClimbType)
                .onChange(of: selectedClimbType) { oldValue, newValue in
                    print("🔄 GradeSystemSelectionView - Climb type changed from \(oldValue) to \(newValue)")
                    validateGradeSystem()
                }
            Spacer()
            GradeSystemPicker(selectedGradeSystem: $selectedGradeSystem, climbType: selectedClimbType)
                .onChange(of: selectedGradeSystem) { oldValue, newValue in
                    print("🔄 GradeSystemSelectionView - Grade system changed from \(oldValue) to \(newValue)")
                    // Validate that the new grade system is compatible with current climb type
                    if !validGradeSystems.contains(newValue) {
                        print("❌ GradeSystemSelectionView - Invalid grade system selected for current climb type")
                        validateGradeSystem()
                    }
                }
        }
    }
}

#Preview {

    @Previewable @State var selectedClimbType: ClimbType = .boulder
    @Previewable @State var selectedGradeSystem: GradeSystem = .vscale

    VStack(spacing: 0) {
        GradeSystemSelectionView(selectedClimbType: $selectedClimbType,
                                             selectedGradeSystem: $selectedGradeSystem)
                        .padding(.horizontal)
                        .padding(.bottom)
    }
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
    .padding()
} 
