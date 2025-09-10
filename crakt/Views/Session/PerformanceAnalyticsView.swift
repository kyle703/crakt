//
//  PerformanceAnalyticsView.swift
//  crakt
//
//  Created for climbing coach analytics - detailed performance metrics

import SwiftUI
import Charts
import SwiftData

struct PerformanceAnalyticsView: View {
    let session: Session

    // MARK: - Performance Data Processing
    private var gradeDistribution: [GradeData] {
        var distribution: [String: Int] = [:]

        for attempt in session.allAttempts {
            if let grade = attempt.route?.grade {
                distribution[grade, default: 0] += 1
            }
        }

        return distribution.map { grade, count in
            GradeData(grade: grade, attempts: count, successRate: successRateForGrade(grade))
        }.sorted { $0.attempts > $1.attempts }
    }

    private var attemptEfficiency: [EfficiencyData] {
        var efficiency: [String: (total: Int, successful: Int)] = [:]

        for attempt in session.allAttempts {
            guard let grade = attempt.route?.grade else { continue }
            let isSuccessful = attempt.status == .send || attempt.status == .flash || attempt.status == .topped

            var stats = efficiency[grade] ?? (total: 0, successful: 0)
            stats.total += 1
            if isSuccessful { stats.successful += 1 }
            efficiency[grade] = stats
        }

        return efficiency.map { grade, stats in
            EfficiencyData(
                grade: grade,
                efficiency: Double(stats.successful) / Double(stats.total),
                attempts: stats.total
            )
        }.sorted { $0.attempts > $1.attempts }
    }

    private var timeDistribution: [TimeData] {
        var hourlyAttempts: [Int: Int] = [:]

        for attempt in session.allAttempts {
            let hour = Calendar.current.component(.hour, from: attempt.date)
            hourlyAttempts[hour, default: 0] += 1
        }

        return (0...23).map { hour in
            TimeData(hour: hour, attempts: hourlyAttempts[hour] ?? 0)
        }
    }

    private var pacingData: [PacingData] {
        let attempts = session.allAttempts.sorted { $0.date < $1.date }
        guard attempts.count > 1 else { return [] }

        var pacingPoints: [PacingData] = []
        let sessionStart = session.startDate

        for (index, attempt) in attempts.enumerated() {
            let timeFromStart = attempt.date.timeIntervalSince(sessionStart)
            let success = attempt.status == .send || attempt.status == .flash || attempt.status == .topped

            pacingPoints.append(PacingData(
                attemptNumber: index + 1,
                timeFromStart: timeFromStart,
                successful: success,
                grade: attempt.route?.grade
            ))
        }

        return pacingPoints
    }

    private var sessionDuration: TimeInterval {
        guard let end = session.endDate else { return 0 }
        return end.timeIntervalSince(session.startDate)
    }

    private var activeClimbingTime: TimeInterval {
        let attempts = session.allAttempts.sorted { $0.date < $1.date }
        guard attempts.count > 1 else { return 0 }

        let totalSpan = attempts.last!.date.timeIntervalSince(attempts.first!.date)
        let estimatedRestTime = Double(attempts.count - 1) * 180.0 // Default 3min rest
        return max(0, totalSpan - estimatedRestTime)
    }

    private var averageAttemptsPerRoute: Double {
        let routesWithAttempts = session.routes.filter { !$0.attempts.isEmpty }
        guard !routesWithAttempts.isEmpty else { return 0 }
        let totalAttempts = routesWithAttempts.reduce(0) { $0 + $1.attempts.count }
        return Double(totalAttempts) / Double(routesWithAttempts.count)
    }

    private func successRateForGrade(_ grade: String) -> Double {
        let gradeAttempts = session.allAttempts.filter { $0.route?.grade == grade }
        let successful = gradeAttempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }
        let successfulCount = successful.count
        return gradeAttempts.isEmpty ? 0 : Double(successfulCount) / Double(gradeAttempts.count)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0m"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Performance Analytics")
                    .font(.title2)
                    .fontWeight(.bold)

                // Grade Distribution Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Grade Distribution")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Chart(gradeDistribution.prefix(8), id: \.grade) { data in
                        BarMark(
                            x: .value("Attempts", data.attempts),
                            y: .value("Grade", data.grade)
                        )
                        .foregroundStyle(Color.blue.opacity(0.7))
                        .annotation(position: .trailing) {
                            Text("\(data.attempts)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Attempt Efficiency Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Success Rate by Grade")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Chart(attemptEfficiency.prefix(8), id: \.grade) { data in
                        BarMark(
                            x: .value("Success Rate", data.efficiency),
                            y: .value("Grade", data.grade)
                        )
                        .foregroundStyle(Color.green.opacity(0.7))
                        .annotation(position: .trailing) {
                            Text(String(format: "%.1f%%", data.efficiency * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                Text(String(format: "%.0f%%", value.as(Double.self) ?? 0 * 100))
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Session Pacing Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Pacing")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Chart(pacingData, id: \.attemptNumber) { data in
                        PointMark(
                            x: .value("Attempt", data.attemptNumber),
                            y: .value("Time (minutes)", data.timeFromStart / 60)
                        )
                        .foregroundStyle(data.successful ? Color.green : Color.red)
                        .symbol(data.successful ? Circle() : Circle())
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                Text(String(format: "%.0fm", value.as(Double.self) ?? 0))
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Session Time Analysis
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Time Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 20) {
                        // Session Duration
                        VStack(spacing: 8) {
                            Text("Total Session")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDuration(sessionDuration))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()

                        // Active Climbing Time
                        VStack(spacing: 8) {
                            Text("Active Climbing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDuration(activeClimbingTime))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()

                        // Average Attempts per Route
                        VStack(spacing: 8) {
                            Text("Avg Attempts/Route")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", averageAttemptsPerRoute))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Time Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity by Hour")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Chart(timeDistribution, id: \.hour) { data in
                        BarMark(
                            x: .value("Hour", data.hour),
                            y: .value("Attempts", data.attempts)
                        )
                        .foregroundStyle(Color.purple.opacity(0.7))
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 4)) { value in
                            AxisValueLabel {
                                Text(String(format: "%02d:00", value.as(Int.self) ?? 0))
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Performance Insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Insights")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        // Peak performance grade
                        if let peakGrade = attemptEfficiency.max(by: { $0.efficiency < $1.efficiency }) {
                            InsightCard(
                                icon: "star.fill",
                                color: .yellow,
                                title: "Peak Performance",
                                description: "Best success rate on \(peakGrade.grade) (\(Int(peakGrade.efficiency * 100))%)"
                            )
                        }

                        // Most attempted grade
                        if let mostAttempted = gradeDistribution.first {
                            InsightCard(
                                icon: "target",
                                color: .blue,
                                title: "Focus Grade",
                                description: "\(mostAttempted.attempts) attempts on \(mostAttempted.grade)"
                            )
                        }

                        // Session consistency
                        let successRates = attemptEfficiency.map { $0.efficiency }
                        if successRates.count > 1 {
                            let avgSuccess = successRates.reduce(0, +) / Double(successRates.count)
                            let variance = successRates.map { pow($0 - avgSuccess, 2) }.reduce(0, +) / Double(successRates.count)
                            let consistency = 1.0 - min(sqrt(variance) / avgSuccess, 1.0)

                            InsightCard(
                                icon: consistency > 0.7 ? "checkmark.circle.fill" : "arrow.left.arrow.right.circle.fill",
                                color: consistency > 0.7 ? .green : .orange,
                                title: "Consistency",
                                description: consistency > 0.7 ? "Consistent performance across grades" : "Variable success rates - focus on technique"
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Data Models
struct GradeData: Identifiable {
    let id = UUID()
    let grade: String
    let attempts: Int
    let successRate: Double
}

struct EfficiencyData: Identifiable {
    let id = UUID()
    let grade: String
    let efficiency: Double
    let attempts: Int
}

struct TimeData: Identifiable {
    let id = UUID()
    let hour: Int
    let attempts: Int
}

struct PacingData: Identifiable {
    let id = UUID()
    let attemptNumber: Int
    let timeFromStart: TimeInterval
    let successful: Bool
    let grade: String?
}

struct InsightCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PerformanceAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceAnalyticsView(session: Session.preview)
            .modelContainer(for: [Route.self, RouteAttempt.self, Session.self, User.self])
    }
}
