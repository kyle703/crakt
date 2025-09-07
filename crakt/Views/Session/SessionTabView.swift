//
//  SessionTabView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/20/25.
//

import SwiftUI
import SwiftData

struct SessionTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var stopwatch = Stopwatch()
    @State var session: Session
    @StateObject private var workoutOrchestrator: WorkoutOrchestrator

    @State var selectedGradeSystem: GradeSystem
    @State var selectedClimbType: ClimbType
    @State var selectedGrade: String?
    @State private var selectedTab: Tab = .routes

    enum Tab {
        case routes
        case progress
        case menu
    }

    private var initialWorkoutType: WorkoutType?
    private var initialSelectedGrades: [String]?
    private var defaultClimbType: ClimbType
    private var defaultGradeSystem: GradeSystem
    private var onSessionEnd: (() -> Void)?

    init(workoutOrchestrator: WorkoutOrchestrator,
         session: Session,
         initialWorkoutType: WorkoutType? = nil,
         initialSelectedGrades: [String]? = nil,
         defaultClimbType: ClimbType = .boulder,
         defaultGradeSystem: GradeSystem = .vscale,
         onSessionEnd: (() -> Void)? = nil) {

        self._workoutOrchestrator = StateObject(wrappedValue: workoutOrchestrator)
        self.session = session
        self.initialWorkoutType = initialWorkoutType
        self.initialSelectedGrades = initialSelectedGrades
        self.defaultClimbType = defaultClimbType
        self.defaultGradeSystem = defaultGradeSystem
        self.onSessionEnd = onSessionEnd

        self._selectedGradeSystem = State(initialValue: session.gradeSystem ?? defaultGradeSystem)
        self._selectedClimbType = State(initialValue: session.climbType ?? defaultClimbType)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Session Header - always visible
            SessionHeader(session: session,
                         stopwatch: stopwatch,
                         workoutOrchestrator: workoutOrchestrator,
                         onSessionEnd: onSessionEnd,
                         selectedClimbType: $selectedClimbType,
                         selectedGradeSystem: $selectedGradeSystem)
                .onAppear {
                    stopwatch.start()
                    workoutOrchestrator.updateModelContext(modelContext)

                    // Start initial workout if specified
                    if let workoutType = initialWorkoutType {
                        if workoutType == .pyramid {
                            let startGrade = initialSelectedGrades?.first
                            let peakGrade = initialSelectedGrades?.dropFirst().first
                            _ = workoutOrchestrator.startWorkout(type: workoutType, pyramidStartGrade: startGrade, pyramidPeakGrade: peakGrade)
                        } else {
                            _ = workoutOrchestrator.startWorkout(type: workoutType, selectedGrade: initialSelectedGrades?.first)
                        }
                    }
                }
                .onChange(of: selectedClimbType) {
                    session.clearRoute(context: modelContext)
                }
                .onChange(of: selectedGradeSystem) {
                    session.clearRoute(context: modelContext)
                }

            // Workout summary (if active or recently completed)
            if workoutOrchestrator.isWorkoutActive || (workoutOrchestrator.activeWorkout != nil && workoutOrchestrator.activeWorkout?.isCompleted == true) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Workout icon
                        Image(systemName: workoutOrchestrator.activeWorkout?.type.icon ?? "figure.climbing")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(workoutOrchestrator.activeWorkout?.type.rawValue ?? "Workout")
                                .font(.headline)
                                .fontWeight(.semibold)

                            let progress = workoutOrchestrator.currentWorkoutProgress
                            if progress.totalSets > 0 {
                                Text("Set \(progress.currentSet)/\(progress.totalSets) • Rep \(progress.completedReps)/\(progress.totalReps)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int((workoutOrchestrator.activeWorkout?.completionPercentage ?? 0) * 100))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * (workoutOrchestrator.activeWorkout?.completionPercentage ?? 0), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4)
                .padding(.horizontal, 16)
            }

            // Tab View for main content
            TabView(selection: $selectedTab) {
                // Routes Tab
                routesTabContent
                    .tabItem {
                        Label("Routes", systemImage: "figure.climbing")
                    }
                    .tag(Tab.routes)

                // Progress Tab
                progressTabContent
                    .tabItem {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                    .tag(Tab.progress)

                // Menu Tab
                menuTabContent
                    .tabItem {
                        Label("Menu", systemImage: "line.horizontal.3")
                    }
                    .tag(Tab.menu)
            }
            .tint(.blue)  // Follow iOS design guidelines
        }
    }

    private var routesTabContent: some View {
        ActiveRouteCardView(
            session: session,
            stopwatch: stopwatch,
            workoutOrchestrator: workoutOrchestrator,
            selectedGrade: $selectedGrade,
            selectedGradeSystem: $selectedGradeSystem
        )
    }

    private var progressTabContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session stats overview
                VStack(spacing: 16) {
                    Text("Session Progress")
                        .font(.title2)
                        .fontWeight(.bold)

                                    HStack(spacing: 20) {
                    StatCardView(icon: "figure.climbing", title: "\(session.routes.count)", subtitle: "Routes", color: .blue)
                    StatCardView(icon: "arrow.up.circle", title: "\(session.totalAttempts)", subtitle: "Attempts", color: .green)
                    StatCardView(icon: "clock", title: stopwatch.totalTime.formatted, subtitle: "Duration", color: .orange)
                }
                }
                .padding(.horizontal)

                // Workout progress (if active)
                if workoutOrchestrator.isWorkoutActive {
                    VStack(spacing: 12) {
                        Text("Workout Progress")
                            .font(.title3)
                            .fontWeight(.semibold)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * (workoutOrchestrator.activeWorkout?.completionPercentage ?? 0), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            let progress = workoutOrchestrator.currentWorkoutProgress
                            if progress.totalSets > 0 {
                                Text("Set \(progress.currentSet)/\(progress.totalSets) • Rep \(progress.completedReps)/\(progress.totalReps)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(workoutOrchestrator.currentRepDescription)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4)
                    .padding(.horizontal)
                }

                // Recent attempts
                VStack(spacing: 12) {
                    Text("Recent Attempts")
                        .font(.title3)
                        .fontWeight(.semibold)

                    if let activeRoute = session.activeRoute {
                        ForEach(activeRoute.attempts.sorted(by: { $0.date > $1.date }).prefix(5), id: \.id) { attempt in
                            HStack {
                                Image(systemName: attempt.status.iconName)
                                    .foregroundColor(attempt.status.color)
                                Text(attempt.status.description)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(attempt.date.formatted(.relative(presentation: .named)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    } else {
                        Text("No recent attempts")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
    }

    private var menuTabContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session controls
                VStack(spacing: 16) {
                    Text("Session Controls")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Pause/Resume and End Session buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            if stopwatch.isRunning {
                                stopwatch.stop()
                            } else {
                                stopwatch.start()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: stopwatch.isRunning ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                Text(stopwatch.isRunning ? "Pause" : "Resume")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Button(action: {
                            onSessionEnd?()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title2)
                                Text("End Session")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Workout selector
                    WorkoutSelectorView(orchestrator: workoutOrchestrator)
                        .padding(.horizontal)
                }

                // Settings
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Grade system picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade System")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        GradeSystemSelectionView(selectedClimbType: $selectedClimbType, selectedGradeSystem: $selectedGradeSystem)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    let tempContext = (try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext)
    let workoutOrchestrator = WorkoutOrchestrator(session: Session.active_preview, modelContext: tempContext)
    let session = Session.active_preview
    SessionTabView(workoutOrchestrator: workoutOrchestrator, session: session)
        .modelContainer(for: [Route.self, RouteAttempt.self, Session.self])
}
