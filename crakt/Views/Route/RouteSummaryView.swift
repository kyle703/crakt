//
//  RouteSummaryView.swift
//  crakt
//
//  Created by Kyle Thompson on 5/12/24.
//

import SwiftUI

struct RouteSummaryView: View {
    var route: Route
    
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                
                let height: CGFloat = route.status == .active ? 50 : 20
                let _system = GradeSystems.systems[route.gradeSystem]!
                RoundedRectangle(cornerRadius: 8)
                    .fill(_system.colors(for: route.grade!).first ?? Color.purple)
                    .frame(width: 50, height: height)
                    .overlay(
                        Text(_system.description(for: route.grade!))
                            .font(.headline)
                            .foregroundColor(Color.white)
                    )
                
                
                
                Spacer()
                
                ForEach(ClimbStatus.allCases, id: \.self) { action in
                    if let count = route.actionCounts[action], count > 0 {
                        HStack {
                            Image(systemName: action.iconName)
                                .foregroundColor(action.color)
                            
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                }
                
                
            }
            
            
            
            
        }
    }
}
