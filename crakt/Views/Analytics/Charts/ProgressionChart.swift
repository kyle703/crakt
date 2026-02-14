//
//  ProgressionChart.swift
//  crakt
//
//  Created by Kyle Thompson on 12/10/24.
//

import SwiftUI
// import Charts // Temporarily disabled to avoid framework dependency issues

struct ProgressionChart: View {
    let sessions: [Session]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                Path { path in
                    let step = geometry.size.height / 4
                    for i in 0...4 {
                        let y = step * CGFloat(i)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)

                // Hardest grade line
                Path { path in
                    let dataPoints = getProgressionData()
                    guard !dataPoints.isEmpty else { return }

                    let maxGrade = dataPoints.map { $0.hardestGradeDI }.max() ?? 100
                    let minGrade = dataPoints.map { $0.hardestGradeDI }.min() ?? 0
                    let gradeRange = max(maxGrade - minGrade, 20)

                    let firstPoint = dataPoints[0]
                    let x = geometry.size.width * CGFloat(0) / CGFloat(max(1, dataPoints.count - 1))
                    let y = geometry.size.height * (1.0 - CGFloat(firstPoint.hardestGradeDI - minGrade) / CGFloat(gradeRange))
                    path.move(to: CGPoint(x: x, y: y))

                    for (index, point) in dataPoints.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(1, dataPoints.count - 1))
                        let y = geometry.size.height * (1.0 - CGFloat(point.hardestGradeDI - minGrade) / CGFloat(gradeRange))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.red, lineWidth: 2)

                // Median grade line
                Path { path in
                    let dataPoints = getProgressionData()
                    guard !dataPoints.isEmpty else { return }

                    let maxGrade = dataPoints.map { $0.medianGradeDI }.max() ?? 100
                    let minGrade = dataPoints.map { $0.medianGradeDI }.min() ?? 0
                    let gradeRange = max(maxGrade - minGrade, 20)

                    let firstPoint = dataPoints[0]
                    let x = geometry.size.width * CGFloat(0) / CGFloat(max(1, dataPoints.count - 1))
                    let y = geometry.size.height * (1.0 - CGFloat(firstPoint.medianGradeDI - minGrade) / CGFloat(gradeRange))
                    path.move(to: CGPoint(x: x, y: y))

                    for (index, point) in dataPoints.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(1, dataPoints.count - 1))
                        let y = geometry.size.height * (1.0 - CGFloat(point.medianGradeDI - minGrade) / CGFloat(gradeRange))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.blue, lineWidth: 2)

                // Legend
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Hardest")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("Median")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func getProgressionData() -> [(date: Date, hardestGradeDI: Int, medianGradeDI: Int)] {
        sessions
            .filter { $0.status == .complete || $0.status == .cancelled }
            .compactMap { session in
                guard let summary = session.computeSummaryMetrics() else { return nil }
                return (date: summary.sessionDate, hardestGradeDI: summary.hardestGradeDI, medianGradeDI: summary.medianGradeDI)
            }
            .sorted { $0.date < $1.date }
            .suffix(20) // Show last 20 sessions
    }

}

#Preview {
    ProgressionChart(sessions: [])
        .frame(height: 200)
        .padding()
}
