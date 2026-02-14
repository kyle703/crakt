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

    // Subjective difficulty rating (optional)
    var difficultyRating: DifficultyRating?

    init(status: ClimbStatus) {
        self.date = Date()
        self.id = UUID()

        self.status = status
    }

    init(date: Date, status: ClimbStatus) {
        self.id = UUID()

        self.date = date
        self.status = status
    }
}
