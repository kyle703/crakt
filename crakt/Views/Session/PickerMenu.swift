//
//  PickerMenu.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct PickerMenu<T: Hashable & CustomStringConvertible>: View {
    @Binding var selectedItem: T
    let options: [T]
    let systemImageName: String
    let color: Color
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedItem = option
                }) {
                    Text(option.description)
                }
            }
        } label: {
            ZStack {
                Label("\(selectedItem.description)", systemImage: systemImageName)
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
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
        }
    }
}
