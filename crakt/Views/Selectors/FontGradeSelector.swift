//
//  FontGradeSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct FontGradeSelector: View {
    @State var selectedIdx: Int = 0
    
    let grades = ["1", "2", "3", "4", "5", "6a", "6b", "6c", "6d", "7a", "7b", "7c", "7d", "8a", "8b", "8c", "8d"]
    let colorMap: [String: Color] = [
        "1": Color.blue,
        "2": Color.blue,
        "3": Color.blue,
        "4": Color.blue,
        "5": Color.green,
        "6a": Color.yellow,
        "6b": Color.yellow,
        "6c": Color.orange,
        "6d": Color.orange,
        "7a": Color.red,
        "7b": Color.red,
        "7c": Color.purple,
        "7d": Color.purple,
        "8a": Color.black,
        "8b": Color.black,
        "8c": Color.black,
        "8d": Color.black
    ]
    
    var body: some View {
        ScrollingSelectionView(items: gradeItems, selectedIdx: $selectedIdx)
    }
    
    var gradeItems: [some View] {
        grades.map { grade in
            Text(grade)
                .frame(width: 60, height: 60)
                .font(.title)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorMap[grade, default: Color.black])
                )
        }
    }
}

struct FontGradeSelector_Previews: PreviewProvider {
    static var previews: some View {
        FontGradeSelector()
    }
}
