//
//  VGradeSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct VGradeSelector: View {
    let grades: [String] = ["B", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17"]
    @State var selectedIdx = 0
    
    enum Background {
        case color(Color)
        case gradient([Color])
    }
    
    let colorGradientMap: [String: Background] = [
        "B": .color(Color.blue),
        "0": .gradient([Color.blue, Color.green]),
        "1": .color(Color.green),
        "2": .gradient([Color.green, Color.yellow]),
        "3": .color(Color.yellow),
        "4": .gradient([Color.yellow, Color.orange]),
        "5": .color(Color.orange),
        "6": .gradient([Color.orange, Color.red]),
        "7": .color(Color.red),
        "8": .gradient([Color.red, Color.purple]),
        "9": .color(Color.purple),
        "10": .gradient([Color.purple, Color.black]),
        "11": .color(Color.black),
    ]
    
    var body: some View {
        ScrollingSelectionView(
            items: grades.map { grade in
                Text("v\(grade)")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(RoundedRectangle(cornerRadius: 10).fill(
                        backgroundForGrade(grade)
                    ))
                    
            },
            selectedIdx: $selectedIdx
        )
    }
    
    private func backgroundForGrade(_ grade: String) -> LinearGradient {
        switch colorGradientMap[grade, default: .color(Color.black)] {
        case .color(let color):
            return LinearGradient(gradient: Gradient(colors: [color]), startPoint: .leading, endPoint: .trailing)
        case .gradient(let gradientColors):
            return LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .leading, endPoint: .trailing)
        }
    }
    
}
struct VGradeSelector_Previews: PreviewProvider {
    static var previews: some View {
        VGradeSelector()
    }
}
