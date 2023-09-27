//
//  YDSSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct YDSSelector: View {
    @State var selectedIdx: Int = 0
    
    let grades = ["5.5", "5.6", "5.7", "5.8", "5.9",
                  "5.10a", "5.10b", "5.10c", "5.10d",
                  "5.11a", "5.11b", "5.11c", "5.11d",
                  "5.12a", "5.12b", "5.12c", "5.12d",
                  "5.13a", "5.13b", "5.13c", "5.13d",
                  "5.14a", "5.14b", "5.14c", "5.14d",
    ]
    
    let colorMapping: [String: Color] = [
        "5.5": Color.blue, "5.6": Color.blue,
        "5.7": Color.green, "5.8": Color.green,
        "5.9": Color.yellow, "5.10a": Color.yellow, "5.10b": Color.yellow,
        "5.10c": Color.orange, "5.10d": Color.orange, "5.11a": Color.orange, "5.11b": Color.orange, "5.11c": Color.orange,
        "5.11d": Color.red, "5.12a": Color.red, "5.12b": Color.red,"5.12c": Color.red, "5.12d": Color.red,
        "5.13": Color.purple, "5.14": Color.black
    ]
    
    var body: some View {
        ScrollingSelectionView(items: grades.map { grade in
            Text(grade)
                .frame(width: 60, height: 60)
                .font(.title2)
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 10).fill(backgroundForGrade(grade)))
        }, selectedIdx: $selectedIdx)
    }
    
    private func backgroundForGrade(_ grade: String) -> LinearGradient {
        let color = colorMapping.first(where: { grade.starts(with: $0.key) })?.value ?? Color.black
        return LinearGradient(gradient: Gradient(colors: [color, color]), startPoint: .leading, endPoint: .trailing)
    }
}

struct YDSSelector_Previews: PreviewProvider {
    static var previews: some View {
        YDSSelector()
    }
}
