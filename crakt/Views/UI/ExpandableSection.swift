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
                Image(systemName: "chevron.up")
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 10)
                    .rotationEffect(Angle(degrees: isExpanded ? 0 : 180))
            }
            .frame(maxWidth: .infinity) // Ensures the HStack occupies the full width
            .contentShape(Rectangle()) // ensures the entire area is tappable
            .onTapGesture {
                withAnimation(nil) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                content()
            }
        }
    }
}
