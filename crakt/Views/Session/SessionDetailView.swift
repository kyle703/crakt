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

    var sessionSummaryLine: String {
        let location = session.gymName ?? "your gym"
        return "You climbed at \(location) for \(elapsedTimeText). Here's how it went."
    }

    var sessionDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: session.startDate)
    }

    var sessionTimeRangeText: String? {
        guard let endDate = session.endDate else { return nil }
        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "h:mm a"

        let startHour = Calendar.current.component(.hour, from: session.startDate)
        let endHour = Calendar.current.component(.hour, from: endDate)
        let samePeriod = (startHour < 12) == (endHour < 12)

        startFormatter.dateFormat = samePeriod ? "h:mm" : "h:mm a"

        return "\(startFormatter.string(from: session.startDate)) – \(endFormatter.string(from: endDate))"
    }

    // MARK: - Climb Type Breakdown

    var hasBoulders: Bool {
        session.routes.contains { $0.climbType == .boulder && !$0.attempts.isEmpty }
    }

    var hasRopes: Bool {
        session.routes.contains { $0.climbType.isRopes && !$0.attempts.isEmpty }
    }

    var boulderSends: Int {
        session.routes.filter { $0.climbType == .boulder }
            .flatMap { $0.attempts }
            .filter { $0.status.isSend }
            .count
    }

    var boulderFalls: Int {
        session.routes.filter { $0.climbType == .boulder }
            .flatMap { $0.attempts }
            .filter { !$0.status.isSend }
            .count
    }

    var ropeSends: Int {
        session.routes.filter { $0.climbType.isRopes }
            .flatMap { $0.attempts }
            .filter { $0.status.isSend }
            .count
    }

    var ropeFalls: Int {
        session.routes.filter { $0.climbType.isRopes }
            .flatMap { $0.attempts }
            .filter { !$0.status.isSend }
            .count
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

    var attemptsPerRouteText: String {
        totalAttempts == 0 ? "—" : String(format: "%.1f", averageAttemptsPerRoute)
    }

    var uniqueGradesAttempted: Int {
        Set(session.routes.compactMap { $0.grade }).count
    }

    var hardestSendText: String {
        hardestGradeSent ?? "—"
    }

    var flashRateText: String {
        String(format: "%.0f%% flash rate", flashRate * 100)
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

    var activeClimbingTimeText: String {
        format(duration: activeClimbingTime)
    }

    var averageRestText: String {
        guard let rest = averageRestTime else { return "No rest data" }
        return "\(format(duration: rest)) avg rest"
    }

    var restToClimbRatioText: String {
        guard let rest = averageRestTime else { return "Balanced pacing" }
        let attemptsCount = max(totalAttempts, 1)
        let climbTimePerAttempt = attemptsCount > 0 ? activeClimbingTime / Double(attemptsCount) : 0
        guard climbTimePerAttempt > 0 else { return "Balanced pacing" }
        let ratio = rest / max(climbTimePerAttempt, 1)
        if ratio > 2 {
            return "Long rests"
        } else if ratio < 0.5 {
            return "Fast pacing"
        }
        return "Balanced pacing"
    }

    // MARK: - Grade Analysis
    var gradeProgression: [String] {
        session.routes
            .filter { !$0.attempts.isEmpty }
            .sorted { ($0.firstAttemptDate ?? Date.distantPast) < ($1.firstAttemptDate ?? Date.distantPast) }
            .compactMap { $0.grade }
    }

    var hardestGradeSent: String? {
        // Use session's built-in method which already handles gradeDescription
        return session.hardestGradeSent
    }

    var gradeDistribution: [(grade: String, count: Int)] {
        // Use gradeDescription to avoid UUIDs
        var gradeMap: [String: Int] = [:]
        for route in session.routes {
            guard let gradeLabel = route.gradeDescription ?? route.grade else { continue }
            gradeMap[gradeLabel, default: 0] += 1
        }
        return gradeMap
            .map { ($0.key, $0.value) }
            .sorted { gradeIndex(for: $0.grade) > gradeIndex(for: $1.grade) }
    }

    var successRateByGrade: [(grade: String, rate: Double)] {
        var map: [String: (success: Int, total: Int)] = [:]
        for attempt in session.allAttempts {
            guard let route = attempt.route,
                  let gradeLabel = route.gradeDescription ?? route.grade else { continue }
            var entry = map[gradeLabel] ?? (0, 0)
            entry.total += 1
            if attempt.status == .send || attempt.status == .flash || attempt.status == .topped {
                entry.success += 1
            }
            map[gradeLabel] = entry
        }
        return map.map { gradeLabel, counts in
            let rate = counts.total > 0 ? Double(counts.success) / Double(counts.total) : 0
            return (gradeLabel, rate)
        }
        .sorted { gradeIndex(for: $0.grade) > gradeIndex(for: $1.grade) }
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

    // MARK: - Helpers
    private func format(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

// MARK: - Performance Overview Components
struct SessionOverviewCard: View {
    let viewModel: SessionDetailViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            SendFallBreakdownCard(viewModel: viewModel)

            MetricCard(
                title: "Send rate",
                value: String(format: "%.0f%%", viewModel.successRate * 100),
                subtitle: "Routes topped",
                icon: "checkmark.circle.fill",
                color: .green
            )

            MetricCard(
                title: "Peak grade",
                value: viewModel.hardestSendText,
                subtitle: "Hardest send",
                icon: "rosette",
                color: .orange
            )

            MetricCard(
                title: "Per-route effort",
                value: viewModel.attemptsPerRouteText,
                subtitle: "Attempts/route",
                icon: "target",
                color: .purple
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Send/Fall Breakdown Card

struct SendFallBreakdownCard: View {
    let viewModel: SessionDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                Spacer()
            }

            if viewModel.hasBoulders {
                ClimbTypeBreakdownRow(
                    label: "Boulders",
                    sends: viewModel.boulderSends,
                    falls: viewModel.boulderFalls
                )
            }

            if viewModel.hasRopes {
                ClimbTypeBreakdownRow(
                    label: "Ropes",
                    sends: viewModel.ropeSends,
                    falls: viewModel.ropeFalls
                )
            }

            if !viewModel.hasBoulders && !viewModel.hasRopes {
                Text("No routes logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Sends / Falls")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}

struct ClimbTypeBreakdownRow: View {
    let label: String
    let sends: Int
    let falls: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text("\(sends)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(falls)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(color)
                }
                Spacer()
            }

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
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}

struct PerformanceStorySection: View {
    let viewModel: SessionDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How you climbed")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Grades, send rate, and pacing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                NavigationLink(destination: PerformanceAnalyticsView(session: viewModel.session)) {
                    Label("Full analytics", systemImage: "arrow.up.right")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(14)
                }
            }

            GradeDistributionView(data: viewModel.gradeDistribution)

            SuccessRateByGradeView(data: viewModel.successRateByGrade)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

struct GradeDistributionView: View {
    let data: [(grade: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grade distribution")
                .font(.headline)
            if data.isEmpty {
                Text("No graded climbs logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                let maxCount = max(data.map { $0.count }.max() ?? 1, 1)
                VStack(spacing: 8) {
                    ForEach(data.prefix(6), id: \.grade) { entry in
                        HStack {
                            Text(entry.grade)
                                .font(.subheadline)
                                .frame(width: 60, alignment: .leading)
                            GeometryReader { proxy in
                                let width = proxy.size.width * CGFloat(entry.count) / CGFloat(maxCount)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.35))
                                    .frame(width: max(width, 4), height: 12)
                            }
                            .frame(height: 12)
                            Text("\(entry.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct SuccessRateByGradeView: View {
    let data: [(grade: String, rate: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Send rate by grade")
                .font(.headline)
            if data.isEmpty {
                Text("No attempts recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                let maxRate = max(data.map { $0.rate }.max() ?? 1, 0.01)
                VStack(spacing: 8) {
                    ForEach(data.prefix(6), id: \.grade) { entry in
                        HStack {
                            Text(entry.grade)
                                .font(.subheadline)
                                .frame(width: 60, alignment: .leading)
                            GeometryReader { proxy in
                                let width = proxy.size.width * CGFloat(entry.rate) / CGFloat(maxRate)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green.opacity(0.35))
                                    .frame(width: max(width, 4), height: 12)
                            }
                            .frame(height: 12)
                            Text(String(format: "%.0f%%", entry.rate * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
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
                title: "Send streak",
                description: String(format: "Send rate stayed at %.0f%% this session", viewModel.successRate * 100),
                action: "Add one harder route next visit",
                priority: .high
            ))
        } else if viewModel.successRate > 0.6 {
            recs.append(Recommendation(
                type: .improvement,
                title: "Solid base",
                description: "Good send rate with room to sharpen beta",
                action: "Review sequences and fine-tune footwork",
                priority: .medium
            ))
        } else if viewModel.successRate < 0.4 {
            recs.append(Recommendation(
                type: .critical,
                title: "Dial in technique",
                description: "Lower send rate hints at technical bottlenecks",
                action: "Break climbs into micro-drills before full sends",
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coach Cues")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Actionable tips for your next session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
                    Text("+\(recommendations.count - 4) more cues available")
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

    var tagTitle: String {
        switch type {
        case .strength: return "Momentum"
        case .improvement: return "Technique"
        case .efficiency: return "Efficiency"
        case .recovery: return "Recovery"
        case .pacing: return "Pacing"
        case .progression: return "Progression"
        case .critical: return "Focus"
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
                Text(recommendation.tagTitle.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(recommendation.color.opacity(0.15))
                    .foregroundColor(recommendation.color)
                    .cornerRadius(8)

                Image(systemName: recommendation.icon)
                    .foregroundColor(recommendation.color)
                    .frame(width: 20, height: 20)

                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

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

            Text(recommendation.action)
                .font(.caption)
                .foregroundColor(.blue)
                .lineLimit(2)
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
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text("Session Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        if !viewModel.sessionStatusText.isEmpty {
                            Text(viewModel.sessionStatusText)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }

                    Text(viewModel.sessionDateText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        if let timeRange = viewModel.sessionTimeRangeText {
                            Text(timeRange)
                        }
                        if viewModel.sessionTimeRangeText != nil && viewModel.session.gymName != nil {
                            Text("·")
                        }
                        if let gymName = viewModel.session.gymName {
                            Text(gymName)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Session Snapshot
                SessionOverviewCard(viewModel: viewModel)
                    .padding(.horizontal)

                PerformanceStorySection(viewModel: viewModel)
                    .padding(.horizontal)

                PerformanceInsightsCard(viewModel: viewModel)
                    .padding(.horizontal)

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
                VStack(alignment: .leading, spacing: 12) {
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
