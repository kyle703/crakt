//
//  CircuitGradeSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct CircuitGradeSelector: View {
    let colors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .black]
    @State var selectedIdx = 0
    
    var body: some View {
        ScrollingSelectionView(
            items: colors.map {
                RoundedRectangle(cornerRadius: 10)
                    .fill($0)
                    .frame(width: 60, height: 60)
            },
            selectedIdx: $selectedIdx
        )
    }
}

struct CircuitGradeSelector_Previews: PreviewProvider {
    static var previews: some View {
        CircuitGradeSelector()
    }
}
