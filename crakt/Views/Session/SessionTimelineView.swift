//
//  SessionTimelineView.swift
//  crakt
//
//  Created for climbing coach analytics - shows session flow and pacing

import SwiftUI
import SwiftData
import Charts

struct SessionTimelineView: View {
    let session: Session

    // MARK: - Timeline Data Processing
    private var timelineEvents: [TimelineEvent] {
        var events: [TimelineEvent] = []

        // Session start
        events.append(TimelineEvent(
            type: .sessionStart,
            timestamp: session.startDate,
            title: "Session Started",
            subtitle: "Warm-up and preparation"
        ))

        // Process all attempts in chronological order, inserting a route header before the first attempt of each route
        let allAttempts = session.allAttempts.sorted { $0.date < $1.date }
        var lastRouteId: UUID?

        for (index, attempt) in allAttempts.enumerated() {
            if let route = attempt.route {
                // Insert header when route changes
                if lastRouteId != route.id {
                    lastRouteId = route.id
                    // Build header title and subtitle
                    let headerTitle = route.grade ?? "Unknown Grade"
                    var headerSubtitleParts: [String] = []
                    if !route.styles.isEmpty {
                        headerSubtitleParts.append(route.styles.map { $0.description }.joined(separator: ", "))
                    }
                    if !route.experiences.isEmpty {
                        headerSubtitleParts.append(route.experiences.map { $0.description }.joined(separator: ", "))
                    }
                    let headerSubtitle = headerSubtitleParts.joined(separator: " • ")

                    events.append(TimelineEvent(
                        type: .routeHeader,
                        timestamp: attempt.date,
                        title: headerTitle,
                        subtitle: headerSubtitle.isEmpty ? "Route details" : headerSubtitle,
                        route: route,
                        attempt: nil
                    ))
                }
                events.append(TimelineEvent(
                    type: .attempt,
                    timestamp: attempt.date,
                    title: "Attempt on \(route.grade ?? "Unknown")",
                    subtitle: attempt.status.description,
                    route: route,
                    attempt: attempt
                ))
            }

            // Add rest period after attempt (except for last attempt)
            if index < allAttempts.count - 1 {
                let nextAttempt = allAttempts[index + 1]
                let restDuration = nextAttempt.date.timeIntervalSince(attempt.date)

                if restDuration > 30 { // Only show rests longer than 30 seconds
                    events.append(TimelineEvent(
                        type: .rest,
                        timestamp: attempt.date.addingTimeInterval(restDuration / 2),
                        title: "Rest Period",
                        subtitle: formatDuration(restDuration),
                        duration: restDuration
                    ))
                }
            }
        }

        // Session end
        if let endDate = session.endDate {
            events.append(TimelineEvent(
                type: .sessionEnd,
                timestamp: endDate,
                title: "Session Ended",
                subtitle: "Total: \(formatDuration(endDate.timeIntervalSince(session.startDate)))"
            ))
        }

        return events.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Session Statistics
    private var sessionStats: SessionStats {
        let attempts = session.allAttempts
        let successfulStatuses: [ClimbStatus] = [.send, .flash, .topped]
        let successful = attempts.filter { successfulStatuses.contains($0.status) }
        let successfulCount = successful.count
        let totalTime = session.endDate?.timeIntervalSince(session.startDate) ?? 0

        return SessionStats(
            totalAttempts: attempts.count,
            successfulAttempts: successfulCount,
            totalRoutes: session.routes.count,
            sessionDuration: totalTime,
            averageRestTime: calculateAverageRestTime()
        )
    }

    private func calculateAverageRestTime() -> TimeInterval? {
        let attempts = session.allAttempts.sorted { $0.date < $1.date }
        guard attempts.count > 1 else { return nil }

        var restPeriods: [TimeInterval] = []
        for i in 1..<attempts.count {
            let restTime = attempts[i].date.timeIntervalSince(attempts[i-1].date)
            if restTime > 30 && restTime < 3600 { // Reasonable rest period
                restPeriods.append(restTime)
            }
        }

        return restPeriods.isEmpty ? nil : restPeriods.reduce(0, +) / Double(restPeriods.count)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0s"
    }

    var body: some View {
            VStack(spacing: 20) {
                // Timeline Header with Stats
                VStack(alignment: .leading, spacing: 16) {
                    

                    // Quick Stats
                    HStack(spacing: 20) {
                        StatItem(
                            value: "\(sessionStats.totalAttempts)",
                            label: "Attempts",
                            icon: "arrow.up.circle.fill",
                            color: .orange
                        )

                        StatItem(
                            value: String(format: "%.1f%%", Double(sessionStats.successfulAttempts) / Double(max(sessionStats.totalAttempts, 1)) * 100),
                            label: "Success",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )

                        if let avgRest = sessionStats.averageRestTime {
                            StatItem(
                                value: formatDuration(avgRest),
                                label: "Avg Rest",
                                icon: "timer",
                                color: .blue
                            )
                        }

                        StatItem(
                            value: formatDuration(sessionStats.sessionDuration),
                            label: "Duration",
                            icon: "clock.fill",
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal)

                // Timeline
                VStack(spacing: 0) {
                    ForEach(timelineEvents.indices, id: \.self) { index in
                        TimelineRow(event: timelineEvents[index], isLast: index == timelineEvents.count - 1)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let type: TimelineEventType
    let timestamp: Date
    let title: String
    let subtitle: String
    var route: Route?
    var attempt: RouteAttempt?
    var duration: TimeInterval?

    var timeSinceSessionStart: TimeInterval {
        // This would need to be calculated relative to session start
        return timestamp.timeIntervalSince1970
    }
}

enum TimelineEventType {
    case sessionStart
    case routeHeader
    case attempt
    case rest
    case sessionEnd

    var color: Color {
        switch self {
        case .sessionStart: return .green
        case .routeHeader: return .blue
        case .attempt: return .blue
        case .rest: return .orange
        case .sessionEnd: return .red
        }
    }

    var icon: String {
        switch self {
        case .sessionStart: return "play.circle.fill"
        case .routeHeader: return "tag.fill"
        case .attempt: return "figure.climbing"
        case .rest: return "pause.circle.fill"
        case .sessionEnd: return "stop.circle.fill"
        }
    }
}

struct TimelineRow: View {
    let event: TimelineEvent
    let isLast: Bool

    @State private var isExpanded: Bool = false

    private func styleSummary(route: Route) -> String {
        var parts: [String] = []
        if !route.styles.isEmpty {
            parts.append(route.styles.map { $0.description }.joined(separator: ", "))
        }
        if !route.experiences.isEmpty {
            parts.append(route.experiences.map { $0.description }.joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0s"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            ZStack {
                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 60)
                        .offset(y: 30)
                }

                // Event dot
                Circle()
                    .fill(event.type == .routeHeader ? Color.gray.opacity(0.4) : event.type.color)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Image(systemName: event.type.icon)
                            .font(.system(size: 6))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 12)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Time and title
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(event.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if event.type != .routeHeader {
                        Text(formatTime(event.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }

                // Route header details (compact, divider-like)
                if event.type == .routeHeader, let route = event.route {
                    VStack(alignment: .leading, spacing: 8) {
                        // Line 1: Grade chip + route experience icons (including difficulty rating)
                        HStack(alignment: .center, spacing: 8) {
                            // Grade chip
                            Text(route.grade ?? "Unknown")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(route.gradeColor.opacity(0.2))
                                .cornerRadius(4)

                            // Experience icons row (decorative only)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    if let latestRating = route.attempts.sorted(by: { $0.date > $1.date }).first?.difficultyRating {
                                        Image(systemName: latestRating.iconName)
                                            .foregroundColor(latestRating.color)
                                            .font(.caption2)
                                            .padding(4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(latestRating.color.opacity(0.4), lineWidth: 1)
                                            )
                                    }

                                    ForEach(route.experiences, id: \.self) { exp in
                                        Image(systemName: exp.iconName)
                                            .foregroundColor(exp.color)
                                            .font(.caption2)
                                            .padding(4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(exp.color.opacity(0.4), lineWidth: 1)
                                            )
                                    }
                                }
                            }

                            Spacer(minLength: 0)
                        }

                        // Line 2: outlined route style chips only
                        if !route.styles.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(route.styles, id: \.self) { style in
                                        Text(style.description)
                                            .font(.caption2)
                                            .foregroundColor(style.color)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(style.color, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }

                // Route details for attempts (lean)
                if event.type == .attempt, let route = event.route, let attempt = event.attempt {
                    VStack(alignment: .leading, spacing: 6) {
                        // Attempt status only; grade is shown in header
                        HStack(spacing: 6) {
                            Image(systemName: attempt.status.iconName)
                                .foregroundColor(attempt.status.color)
                                .font(.caption)
                            Text(attempt.status.description)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        // Minimal metadata (consider showing only on last attempt; for now keep light)
                        if let firstAttemptDate = route.firstAttemptDate {
                            Text("Route time: \(formatDuration(attempt.date.timeIntervalSince(firstAttemptDate)))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(6)
                }

                // Rest period details
                if event.type == .rest, let _ = event.duration {
                    HStack {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Resting...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SessionStats {
    let totalAttempts: Int
    let successfulAttempts: Int
    let totalRoutes: Int
    let sessionDuration: TimeInterval
    let averageRestTime: TimeInterval?
}

struct SessionTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        SessionTimelineView(session: Session.preview)
            .modelContainer(for: [Route.self, RouteAttempt.self, Session.self, User.self])
    }
}
