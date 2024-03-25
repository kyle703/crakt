//
//  User.swift
//  crakt
//
//  Created by Kyle Thompson on 3/21/24.
//
//

import Foundation
import SwiftData


@Model 
class User {
    var id: UUID
    var createdAt: Date

    var name: String
    
    public init(name: String = "Test user") {
        self.id = UUID()
        self.createdAt = Date()

        self.name = name
    }
    
}
