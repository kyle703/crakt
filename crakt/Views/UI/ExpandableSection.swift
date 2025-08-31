//
//  ExpandableSection.swift
//  crakt
//
//  Created by Kyle Thompson on 5/12/24.
//

import SwiftUI

struct ExpandableSection<Label: View, Content: View>: View {
    @Binding var isExpanded: Bool
    let label: () -> Label
    let content: () -> Content
    
    var body: some View {
        VStack() {
            HStack {
                label()
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white)
                    
                    Image(systemName: "chevron.up")
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                        // Adjust icon size relative to circle
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(width: 24, height: 24)
                    
            }
            .padding(.trailing)
            .frame(maxWidth: .infinity) // Ensures the HStack occupies the full width
            .contentShape(Rectangle()) // ensures the entire area is tappable
            .onTapGesture {
                withAnimation(nil) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                content()
//                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.9, blendDuration: 0), value: isExpanded)

    }
}
