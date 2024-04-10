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
    
    var statusText: String {
        switch session.status {
        case .active:
            return "Active"
        case .complete:
            return "Completed"
        case .cancelled:
            return "Cancelled"

        }
    }
    
    var routesList: RouteAttemptScrollView {
        return RouteAttemptScrollView(routes: session.routes)
    }
}

import Charts
struct RoutesOverTimeView: View {
    var routes: [Route]
    @State var gradeSystem: GradeSystem
    
    private var sortedRoutes: [Route] {
            routes.sorted { route1, route2 in
                let gradingProtocol1 = route1.gradeSystem._protocol
                let gradingProtocol2 = route2.gradeSystem._protocol
                
                return gradingProtocol1.normalizedDifficulty(for: route1.grade!) < gradingProtocol2.normalizedDifficulty(for: route2.grade!)
            }
        }

    var body: some View {
        
        VStack {
            GradeSystemPicker(selectedGradeSystem: $gradeSystem, climbType: routes.first!.climbType)
            
            
            Chart(sortedRoutes) {
                
                BarMark(x: .value("grade",gradeSystem._protocol.grade(forNormalizedDifficulty: $0.gradeSystem._protocol.normalizedDifficulty(for: $0.grade!))), y: .value("attempts", $0.attempts.count))
                    .foregroundStyle(gradeSystem._protocol.color(forNormalizedDifficulty: $0.gradeSystem._protocol.normalizedDifficulty(for: $0.grade!)))
                
            }
            .chartXAxis {
                AxisMarks(preset: .extended, position: .bottom)
            }
        }

    }
}


import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    
    var body: some View {
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
                Text("Elapsed Time")
                    .font(.headline)
                Spacer()
                Text(viewModel.elapsedTimeText)
                    .font(.body)
            }
            
            Divider()
            
            HStack {
                Text("Status")
                    .font(.headline)
                Spacer()
                Text(viewModel.statusText)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
        
        RoutesOverTimeView(routes: viewModel.session.routes, gradeSystem: viewModel.session.routes.first!.gradeSystem)
        viewModel.routesList
    }
}
