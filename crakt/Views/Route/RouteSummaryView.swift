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
        // (Assumes you have logic to get the system, color, and text from route.gradeSystem and route.grade)
        let gradeSystem = GradeSystems.systems[route.gradeSystem]!
        let gradeLabel = route.grade.flatMap { gradeSystem.description(for: $0) }
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Grade label in a white pill
                Text(gradeLabel ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                
                Spacer()
                
                // Action counts in white pills
                ForEach(ClimbStatus.allCases, id: \.self) { action in
                    if let count = route.actionCounts[action], count > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: action.iconName)
                                .foregroundColor(action.color)
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        // Add some padding inside
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}
