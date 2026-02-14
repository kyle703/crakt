//
//  VolumeChart.swift
//  crakt
//
//  Created by Kyle Thompson on 12/10/24.
//

import SwiftUI
// import Charts // Temporarily disabled to avoid framework dependency issues

struct VolumeChart: View {
    let sessions: [Session]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // Volume bars
                HStack(spacing: 4) {
                    ForEach(getVolumeData(), id: \.id) { data in
                        VStack(spacing: 4) {
                            ZStack(alignment: .bottom) {
                                // Attempts bar (background)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(height: max(4, geometry.size.height * 0.6 * CGFloat(data.attempts) / maxVolume()))

                                // Sends bar (foreground)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.green)
                                    .frame(height: max(4, geometry.size.height * 0.6 * CGFloat(data.sends) / maxVolume()))
                            }
                            .frame(maxWidth: .infinity)

                            // Label
                            Text(data.weekLabel)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 12, height: 8)
                        Text("Attempts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 12, height: 8)
                        Text("Sends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func getVolumeData() -> [(id: String, week: Date, attempts: Int, sends: Int, weekLabel: String)] {
        let weeklyVolume = GlobalAnalytics.getWeeklyVolume(sessions: sessions)
        return weeklyVolume.map { volume in
            let weekNumber = Calendar.current.component(.weekOfYear, from: volume.week)
            return (id: volume.week.description, week: volume.week, attempts: volume.attempts, sends: volume.sends, weekLabel: "W\(weekNumber)")
        }
    }

    private func maxVolume() -> Double {
        let data = getVolumeData()
        let maxAttempts = data.map { Double($0.attempts) }.max() ?? 1.0
        let maxSends = data.map { Double($0.sends) }.max() ?? 1.0
        return max(maxAttempts, maxSends)
    }

}

#Preview {
    VolumeChart(sessions: [])
        .frame(height: 200)
        .padding()
}
