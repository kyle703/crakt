//
//  RouteAttempt.swift
//  crakt
//
//  Created by Kyle Thompson on 3/21/24.
//
//

import Foundation
import SwiftData


@Model class RouteAttempt {
    var id: UUID
    var date: Date
   
    var route: Route?
    
    var status: ClimbStatus = ClimbStatus.fall
    
    public init(status: ClimbStatus) {
        self.date = Date()
        self.id = UUID()
        
        self.status = status
    }
    
    public init(date: Date, status: ClimbStatus) {
        self.id = UUID()
        
        self.date = date
        self.status = status
    }
    
    public init(date: Date, status: ClimbStatus, route: Route) {
        self.id = UUID()
        
        self.date = date
        self.status = status
        self.route = route
    }
    
}
