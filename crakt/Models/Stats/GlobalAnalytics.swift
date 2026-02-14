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
}

/// Grade distribution by DI bands
struct GradeDistribution {
    let band: String  // e.g., "V0-V2", "V3-V5", "V6+"
    let percentage: Double
}

// MARK: - Aggregation Functions

/// Global analytics utilities for aggregating session data
struct GlobalAnalytics {

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
                sends: data.sends
            )
        }.sorted { $0.week < $1.week }
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
                percentage: totalAttempts > 0 ? Double(attempts) / Double(totalAttempts) * 100.0 : 0.0
            )
        }.sorted { $0.band < $1.band }
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
}
