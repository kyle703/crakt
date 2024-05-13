//
//  AttemptStatusByGradeStackedBarChartView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI
import Charts

struct AttemptStatusByGradeStackedBarChartView: View {
    // TODO order stacks by status
    // TODO figure out where to put statusColors
   
    var session: Session
    var preview = false
    let statusColors: [Color] = [.red, .green, .orange, .yellow]

    var body: some View {
        Chart(session.attemptsByGradeAndStatus, id: \.grade) { data in
            BarMark(
                x: .value("Grade", data.grade),
                y: .value("Count", data.attempts)
            )
            .foregroundStyle(by: .value("Status", data.status.description))
        }
        .chartForegroundStyleScale(domain: ClimbStatus.allCases, range: statusColors)
        .aspectRatio(1, contentMode: .fit)
        .chartLegend(preview ? .hidden : .automatic)  // Conditionally display chart legend
        .chartXAxis(preview ? .hidden : .automatic)  // Conditionally display X axis
        .chartYAxis(preview ? .hidden : .automatic)
    }
}
