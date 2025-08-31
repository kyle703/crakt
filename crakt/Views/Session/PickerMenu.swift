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
    
    @State private var isPressed = false
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedItem = option
                }) {
                    HStack {
                        Text(option.description)
                        if option == selectedItem {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: systemImageName)
                    .font(.title3)
                    .foregroundColor(selectedItem == nil ? .secondary : color)
                
                Text(selectedItem.description)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(selectedItem == nil ? .secondary : .primary)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isPressed ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isPressed)
            }
            .frame(minWidth: 44, minHeight: 44)
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color)
                    )
            )
            .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.05), radius: isPressed ? 4 : 2, x: 0, y: isPressed ? 2 : 1)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}
