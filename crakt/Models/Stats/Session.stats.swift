//
//  Session.stats.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI

extension Session {
    
    // MARK: - Core Helpers (Computed Once)
    
    /// All routes including active route if present
    private var allRoutesIncludingActive: [Route] {
        activeRoute != nil ? [activeRoute!] + routes : routes
    }
    
    /// Routes that have been successfully sent (send, flash, or topped)
    private var successfulRoutes: [Route] {
        allRoutesIncludingActive.filter { route in
            route.attempts.contains { $0.status == .send || $0.status == .flash || $0.status == .topped }
        }
    }
    
    /// Routes sorted by normalized difficulty
    var routesSortedByGrade: [Route] {
        routes.sorted { $0.normalizedGrade < $1.normalizedGrade }
    }
    
    /// Routes sorted by first attempt date
    var routesSortedByDate: [Route] {
        routes.sorted { $0.firstAttemptDate ?? Date.distantPast < $1.firstAttemptDate ?? Date.distantPast }
    }
    
    // MARK: - Volume Metrics
    
    /// Total number of routes attempted (completed routes only)
    var totalRoutes: Int {
        routes.count
    }
    
    /// Total attempts across all routes (including active route)
    var totalAttempts: Int {
        allAttempts.count
    }
    
    /// Total successful sends (send, flash, or topped)
    var totalSends: Int {
        allAttempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }.count
    }
    
    /// Total number of routes successfully sent
    var successfulClimbs: Int {
        routes.filter { route in
            route.attempts.contains { $0.status == .send }
        }.count
    }
    
    /// Distribution of attempts by status (send, fall, flash, etc.)
    var attemptStatusDistribution: [ClimbStatus: Int] {
        var distribution: [ClimbStatus: Int] = [:]
        for attempt in allAttempts {
            distribution[attempt.status, default: 0] += 1
        }
        return distribution
    }
    
    // MARK: - Intensity Metrics
    
    /// Average normalized difficulty of all routes attempted
    var averageGradeAttempted: Double {
        let grades = routes.compactMap { $0.normalizedGrade }
        guard !grades.isEmpty else { return 0.0 }
        return grades.reduce(0, +) / Double(grades.count)
    }
    
    /// Hardest grade successfully sent (string representation)
    var hardestGradeSent: String? {
        guard let route = successfulRoutes.max(by: { $0.normalizedGrade < $1.normalizedGrade }) else {
            return nil
        }
        return route.gradeDescription ?? route.grade
    }
    
    /// Hardest grade flashed
    var highestGradeFlashed: String? {
        let flashedRoutes = allRoutesIncludingActive.filter { route in
            route.attempts.contains { $0.status == .flash }
        }
        guard let route = flashedRoutes.max(by: { $0.normalizedGrade < $1.normalizedGrade }) else {
            return nil
        }
        return route.gradeDescription ?? route.grade
    }
    
    /// Median grade of successfully sent routes
    var medianGradeSent: String? {
        let sorted = successfulRoutes.sorted { $0.normalizedGrade < $1.normalizedGrade }
        guard !sorted.isEmpty else { return nil }
        
        let middleIndex = sorted.count / 2
        let medianRoute = sorted.count % 2 == 0 ?
            sorted[middleIndex - 1] : sorted[middleIndex]
        
        return medianRoute.gradeDescription ?? medianRoute.grade
    }
    
    // MARK: - Efficiency Metrics
    
    /// Success percentage (sends / total attempts)
    var successPercentage: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(totalSends) / Double(totalAttempts) * 100.0
    }
    
    /// Average attempts needed per successful send
    var attemptsPerSend: Double {
        guard totalSends > 0 else { return 0.0 }
        return Double(totalAttempts) / Double(totalSends)
    }
    
    // MARK: - Distribution Analytics
    
    /// Attempts grouped by grade and status for stacked bar charts
    var attemptsByGradeAndStatus: [(grade: String, status: ClimbStatus, attempts: Int)] {
        var aggregatedData: [String: [ClimbStatus: Int]] = [:]
        
        // Group by grade, then by status
        for route in routesSortedByGrade {
            guard let grade = route.gradeDescription ?? route.grade else { continue }
            
            for attempt in route.attempts {
                if aggregatedData[grade] == nil {
                    aggregatedData[grade] = [:]
                }
                aggregatedData[grade]![attempt.status, default: 0] += 1
            }
        }
        
        // Convert to array format
        return aggregatedData.flatMap { grade, statusCounts in
            statusCounts.map { status, count in
                (grade: grade, status: status, attempts: count)
            }
        }.sorted { $0.grade < $1.grade }
    }
    
    /// Total attempts per grade (for simple distributions)
    var totalAttemptsPerGrade: [(grade: String, attempts: Int)] {
        var gradeAttempts: [String: Int] = [:]
        
        for route in routes {
            guard let grade = route.gradeDescription ?? route.grade else { continue }
            gradeAttempts[grade, default: 0] += route.attempts.count
        }
        
        return gradeAttempts.map { (grade: $0.key, attempts: $0.value) }
            .sorted { $0.grade < $1.grade }
    }
    
    /// Grade band distribution with dynamic bucketing
    var gradeBandDistribution: [(band: String, attempts: Int, normalizedRange: ClosedRange<Double>)] {
        let routesWithAttempts = allRoutesIncludingActive.filter { !$0.attempts.isEmpty && $0.grade != nil }
        guard !routesWithAttempts.isEmpty else { return [] }
        
        // Aggregate attempts by unique grade (use gradeDescription to avoid UUIDs)
        var gradeData: [(grade: String, normalized: Double, attempts: Int)] = []
        var seen: Set<String> = []
        
        for route in routesWithAttempts {
            // Use gradeDescription instead of grade to get human-readable labels
            guard let gradeLabel = route.gradeDescription ?? route.grade, !seen.contains(gradeLabel) else {
                // If we've seen this grade label, aggregate attempts
                if let gradeLabel = route.gradeDescription ?? route.grade,
                   let idx = gradeData.firstIndex(where: { $0.grade == gradeLabel }) {
                    gradeData[idx].attempts += route.attempts.count
                }
                continue
            }
            
            seen.insert(gradeLabel)
            gradeData.append((
                grade: gradeLabel,
                normalized: route.normalizedGrade,
                attempts: route.attempts.count
            ))
        }
        
        gradeData.sort { $0.normalized < $1.normalized }
        guard !gradeData.isEmpty else { return [] }
        
        // Cap distribution at hardest successful send
        let maxSendNormalized = successfulRoutes.map { $0.normalizedGrade }.max()
        let filteredData = maxSendNormalized != nil ?
            gradeData.filter { $0.normalized <= maxSendNormalized! } : gradeData
        
        guard !filteredData.isEmpty else { return [] }
        
        let minGrade = filteredData.first!.normalized
        let maxGrade = filteredData.last!.normalized
        let gradeRange = maxGrade - minGrade
        
        // Determine bucket count based on range
        let bucketCount = min(max(2, filteredData.count),
                            gradeRange <= 3.0 ? 3 : gradeRange <= 6.0 ? 4 : 5)
        
        // Single bucket case
        guard bucketCount > 1 else {
            let totalAttempts = filteredData.reduce(0) { $0 + $1.attempts }
            let label = filteredData.count == 1 ?
                filteredData[0].grade :
                "\(filteredData.first!.grade)-\(filteredData.last!.grade)"
            return [(band: label, attempts: totalAttempts, normalizedRange: minGrade...maxGrade)]
        }
        
        // Multiple buckets
        var distribution: [(band: String, attempts: Int, normalizedRange: ClosedRange<Double>)] = []
        let bucketSize = gradeRange / Double(bucketCount)
        
        for i in 0..<bucketCount {
            let rangeStart = minGrade + Double(i) * bucketSize
            let rangeEnd = i == bucketCount - 1 ? maxGrade + 0.01 : rangeStart + bucketSize
            
            let gradesInBucket = filteredData.filter { $0.normalized >= rangeStart && $0.normalized < rangeEnd }
            guard !gradesInBucket.isEmpty else { continue }
            
            let attemptsInBucket = gradesInBucket.reduce(0) { $0 + $1.attempts }
            let label = gradesInBucket.count == 1 ?
                gradesInBucket[0].grade :
                "\(gradesInBucket.first!.grade)-\(gradesInBucket.last!.grade)"
            
            distribution.append((band: label, attempts: attemptsInBucket, normalizedRange: rangeStart...rangeEnd))
        }
        
        return distribution
    }
    
    // MARK: - Timeline Data
    
    /// All attempts with normalized timestamps (for timeline charts)
    var normalizedAttempts: [(normalizedTime: Date, grade: String, status: ClimbStatus, routeId: UUID)] {
        guard endDate != nil else { return [] }
        
        return routesSortedByGrade.flatMap { route -> [(Date, String, ClimbStatus, UUID)] in
            guard let grade = route.grade else { return [] }
            return route.attempts.map { (
                normalizedTime: $0.date,
                grade: grade,
                status: $0.status,
                routeId: route.id
            )}
        }
    }
    
    /// All attempts with their associated routes (for detailed analysis)
    var attemptsWithRoute: [(attemptNumber: Int, attemptDate: Date, status: ClimbStatus, route: Route)] {
        routes
            .flatMap { route in
                route.attempts.map { ($0.date, $0.status, route) }
            }
            .sorted { $0.0 < $1.0 }
            .enumerated()
            .map { (attemptNumber: $0 + 1, attemptDate: $1.0, status: $1.1, route: $1.2) }
    }
    
    // MARK: - DI-Normalized Metrics (for cross-session comparison)
    
    /// Hardest grade sent as Difficulty Index (0-200 scale)
    var hardestGradeDI: Int {
        guard let route = successfulRoutes.max(by: { $0.normalizedGrade < $1.normalizedGrade }) else {
            return 0
        }
        let di = Int(route.normalizedGrade * 10)
        return max(0, min(200, di))
    }
    
    /// Median grade sent as Difficulty Index (0-200 scale)
    var medianGradeDI: Int {
        let sorted = successfulRoutes.sorted { $0.normalizedGrade < $1.normalizedGrade }
        guard !sorted.isEmpty else { return 0 }
        
        let middleIndex = sorted.count / 2
        let medianRoute = sorted.count % 2 == 0 ?
            sorted[middleIndex - 1] : sorted[middleIndex]
        
        let di = Int(medianRoute.normalizedGrade * 10)
        return max(0, min(200, di))
    }
    
    // MARK: - Formatted Display Helpers
    
    /// Success percentage formatted for display
    var formattedSuccessPercentage: String {
        String(format: "%.1f%%", successPercentage)
    }
    
    /// Attempts per send formatted for display
    var formattedAttemptsPerSend: String {
        guard attemptsPerSend > 0 else { return "0.0" }
        return String(format: "%.1f", attemptsPerSend)
    }
    
    /// Grade distribution with percentages (for display)
    var formattedGradeDistribution: [(band: String, attempts: Int, percentage: Double)] {
        guard totalAttempts > 0 else { return [] }
        let total = Double(totalAttempts)
        
        return gradeBandDistribution.map {
            (band: $0.band, attempts: $0.attempts, percentage: Double($0.attempts) / total * 100.0)
        }
    }
    
    // MARK: - Utility Functions
    
    /// Calculate trend arrow compared to historical value
    func calculateTrend(current: Double, historical: Double) -> String {
        if current > historical { return "↑" }
        if current < historical { return "↓" }
        return "→"
    }
    
    /// Calculate percentage change from historical value
    func calculatePercentChange(current: Double, historical: Double) -> Double {
        guard historical > 0 else { return 0.0 }
        return ((current - historical) / historical) * 100.0
    }
    
    // MARK: - Session Summary (for historical tracking)
    
    /// Compute summary metrics for cross-session analysis
    func computeSummaryMetrics() -> SessionSummary? {
        guard status == .complete || status == .cancelled || status == .active else { return nil }
        
        return SessionSummary(
            hardestGradeDI: hardestGradeDI,
            medianGradeDI: medianGradeDI,
            sendCount: totalSends,
            attemptCount: totalAttempts,
            sendPercent: successPercentage,
            attemptsPerSend: attemptsPerSend,
            sessionDate: startDate
        )
    }
}

// MARK: - Session Summary Data Structure

/// Summary metrics for a single session (for historical comparison)
struct SessionSummary {
    /// DI-normalized hardest grade sent (0-200 scale)
    let hardestGradeDI: Int
    
    /// DI-normalized median grade sent (0-200 scale)
    let medianGradeDI: Int
    
    /// Total successful sends in the session
    let sendCount: Int
    
    /// Total attempts in the session
    let attemptCount: Int
    
    /// Success percentage (0.0-100.0)
    let sendPercent: Double
    
    /// Attempts per send ratio
    let attemptsPerSend: Double
    
    /// Session date for time-series analysis
    let sessionDate: Date
}
