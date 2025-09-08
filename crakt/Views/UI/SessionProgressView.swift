//
//  SessionProgressView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/27/25.
//

import SwiftUI
import SwiftData

struct SessionProgressView: View {
    let session: Session

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Session Volume Stats
                sessionVolumeSection

                // Intensity Benchmarks
                intensityBenchmarksSection

                // Efficiency Metrics
                efficiencySection

                // Volume Distribution
                volumeDistributionSection

                // Progress vs Past Sessions
                progressTrendsSection
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Session Volume Section
    private var sessionVolumeSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Session Volume", icon: "chart.bar.fill")

            HStack(spacing: 16) {
                StatCardView(
                    icon: "arrow.up.circle",
                    title: "\(session.sessionTotalAttempts)",
                    subtitle: "Total Attempts",
                    color: .blue
                )

                StatCardView(
                    icon: "checkmark.circle",
                    title: "\(session.sessionTotalSends)",
                    subtitle: "Sends",
                    color: .green
                )

                StatCardView(
                    icon: "percent",
                    title: session.formattedSuccessPercentage,
                    subtitle: "Success Rate",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Intensity Benchmarks Section
    private var intensityBenchmarksSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Intensity Benchmarks", icon: "flame.fill")

            HStack(spacing: 16) {
                if let hardestGrade = session.sessionHardestGradeSent {
                    StatCardView(
                        icon: "mountain.2.fill",
                        title: hardestGrade,
                        subtitle: "Hardest Sent",
                        color: .red
                    )
                } else {
                    StatCardView(
                        icon: "mountain.2.fill",
                        title: "—",
                        subtitle: "Hardest Sent",
                        color: .gray
                    )
                }

                if let medianGrade = session.sessionMedianGradeSent {
                    StatCardView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: medianGrade,
                        subtitle: "Median Grade",
                        color: .purple
                    )
                } else {
                    StatCardView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "—",
                        subtitle: "Median Grade",
                        color: .gray
                    )
                }
            }

            // Historical comparison (placeholder for now)
            if let hardestTrend = session.hardestGradeTrend {
                HStack(spacing: 8) {
                    Text("Today's hardest:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(hardestTrend.current ?? "—")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(hardestTrend.trend)
                        .font(.subheadline)
                        .foregroundColor(hardestTrend.trend == "↑" ? .green : hardestTrend.trend == "↓" ? .red : .gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Efficiency Section
    private var efficiencySection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Efficiency", icon: "target")

            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    StatCardView(
                        icon: "repeat",
                        title: session.formattedAttemptsPerSend,
                        subtitle: "Attempts/Send",
                        color: .blue
                    )

                    StatCardView(
                        icon: "gauge.with.dots.needle.50percent",
                        title: "2.5",
                        subtitle: "Baseline",
                        color: .gray
                    )
                }

                // Efficiency comparison
                let efficiencyChange = session.calculatePercentChange(
                    current: session.sessionAttemptsPerSend,
                    historical: 2.5
                )

                HStack(spacing: 8) {
                    Text("Efficiency vs baseline:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f attempts/send today (baseline: 2.5)", session.sessionAttemptsPerSend))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    let trend = session.calculateTrend(current: session.sessionAttemptsPerSend, historical: 2.5)
                    Text(trend)
                        .font(.subheadline)
                        .foregroundColor(trend == "↑" ? .red : trend == "↓" ? .green : .gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Volume Distribution Section
    private var volumeDistributionSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Volume Distribution", icon: "chart.pie.fill")

            VStack(spacing: 12) {
                ForEach(session.formattedGradeDistribution, id: \.band) { distribution in
                    HStack {
                        Text(distribution.band)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)

                        Text("\(distribution.attempts) attempts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(String(format: "%.1f%%", distribution.percentage))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                    .cornerRadius(3)

                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * distribution.percentage / 100.0, height: 6)
                                    .cornerRadius(3)
                            }
                        }
                        .frame(height: 6)
                        .frame(width: 60)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 4)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Progress Trends Section
    private var progressTrendsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Progress Trends", icon: "arrow.up.arrow.down")

            VStack(spacing: 12) {
                // Success percentage trend
                let successTrend = session.successPercentageTrend
                TrendRowView(
                    label: "Success Rate",
                    current: session.formattedSuccessPercentage,
                    trend: successTrend.trend,
                    change: successTrend.change
                )

                // Hardest grade trend
                if let hardestTrend = session.hardestGradeTrend {
                    TrendRowView(
                        label: "Hardest Grade",
                        current: hardestTrend.current ?? "—",
                        trend: hardestTrend.trend,
                        change: hardestTrend.change
                    )
                }

                // Median grade trend
                if let medianTrend = session.medianGradeTrend {
                    TrendRowView(
                        label: "Median Grade",
                        current: medianTrend.current ?? "—",
                        trend: medianTrend.trend,
                        change: medianTrend.change
                    )
                }

                // Personal best indicators
                if session.isHardestGradePersonalBest {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("New personal best - hardest grade!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }

                if session.isSuccessPercentagePersonalBest {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("New personal best - success rate!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primary)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

struct TrendRowView: View {
    let label: String
    let current: String
    let trend: String
    let change: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text(current)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(trend)
                .font(.subheadline)
                .foregroundColor(trend == "↑" ? .green : trend == "↓" ? .red : .gray)

            if change != 0 {
                Text(String(format: "%.1f%%", abs(change)))
                    .font(.caption)
                    .foregroundColor(change > 0 ? .green : .red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

#Preview {
    let tempContext = try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext
    let session = Session.active_preview

    return SessionProgressView(session: session)
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
}
