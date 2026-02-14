//
//  GlobalSessionsView.swift
//  crakt
//
//  Created by Kyle Thompson on 12/10/24.
//

import SwiftUI
import SwiftData
import Charts

struct GlobalSessionsView: View {
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 24) {
                        heroSection
                        scoreRow
                        trendsSection
                        focusCardsSection
                        insightsSection
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.climbing")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("No climbs yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start a session or find a gym to see your lifetime trends.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                NavigationLink(destination: SessionConfigView()) {
                    Text("Start Session")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                NavigationLink(destination: GymFinderView()) {
                    Text("Find a Gym")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Hero & Scores

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Momentum")
                .font(.title2)
                .fontWeight(.bold)
            Text(heroSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HeroTrendCard(
                title: "Momentum trend",
                sparkline: momentumSparkline,
                currentValue: String(format: "%.0f", momentumScore),
                deltaText: momentumDeltaText
            )
        }
        .padding(.horizontal)
    }

    private var scoreRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ScoreCard(
                    title: "Momentum",
                    value: momentumScoreText,
                    subtitle: momentumDeltaText,
                    color: .blue,
                    icon: "arrow.triangle.2.circlepath",
                    isDisabled: !hasSufficientMomentumData
                )
                ScoreCard(
                    title: "Consistency",
                    value: consistencyScoreText,
                    subtitle: consistencyDetail,
                    color: .green,
                    icon: "waveform.path.ecg",
                    isDisabled: !hasSufficientConsistencyData
                )
                ScoreCard(
                    title: "Session streak",
                    value: "\(streakCount)",
                    subtitle: streakSubtitle,
                    color: .orange,
                    icon: "flame.fill"
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Trends Section

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trends")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("Last 12 weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    TrendCard(title: "Grade ladder", subtitle: "Hardest & median", chart: AnyView(GradeProgressionChart(sessions: sessions).frame(height: 140)))
                    TrendCard(title: "Send rate", subtitle: "Sends & flash", chart: AnyView(EfficiencyChart(sessions: sessions).frame(height: 140)))
                    TrendCard(title: "Weekly volume", subtitle: "Attempts by week", chart: AnyView(VolumeBarChart(sessions: sessions).frame(height: 140)))
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Focus Section

    private var focusCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Focus areas")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                FocusCard(
                    icon: "rectangle.3.group.bubble.left.fill",
                    title: "Grade variety",
                    detail: varietyDetail,
                    action: "Add 2 new grades next week",
                    color: .purple
                )
                FocusCard(
                    icon: "bolt.fill",
                    title: "Power vs endurance",
                    detail: powerEnduranceDetail,
                    action: "Balance high grades with volume sets",
                    color: .orange
                )
                FocusCard(
                    icon: "timer",
                    title: "Pacing",
                    detail: pacingDetail,
                    action: "Aim for steady rest and attempt rhythm",
                    color: .blue
                )
                FocusCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Plateau check",
                    detail: plateauDetail,
                    action: "Push one harder climb next session",
                    color: .red
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("\(insights.count) notes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(insights, id: \.self) { insight in
                    AnalyticsInsightRow(text: insight)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Methods & Derived Metrics

    private var last12WeeksSessions: [Session] {
        let twelveWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date())!
        return sessions.filter { $0.startDate >= twelveWeeksAgo }
    }

    private var momentumScore: Double {
        guard hasSufficientMomentumData else { return 0 }
        let sendDelta = percentChangeSafe(current: getRecentSendRate(), historical: getHistoricalSendRate())
        let gradeDelta = percentChangeSafe(current: Double(getRecentHardestDI()), historical: Double(getHistoricalHardestDI()))
        let effortDelta = percentChangeSafe(current: getHistoricalAttemptsPerRoute(), historical: getRecentAttemptsPerRoute(), invert: true)

        let score = 50
            + 20 * sendDelta
            + 20 * gradeDelta
            + 10 * effortDelta
        return max(0, min(100, score))
    }

    private var consistencyScore: Double {
        guard hasSufficientConsistencyData else { return 0 }
        let freqScore = min(1.0, Double(last12WeeksSessions.count) / 12.0) // aiming for 2/wk over 6 weeks
        let effortVarScore = max(0, 1 - normalizedVariance(values: attemptsPerRouteHistory))
        let score = 100 * (0.6 * freqScore + 0.4 * effortVarScore)
        return max(0, min(100, score))
    }

    private var streakCount: Int {
        GlobalAnalytics.calculateConsistencyStreak(sessions: sessions)
    }

    private var heroSubtitle: String {
        "Tracking your send rate, hardest grade, and pacing over the last 12 weeks."
    }

    private var momentumSparkline: [Double] {
        rollingSendRates
    }

    private var momentumDeltaText: String {
        let delta = percentChangeSafe(current: getRecentSendRate(), historical: getHistoricalSendRate()) * 100
        return hasSufficientMomentumData ? String(format: "%+.0f pts vs baseline", delta) : "Not enough data"
    }

    private var consistencyDetail: String {
        hasSufficientConsistencyData ? "\(last12WeeksSessions.count) sessions in 12 weeks" : "Not enough data"
    }

    private var streakSubtitle: String {
        streakCount > 0 ? "Week streak" : "Start a streak"
    }

    private var varietyDetail: String {
        let uniqueGrades = Set(last12WeeksSessions.flatMap { $0.routes.compactMap { $0.grade } }).count
        return uniqueGrades < 4 ? "Low variety (\(uniqueGrades) grades)" : "Healthy variety (\(uniqueGrades) grades)"
    }

    private var powerEnduranceDetail: String {
        let avgAttempts = last12WeeksSessions.compactMap { $0.computeSummaryMetrics()?.attemptCount }.averageValue
        return avgAttempts > 15 ? "High volume focus" : "Push a harder project"
    }

    private var pacingDetail: String {
        let avgAttemptsPerSend = last12WeeksSessions.compactMap { $0.computeSummaryMetrics()?.attemptsPerSend }.averageValue
        if avgAttemptsPerSend > 3 { return "Pacing: heavy attempts per send" }
        return "Pacing: efficient sends"
    }

    private var plateauDetail: String {
        let recent = getRecentHardestDI()
        let historical = getHistoricalHardestDI()
        return recent <= historical ? "Hardest grade is flat" : "Trending up"
    }

    private var insights: [String] {
        var items: [String] = []
        let sendRate = getRecentSendRate()
        if sendRate < 40 { items.append("Send rate is low. Try more beta review.") }
        if varietyDetail.contains("Low variety") { items.append("Add more grade variety next week.") }
        if plateauDetail.contains("flat") { items.append("Push one harder climb to break plateau.") }
        return items.isEmpty ? ["Keep the momentum going."] : items
    }

    private func getRecentSendRate() -> Double {
        let recent = Array(last12WeeksSessions.prefix(6))
        let values = recent.compactMap { $0.computeSummaryMetrics()?.sendPercent }
        return GlobalAnalytics.rollingAverage(values: values)
    }

    private func getHistoricalSendRate() -> Double {
        let history = Array(last12WeeksSessions.dropFirst(6))
        let values = history.compactMap { $0.computeSummaryMetrics()?.sendPercent }
        return GlobalAnalytics.rollingAverage(values: values)
    }

    private func getRecentHardestDI() -> Int {
        let recent = Array(last12WeeksSessions.prefix(6))
        return recent.compactMap { $0.computeSummaryMetrics()?.hardestGradeDI }.max() ?? 0
    }

    private func getHistoricalHardestDI() -> Int {
        let history = Array(last12WeeksSessions.dropFirst(6))
        let values = history.compactMap { $0.computeSummaryMetrics()?.hardestGradeDI }
        return values.max() ?? 0
    }

    private func percentChangeSafe(current: Double, historical: Double, invert: Bool = false) -> Double {
        let epsilon = 0.0001
        let base = max(abs(historical), epsilon)
        let delta = (current - historical) / base
        let clamped = max(-0.5, min(0.5, delta))
        return invert ? -clamped : clamped
    }

    private func normalizedVariance(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        if mean == 0 { return 0 }
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let std = sqrt(variance)
        return min(1, std / mean) // normalize variance to 0-1 range
    }

    private var rollingSendRates: [Double] {
        let sortedSessions = last12WeeksSessions.sorted { $0.startDate < $1.startDate }
        return sortedSessions.compactMap { $0.computeSummaryMetrics()?.sendPercent }
    }

    private func getRecentAttemptsPerRoute() -> Double {
        let recent = Array(last12WeeksSessions.prefix(6))
        let values = recent.compactMap { $0.computeSummaryMetrics()?.attemptsPerSend }
        return values.averageValue
    }

    private func getHistoricalAttemptsPerRoute() -> Double {
        let history = Array(last12WeeksSessions.dropFirst(6)).prefix(6)
        let values = history.compactMap { $0.computeSummaryMetrics()?.attemptsPerSend }
        return values.averageValue
    }

    private var attemptsPerRouteHistory: [Double] {
        last12WeeksSessions.compactMap { $0.computeSummaryMetrics()?.attemptsPerSend }
    }

    private var hasSufficientMomentumData: Bool {
        let recentCount = Array(last12WeeksSessions.prefix(6)).count
        let baselineCount = Array(last12WeeksSessions.dropFirst(6)).prefix(6).count
        return recentCount >= 3 && baselineCount >= 3
    }

    private var hasSufficientConsistencyData: Bool {
        last12WeeksSessions.count >= 3
    }

    private var momentumScoreText: String {
        hasSufficientMomentumData ? String(format: "%.0f", momentumScore) : "—"
    }

    private var consistencyScoreText: String {
        hasSufficientConsistencyData ? String(format: "%.0f", consistencyScore) : "—"
    }
}

// MARK: - Supporting Views

struct HeroTrendCard: View {
    let title: String
    let sparkline: [Double]
    let currentValue: String
    let deltaText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(deltaText)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            Chart {
                ForEach(Array(sparkline.enumerated()), id: \.0) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 100)

            HStack {
                Text(currentValue)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Text("Momentum score")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

struct ScoreCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    var isDisabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(isDisabled ? .secondary.opacity(0.6) : .secondary)
        }
        .padding()
        .frame(width: 180, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct TrendCard: View {
    let title: String
    let subtitle: String
    let chart: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            chart
        }
        .padding()
        .frame(width: 260, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct FocusCard: View {
    let icon: String
    let title: String
    let detail: String
    let action: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(action)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct AnalyticsInsightRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Helpers

extension Array where Element: BinaryInteger {
    var averageValue: Double {
        guard !isEmpty else { return 0 }
        let total = self.reduce(0, +)
        return Double(total) / Double(count)
    }
}

extension Array where Element: BinaryFloatingPoint {
    var averageValue: Double {
        guard !isEmpty else { return 0 }
        let total = self.reduce(0, +)
        return Double(total) / Double(count)
    }
}

// MARK: - Custom Chart Views

struct VolumeBarChart: View {
    let sessions: [Session]

    var body: some View {
        Chart {
            ForEach(getWeeklyData(), id: \.week) { data in
                BarMark(
                    x: .value("Week", data.week, unit: .weekOfYear),
                    y: .value("Attempts", data.attempts)
                )
                .foregroundStyle(Color.blue.opacity(0.7))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let attempts = value.as(Int.self) {
                        Text("\(attempts)")
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        let weekNumber = Calendar.current.component(.weekOfYear, from: date)
                        Text("W\(weekNumber)")
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .frame(height: 120)
    }

    private func getWeeklyData() -> [(week: Date, attempts: Int)] {
        let calendar = Calendar.current
        var weeklyData: [Date: Int] = [:]

        // Get last 8 weeks
        for i in (0..<8).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: Date())!
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!

            let weekSessions = sessions.filter {
                $0.startDate >= weekStart && $0.startDate < weekEnd &&
                ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
            }

            let totalAttempts = weekSessions.compactMap { $0.computeSummaryMetrics()?.attemptCount }.reduce(0, +)
            weeklyData[weekStart] = totalAttempts
        }

        return weeklyData.map { week, attempts in
            (week: week, attempts: attempts)
        }.sorted { $0.week < $1.week }
    }
}

struct GradeProgressionChart: View {
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

                // Data line
                Path { path in
                    let dataPoints = getGradeData()
                    guard !dataPoints.isEmpty else { return }

                    let maxGrade = dataPoints.map { $0.grade }.max() ?? 100
                    let minGrade = dataPoints.map { $0.grade }.min() ?? 0
                    let gradeRange = max(maxGrade - minGrade, 20) // Minimum range

                    let firstPoint = dataPoints[0]
                    let x = geometry.size.width * CGFloat(0) / CGFloat(max(1, dataPoints.count - 1))
                    let y = geometry.size.height * (1.0 - CGFloat(firstPoint.grade - minGrade) / CGFloat(gradeRange))
                    path.move(to: CGPoint(x: x, y: y))

                    for (index, point) in dataPoints.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(1, dataPoints.count - 1))
                        let y = geometry.size.height * (1.0 - CGFloat(point.grade - minGrade) / CGFloat(gradeRange))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.red, lineWidth: 2)

                // Data points
                ForEach(getGradeData().enumerated().map { ($0, $1) }, id: \.0) { index, point in
                    let dataPoints = getGradeData()
                    let maxGrade = dataPoints.map { $0.grade }.max() ?? 100
                    let minGrade = dataPoints.map { $0.grade }.min() ?? 0
                    let gradeRange = max(maxGrade - minGrade, 20)

                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(1, dataPoints.count - 1))
                    let y = geometry.size.height * (1.0 - CGFloat(point.grade - minGrade) / CGFloat(gradeRange))

                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func getGradeData() -> [(grade: Int, date: Date)] {
        let recentSessions = Array(sessions.sorted { $0.startDate < $1.startDate }.suffix(12))
        return recentSessions.compactMap { session in
            if let summary = session.computeSummaryMetrics() {
                return (grade: summary.hardestGradeDI, date: session.startDate)
            }
            return nil
        }
    }
}


// Preview removed due to @Query and @Environment dependencies
