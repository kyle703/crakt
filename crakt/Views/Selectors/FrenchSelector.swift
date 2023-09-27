//
//  FrenchSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct FrenchSelector: View {
    @State var selectedIdx: Int = 0
    
    let grades = ["4",
                  "5a", "5b", "5c",
                  "6a", "6b", "6c",
                  "7a", "7b", "7c",
                  "8a", "8b", "8c",
                  "9a", "9b", "9c"
    ]
    
    let colorMapping: [String: Color] = [
        "4": Color.blue,
        "5a": Color.blue,
        "5b": Color.green,
        "5c": Color.green,
        "6a": Color.yellow,
        "6b": Color.yellow,
        "6c": Color.orange,
        "7a": Color.orange,
        "7b": Color.red,
        "7c": Color.red,
        "8a": Color.purple,
        "8b": Color.purple,
        "8c": Color.purple,
        "9a": Color.black,
        "9b": Color.black,
        "9c": Color.black
    ]
    
    var body: some View {
        ScrollingSelectionView(items: grades.map { grade in
            Text(grade)
                .frame(width: 60, height: 60)
                .font(.title2)
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 10).fill(colorMapping[grade]!))
        }, selectedIdx: $selectedIdx)
    }
}

struct FrenchSelector_Previews: PreviewProvider {
    static var previews: some View {
        FrenchSelector()
    }
}
