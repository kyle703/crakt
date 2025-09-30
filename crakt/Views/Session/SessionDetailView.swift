//
//  SessionDetailView.swift
//  crakt
//
//  Created by Kyle Thompson on 3/25/24.
//  Enhanced for climbing coach analytics and performance insights

import SwiftUI
import Foundation
import SwiftData

// MARK: - Timeline Integration
// Note: SessionTimelineView is imported automatically via the same module

class SessionDetailViewModel: ObservableObject {
    var session: Session

    init(session: Session) {
        self.session = session
    }

    // MARK: - Session Overview
    var sessionDateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • h:mm a"

        let startTime = formatter.string(from: session.startDate)

        if let endDate = session.endDate {
            formatter.dateFormat = "h:mm a"
            let endTime = formatter.string(from: endDate)
            return "\(startTime) – \(endTime)"
        } else {
            return startTime
        }
    }

    var elapsedTimeText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(session.elapsedTime)) ?? "N/A"
    }

    var sessionStatusText: String {
        switch session.status {
        case .active: return "Active Session"
        case .complete: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    // MARK: - Performance Metrics
    var totalAttempts: Int {
        session.allAttempts.count
    }

    var successfulAttempts: Int {
        let attempts = session.allAttempts
        let successful = attempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }
        return successful.count
    }

    var successRate: Double {
        totalAttempts > 0 ? Double(successfulAttempts) / Double(totalAttempts) : 0.0
    }

    var flashRate: Double {
        let attempts = session.allAttempts
        let flashAttempts = attempts.filter { $0.status == .flash }.count
        return totalAttempts > 0 ? Double(flashAttempts) / Double(totalAttempts) : 0.0
    }

    var averageAttemptsPerRoute: Double {
        let routesWithAttempts = session.routes.filter { !$0.attempts.isEmpty }.count
        return routesWithAttempts > 0 ? Double(totalAttempts) / Double(routesWithAttempts) : 0.0
    }

    var uniqueGradesAttempted: Int {
        Set(session.routes.compactMap { $0.grade }).count
    }

    // MARK: - Time Analysis
    var averageRestTime: TimeInterval? {
        let completedAttempts = session.allAttempts.sorted { $0.date < $1.date }
        guard completedAttempts.count > 1 else { return nil }

        var restPeriods: [TimeInterval] = []
        for i in 1..<completedAttempts.count {
            let restTime = completedAttempts[i].date.timeIntervalSince(completedAttempts[i-1].date)
            restPeriods.append(restTime)
        }

        return restPeriods.isEmpty ? nil : restPeriods.reduce(0, +) / Double(restPeriods.count)
    }

    var activeClimbingTime: TimeInterval {
        // Use session elapsed time minus estimated rest periods for active climbing time
        let attempts = session.allAttempts.sorted { $0.date < $1.date }
        guard attempts.count > 1 else { return session.elapsedTime }

        let estimatedRestTime = Double(attempts.count - 1) * (averageRestTime ?? 180.0) // Default 3min rest
        return max(0, session.elapsedTime - estimatedRestTime)
    }

    // MARK: - Grade Analysis
    var gradeProgression: [String] {
        session.routes
            .filter { !$0.attempts.isEmpty }
            .sorted { ($0.firstAttemptDate ?? Date.distantPast) < ($1.firstAttemptDate ?? Date.distantPast) }
            .compactMap { $0.grade }
    }

    var hardestGradeSent: String? {
        let attempts = session.allAttempts
        let successfulAttempts = attempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }
        let grades = successfulAttempts.compactMap { $0.route?.grade }
        return grades.max { gradeIndex(for: $0) < gradeIndex(for: $1) }
    }

    private func gradeIndex(for grade: String) -> Int {
        // Simplified grade indexing - would need proper grade system integration
        return grade.hashValue
    }

    // MARK: - Workouts
    var completedWorkouts: [Workout] {
        session.workouts.filter { $0.isCompleted }
    }

    var workoutCompletionRate: Double {
        let totalWorkouts = session.workouts.count
        return totalWorkouts > 0 ? Double(completedWorkouts.count) / Double(totalWorkouts) : 0.0
    }
}

// MARK: - Performance Overview Components
struct SessionOverviewCard: View {
    let viewModel: SessionDetailViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Session Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(viewModel.sessionStatusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            // Key Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Duration",
                    value: viewModel.elapsedTimeText,
                    icon: "clock.fill",
                    color: .blue
                )

                MetricCard(
                    title: "Success Rate",
                    value: String(format: "%.1f%%", viewModel.successRate * 100),
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                MetricCard(
                    title: "Total Attempts",
                    value: "\(viewModel.totalAttempts)",
                    icon: "arrow.up.circle.fill",
                    color: .orange
                )

                MetricCard(
                    title: "Avg/Routes",
                    value: String(format: "%.1f", viewModel.averageAttemptsPerRoute),
                    icon: "target",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: Trend?

    enum Trend {
        case up, down, neutral
    }

    init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = nil
        self.icon = icon
        self.color = color
        self.trend = nil
    }

    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color, trend: Trend? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(spacing: 8) {
            // Icon with optional trend indicator
            ZStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                if let trend = trend {
                    VStack {
                        if trend == .up {
                            Image(systemName: "arrow.up")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .offset(y: -12)
                        } else if trend == .down {
                            Image(systemName: "arrow.down")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .offset(y: -12)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 24)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PerformanceInsightsCard: View {
    let viewModel: SessionDetailViewModel

    // MARK: - Recommendations Engine
    private var recommendations: [Recommendation] {
        var recs: [Recommendation] = []

        // Success rate analysis
        if viewModel.successRate > 0.8 {
            recs.append(Recommendation(
                type: .strength,
                title: "Outstanding Performance",
                description: "Exceptional success rate - continue current training approach",
                action: "Consider increasing difficulty for next session",
                priority: .high
            ))
        } else if viewModel.successRate > 0.6 {
            recs.append(Recommendation(
                type: .improvement,
                title: "Solid Foundation",
                description: "Good success rate with room for refinement",
                action: "Focus on beta refinement and sequence optimization",
                priority: .medium
            ))
        } else if viewModel.successRate < 0.4 {
            recs.append(Recommendation(
                type: .critical,
                title: "Technical Focus Needed",
                description: "Lower success rate suggests technical challenges",
                action: "Break down moves, work on individual techniques",
                priority: .high
            ))
        }

        // Attempt efficiency analysis
        if viewModel.averageAttemptsPerRoute > 4.0 {
            recs.append(Recommendation(
                type: .efficiency,
                title: "Efficiency Opportunity",
                description: String(format: "%.1f attempts per route - significant improvement potential", viewModel.averageAttemptsPerRoute),
                action: "Pre-climb visualization and beta collection",
                priority: .high
            ))
        } else if viewModel.averageAttemptsPerRoute > 2.5 {
            recs.append(Recommendation(
                type: .efficiency,
                title: "Moderate Efficiency",
                description: String(format: "%.1f attempts per route - good but improvable", viewModel.averageAttemptsPerRoute),
                action: "Practice route reading and sequence planning",
                priority: .medium
            ))
        }

        // Rest and pacing analysis
        if let restTime = viewModel.averageRestTime {
            if restTime < 90 {
                recs.append(Recommendation(
                    type: .recovery,
                    title: "Rest Period Optimization",
                    description: String(format: "%.0f sec average rest - may be too short for recovery", restTime),
                    action: "Increase rest to 2-3 minutes between attempts",
                    priority: .medium
                ))
            } else if restTime > 300 {
                recs.append(Recommendation(
                    type: .pacing,
                    title: "Pacing Efficiency",
                    description: String(format: "%.0f sec average rest - consider more consistent rhythm", restTime),
                    action: "Maintain steady rest periods for better flow",
                    priority: .low
                ))
            }
        }

        // Flash rate analysis
        if viewModel.flashRate > 0.4 {
            recs.append(Recommendation(
                type: .strength,
                title: "Excellent Onsight Ability",
                description: String(format: "%.1f%% flash rate demonstrates strong route reading", viewModel.flashRate * 100),
                action: "Continue building onsight confidence",
                priority: .medium
            ))
        } else if viewModel.flashRate < 0.1 {
            recs.append(Recommendation(
                type: .improvement,
                title: "Onsight Development",
                description: "Low flash rate suggests opportunity for improvement",
                action: "Practice route preview and first-attempt strategy",
                priority: .medium
            ))
        }

        // Grade range analysis
        if viewModel.uniqueGradesAttempted < 3 {
            recs.append(Recommendation(
                type: .progression,
                title: "Grade Diversity",
                description: "Limited grade range attempted",
                action: "Include more grade variety for balanced development",
                priority: .low
            ))
        }

        return recs.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Coach Recommendations")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("\(recommendations.count) insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(spacing: 12) {
                ForEach(recommendations.prefix(4), id: \.id) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }

                if recommendations.count > 4 {
                    Text("+\(recommendations.count - 4) more insights available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}


// MARK: - Recommendation System
struct Recommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let action: String
    let priority: RecommendationPriority

    var icon: String {
        switch type {
        case .strength: return "star.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .efficiency: return "target"
        case .recovery: return "bed.double.fill"
        case .pacing: return "timer"
        case .progression: return "chart.line.uptrend.xyaxis"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

enum RecommendationType {
    case strength      // What they're doing well
    case improvement   // Areas for general improvement
    case efficiency    // Attempt efficiency and technique
    case recovery      // Rest and recovery optimization
    case pacing        // Session flow and timing
    case progression   // Grade and difficulty progression
    case critical      // Important issues needing attention
}

enum RecommendationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
}

struct RecommendationRow: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: recommendation.icon)
                    .foregroundColor(recommendation.color)
                    .frame(width: 20, height: 20)

                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                // Priority indicator
                Circle()
                    .fill(recommendation.color.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(recommendation.color)
                            .frame(width: 4, height: 4)
                    )
            }

            Text(recommendation.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text(recommendation.action)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(recommendation.color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SessionDetailView: View {
    @StateObject private var viewModel: SessionDetailViewModel

    init(session: Session) {
        _viewModel = StateObject(wrappedValue: SessionDetailViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(viewModel.sessionDateRangeText)
                        .font(.title3)

                    if let gymName = viewModel.session.gymName {
                        Text(gymName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Performance Overview
                SessionOverviewCard(viewModel: viewModel)
                    .padding(.horizontal)

                // Performance Insights
                PerformanceInsightsCard(viewModel: viewModel)
                    .padding(.horizontal)

                // Existing Charts
                VStack(alignment: .leading) {
                    HStack {
                        Text("Analytics")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        NavigationLink(destination: PerformanceAnalyticsView(session: viewModel.session)) {
                            Text("View Details")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    SessionChartsControllerView(session: viewModel.session)
                }

                // Workouts Section
                if !viewModel.completedWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Workouts Completed")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(viewModel.completedWorkouts, id: \.id) { workout in
                                WorkoutSummaryCard(workout: workout)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Session Timeline
                VStack(alignment: .leading) {
                    Text("Session Flow")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    SessionTimelineView(session: viewModel.session)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}
