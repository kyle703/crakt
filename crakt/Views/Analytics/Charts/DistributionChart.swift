//
//  DistributionChart.swift
//  crakt
//
//  Created by Kyle Thompson on 12/10/24.
//

import SwiftUI
// import Charts // Temporarily disabled to avoid framework dependency issues

struct DistributionChart: View {
    let sessions: [Session]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // Distribution bars
                HStack(spacing: 8) {
                    ForEach(getDistributionData(), id: \.band) { data in
                        VStack(spacing: 4) {
                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getColorForBand(data.band))
                                .frame(height: max(4, geometry.size.height * 0.7 * CGFloat(data.percentage) / 100))
                                .frame(width: 40)

                            // Label
                            Text(data.band)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            // Percentage
                            Text(String(format: "%.1f%%", data.percentage))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func getDistributionData() -> [(band: String, percentage: Double)] {
        let distribution = GlobalAnalytics.getGradeDistribution(sessions: sessions)
        return distribution.map { dist in
            (band: dist.band, percentage: dist.percentage)
        }
    }

    private func getColorForBand(_ band: String) -> Color {
        switch band {
        case "V0-V2":
            return .green
        case "V3-V5":
            return .blue
        case "V6+":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    DistributionChart(sessions: [])
        .frame(height: 200)
        .padding()
}
