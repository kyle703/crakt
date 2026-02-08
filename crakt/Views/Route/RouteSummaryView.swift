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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Grade display - color swatch + text for circuit grades, just text for others
                if route.gradeSystem == .circuit {
                    // Circuit grade: show color swatch with name
                    HStack(spacing: 6) {
                        Circle()
                            .fill(route.gradeColor)
                            .frame(width: 20, height: 20)
                        Text(route.circuitColorName ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                } else {
                    // Standard grade: text only
                    Text(route.gradeDescription ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
                
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
