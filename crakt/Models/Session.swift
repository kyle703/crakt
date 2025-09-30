//
//  Session.swift
//  crakt
//
//  Created by Kyle Thompson on 3/21/24.
//
//

import Foundation
import SwiftData


enum SessionStatus: Int, Codable {
    case active = 0
    case complete = 1
    case cancelled = 2
}

enum SessionPhase: String, Codable {
    case warmup = "Warm-up"
    case main = "Main Session"
    case complete = "Complete"
}

extension SessionStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active: return "Active"
        case .complete: return "Complete"
        case .cancelled: return "Cancelled"
        }
    }
}

@Model 
class Session {
    
    var id: UUID
    var user: User
    
    var startDate: Date
    var endDate: Date?
    var elapsedTime: Double = 0.0
    
    var status: SessionStatus = SessionStatus.active
    
    @Relationship(deleteRule: .cascade, inverse: \Route.session)
    var routes: [Route] = []

    @Relationship(deleteRule: .cascade, inverse: \Workout.session)
    var workouts: [Workout] = []

    @Relationship(deleteRule: .cascade, inverse: \WarmupExercise.session)
    var warmupExercisesList: [WarmupExercise] = []

    var activeRoute: Route?
    var activeWorkout: Workout?

    // Session configuration
    var climbType: ClimbType?
    var gradeSystem: GradeSystem?
    var gymName: String?

    // Warm-up state
    var currentPhase: SessionPhase?
    var warmupExercises: [WarmupExercise] = []
    var currentWarmupExerciseIndex: Int = 0
    var warmupStartTime: Date?
    var warmupCompleted: Bool = false

    // ----
    var sessionDescription = "Peak RVA"
    
    public init(user: User) {
        self.id = UUID()
        self.startDate = Date()
        self.user = user
    }
    
    public init() {
        self.id = UUID()
        self.startDate = Date()
        self.routes = []
        self.user = User()
    }
    
    public init(routes: [Route], startDate: Date) {
        self.id = UUID()
        self.startDate = startDate
        self.routes = routes
        self.user = User()
    }
    
    static var preview: Session {

        let sessionStart = Date()

        let routes = [
            Route(gradeSystem: .vscale, grade: "1", attempts: [
                RouteAttempt(date: sessionStart.addingTimeInterval(5 * 60), status: .flash),
                RouteAttempt(date: sessionStart.addingTimeInterval(10 * 60), status: .send)
            ]),
            Route(gradeSystem: .vscale, grade: "2", attempts: [
                RouteAttempt(date: sessionStart.addingTimeInterval(20 * 60), status: .flash),
                RouteAttempt(date: sessionStart.addingTimeInterval(25 * 60), status: .fall),
                RouteAttempt(date: sessionStart.addingTimeInterval(30 * 60), status: .send)
            ]),
            Route(gradeSystem: .vscale, grade: "3", attempts: [
                RouteAttempt(date: sessionStart.addingTimeInterval(40 * 60), status: .fall),
                RouteAttempt(date: sessionStart.addingTimeInterval(45 * 60), status: .fall)
            ]),
            Route(gradeSystem: .vscale, grade: "4", attempts: [
                RouteAttempt(date: sessionStart.addingTimeInterval(55 * 60), status: .fall),
                RouteAttempt(date: sessionStart.addingTimeInterval(60 * 60), status: .fall),
                RouteAttempt(date: sessionStart.addingTimeInterval(65 * 60), status: .send)
            ])
        ]

        return Session(routes: routes, startDate: sessionStart)
    }
    
    static var active_preview: Session {
        let session = Session.preview
        session.activeRoute = session.routes.first!
        return session
    }
    
}

extension Session {
    var allAttempts: [RouteAttempt] {
        // Start with an empty array or with the activeRoute if it exists
        let allRoutes = activeRoute != nil ? [activeRoute!] + routes : routes
        
        // Use flatMap to iterate over all routes and collect their attempts
        return allRoutes.flatMap { $0.attempts }
    }
    
    var tops: Int {
        let filteredAttempts = allAttempts.filter {
            $0.status == .topped || $0.status == .send || $0.status == .flash
        }
        return filteredAttempts.count
    }
    
    var tries: Int {
        return allAttempts.count
    }
    
    func addAttempt(action: Any) -> Void {
        fatalError("not implemented")
    }
    
    func clearRoute(context: ModelContext) -> Void {
        // find active route
        // remove active route from
        if activeRoute != nil {
            context.delete(activeRoute!)
        }
        activeRoute = nil
        
    }
    
    func completeSession(context: ModelContext, elapsedTime: TimeInterval) {
        logRoute()
        self.status = .complete
        self.endDate = Date()
        self.elapsedTime = elapsedTime
        
    }
    
    func cancelSession() {
        logRoute()
        self.status = .cancelled
    }
    
    func logRoute() -> Void {
        // find active rotue
        // mark inactive
        if let route = activeRoute {
            route.status = .inactive
            self.routes.append(route)
            self.activeRoute = nil
        }
    }
    
    var highestGrade : String {
        let filteredAttempts = allAttempts.filter {
            $0.status == .topped || $0.status == .send || $0.status == .flash
        }.filter { $0.route != nil }
        return filteredAttempts.max { $0.route!.gradeIndex < $1.route!.gradeIndex }?.route?.grade ?? "NA"

    }
    
}
