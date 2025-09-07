//
//  GradeSystemPicker.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI
import SwiftData

struct GradeSystemPicker: View {
    @Binding var selectedGradeSystem: GradeSystem
    var climbType: ClimbType

    var applicableSystems: [GradeSystem] {
        if climbType == .boulder {
            return [GradeSystem.circuit, GradeSystem.vscale, GradeSystem.font]
        } else if climbType == .toprope || climbType == .lead {
            return [GradeSystem.french, GradeSystem.yds]
        }
        return []
    }


    var body: some View {
        PickerMenu(selectedItem: $selectedGradeSystem, options: applicableSystems, systemImageName: "ruler", color: .gray)
            .onChange(of: climbType) {
                // Ensure selected grade system is valid for the new climb type
                if !applicableSystems.contains(selectedGradeSystem) {
                    // Switch to a valid default for the new climb type
                    if climbType == .boulder {
                        selectedGradeSystem = GradeSystem.vscale
                    } else {
                        selectedGradeSystem = GradeSystem.yds
                    }
                    print("🔄 GradeSystemPicker - Switched to default grade system for \(climbType): \(selectedGradeSystem)")
                }
            }
            .onAppear {
                // Ensure we start with a valid grade system
                if !applicableSystems.contains(selectedGradeSystem) {
                    if climbType == .boulder {
                        selectedGradeSystem = GradeSystem.vscale
                    } else {
                        selectedGradeSystem = GradeSystem.yds
                    }
                }
            }
    }
}
