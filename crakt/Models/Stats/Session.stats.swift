//
//  Session.stats.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import Foundation

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
    
    /// Hardest grade successfully sent (string representation)
    var hardestGradeSent: String? {
        guard let route = successfulRoutes.max(by: { $0.normalizedGrade < $1.normalizedGrade }) else {
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
