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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Top Summary
                    topSummarySection

                    // Charts Section
                    chartsSection

                    // Highlights Section
                    highlightsSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Top Summary Section

    private var topSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.primary)
                Text("This Month vs Last 3 Months")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 16) {
                // Hardest Grade Comparison
                hardestGradeCard

                // Success % Comparison
                successPercentCard

                // Total Attempts
                totalAttemptsCard
            }
        }
        .padding(.horizontal)
    }

    private func formatDIAsGrade(_ di: Int) -> String {
        if let grade = DifficultyIndex.gradeForDI(di, system: .vscale, climbType: .boulder) {
            return grade
        }
        return "V\(di / 10)" // Fallback
    }

    private var hardestGradeCard: some View {
        let thisMonthDI = getThisMonthMaxDI()
        let last3MonthsDI = getLast3MonthsAverageDI()

        return StatCardView(
            icon: "mountain.2.fill",
            title: formatDIAsGrade(thisMonthDI),
            subtitle: "Hardest Grade",
            color: .red,
            trend: calculateTrend(current: Double(thisMonthDI), historical: Double(last3MonthsDI))
        )
    }

    private var successPercentCard: some View {
        let thisMonthPercent = getThisMonthAverageSendPercent()
        let last3MonthsPercent = getLast3MonthsAverageSendPercent()

        return StatCardView(
            icon: "checkmark.circle.fill",
            title: String(format: "%.1f%%", thisMonthPercent),
            subtitle: "Success Rate",
            color: .green,
            trend: calculateTrend(current: thisMonthPercent, historical: last3MonthsPercent)
        )
    }

    private var totalAttemptsCard: some View {
        let thisMonthAttempts = getThisMonthTotalAttempts()
        let last3MonthsAttempts = getLast3MonthsAverageAttempts()

        return StatCardView(
            icon: "bolt.fill",
            title: "\(thisMonthAttempts)",
            subtitle: "Total Attempts",
            color: .orange,
            trend: calculateTrend(current: Double(thisMonthAttempts), historical: last3MonthsAttempts)
        )
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        VStack(spacing: 24) {
            // Volume Trend Chart
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                    Text("Weekly Volume")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Last 8 weeks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VolumeBarChart(sessions: sessions)
                    .frame(height: 120)
            }

            // Grade Progression Chart
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.primary)
                    Text("Grade Progression")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Last 12 sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                GradeProgressionChart(sessions: sessions)
                    .frame(height: 120)
            }

            // Efficiency Chart
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(.primary)
                    Text("Send Efficiency")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Last 10 sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                EfficiencyChart(sessions: sessions)
                    .frame(height: 120)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.primary)
                Text("Highlights")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            VStack(spacing: 12) {
                // PR Badge
                if let prGrade = getRecentPRGrade() {
                    HighlightCard(
                        icon: "trophy.fill",
                        title: "New Personal Record!",
                        subtitle: "Sent \(prGrade)",
                        color: .yellow
                    )
                }

                // Consistency Streak
                let streak = GlobalAnalytics.calculateConsistencyStreak(sessions: sessions)
                if streak > 0 {
                    HighlightCard(
                        icon: "flame.fill",
                        title: "\(streak) Week Streak",
                        subtitle: "Consistent climbing",
                        color: .orange
                    )
                }

                // Recent Performance
                if sessions.count >= 3 {
                    let recentSessions = Array(sessions.prefix(3))
                    let avgSendPercent = GlobalAnalytics.rollingAverage(
                        values: recentSessions.compactMap { $0.computeSummaryMetrics()?.sendPercent }
                    )

                    HighlightCard(
                        icon: "target",
                        title: String(format: "%.1f%%", avgSendPercent),
                        subtitle: "Recent send rate",
                        color: avgSendPercent >= 60 ? .green : avgSendPercent >= 40 ? .blue : .red
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    private func getThisMonthMaxDI() -> Int {
        let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())!
        let thisMonthSessions = sessions.filter {
            thisMonth.contains($0.startDate) && ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        return thisMonthSessions.compactMap { $0.computeSummaryMetrics()?.hardestGradeDI }.max() ?? 0
    }

    private func getLast3MonthsAverageDI() -> Int {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let last3MonthsSessions = sessions.filter {
            $0.startDate >= threeMonthsAgo && $0.startDate < Calendar.current.dateInterval(of: .month, for: Date())!.start &&
            ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        let values = last3MonthsSessions.compactMap { $0.computeSummaryMetrics()?.hardestGradeDI }
        return values.isEmpty ? 0 : Int(values.reduce(0, +) / values.count)
    }

    private func getThisMonthAverageSendPercent() -> Double {
        let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())!
        let thisMonthSessions = sessions.filter {
            thisMonth.contains($0.startDate) && ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        let values = thisMonthSessions.compactMap { $0.computeSummaryMetrics()?.sendPercent }
        return GlobalAnalytics.rollingAverage(values: values)
    }

    private func getLast3MonthsAverageSendPercent() -> Double {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let last3MonthsSessions = sessions.filter {
            $0.startDate >= threeMonthsAgo && $0.startDate < Calendar.current.dateInterval(of: .month, for: Date())!.start &&
            ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        let values = last3MonthsSessions.compactMap { $0.computeSummaryMetrics()?.sendPercent }
        return GlobalAnalytics.rollingAverage(values: values)
    }

    private func getThisMonthTotalAttempts() -> Int {
        let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())!
        let thisMonthSessions = sessions.filter {
            thisMonth.contains($0.startDate) && ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        return thisMonthSessions.compactMap { $0.computeSummaryMetrics()?.attemptCount }.reduce(0, +)
    }

    private func getLast3MonthsAverageAttempts() -> Double {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let last3MonthsSessions = sessions.filter {
            $0.startDate >= threeMonthsAgo && $0.startDate < Calendar.current.dateInterval(of: .month, for: Date())!.start &&
            ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        let values = last3MonthsSessions.compactMap { $0.computeSummaryMetrics()?.attemptCount }
        return values.isEmpty ? 0.0 : Double(values.reduce(0, +)) / Double(values.count)
    }

    private func getThisMonthAverageAttemptsPerSend() -> Double {
        let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())!
        let thisMonthSessions = sessions.filter {
            thisMonth.contains($0.startDate) && ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        let values = thisMonthSessions.compactMap { $0.computeSummaryMetrics()?.attemptsPerSend }
        return GlobalAnalytics.rollingAverage(values: values)
    }

    private func getLast3MonthsAverageAttemptsPerSend() -> Double {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let last3MonthsSessions = sessions.filter {
            $0.startDate >= threeMonthsAgo && $0.startDate < Calendar.current.dateInterval(of: .month, for: Date())!.start &&
            ($0.status == .complete || $0.status == .cancelled || $0.status == .active)
        }

        let values = last3MonthsSessions.compactMap { $0.computeSummaryMetrics()?.attemptsPerSend }
        return GlobalAnalytics.rollingAverage(values: values)
    }

    private func calculateTrend(current: Double, historical: Double) -> String {
        if current > historical { return "↑" }
        if current < historical { return "↓" }
        return "→"
    }

    private func getRecentPRGrade() -> String? {
        // PR detection requires SwiftUI Charts integration
        // For now, return nil to disable PR display
        return nil
    }
}

// MARK: - Supporting Views

struct HighlightCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
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
