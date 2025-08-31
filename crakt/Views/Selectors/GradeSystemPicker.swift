//
//  GradeSystemPicker.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct GradeSystemPicker: View {
    @Binding var selectedGradeSystem: GradeSystem
    var climbType: ClimbType
    
    var applicableSystems: [GradeSystem] {
        if climbType == .boulder {
            return [.circuit, .vscale, .font]
        } else if climbType == .toprope || climbType == .lead {
            return [.french, .yds]
        }
        return []
    }
    
    var body: some View {
        PickerMenu(selectedItem: $selectedGradeSystem, options: applicableSystems, systemImageName: "ruler", color: .gray)
    }
}
