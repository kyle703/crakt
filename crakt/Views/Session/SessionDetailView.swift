//
//  SessionDetailView.swift
//  crakt
//
//  Created by Kyle Thompson on 3/25/24.
//

import SwiftUI

import Foundation

class SessionDetailViewModel: ObservableObject {
    var session: Session
    
    init(session: Session) {
        self.session = session
    }
    
    var startDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.startDate)
    }
    
    var endDateText: String {
        guard let endDate = session.endDate else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
    
    var elapsedTimeText: String {
        // Assuming elapsedTime is in seconds
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(session.elapsedTime)) ?? "N/A"
    }
    
}

struct SessionDetailView: View {
    var session: Session
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d yyyy" // Abbreviated Month, Day, Year
        return formatter.string(from: session.startDate)
    }
    
    var elapsedTimeText: String {
        // Assuming elapsedTime is in seconds
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(session.elapsedTime)) ?? "N/A"
    }
    
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Session Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(dateFormatted)
                    .font(.body)
                
                
                Divider()
                
                HStack {
                    Text("Session Duration")
                        .font(.headline)
                    Spacer()
                    Text(elapsedTimeText)
                        .font(.body)
                }
                
                Divider()
                
                HStack {
                    Text("Hardest grade sent")
                        .font(.headline)
                    Spacer()
                    Text(session.highestGradeSent ?? "N/A")
                        .font(.body)
                }
                
            }
            .padding()
            SessionChartsControllerView(session: session)
            RouteAttemptScrollView(routes: session.routesSortedByDate)
            
        }
    }
}
