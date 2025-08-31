//
//  RouteLogRowItem.swift
//  crakt
//
//  Created by Kyle Thompson on 5/12/24.
//

import SwiftUI

struct AttemptsList: View {
    var route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(route.attempts, id: \.id) { attempt in
                HStack {
                    // Attempt status icon
                    Image(systemName: attempt.status.iconName)
                        .foregroundColor(attempt.status.color)
                    
                    Text(attempt.status.description)
                        .font(.caption)
                        .padding(.leading, 4)
                    
                    Spacer()
                    
                    // Time delta from route.createdAt
                    Text(deltaString(for: attempt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                // White background for each row
                .background(Color.white)
                .cornerRadius(8)
            }
        }
        // Top/bottom padding for the list as a whole
        .padding(.vertical, 4)
    }
    
    private func deltaString(for attempt: RouteAttempt) -> String {
        guard let start = route.firstAttemptDate else {
            // Fallback if no start date on route
            return attempt.date.toString()
        }
        
        let interval = attempt.date.timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "+%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "+%dm %ds", minutes, seconds)
        } else {
            return String(format: "+%ds", seconds)
        }
    }
}




