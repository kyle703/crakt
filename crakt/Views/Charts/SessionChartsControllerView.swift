//
//  SessionChartsControllerView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI
import SwiftData

struct SessionChartsControllerView: View {
    var session: Session

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Computed Metrics
    private var successRate: Double {
        let attempts = session.allAttempts
        guard !attempts.isEmpty else { return 0 }
        let successful = attempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }
        return Double(successful.count) / Double(attempts.count)
    }

    private var totalClimbingTime: TimeInterval {
        // Use session elapsed time minus estimated rest periods for active climbing time
        let attempts = session.allAttempts.sorted { $0.date < $1.date }
        guard attempts.count > 1 else { return session.elapsedTime }

        let estimatedRestTime = Double(attempts.count - 1) * 180.0 // Default 3min rest
        return max(0, session.elapsedTime - estimatedRestTime)
    }

    private var hardestGradeSent: String? {
        // Use session's built-in method which already handles gradeDescription
        return session.hardestGradeSent
    }

    private var averageAttemptsPerRoute: Double {
        let routesWithAttempts = session.routes.filter { !$0.attempts.isEmpty }
        guard !routesWithAttempts.isEmpty else { return 0 }
        let totalAttempts = routesWithAttempts.reduce(0) { $0 + $1.attempts.count }
        return Double(totalAttempts) / Double(routesWithAttempts.count)
    }

    private var gradeConsistency: Double {
        let attempts = session.allAttempts
        let successfulByGrade = Dictionary(grouping: attempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }) { $0.route?.grade }
        let rates = successfulByGrade.compactMapValues { attempts -> Double? in
            let total = session.allAttempts.filter { $0.route?.grade == attempts.first?.route?.grade }.count
            return total > 0 ? Double(attempts.count) / Double(total) : nil
        }.values

        guard !rates.isEmpty else { return 0 }
        let avg = rates.reduce(0, +) / Double(rates.count)
        let variance = rates.map { pow($0 - avg, 2) }.reduce(0, +) / Double(rates.count)
        return 1.0 - min(sqrt(variance) / max(avg, 0.001), 1.0)
    }

    private var sessionDuration: TimeInterval {
        guard let end = session.endDate else { return 0 }
        return end.timeIntervalSince(session.startDate)
    }

    private func gradeIndex(for grade: String) -> Int {
        // Simplified grade indexing - would need proper grade system integration
        return grade.hashValue
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0m"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Quick Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Key performance metrics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                NavigationLink(destination: PerformanceAnalyticsView(session: session)) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Metric Cards Grid
            LazyVGrid(columns: columns, spacing: 16) {
                // Success Rate
                NavigationLink(destination: PerformanceAnalyticsView(session: session)) {
                    MetricCard(
                        title: "Success Rate",
                        value: String(format: "%.1f%%", successRate * 100),
                        subtitle: "Overall performance",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        trend: successRate > 0.5 ? .up : .down
                    )
                }

                // Climbing Time
                NavigationLink(destination: PerformanceAnalyticsView(session: session)) {
                    MetricCard(
                        title: "Climbing Time",
                        value: formatDuration(totalClimbingTime),
                        subtitle: "Active climbing",
                        icon: "clock.fill",
                        color: .blue,
                        trend: totalClimbingTime > 1800 ? .up : .neutral // 30+ min is good
                    )
                }

                // Hardest Grade
                NavigationLink(destination: PerformanceAnalyticsView(session: session)) {
                    MetricCard(
                        title: "Hardest Send",
                        value: hardestGradeSent ?? "N/A",
                        subtitle: "Peak achievement",
                        icon: "star.fill",
                        color: .yellow,
                        trend: hardestGradeSent != nil ? .up : .neutral
                    )
                }

                // Efficiency
                NavigationLink(destination: PerformanceAnalyticsView(session: session)) {
                    MetricCard(
                        title: "Avg Attempts",
                        value: String(format: "%.1f", averageAttemptsPerRoute),
                        subtitle: "Per route efficiency",
                        icon: "target",
                        color: .purple,
                        trend: averageAttemptsPerRoute < 3 ? .up : .down
                    )
                }

                // Consistency
                NavigationLink(destination: PerformanceAnalyticsView(session: session)) {
                    MetricCard(
                        title: "Consistency",
                        value: String(format: "%.1f%%", gradeConsistency * 100),
                        subtitle: "Performance stability",
                        icon: gradeConsistency > 0.7 ? "checkmark.circle.fill" : "arrow.left.arrow.right.circle.fill",
                        color: gradeConsistency > 0.7 ? .green : .orange,
                        trend: gradeConsistency > 0.7 ? .up : .neutral
                    )
                }

                // Session Duration
                NavigationLink(destination: PerformanceAnalyticsView(session: session)) {
                    MetricCard(
                        title: "Session Time",
                        value: formatDuration(sessionDuration),
                        subtitle: "Total duration",
                        icon: "timer",
                        color: .gray,
                        trend: .neutral
                    )
                }
            }
        }
        .padding()
    }
}







