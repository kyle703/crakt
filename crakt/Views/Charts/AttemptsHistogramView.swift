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
                        y: .value("Grade", route.gradeIndex),
                        width: 4
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
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    
                }
            }
            
            if !preview, let rawSelectedDate {
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
                        // For circuit grades, find the route with this grade index
                        if gradeSystem == .circuit {
                            if let route = session.routesSortedByDate.first(where: { $0.gradeIndex == rawGrade }) {
                                Text(route.gradeDescription ?? "Circuit")
                                    .foregroundStyle(route.gradeColor)
                            } else {
                                Text("\(rawGrade)")
                            }
                        } else {
                            // For standard grades, use the protocol
                            let proto = GradeSystemFactory.safeProtocol(for: gradeSystem)
                            let grades = proto.grades
                            if rawGrade >= 0 && rawGrade < grades.count {
                                let grade = grades[rawGrade]
                                let desc = proto.description(for: grade)
                                Text(desc ?? rawGrade.description)
                                    .foregroundStyle(proto.colorMap[grade] ?? .primary)
                            } else {
                                Text("\(rawGrade)")
                            }
                        }
                    }
                }
            }
        }
        .chartXSelection(value: $rawSelectedDate)
    }
    
    @ViewBuilder
    var selectionPopover: some View {
        if let selectedRoute {
            VStack(alignment: .leading, spacing: 4) {
                // Use gradeDescription instead of grade to avoid UUIDs
                Text(selectedRoute.gradeDescription ?? "Unknown")
                    .font(.headline)
                if let range = selectedRoute.circuitGradeRange {
                    Text(range)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("Attempts: \(selectedRoute.attempts.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }
}
