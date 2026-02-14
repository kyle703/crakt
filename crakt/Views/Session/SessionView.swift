//
//  SessionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI
import SwiftData
import Foundation

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext

    @State var session: Session
    @StateObject private var sessionManager = SessionManager.shared

    private var initialWorkoutType: WorkoutType?
    private var initialSelectedGrades: [String]?
    private var defaultClimbType: ClimbType
    private var defaultGradeSystem: GradeSystem
    private var onSessionEnd: ((Session?) -> Void)?

    init(session: Session, initialWorkoutType: WorkoutType? = nil, initialSelectedGrades: [String]? = nil, defaultClimbType: ClimbType = .boulder, defaultGradeSystem: GradeSystem = .vscale, onSessionEnd: ((Session?) -> Void)? = nil) {
        self.session = session
        self.initialWorkoutType = initialWorkoutType
        self.initialSelectedGrades = initialSelectedGrades
        self.defaultClimbType = defaultClimbType
        self.defaultGradeSystem = defaultGradeSystem
        self.onSessionEnd = onSessionEnd
    }

    var body: some View {
        // Use the consolidated SessionTabView which handles all session functionality
        SessionTabView(
            session: session,
            initialWorkoutType: initialWorkoutType,
            initialSelectedGrades: initialSelectedGrades,
            defaultClimbType: defaultClimbType,
            defaultGradeSystem: defaultGradeSystem,
            onSessionEnd: onSessionEnd
        )
        .environment(\.modelContext, modelContext)
        .onAppear {
            // Activate auto-lock prevention for active climbing sessions
            sessionManager.startSession(sessionId: session.id)
        }
        .onDisappear {
            // Deactivate auto-lock prevention when leaving session
            if session.status != .active {
                sessionManager.endSession()
            }
        }
    }
}

