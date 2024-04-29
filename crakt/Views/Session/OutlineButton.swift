//
//  ActionFooter.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct OutlineButton: View {
    var action: () -> Void
    var systemImage: String = "arrowshape.turn.up.right.circle.fill"
    var label: String = "Climb On"
    var color: Color = .blue
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Label(label, systemImage: systemImage)
                    .font(.headline)
                    .padding(10)
                    .foregroundColor(color)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 2)
                    )
            }
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
        }
    }
}
