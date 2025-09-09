//
//  GlobalAnalytics.swift
//  crakt
//
//  Created by Kyle Thompson on 12/10/24.
//

import Foundation

// MARK: - Note: SessionSummary struct moved to Session.stats.swift

// MARK: - Analytics Aggregation Structures

/// Weekly volume metrics
struct WeeklyVolume {
    let week: Date
    let attempts: Int
    let sends: Int
    let sendPercentage: Double
}

/// Grade distribution by DI bands
struct GradeDistribution {
    let band: String  // e.g., "V0-V2", "V3-V5", "V6+"
    let attempts: Int
    let percentage: Double
    let diRange: ClosedRange<Int>
}

// MARK: - Trend Analysis

/// Trend data for a metric over time
struct TrendData {
    let currentValue: Double
    let historicalAverage: Double
    let trend: String  // "↑", "↓", "→"
    let percentChange: Double
    let isPersonalBest: Bool
}

// MARK: - Aggregation Functions

/// Global analytics utilities for aggregating session data
struct GlobalAnalytics {

    // MARK: - Progression Trends

    /// Calculate hardest grade trend across sessions
    static func getHardestGradeTrend(sessions: [Session]) -> [Date: Int] {
        var trends: [Date: Int] = [:]

        for session in sessions {
            if let summary = session.computeSummaryMetrics() {
                trends[summary.sessionDate] = summary.hardestGradeDI
            }
        }

        return trends
    }

    /// Calculate median grade trend across sessions
    static func getMedianGradeTrend(sessions: [Session]) -> [Date: Int] {
        var trends: [Date: Int] = [:]

        for session in sessions {
            if let summary = session.computeSummaryMetrics() {
                trends[summary.sessionDate] = summary.medianGradeDI
            }
        }

        return trends
    }

    // MARK: - Volume & Efficiency

    /// Get weekly volume aggregation
    static func getWeeklyVolume(sessions: [Session]) -> [WeeklyVolume] {
        // Group sessions by week
        let calendar = Calendar.current
        var weeklyData: [Date: (attempts: Int, sends: Int)] = [:]

        for session in sessions {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.startDate))!

            if let summary = session.computeSummaryMetrics() {
                weeklyData[weekStart, default: (0, 0)] = (
                    weeklyData[weekStart]?.attempts ?? 0 + summary.attemptCount,
                    weeklyData[weekStart]?.sends ?? 0 + summary.sendCount
                )
            }
        }

        return weeklyData.map { week, data in
            WeeklyVolume(
                week: week,
                attempts: data.attempts,
                sends: data.sends,
                sendPercentage: data.attempts > 0 ? Double(data.sends) / Double(data.attempts) * 100.0 : 0.0
            )
        }.sorted { $0.week < $1.week }
    }

    /// Get send percentage trend over time
    static func getSendPercentTrend(sessions: [Session]) -> [Date: Double] {
        var trends: [Date: Double] = [:]

        for session in sessions {
            if let summary = session.computeSummaryMetrics() {
                trends[summary.sessionDate] = summary.sendPercent
            }
        }

        return trends
    }

    /// Get attempts per send trend
    static func getAttemptsPerSendTrend(sessions: [Session]) -> [Date: Double] {
        var trends: [Date: Double] = [:]

        for session in sessions {
            if let summary = session.computeSummaryMetrics() {
                trends[summary.sessionDate] = summary.attemptsPerSend
            }
        }

        return trends
    }

    // MARK: - Distribution

    /// Get grade distribution across sessions
    static func getGradeDistribution(sessions: [Session], window: Int? = nil) -> [GradeDistribution] {
        let sessionsToAnalyze = window != nil ? Array(sessions.suffix(window!)) : sessions
        var totalAttempts = 0
        var bandCounts: [String: Int] = [
            "V0-V2": 0,
            "V3-V5": 0,
            "V6+": 0
        ]

        for session in sessionsToAnalyze {
            for route in session.routes where !route.attempts.isEmpty {
                if let grade = route.grade,
                   let di = DifficultyIndex.normalizeToDI(grade: grade, system: session.gradeSystem ?? .vscale, climbType: .boulder) {
                    totalAttempts += route.attempts.count

                    switch di {
                    case 0...25:  // V0-V2 equivalent
                        bandCounts["V0-V2", default: 0] += route.attempts.count
                    case 26...55: // V3-V5 equivalent
                        bandCounts["V3-V5", default: 0] += route.attempts.count
                    default:      // V6+ equivalent
                        bandCounts["V6+", default: 0] += route.attempts.count
                    }
                }
            }
        }

        return bandCounts.map { band, attempts in
            GradeDistribution(
                band: band,
                attempts: attempts,
                percentage: totalAttempts > 0 ? Double(attempts) / Double(totalAttempts) * 100.0 : 0.0,
                diRange: band == "V0-V2" ? 0...25 : band == "V3-V5" ? 26...55 : 56...200
            )
        }.sorted { $0.band < $1.band }
    }

    // MARK: - Personal Records

    /// Detect personal best for hardest grade
    static func detectHardestGradePR(sessions: [Session], currentSession: Session) -> Bool {
        guard let currentSummary = currentSession.computeSummaryMetrics() else { return false }

        let historicalMaxDI = sessions.compactMap { session in
            session.computeSummaryMetrics()?.hardestGradeDI
        }.max() ?? 0

        return currentSummary.hardestGradeDI > historicalMaxDI
    }

    /// Detect personal best for send percentage
    static func detectSendPercentPR(sessions: [Session], currentSession: Session) -> Bool {
        guard let currentSummary = currentSession.computeSummaryMetrics() else { return false }

        let historicalMaxPercent = sessions.compactMap { session in
            session.computeSummaryMetrics()?.sendPercent
        }.max() ?? 0.0

        return currentSummary.sendPercent > historicalMaxPercent
    }

    // MARK: - Utility Functions

    /// Calculate rolling average with exponential decay
    static func rollingAverage(values: [Double], halfLife: Double = 30.0) -> Double {
        guard !values.isEmpty else { return 0.0 }

        let weights = (0..<values.count).map { index in
            pow(0.5, Double(index) / halfLife)
        }

        let totalWeight = weights.reduce(0, +)
        let weightedSum = zip(values, weights).map(*).reduce(0, +)

        return totalWeight > 0 ? weightedSum / totalWeight : values.last ?? 0.0
    }

    /// Calculate consistency streak (consecutive weeks with sessions)
    static func calculateConsistencyStreak(sessions: [Session]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let sortedSessions = sessions.sorted { $0.startDate > $1.startDate }
        let calendar = Calendar.current

        var streak = 0
        var currentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: sortedSessions.first!.startDate))!

        for session in sortedSessions {
            let sessionWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.startDate))!

            if sessionWeek == currentWeek {
                continue // Same week, keep going
            } else if sessionWeek == calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek) {
                // Consecutive week
                streak += 1
                currentWeek = sessionWeek
            } else {
                // Gap in weeks, streak broken
                break
            }
        }

        return streak
    }

    // MARK: - Advanced Analytics

    /// Calculate trend direction and strength
    static func calculateTrendAnalysis(current: Double, historical: [Double], window: Int = 5) -> TrendData {
        let recentHistorical = Array(historical.suffix(window))
        let historicalAverage = recentHistorical.isEmpty ? 0.0 : recentHistorical.reduce(0, +) / Double(recentHistorical.count)
        let historicalMax = recentHistorical.max() ?? 0.0

        let trend: String
        if current > historicalAverage * 1.1 { trend = "↑" }
        else if current < historicalAverage * 0.9 { trend = "↓" }
        else { trend = "→" }

        let percentChange = historicalAverage > 0 ? ((current - historicalAverage) / historicalAverage) * 100.0 : 0.0
        let isPersonalBest = current > historicalMax

        return TrendData(
            currentValue: current,
            historicalAverage: historicalAverage,
            trend: trend,
            percentChange: percentChange,
            isPersonalBest: isPersonalBest
        )
    }

    /// Calculate volume forecast based on recent trends
    static func calculateVolumeForecast(sessions: [Session], daysAhead: Int = 7) -> Double {
        guard sessions.count >= 3 else { return 0.0 }

        let recentSessions = Array(sessions.suffix(5))
        let volumes = recentSessions.compactMap { $0.computeSummaryMetrics()?.attemptCount }
        guard !volumes.isEmpty else { return 0.0 }

        // Simple linear regression on recent volume
        let n = Double(volumes.count)
        let sumX = (0..<volumes.count).reduce(0.0) { $0 + Double($1) }
        let sumY = volumes.reduce(0.0) { $0 + Double($1) }

        // Break down the complex sumXY calculation into simpler steps
        let indices = Array(0..<volumes.count)
        let sumXY = zip(indices, volumes).reduce(0.0) { sum, pair in
            let (index, volume) = pair
            return sum + Double(index) * Double(volume)
        }

        let sumXX = (0..<volumes.count).reduce(0.0) { $0 + Double($1) * Double($1) }

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        let nextX = Double(volumes.count)
        let forecast = slope * nextX + intercept

        return max(0, forecast)
    }

    /// Calculate grade progression velocity (DI points per session)
    static func calculateGradeProgressionVelocity(sessions: [Session], window: Int = 10) -> Double {
        guard sessions.count >= 2 else { return 0.0 }

        let recentSessions = Array(sessions.suffix(window))
        let hardestGrades = recentSessions.compactMap { $0.computeSummaryMetrics()?.hardestGradeDI }
        guard hardestGrades.count >= 2 else { return 0.0 }

        let firstGrade = hardestGrades.first!
        let lastGrade = hardestGrades.last!
        let sessionsSpan = Double(hardestGrades.count - 1)

        return (Double(lastGrade - firstGrade)) / sessionsSpan
    }

    /// Identify plateau periods (no grade improvement for N sessions)
    static func detectPlateauPeriods(sessions: [Session], threshold: Int = 5) -> [ClosedRange<Date>] {
        guard sessions.count >= threshold else { return [] }

        let sortedSessions = sessions.sorted { $0.startDate < $1.startDate }
        var plateaus: [ClosedRange<Date>] = []
        var plateauStart: Date?
        var plateauGrades: [Int] = []

        for session in sortedSessions {
            if let summary = session.computeSummaryMetrics() {
                let currentGrade = summary.hardestGradeDI

                if plateauGrades.isEmpty {
                    plateauStart = session.startDate
                    plateauGrades.append(currentGrade)
                } else if currentGrade <= plateauGrades.max()! {
                    // Still on plateau or declining
                    plateauGrades.append(currentGrade)

                    if plateauGrades.count >= threshold && plateauStart != nil {
                        plateaus.append(plateauStart!...session.startDate)
                        plateauStart = session.startDate
                        plateauGrades = [currentGrade]
                    }
                } else {
                    // Improvement detected, reset plateau tracking
                    plateauStart = session.startDate
                    plateauGrades = [currentGrade]
                }
            }
        }

        return plateaus
    }

    /// Calculate efficiency improvement rate
    static func calculateEfficiencyImprovement(sessions: [Session]) -> Double {
        guard sessions.count >= 3 else { return 0.0 }

        let sortedSessions = sessions.sorted { $0.startDate < $1.startDate }
        let attemptsPerSend = sortedSessions.compactMap { $0.computeSummaryMetrics()?.attemptsPerSend }
        guard attemptsPerSend.count >= 2 else { return 0.0 }

        let firstAPS = attemptsPerSend.first!
        let lastAPS = attemptsPerSend.last!
        let sessionsSpan = Double(attemptsPerSend.count - 1)

        // Negative value means improvement (fewer attempts per send over time)
        return (lastAPS - firstAPS) / sessionsSpan
    }

    /// Calculate session quality score (composite metric)
    static func calculateSessionQualityScore(session: Session) -> Double {
        guard let summary = session.computeSummaryMetrics() else { return 0.0 }

        // Weights for different factors
        let volumeWeight = 0.3
        let efficiencyWeight = 0.3
        let gradeWeight = 0.4

        // Normalize each component to 0-1 scale
        let volumeScore = min(1.0, Double(summary.attemptCount) / 50.0) // 50 attempts = perfect score
        let efficiencyScore = max(0.0, min(1.0, (3.0 - summary.attemptsPerSend) / 3.0)) // Better if < 3 attempts/send
        let gradeScore = min(1.0, Double(summary.hardestGradeDI) / 100.0) // 100 DI = perfect score

        return volumeScore * volumeWeight + efficiencyScore * efficiencyWeight + gradeScore * gradeWeight
    }

    /// Identify peak performance periods
    static func identifyPeakPeriods(sessions: [Session], windowSize: Int = 7) -> [Date] {
        guard sessions.count >= windowSize else { return [] }

        let sortedSessions = sessions.sorted { $0.startDate < $1.startDate }
        var peakDates: [Date] = []

        for i in (windowSize - 1)..<sortedSessions.count {
            let window = Array(sortedSessions[(i - windowSize + 1)...i])
            let windowScores = window.compactMap { calculateSessionQualityScore(session: $0) }
            let averageScore = windowScores.reduce(0, +) / Double(windowScores.count)

            let previousWindow = i >= windowSize ? Array(sortedSessions[(i - windowSize)...(i - 1)]) : []
            let previousScores = previousWindow.compactMap { calculateSessionQualityScore(session: $0) }
            let previousAverage = previousScores.isEmpty ? 0 : previousScores.reduce(0, +) / Double(previousScores.count)

            // Peak if current window is significantly better than previous
            if averageScore > previousAverage * 1.2 && windowScores.count == windowSize {
                peakDates.append(sortedSessions[i].startDate)
            }
        }

        return peakDates
    }

    // MARK: - Comparison Utilities

    /// Compare two sessions on multiple metrics
    static func compareSessions(session1: Session, session2: Session) -> [String: Double] {
        guard let summary1 = session1.computeSummaryMetrics(),
              let summary2 = session2.computeSummaryMetrics() else {
            return [:]
        }

        return [
            "hardestGradeDI": Double(summary2.hardestGradeDI - summary1.hardestGradeDI),
            "medianGradeDI": Double(summary2.medianGradeDI - summary1.medianGradeDI),
            "attemptCount": Double(summary2.attemptCount - summary1.attemptCount),
            "sendCount": Double(summary2.sendCount - summary1.sendCount),
            "sendPercent": summary2.sendPercent - summary1.sendPercent,
            "attemptsPerSend": summary2.attemptsPerSend - summary1.attemptsPerSend
        ]
    }

    /// Calculate percentile ranking for a session compared to historical data
    static func calculatePercentileRank(session: Session, historicalSessions: [Session], metric: String) -> Double {
        guard let sessionSummary = session.computeSummaryMetrics() else { return 0.0 }

        let historicalSummaries = historicalSessions.compactMap { $0.computeSummaryMetrics() }
        guard !historicalSummaries.isEmpty else { return 0.0 }

        let sessionValue: Double
        switch metric {
        case "hardestGradeDI": sessionValue = Double(sessionSummary.hardestGradeDI)
        case "sendPercent": sessionValue = sessionSummary.sendPercent
        case "attemptsPerSend": sessionValue = sessionSummary.attemptsPerSend
        default: return 0.0
        }

        let historicalValues = historicalSummaries.map { summary -> Double in
            switch metric {
            case "hardestGradeDI": return Double(summary.hardestGradeDI)
            case "sendPercent": return summary.sendPercent
            case "attemptsPerSend": return summary.attemptsPerSend
            default: return 0.0
            }
        }

        let betterOrEqualCount = historicalValues.filter { $0 <= sessionValue }.count
        return Double(betterOrEqualCount) / Double(historicalValues.count) * 100.0
    }
}
