//
//  SessionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI
import SwiftData
import Foundation

// MARK: RouteAttempScrollView
struct RouteAttemptScrollView: View {
    var routes: [Route]
    
    var body: some View {
        ScrollViewReader { scrollView in
            if routes.isEmpty {
                // Enhanced empty state with CTA button
                VStack(spacing: 24) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    VStack(spacing: 12) {
                        Text("No routes logged yet!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Start your climbing session by logging your first route")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            } else {
                ForEach(routes, id: \.id) { route in
                    RouteLogRowItem(route: route)
                }
                .onChange(of: routes.count) {
                    // Scroll to last item whenever a new route is added
                    if let lastItem = routes.last {
                        withAnimation {
                            scrollView.scrollTo(lastItem.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}


// MARK: ViewModifiers for consistent styling
struct CardStyle: ViewModifier {
    var backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PillStyle: ViewModifier {
    var borderColor: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 2)
            )
            .background(Color.white)
            .cornerRadius(20)
    }
}

extension View {
    func cardStyle(backgroundColor: Color) -> some View {
        self.modifier(CardStyle(backgroundColor: backgroundColor))
    }

    func pillStyle(borderColor: Color) -> some View {
        self.modifier(PillStyle(borderColor: borderColor))
    }
}



struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(session: Session())
            .modelContainer(for: [Route.self, RouteAttempt.self, Session.self, User.self])
    }
}


struct SessionView: View {
    @Environment(\.modelContext) private var modelContext

    @State var session: Session
    @StateObject private var sessionManager = SessionManager.shared

    private var initialWorkoutType: WorkoutType?
    private var initialSelectedGrades: [String]?
    private var defaultClimbType: ClimbType
    private var defaultGradeSystem: GradeSystem
    private var onSessionEnd: (() -> Void)?

    init(session: Session, initialWorkoutType: WorkoutType? = nil, initialSelectedGrades: [String]? = nil, defaultClimbType: ClimbType = .boulder, defaultGradeSystem: GradeSystem = .vscale, onSessionEnd: (() -> Void)? = nil) {
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
            sessionManager.isSessionActive = true
        }
        .onDisappear {
            // Deactivate auto-lock prevention when leaving session
            sessionManager.isSessionActive = false
        }
    }
}


