//
//  EfficiencyChart.swift
//  crakt
//
//  Created by Kyle Thompson on 12/10/24.
//

import SwiftUI
import Charts

struct EfficiencyChart: View {
    let sessions: [Session]

    var body: some View {
        Chart {
            ForEach(getEfficiencyData().enumerated().map { ($0, $1) }, id: \.0) { index, data in
                LineMark(
                    x: .value("Session", index),
                    y: .value("Attempts/Send", data.attemptsPerSend)
                )
                .foregroundStyle(data.efficiencyColor)
                .symbol(.circle)

                AreaMark(
                    x: .value("Session", index),
                    y: .value("Attempts/Send", data.attemptsPerSend)
                )
                .foregroundStyle(data.efficiencyColor.opacity(0.2))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let attempts = value.as(Double.self) {
                        Text(String(format: "%.1f", attempts))
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                if let index = value.as(Int.self), index < getEfficiencyData().count {
                    let sessionNumber = getEfficiencyData().count - index
                    AxisValueLabel("S\(sessionNumber)")
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .frame(height: 120)
    }

    private func getEfficiencyData() -> [(attemptsPerSend: Double, date: Date, efficiencyColor: Color)] {
        let recentSessions = Array(sessions.sorted { $0.startDate < $1.startDate }.suffix(10))
        return recentSessions.compactMap { session in
            if let summary = session.computeSummaryMetrics() {
                let efficiencyColor: Color
                if summary.attemptsPerSend <= 2.0 {
                    efficiencyColor = .green
                } else if summary.attemptsPerSend <= 3.5 {
                    efficiencyColor = .yellow
                } else {
                    efficiencyColor = .red
                }

                return (attemptsPerSend: summary.attemptsPerSend, date: session.startDate, efficiencyColor: efficiencyColor)
            }
            return nil
        }
    }
}

#Preview {
    EfficiencyChart(sessions: [])
        .frame(height: 200)
        .padding()
}
