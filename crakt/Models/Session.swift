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
    
    var activeRoute: Route?
    
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
            self.routes.append(route)
            self.activeRoute = nil
        }
    }
    
}
