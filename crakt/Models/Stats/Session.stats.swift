//
//  SwiftUIView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI

extension Session {
    var totalAttempts: Int {
        routes.reduce(0) { $0 + $1.attempts.count }
    }
    
    var totalRoutes: Int {
            routes.count
    }
    
    var successfulClimbs: Int {
            routes.filter { route in
                route.attempts.contains { attempt in
                    attempt.status == .send
                }
            }.count
        }
    
    var attemptStatusDistribution: [ClimbStatus: Int] {
            var distribution: [ClimbStatus: Int] = [:]
            for route in routes {
                for attempt in route.attempts {
                    distribution[attempt.status, default: 0] += 1
                }
            }
            return distribution
        }
    
    var averageGradeAttempted: Double {
            let totalGrades = routes.compactMap { $0.normalizedGrade }
            guard !totalGrades.isEmpty else { return 0.0 }
            return totalGrades.reduce(0, +) / Double(totalGrades.count)
        }
    
    var highestGradeSent: String? {
            let _max_route = routes.filter { route in
                route.attempts.contains { attempt in
                    attempt.status == .send || attempt.status == .flash || attempt.status == .topped
                }
            }.max(by: { a, b in
                a.normalizedGrade < b.normalizedGrade
            })

            if let _max_route {
                return _max_route.gradeDescription ?? "Unknown"
            }
            return nil
        }
    
    var highestGradeFlashedClimbed: String? {
            let _max_route = routes.filter { route in
                route.attempts.contains { attempt in
                    attempt.status == .flash
                }
            }.max(by: { a, b in
                a.normalizedGrade < b.normalizedGrade
            })

            if let _max_route {
                return _max_route.gradeDescription ?? "Unknown"
            }
            return nil
        }
    
    var totalAttemptsPerGrade: [(grade: String, attempts: Int)] {
        let attemptsByGrade = attemptsGroupedByGrade(routes: routes)
        let totalAttemptsPerGrade = totalAttemptsByGrade(attemptsByCategory: attemptsByGrade)
        return totalAttemptsPerGrade
    }
    
    var routesSorted: [Route] {
        routes.sorted { route1, route2 in
            let gradingProtocol1 = route1.gradeSystem._protocol
            let gradingProtocol2 = route2.gradeSystem._protocol

            let grade1Difficulty = route1.grade.map { gradingProtocol1.normalizedDifficulty(for: $0) } ?? 0.0
            let grade2Difficulty = route2.grade.map { gradingProtocol2.normalizedDifficulty(for: $0) } ?? 0.0

            return grade1Difficulty < grade2Difficulty
        }
    }
    
    var routesSortedByDate: [Route] {
            routes.sorted { $0.firstAttemptDate ?? Date.distantPast < $1.firstAttemptDate ?? Date.distantPast }
    }
    
    var attemptsByGradeAndStatus: [(grade: String, status: ClimbStatus, attempts: Int)] {
        var aggregatedData = [(grade: String, status: ClimbStatus, attempts: Int)]()
        
        for route in routesSorted {
            let grade = route.grade ?? "Unknown"
            for attempt in route.attempts {
                let status = attempt.status
                if let index = aggregatedData.firstIndex(where: { $0.grade == grade && $0.status == status }) {
                    aggregatedData[index].attempts += 1
                } else {
                    aggregatedData.append((grade: route.gradeDescription ?? "Unknown", status: status, attempts: 1))
                }
            }
        }
        
        return aggregatedData
    }
    
    func attemptsGroupedByGrade(routes: [Route]) -> [String: [Route]] {
        var attemptsByGrade: [String: [Route]] = [:]
        
        for route in routes {
            guard let grade = route.grade else { continue }

            if attemptsByGrade[grade] != nil {
                attemptsByGrade[grade]!.append(route)
            } else {
                attemptsByGrade[grade] = [route]
            }
            
            
        }
        
        return attemptsByGrade
    }
    
    func totalAttemptsByGrade(attemptsByCategory: [String: [Route]]) -> [(grade: String, attempts: Int)] {
        var totals: [(String, Int)] = []
        
        for (grade, routes) in attemptsByCategory {
            // Sum the total attempts for routes of this grade
            let totalAttempts = routes.reduce(0) { $0 + $1.attempts.count }
            totals.append((grade, totalAttempts))
        }
        
        // Sort the totals by grade if grades are numeric or alphabetically otherwise
        // Assuming grades can be sorted in a meaningful way as strings
        return totals.sorted(by: { $0.0 < $1.0 })
    }
    
    var normalizedAttempts: [(normalizedTime: Date, grade: String, status: ClimbStatus, routeId: UUID)] {
            guard endDate != nil else { return [] }
        
            let _grade_sorted = routes.sorted { $0.normalizedGrade < $1.normalizedGrade }
            
            return _grade_sorted.flatMap { route -> [(normalizedTime: Date, grade: String, status: ClimbStatus, routeId: UUID)] in
                guard let grade = route.grade else { return [] }
                return route.attempts.map { attempt in
                    return (normalizedTime: attempt.date, grade: grade, status: attempt.status, routeId: route.id)
                }
            }
        }
    
    var attemptsWithRoute: [(attemptNumber: Int, attemptDate: Date, status: ClimbStatus, route: Route)] {
        routes
            .flatMap { route in
                route.attempts.map { attempt in
                    (attempt.date, attempt.status, route)
                }
            }
            .sorted { $0.0 < $1.0 }  // Sorting by attempt date
            .enumerated()  // Enumerating the sorted attempts
            .map { index, attempt in
                (attemptNumber: index + 1, attemptDate: attempt.0, status: attempt.1, route: attempt.2)
            }
    }

    // MARK: - Session Volume Stats

    /// Total attempts in current session
    var sessionTotalAttempts: Int {
        allAttempts.count
    }

    /// Total successful sends/tops in current session
    var sessionTotalSends: Int {
        allAttempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }.count
    }

    /// Success percentage for current session
    var sessionSuccessPercentage: Double {
        guard sessionTotalAttempts > 0 else { return 0.0 }
        return Double(sessionTotalSends) / Double(sessionTotalAttempts) * 100.0
    }

    // MARK: - Intensity Benchmarks

    /// Hardest grade successfully sent in current session
    var sessionHardestGradeSent: String? {
        let successfulRoutes = routes.filter { route in
            route.attempts.contains { $0.status == .send || $0.status == .flash || $0.status == .topped }
        }

        guard let hardestRoute = successfulRoutes.max(by: { $0.normalizedGrade < $1.normalizedGrade }) else {
            return nil
        }

        return hardestRoute.gradeDescription ?? hardestRoute.grade
    }

    /// Median grade of successfully sent routes
    var sessionMedianGradeSent: String? {
        let successfulRoutes = routes.filter { route in
            route.attempts.contains { $0.status == .send || $0.status == .flash || $0.status == .topped }
        }.sorted { $0.normalizedGrade < $1.normalizedGrade }

        guard !successfulRoutes.isEmpty else { return nil }

        let middleIndex = successfulRoutes.count / 2
        let medianRoute = successfulRoutes.count % 2 == 0 ?
            successfulRoutes[middleIndex - 1] : successfulRoutes[middleIndex]

        return medianRoute.gradeDescription ?? medianRoute.grade
    }

    /// All grades attempted in current session (for volume distribution)
    var sessionGradesAttempted: [Route] {
        routes.filter { !$0.attempts.isEmpty }.sorted { $0.normalizedGrade < $1.normalizedGrade }
    }

    // MARK: - Efficiency Metrics

    /// Attempts per send ratio for current session
    var sessionAttemptsPerSend: Double {
        guard sessionTotalSends > 0 else { return 0.0 }
        return Double(sessionTotalAttempts) / Double(sessionTotalSends)
    }

    // MARK: - Volume Distribution

    /// Grade band distribution for current session
    var sessionGradeBandDistribution: [String: Int] {
        var distribution: [String: Int] = [
            "V0-V2": 0,
            "V3-V5": 0,
            "V6+": 0
        ]

        for route in routes where !route.attempts.isEmpty {
            guard let grade = route.grade else { continue }

            // For V-scale, parse the V number
            if gradeSystem == .vscale, let vNumber = parseVGrade(grade) {
                switch vNumber {
                case 0...2:
                    distribution["V0-V2", default: 0] += route.attempts.count
                case 3...5:
                    distribution["V3-V5", default: 0] += route.attempts.count
                default:
                    distribution["V6+", default: 0] += route.attempts.count
                }
            } else if gradeSystem == .yds {
                // For YDS, we need to convert to V-scale equivalent for comparison
                let normalized = route.normalizedGrade
                if normalized <= 2.0 {
                    distribution["V0-V2", default: 0] += route.attempts.count
                } else if normalized <= 5.0 {
                    distribution["V3-V5", default: 0] += route.attempts.count
                } else {
                    distribution["V6+", default: 0] += route.attempts.count
                }
            }
        }

        return distribution
    }

    /// Parse V-grade number from string (e.g., "V3" -> 3)
    private func parseVGrade(_ grade: String) -> Int? {
        let pattern = "V(\\d+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: grade.count)

        if let match = regex?.firstMatch(in: grade, options: [], range: range),
           let numberRange = Range(match.range(at: 1), in: grade) {
            return Int(grade[numberRange])
        }

        return nil
    }

    // MARK: - Historical Comparison Helpers

    /// Calculate trend direction compared to historical average
    func calculateTrend(current: Double, historical: Double) -> String {
        if current > historical { return "↑" }
        if current < historical { return "↓" }
        return "→"
    }

    /// Calculate percentage change from historical average
    func calculatePercentChange(current: Double, historical: Double) -> Double {
        guard historical > 0 else { return 0.0 }
        return ((current - historical) / historical) * 100.0
    }

    // MARK: - Progress vs Past Sessions (Placeholder - needs historical session access)

    /// Placeholder for hardest grade comparison with last N sessions
    var hardestGradeTrend: (current: String?, trend: String, change: Double)? {
        // This would need access to previous sessions
        // For now, return current value with neutral trend
        guard let current = sessionHardestGradeSent else { return nil }
        return (current: current, trend: "→", change: 0.0)
    }

    /// Placeholder for median grade comparison with last N sessions
    var medianGradeTrend: (current: String?, trend: String, change: Double)? {
        // This would need access to previous sessions
        guard let current = sessionMedianGradeSent else { return nil }
        return (current: current, trend: "→", change: 0.0)
    }

    /// Placeholder for success percentage comparison with last N sessions
    var successPercentageTrend: (current: Double, trend: String, change: Double) {
        // This would need access to previous sessions
        return (current: sessionSuccessPercentage, trend: "→", change: 0.0)
    }

    // MARK: - Personal Best Tracking

    /// Check if current session sets a new personal best for hardest grade
    var isHardestGradePersonalBest: Bool {
        // This would need access to user's historical data
        // For now, always return false
        return false
    }

    /// Check if current session sets a new personal best for success percentage
    var isSuccessPercentagePersonalBest: Bool {
        // This would need access to user's historical data
        // For now, always return false
        return false
    }

    // MARK: - Formatted Display Helpers

    /// Format success percentage for display
    var formattedSuccessPercentage: String {
        String(format: "%.1f%%", sessionSuccessPercentage)
    }

    /// Format attempts per send ratio for display
    var formattedAttemptsPerSend: String {
        guard sessionAttemptsPerSend > 0 else { return "0.0" }
        return String(format: "%.1f", sessionAttemptsPerSend)
    }

    /// Format grade band distribution for display
    var formattedGradeDistribution: [(band: String, attempts: Int, percentage: Double)] {
        let totalAttempts = Double(sessionTotalAttempts)
        guard totalAttempts > 0 else { return [] }

        return sessionGradeBandDistribution.map { band, attempts in
            (band: band, attempts: attempts, percentage: Double(attempts) / totalAttempts * 100.0)
        }.sorted { $0.band < $1.band }
    }
    
}
