//
//  AttemptsByGradePieChartView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/10/24.
//

import SwiftUI
import Charts
import SwiftData





struct HighestGradeSuccessfullyClimbedView: View {
    var session: Session
    
    var body: some View {
        VStack {
            Text("Highest Grade Successfully Climbed")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            // Displaying the highest grade or a default message
            if let highestGrade = session.hardestGradeSent {
                Text(highestGrade)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding()
            } else {
                Text("No successful climbs recorded")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }
}






struct AttemptsByGradePieChartView: View {
    // TODO add handling to tap on a slice to get more details in the middle
    var session: Session
    var preview = false

    @State var selectedAngle: Int?
    
    /// Get color for a grade label (handles circuit grades)
    private func colorForGrade(_ gradeLabel: String) -> Color {
        // Find the route that matches this grade label
        // For circuit grades, use the route's actual color
        for route in session.routes {
            if let routeGradeLabel = route.gradeDescription, routeGradeLabel == gradeLabel {
                return route.gradeColor
            }
        }
        // Check active route too
        if let route = session.activeRoute,
           let routeGradeLabel = route.gradeDescription,
           routeGradeLabel == gradeLabel {
            return route.gradeColor
        }
        // Fallback: use a hash-based color for consistency
        return Color(hash: gradeLabel.hashValue)
    }
    
    private var selectedSector: String {
        if let angle = selectedAngle {
            return findSelectedSector(value: Int(angle)) ?? ""
        }
        return ""
    }
    
    private func findSelectedSector(value: Int) -> String? {
        var accumulatedCount = 0
        let entry = session.totalAttemptsPerGrade.first { (_, attempts) in
            accumulatedCount += attempts
            return value <= accumulatedCount
        }
        return entry?.grade
    }
    
    var body: some View {
        Chart(session.totalAttemptsPerGrade, id: \.grade) { data in
            SectorMark(
                angle: .value("Attempts", data.attempts),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .cornerRadius(5.0)
            .foregroundStyle(colorForGrade(data.grade))
            .opacity(selectedSector == data.grade ? 1.0 : 0.5)
        }
        .chartAngleSelection(value: $selectedAngle)
        .chartLegend(preview ? .hidden : .automatic)
        .aspectRatio(1, contentMode: .fit)
        .chartBackground { proxy in
            VStack(spacing: 4) {
                Text(selectedSector)
                    .font(.headline)
                // Show grade range for circuit grades if available
                if let route = session.routes.first(where: { $0.gradeDescription == selectedSector }),
                   let range = route.circuitGradeRange {
                    Text(range)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// Helper extension for consistent color generation
extension Color {
    init(hash: Int) {
        // Generate a color from a hash value
        let hue = Double(abs(hash) % 360) / 360.0
        self.init(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}






