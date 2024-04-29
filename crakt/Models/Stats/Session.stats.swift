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
                    attempt.status == .topped
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
    
    var highestGradeSuccessfullyClimbed: String? {
            routes.filter { route in
                route.attempts.contains { attempt in
                    attempt.status == .topped || attempt.status == .flash // Assuming 'top' status indicates a successful climb
                }
            }.max(by: { a, b in
                a.normalizedGrade < b.normalizedGrade
            })?.grade
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
            
            return gradingProtocol1.normalizedDifficulty(for: route1.grade!) < gradingProtocol2.normalizedDifficulty(for: route2.grade!)
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
                    aggregatedData.append((grade: route.gradeDescription!, status: status, attempts: 1))
                }
            }
        }
        
        return aggregatedData
    }
    
    func attemptsGroupedByGrade(routes: [Route]) -> [String: [Route]] {
        var attemptsByGrade: [String: [Route]] = [:]
        
        for route in routes {
            
            let grade = route.grade!
            if attemptsByGrade[grade] != nil && true{
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
            guard let endDate = endDate else { return [] }
        
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
    
}
