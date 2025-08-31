//
//  ClimbingGradeSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct ClimbingGradeSelector<GS: GradeProtocol>: View {
    var gradeSystem: GS
    
    @Binding var selectedGrade: String?
    
    @State private var selectedIdx: Int
    
    init(gradeSystem: GS, selectedGrade: Binding<String?>) {
        self.gradeSystem = gradeSystem
        self._selectedGrade = selectedGrade
        
        if let idx = gradeSystem.grades.firstIndex(of: selectedGrade.wrappedValue ?? "") {
            _selectedIdx = State(initialValue: idx)
        } else {
            _selectedIdx = State(initialValue: -1)
        }
    }

    
    var items: [AnyView] {
            gradeSystem.grades.map { grade in
                let colors = gradeSystem.colors(for: grade)
                return AnyView(ZStack {
                    if colors.count == 1 {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colors.first!)
                            .frame(width: 60, height: 60)
                    } else if colors.count == 2 {
                        // Handle the case with a linear gradient or similar if you expect two colors.
                        LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 60, height: 60)
                            .cornerRadius(10)
                    } else {
                        // Handle other cases if necessary, or display a default.
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray)
                            .frame(width: 60, height: 60)
                    }
                }.overlay(
                    Text(gradeSystem.description(for: grade) ?? "")
                        .foregroundColor(.white)
                ))
            }
        }

    // Type 'any View' cannot conform to 'View'
    var body: some View {
            ScrollingSelectionView(
                items: items,
                selectedIdx: $selectedIdx
            )
            //Instance method 'onChange(of:perform:)' requires that 'V' conform to 'Equatable'
            .onChange(of: selectedIdx) { idx in
                selectedGrade = gradeSystem.grades[idx]
            }.onChange(of: gradeSystem) { system in
                
                if selectedIdx >= 0 && selectedIdx < system.grades.count {
                    selectedGrade = system.grades[selectedIdx]
                } else {
                    selectedGrade = nil
                }
                
            }
        }
}

struct ClimbingGradeSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ClimbingGradeSelector(gradeSystem: FrenchGrade(), selectedGrade: .constant(""))
            ClimbingGradeSelector(gradeSystem: YDS(), selectedGrade: .constant(""))
            ClimbingGradeSelector(gradeSystem: FontGrade(), selectedGrade: .constant(""))
            ClimbingGradeSelector(gradeSystem: VGrade(), selectedGrade: .constant(""))
            ClimbingGradeSelector(gradeSystem: FrenchGrade(), selectedGrade: .constant(""))
            ClimbingGradeSelector(gradeSystem: UserConfiguredCircuitGrade(), selectedGrade: .constant(""))
        }
        
    }
}
