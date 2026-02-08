//
//  DifficultyTimelineChartView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/3/26.
//

import SwiftUI
import Charts

/// A combo chart: scatter points for route difficulty + bars for attempt count per route
struct DifficultyTimelineChartView: View {
    var session: Session
    var currentGradeSystem: GradeSystem
    var preview = false
    
    /// Route data point combining difficulty and attempt count
    struct RouteChartData: Identifiable {
        let id: UUID
        let startDate: Date
        let gradeIndex: Int
        let gradeLabel: String
        let gradeColor: Color
        let attemptCount: Int
        let sendCount: Int
        let fallCount: Int
    }
    
    /// Get all routes sorted by first attempt - deduplicated
    private var sortedRoutes: [Route] {
        var seenIds = Set<UUID>()
        var result: [Route] = []
        
        // Add active route first if it exists and has attempts
        if let activeRoute = session.activeRoute, 
           !activeRoute.attempts.isEmpty,
           !seenIds.contains(activeRoute.id) {
            seenIds.insert(activeRoute.id)
            result.append(activeRoute)
        }
        
        // Add other routes, skipping duplicates
        for route in session.routes {
            if !route.attempts.isEmpty && !seenIds.contains(route.id) {
                seenIds.insert(route.id)
                result.append(route)
            }
        }
        
        return result.sorted { ($0.firstAttemptDate ?? Date.distantPast) < ($1.firstAttemptDate ?? Date.distantPast) }
    }
    
    /// Combined data for each route
    private var routeChartData: [RouteChartData] {
        sortedRoutes.compactMap { route -> RouteChartData? in
            guard let startDate = route.firstAttemptDate else { return nil }
            
            // Use the route's built-in grade display for circuit grades
            let gradeLabel: String
            let gradeIndex: Int
            let gradeColor: Color
            
            if route.gradeSystem == .circuit {
                // For circuit grades, use color name and route's own color
                gradeLabel = route.circuitColorName ?? route.gradeDescription ?? "Unknown"
                gradeIndex = route.gradeIndex
                gradeColor = route.gradeColor
            } else if route.gradeSystem == currentGradeSystem {
                let grade = route.grade ?? "0"
                let proto = GradeSystemFactory.safeProtocol(for: currentGradeSystem)
                gradeLabel = proto.description(for: grade) ?? grade
                gradeIndex = proto.gradeIndex(for: grade)
                gradeColor = proto.colorMap[grade] ?? route.gradeColor
            } else {
                let convertedGrade = route.getConvertedGrade(system: currentGradeSystem)
                let proto = GradeSystemFactory.safeProtocol(for: currentGradeSystem)
                gradeLabel = proto.description(for: convertedGrade) ?? convertedGrade
                gradeIndex = proto.gradeIndex(for: convertedGrade)
                gradeColor = proto.colorMap[convertedGrade] ?? route.gradeColor
            }
            
            let sendCount = route.attempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }.count
            let fallCount = route.attempts.filter { $0.status == .fall }.count
            
            return RouteChartData(
                id: route.id,
                startDate: startDate,
                gradeIndex: gradeIndex,
                gradeLabel: gradeLabel,
                gradeColor: gradeColor,
                attemptCount: route.attempts.count,
                sendCount: sendCount,
                fallCount: fallCount
            )
        }
    }
    
    /// X-axis domain - from session start to now
    private var xAxisDomain: ClosedRange<Date> {
        let startDate = session.startDate
        let latestRoute = routeChartData.map { $0.startDate }.max() ?? startDate
        let endDate = session.status == .active ? max(Date(), latestRoute) : (session.endDate ?? latestRoute)
        
        let paddedStart = startDate.addingTimeInterval(-60)
        let paddedEnd = endDate.addingTimeInterval(120)
        
        return paddedStart...paddedEnd
    }
    
    /// Y-axis domain for grade
    private var gradeAxisDomain: ClosedRange<Int> {
        guard !routeChartData.isEmpty else { return 0...10 }
        
        let indices = routeChartData.map { $0.gradeIndex }
        let minIndex = max(0, (indices.min() ?? 0) - 1)
        let maxIndex = (indices.max() ?? 10) + 1
        
        return minIndex...maxIndex
    }
    
    /// Max attempts for scaling - minimum of 10, with 2 buffer
    private var attemptScaleMax: Int {
        let actualMax = routeChartData.map { $0.attemptCount }.max() ?? 0
        return max(10, actualMax + 2)
    }
    
    /// Y-axis tick values for grades
    private var gradeAxisValues: [Int] {
        let range = gradeAxisDomain
        let span = range.upperBound - range.lowerBound
        let step = max(1, span / 5)
        return Array(stride(from: range.lowerBound, through: range.upperBound, by: step))
    }
    
    /// Y-axis tick values for attempts (right side)
    private var attemptAxisValues: [Int] {
        // Show 0, mid, max
        let mid = attemptScaleMax / 2
        return [0, mid, attemptScaleMax]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if !preview {
                // Title - centered
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.title3)
                            .foregroundColor(.primary)
                        Text("Climbing Activity")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                
                // Legend - trailing aligned
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(.green.opacity(0.4))
                                .frame(width: 6, height: 10)
                            Text("Sends")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(.red.opacity(0.4))
                                .frame(width: 6, height: 10)
                            Text("Falls")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if routeChartData.isEmpty {
                Text("No attempts recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    // Stacked bars for attempts (falls on bottom, sends on top)
                    ForEach(routeChartData) { route in
                        // Falls (bottom of stack)
                        if route.fallCount > 0 {
                            BarMark(
                                x: .value("Time", route.startDate),
                                y: .value("Falls", scaleAttempts(route.fallCount)),
                                width: .fixed(6)
                            )
                            .foregroundStyle(.red.opacity(0.35))
                            .cornerRadius(1)
                        }
                        
                        // Sends (stacked on top)
                        if route.sendCount > 0 {
                            BarMark(
                                x: .value("Time", route.startDate),
                                y: .value("Sends", scaleAttempts(route.sendCount)),
                                width: .fixed(6)
                            )
                            .foregroundStyle(.green.opacity(0.35))
                            .cornerRadius(1)
                        }
                    }
                    
                    // Scatter points for grade difficulty
                    ForEach(routeChartData) { route in
                        PointMark(
                            x: .value("Time", route.startDate),
                            y: .value("Grade", route.gradeIndex)
                        )
                        .symbolSize(100)
                        .foregroundStyle(route.gradeColor)
                    }
                }
                .chartXScale(domain: xAxisDomain)
                .chartYScale(domain: gradeAxisDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatTime(date))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    // Left axis - Grade
                    AxisMarks(position: .leading, values: gradeAxisValues) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel {
                            if let index = value.as(Int.self) {
                                // For circuit grades, find the route with this index
                                if currentGradeSystem == .circuit {
                                    if let route = routeChartData.first(where: { $0.gradeIndex == index }) {
                                        Text(route.gradeLabel)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(route.gradeColor)
                                    }
                                } else {
                                    // For standard grades, use the protocol
                                    let proto = GradeSystemFactory.safeProtocol(for: currentGradeSystem)
                                    let grades = proto.grades
                                    if index >= 0 && index < grades.count {
                                        let grade = grades[index]
                                        let label = proto.description(for: grade) ?? grade
                                        Text(label)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(proto.colorMap[grade] ?? .primary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Right axis - Attempts
                    AxisMarks(position: .trailing, values: attemptAxisValues) { value in
                        AxisValueLabel {
                            if let scaledValue = value.as(Int.self) {
                                // Convert back from grade scale to attempt count
                                let attemptCount = unscaleAttempts(scaledValue)
                                Text("\(attemptCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis(preview ? .hidden : .automatic)
                .chartYAxis(preview ? .hidden : .automatic)
                .chartLegend(.hidden)
                .frame(height: preview ? 100 : 200)
            }
        }
    }
    
    /// Scale attempt count to grade axis range
    private func scaleAttempts(_ count: Int) -> Double {
        Double(count) / Double(attemptScaleMax) * Double(gradeAxisDomain.upperBound)
    }
    
    /// Convert scaled value back to attempt count (for right axis labels)
    private func unscaleAttempts(_ scaledValue: Int) -> Int {
        Int(Double(scaledValue) / Double(gradeAxisDomain.upperBound) * Double(attemptScaleMax))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let session = Session.preview
    DifficultyTimelineChartView(session: session, currentGradeSystem: .vscale)
        .padding()
}
