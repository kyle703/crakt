//
//  ClimbTypePicker.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct ClimbTypePicker: View {
    @Binding var selectedClimbType: ClimbType
    
    var body: some View {
        PickerMenu(selectedItem: $selectedClimbType, options: ClimbType.allCases, systemImageName: "figure.climbing", color: .gray)
    }
}
