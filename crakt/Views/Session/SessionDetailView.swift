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




import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    
    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Session Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.headline)
                        Text(viewModel.startDateText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Date")
                            .font(.headline)
                        Text(viewModel.endDateText)
                            .font(.body)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total Session Time")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.elapsedTimeText)
                        .font(.body)
                }

            }
            .padding()
            
            SessionChartsControllerView(session: viewModel.session, gradeSystem: viewModel.session.routes.first!.gradeSystem)
            RouteAttemptScrollView(routes: viewModel.session.routes)
        }
    }
}
