//
//  AttemptsHistogramView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI
import Charts

struct AttemptsHistogramView: View {
    var session: Session
    var preview = false
    
    var gradeSystem: GradeSystem  {
        session.routes.first?.gradeSystem ?? GradeSystem.vscale
    }
        
    @State private var rawSelectedDate: Date? = nil
    
    var selectedRoute: Route? {
        if let rawSelectedDate {
            return session.routesSortedByDate.first {
                return $0.attemptDateRange.contains(rawSelectedDate)
            }
        }
        return nil
    }
    
    var body: some View {
        Chart {
            ForEach(Array(session.routesSortedByDate.enumerated()), id: \.element.id) { index, route in
                if preview {
                    // Preview mode: Use index as x-value and style differently
                    BarMark(
                        x: .value("Index", index),
                        y: .value("Grade", route.gradeIndex.description),
                        width: 6
                    )
                    .foregroundStyle(route.gradeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                } else {
                    
                    ForEach(route.attempts) { attempt in
                        // Normal mode: Use firstAttemptDate as x-value
                        BarMark(
                            x: .value("Date", attempt.date),
                            y: .value("Grade", route.gradeIndex)
                        )
                        .foregroundStyle(route.gradeColor)
    //                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    
                }
            }
            
            if let rawSelectedDate {
                RuleMark(x: .value("selected date", rawSelectedDate, unit: .minute))
                    .foregroundStyle(.gray.opacity(0.3)).zIndex(-1)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        selectionPopover
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .chartLegend(preview ? .hidden : .automatic)  // Conditionally display chart legend
        .chartXAxis(preview ? .hidden : .automatic)  // Conditionally display X axis
        .chartYAxis(preview ? .hidden : .automatic)
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let rawGrade = value.as(Int.self) {
                        let grade = gradeSystem._protocol.grades[rawGrade];
                        let desc = gradeSystem._protocol.description(for: grade)
                        Text(desc)
                    }
                }
            }
        }
        .chartXSelection(value: $rawSelectedDate)
    }
    
    @ViewBuilder
    var selectionPopover: some View {
        if let selectedRoute {
            VStack {
                Text(selectedRoute.grade ?? "idk")
                Text("Attempts: ")
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }
}
