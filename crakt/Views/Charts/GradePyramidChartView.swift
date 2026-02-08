//
//  GradePyramidChartView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/7/26.
//

import SwiftUI
import Charts

/// A horizontal bar chart showing attempts per grade, ordered by difficulty (easiest at bottom)
struct GradePyramidChartView: View {
    var session: Session
    var currentGradeSystem: GradeSystem
    var preview = false
    
    /// Data for each grade level
    struct GradeData: Identifiable {
        let id = UUID()
        let grade: String
        let gradeIndex: Int
        let fallCount: Int
        let toppedCount: Int
        let sendCount: Int
        let flashCount: Int
        let totalAttempts: Int
    }
    
    /// Get all routes deduplicated
    private var allRoutes: [Route] {
        var seenIds = Set<UUID>()
        var result: [Route] = []
        
        if let activeRoute = session.activeRoute,
           !activeRoute.attempts.isEmpty,
           !seenIds.contains(activeRoute.id) {
            seenIds.insert(activeRoute.id)
            result.append(activeRoute)
        }
        
        for route in session.routes {
            if !route.attempts.isEmpty && !seenIds.contains(route.id) {
                seenIds.insert(route.id)
                result.append(route)
            }
        }
        
        return result
    }
    
    /// Aggregate attempts by grade
    private var attemptsByGrade: [String: (falls: Int, topped: Int, sends: Int, flashes: Int, index: Int)] {
        var gradeMap: [String: (falls: Int, topped: Int, sends: Int, flashes: Int, index: Int)] = [:]
        
        for route in allRoutes {
            // Use the route's display label (handles circuit grades properly)
            let gradeLabel: String
            let gradeIndex: Int
            
            if route.gradeSystem == .circuit {
                // For circuit grades, use the color name as the label
                gradeLabel = route.circuitColorName ?? route.gradeDescription ?? "Unknown"
                gradeIndex = route.gradeIndex
            } else if route.gradeSystem == currentGradeSystem {
                let grade = route.grade ?? "0"
                let proto = GradeSystemFactory.safeProtocol(for: currentGradeSystem)
                gradeLabel = proto.description(for: grade) ?? grade
                gradeIndex = proto.gradeIndex(for: grade)
            } else {
                let convertedGrade = route.getConvertedGrade(system: currentGradeSystem)
                let proto = GradeSystemFactory.safeProtocol(for: currentGradeSystem)
                gradeLabel = proto.description(for: convertedGrade) ?? convertedGrade
                gradeIndex = proto.gradeIndex(for: convertedGrade)
            }
            
            let fallCount = route.attempts.filter { $0.status == .fall }.count
            let toppedCount = route.attempts.filter { $0.status == .topped }.count
            let sendCount = route.attempts.filter { $0.status == .send }.count
            let flashCount = route.attempts.filter { $0.status == .flash }.count
            
            if gradeMap[gradeLabel] == nil {
                gradeMap[gradeLabel] = (falls: 0, topped: 0, sends: 0, flashes: 0, index: gradeIndex)
            }
            
            gradeMap[gradeLabel]!.falls += fallCount
            gradeMap[gradeLabel]!.topped += toppedCount
            gradeMap[gradeLabel]!.sends += sendCount
            gradeMap[gradeLabel]!.flashes += flashCount
        }
        
        return gradeMap
    }
    
    /// Complete grade data including all grades in range (no gaps)
    private var gradeData: [GradeData] {
        let attempts = attemptsByGrade
        guard !attempts.isEmpty else { return [] }
        
        // For circuit grades, just return the data we have (no gap filling)
        // since circuit grades are color-based and don't have a continuous range
        if currentGradeSystem == .circuit || allRoutes.contains(where: { $0.gradeSystem == .circuit }) {
            return attempts.map { gradeLabel, data in
                GradeData(
                    grade: gradeLabel,
                    gradeIndex: data.index,
                    fallCount: data.falls,
                    toppedCount: data.topped,
                    sendCount: data.sends,
                    flashCount: data.flashes,
                    totalAttempts: data.falls + data.topped + data.sends + data.flashes
                )
            }.sorted { $0.gradeIndex < $1.gradeIndex }
        }
        
        // For non-circuit grades, fill gaps
        let indices = attempts.values.map { $0.index }
        let minIndex = indices.min() ?? 0
        let maxIndex = indices.max() ?? 0
        
        let proto = GradeSystemFactory.safeProtocol(for: currentGradeSystem)
        let grades = proto.grades
        
        var result: [GradeData] = []
        for index in minIndex...maxIndex {
            guard index >= 0 && index < grades.count else { continue }
            
            let grade = grades[index]
            let gradeLabel = proto.description(for: grade) ?? grade
            
            if let data = attempts[gradeLabel] {
                result.append(GradeData(
                    grade: gradeLabel,
                    gradeIndex: index,
                    fallCount: data.falls,
                    toppedCount: data.topped,
                    sendCount: data.sends,
                    flashCount: data.flashes,
                    totalAttempts: data.falls + data.topped + data.sends + data.flashes
                ))
            } else {
                result.append(GradeData(
                    grade: gradeLabel,
                    gradeIndex: index,
                    fallCount: 0,
                    toppedCount: 0,
                    sendCount: 0,
                    flashCount: 0,
                    totalAttempts: 0
                ))
            }
        }
        
        return result.sorted { $0.gradeIndex < $1.gradeIndex }
    }
    
    /// All grade labels for Y-axis domain
    private var allGradeLabels: [String] {
        gradeData.map { $0.grade }
    }
    
    /// Totals for legend
    private var totalFalls: Int { gradeData.reduce(0) { $0 + $1.fallCount } }
    private var totalTopped: Int { gradeData.reduce(0) { $0 + $1.toppedCount } }
    private var totalSends: Int { gradeData.reduce(0) { $0 + $1.sendCount } }
    private var totalFlashes: Int { gradeData.reduce(0) { $0 + $1.flashCount } }
    
    var body: some View {
        VStack(spacing: 12) {
            if !preview {
                // Title - centered
                HStack(spacing: 6) {
                    Image(systemName: "triangle.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                    Text("Grade Pyramid")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Legend - two rows for readability
                VStack(spacing: 4) {
                    HStack(spacing: 16) {
                        legendItem(color: .red.opacity(0.6), label: "Falls", count: totalFalls)
                        legendItem(color: .orange.opacity(0.7), label: "Topped", count: totalTopped)
                    }
                    HStack(spacing: 16) {
                        legendItem(color: .green.opacity(0.7), label: "Sends", count: totalSends)
                        legendItem(color: .yellow.opacity(0.9), label: "Flashes", count: totalFlashes)
                    }
                }
            }
            
            if gradeData.isEmpty {
                Text("No attempts recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    ForEach(gradeData) { data in
                        // Always add a point at 0 so the grade appears on axis
                        BarMark(
                            x: .value("Zero", 0),
                            y: .value("Grade", data.grade)
                        )
                        .foregroundStyle(.clear)
                        
                        // Falls (red)
                        if data.fallCount > 0 {
                            BarMark(
                                x: .value("Count", data.fallCount),
                                y: .value("Grade", data.grade)
                            )
                            .foregroundStyle(Color.red.opacity(0.6))
                        }
                        
                        // Topped (orange)
                        if data.toppedCount > 0 {
                            BarMark(
                                x: .value("Count", data.toppedCount),
                                y: .value("Grade", data.grade)
                            )
                            .foregroundStyle(Color.orange.opacity(0.7))
                        }
                        
                        // Sends (green)
                        if data.sendCount > 0 {
                            BarMark(
                                x: .value("Count", data.sendCount),
                                y: .value("Grade", data.grade)
                            )
                            .foregroundStyle(Color.green.opacity(0.7))
                        }
                        
                        // Flashes (yellow)
                        if data.flashCount > 0 {
                            BarMark(
                                x: .value("Count", data.flashCount),
                                y: .value("Grade", data.grade)
                            )
                            .foregroundStyle(Color.yellow.opacity(0.9))
                        }
                    }
                }
                .chartYScale(domain: allGradeLabels)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel {
                            if let count = value.as(Int.self) {
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel(horizontalSpacing: 8) {
                            if let grade = value.as(String.self) {
                                Text(grade)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: max(150, CGFloat(gradeData.count) * 24))
            }
        }
    }
    
    @ViewBuilder
    private func legendItem(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    let session = Session.preview
    GradePyramidChartView(session: session, currentGradeSystem: .vscale)
        .padding()
}
