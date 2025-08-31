//
//  ActionButton.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct ActionButton: View {
    let icon: String
    let label: String?
    var size: CGFloat = 60
    let color: Color
    let action: () -> Void
    var disabled: Bool = false  // Default value
    var width: CGFloat = 60
    var height: CGFloat = 60
    
    var body: some View {
        Button(action: {
            if !disabled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    action()
                }
            }
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(disabled ? .gray : color)
                if let label {
                    Text(label)
                        .foregroundColor(disabled ? .gray : color)
                        .font(.caption)
                }
            }
            .frame(minWidth: 20, maxWidth: .infinity, minHeight: 20, maxHeight: .infinity)
            .background(Color.white.opacity(disabled ? 0.7 : 1.0))  // Adjust opacity as needed
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(disabled ? .gray : color, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(disabled ? 0.05 : 0.1), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(disabled ? 0.1 : 0.2), radius: 10, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())  // Ensure no built-in styles are applied
        .disabled(disabled)  // Disable the button action
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ActionButton(icon: "xmark", label: ClimbStatus.fall.description, color: .red, action: {}).frame(width: 100, height: 100)
    }
}
