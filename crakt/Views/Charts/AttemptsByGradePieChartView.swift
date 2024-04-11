//
//  AttemptsByGradePieChartView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/10/24.
//

import SwiftUI
import Charts

extension Route {
    var normalizedGrade: Double {
        self.gradeSystem._protocol.normalizedDifficulty(for: grade!)
    }
    
    func getConvertedGrade(system: GradeSystem) -> String {
        return system._protocol.grade(forNormalizedDifficulty: self.normalizedGrade)
    }
}

extension Session {
    var totalAttempts: Int {
        routes.reduce(0) { $0 + $1.attempts.count }
    }
    
    var totalAttemptsPerGrade: [(grade: String, attempts: Int)] {
        let attemptsByGrade = attemptsGroupedByGrade(routes: routes)
        let totalAttemptsPerGrade = totalAttemptsByGrade(attemptsByCategory: attemptsByGrade)
        return totalAttemptsPerGrade.sorted { $0.attempts > $1.attempts }
    }
    
    var routesSorted: [Route] {
        routes.sorted { route1, route2 in
            let gradingProtocol1 = route1.gradeSystem._protocol
            let gradingProtocol2 = route2.gradeSystem._protocol
            
            return gradingProtocol1.normalizedDifficulty(for: route1.grade!) < gradingProtocol2.normalizedDifficulty(for: route2.grade!)
        }
    }
    
    var attemptsByGradeAndStatus: [(grade: String, status: ClimbStatus, attempts: Int)] {
        var aggregatedData = [(grade: String, status: ClimbStatus, attempts: Int)]()
        
        for route in routesSorted {
            let grade = route.grade ?? "Unknown"  // Safely handle nil grades if any
            for attempt in route.attempts {
                let status = attempt.status
                if let index = aggregatedData.firstIndex(where: { $0.grade == grade && $0.status == status }) {
                    aggregatedData[index].attempts += 1
                } else {
                    aggregatedData.append((grade: grade, status: status, attempts: 1))
                }
            }
        }
        
        return aggregatedData
    }
    
    func attemptsGroupedByGrade(routes: [Route]) -> [String: [Route]] {
        var attemptsByGrade: [String: [Route]] = [:]
        
        for route in routes {
            
            let grade = route.grade!
            if attemptsByGrade[grade] != nil && true{
                attemptsByGrade[grade]!.append(route)
            } else {
                attemptsByGrade[grade] = [route]
            }
            
            
        }
        
        return attemptsByGrade
    }
    
    func totalAttemptsByGrade(attemptsByCategory: [String: [Route]]) -> [(grade: String, attempts: Int)] {
        var totals: [(String, Int)] = []
        
        for (grade, routes) in attemptsByCategory {
            // Sum the total attempts for routes of this grade
            let totalAttempts = routes.reduce(0) { $0 + $1.attempts.count }
            totals.append((grade, totalAttempts))
        }
        
        // Sort the totals by grade if grades are numeric or alphabetically otherwise
        // Assuming grades can be sorted in a meaningful way as strings
        return totals.sorted(by: { $0.0 < $1.0 })
    }
    
    
}


struct AttemptsByGradePieChartView: View {
    // TODO add handling to tap on a slice to get more details in the middle
    var session: Session
    var body: some View {
        Chart(session.totalAttemptsPerGrade, id: \.grade) { data in
            SectorMark(
                angle: .value("Attempts", data.attempts),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .cornerRadius(5.0)
            .foregroundStyle(by: .value("Grade", data.grade))
        }
        .chartLegend(alignment: .center, spacing: 18)
        .aspectRatio(1, contentMode: .fit)
    }
}

struct AttemptStatusByGradeStackedBarChartView: View {
    // TODO order stacks by status
    // TODO figure out where to put statusColors
    var session: Session
    let statusColors: [Color] = [.red, .green, .orange, .yellow]

    var body: some View {
        Chart(session.attemptsByGradeAndStatus, id: \.grade) { data in
            BarMark(
                x: .value("Grade", data.grade),
                y: .value("Count", data.attempts)
            )
            .foregroundStyle(by: .value("Status", data.status.description))
            .annotation(position: .overlay) {
                Text("\(data.attempts)")
                    .foregroundStyle(Color.white)
                
            }
        }
        .chartForegroundStyleScale(domain: ClimbStatus.allCases, range: statusColors)
        .aspectRatio(1, contentMode: .fit)
    }
}



struct AttemptsByGradeBarChartView: View {
    var session: Session
    @State var gradeSystem: GradeSystem
    
    
    var body: some View {
        
        VStack {
            
            
            GradeSystemPicker(selectedGradeSystem: $gradeSystem, climbType: session.routes.first!.climbType)
            AttemptsByGradePieChartView(session: session)
            AttemptStatusByGradeStackedBarChartView(session: session)
            
        }
        
        
    }
}
