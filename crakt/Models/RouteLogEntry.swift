//
//  RouteLogEntry.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI
import CoreData



extension Session {
    func toActiveSession() -> ActiveSession {
        let activeSession = ActiveSession()
        
        if let startDate = self.start {
            activeSession.start = startDate
        }

        if let routesSet = self.routes as? Set<Route> {
            activeSession.routes = routesSet.map { $0.toRouteLogEntry() }
        }
                
        return activeSession
    }
    
    convenience init(from activeSession: ActiveSession, context: NSManagedObjectContext) {
        self.init(context: context)
        self.configure(from: activeSession, context: context)
    }

    func configure(from activeSession: ActiveSession, context: NSManagedObjectContext) {
        self.start = activeSession.start
        let routeEntities = activeSession.routes.map { $0.toRoute(context: context) }
        self.routes = NSSet(array: routeEntities)
    }
}

extension ActiveSession {
    func toSession(for user: User, context: NSManagedObjectContext) -> Session {
        let session = Session(context: context)
        
        session.start = self.start
        session.user = user
        session.id = self.id
        
        let routeEntities = self.routes.map { $0.toRoute(context: context) }
        session.routes = NSSet(array: routeEntities)
        
        
        return session
    }
}

extension Route {
    func toRouteLogEntry() -> RouteLogEntry {
        var entry = RouteLogEntry()
        
        entry.grade = self.grade ?? ""
        entry.id = self.id!
        
        if let gradeSystemValue = GradeSystem(rawValue: self.gradeSystem) {
            entry.gradeSystem = GradeSystems.systems[gradeSystemValue]!
        }

        if let attemptsSet = self.attempts as? Set<RouteAttempt> {
            entry.attempts = attemptsSet.map { $0.toClimbAttempt() }
        }
        
        return entry
    }
}

extension RouteLogEntry {
    func toRoute(context: NSManagedObjectContext) -> Route {
        let route = Route(context: context)
        
        route.grade = self.grade
        route.gradeSystem = self.gradeSystem.system.rawValue
        route.id = self.id
        
        let attemptEntities = self.attempts.map { $0.toRouteAttempt(context: context) }
        route.attempts = NSSet(array: attemptEntities)
        
        return route
    }
}

extension RouteAttempt {
    func toClimbAttempt() -> ClimbAttempt {
        return ClimbAttempt(status: ClimbStatus(rawValue: self.status) ?? ClimbStatus.fall, date: self.date ?? Date(), id: self.id ?? UUID())
    }
}

extension ClimbAttempt {
    func toRouteAttempt(context: NSManagedObjectContext) -> RouteAttempt {
        let routeAttempt = RouteAttempt(context: context)
        
        routeAttempt.date = self.date
        routeAttempt.status = self.status.rawValue
        routeAttempt.id = self.id
                
        return routeAttempt
    }
}


class ActiveSession: ObservableObject, Hashable, Identifiable {
    
    var start: Date = Date()
    @Published var elapsedTime: TimeInterval = 0
    @Published var routes: [RouteLogEntry] = []
    @Published var activeRoute: RouteLogEntry?
    var id: UUID = UUID()
    
    var allAttempts: [ClimbAttempt] {
            var attempts = routes.flatMap { $0.attempts }
            if let activeAttempts = activeRoute?.attempts {
                attempts.append(contentsOf: activeAttempts)
            }
            return attempts
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
    
    func moveActiveRouteToLogs() {
            if let route = activeRoute {
                routes.append(route)
                activeRoute = nil
            }
        }
    
    func clearRoute() {
        if activeRoute?.attempts.count ?? 0 > 0 {
            moveActiveRouteToLogs()
        }
        activeRoute = nil
    }
    
    static func == (lhs: ActiveSession, rhs: ActiveSession) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
    }
}

struct ClimbAttempt {
    var status: ClimbStatus
    var date: Date = Date()
    var id: UUID = UUID()
}

struct RouteLogEntry {
    var gradeSystem: AnyGradeProtocol = GradeSystems.systems.first!.value 

    var grade: String = ""
    var attempts: [ClimbAttempt] = []
    var id: UUID = UUID()
    
    var date: Date? {
        return attempts.last?.date
    }
    
    var actionCounts: [ClimbStatus: Int] {
        var counts: [ClimbStatus: Int] = [:]
        
        for attempt in attempts {
            counts[attempt.status, default: 0] += 1
        }
        
        return counts
    }
    
    mutating func addClimbAttempt(with status: ClimbStatus, on date: Date = Date()) {
        let newAttempt = ClimbAttempt(status: status, date: date)
        attempts.append(newAttempt)
    }
}
