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
    @State private var selectedTab: UnifiedSessionHeader.Tab = .routes

    private var initialWorkoutType: WorkoutType?
    private var initialSelectedGrades: [String]?
    private var defaultClimbType: ClimbType
    private var defaultGradeSystem: GradeSystem
    private var onSessionEnd: (() -> Void)?

    init(session: Session,
         initialWorkoutType: WorkoutType? = nil,
         initialSelectedGrades: [String]? = nil,
         defaultClimbType: ClimbType = .boulder,
         defaultGradeSystem: GradeSystem = .vscale,
         onSessionEnd: (() -> Void)? = nil) {

        self.session = session
        self.initialWorkoutType = initialWorkoutType
        self.initialSelectedGrades = initialSelectedGrades
        self.defaultClimbType = defaultClimbType
        self.defaultGradeSystem = defaultGradeSystem
        self.onSessionEnd = onSessionEnd

        // Debug logging
        print("🏗️ SessionTabView - Initializing with:")
        print("  - Session climbType: \(session.climbType ?? .boulder)")
        print("  - Session gradeSystem: \(session.gradeSystem ?? .vscale)")
        print("  - Default climbType: \(defaultClimbType)")
        print("  - Default gradeSystem: \(defaultGradeSystem)")

        self._selectedGradeSystem = State(initialValue: session.gradeSystem ?? defaultGradeSystem)
        self._selectedClimbType = State(initialValue: session.climbType ?? defaultClimbType)

        // Debug logging for final values
        print("  - Final selectedClimbType: \(session.climbType ?? defaultClimbType)")
        print("  - Final selectedGradeSystem: \(session.gradeSystem ?? defaultGradeSystem)")

        // Initialize workout orchestrator with session
        let tempContext = (try? ModelContainer(for: Workout.self, WorkoutSet.self, WorkoutRep.self))?.mainContext ?? (try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext)
        self._workoutOrchestrator = StateObject(wrappedValue: WorkoutOrchestrator(session: session, modelContext: tempContext))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Unified Session Header - always visible
            UnifiedSessionHeader(session: session,
                                stopwatch: stopwatch,
                                workoutOrchestrator: workoutOrchestrator,
                                onSessionEnd: onSessionEnd,
                                selectedClimbType: $selectedClimbType,
                                selectedGradeSystem: $selectedGradeSystem,
                                selectedTab: $selectedTab)
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

                    // Create initial route if none exists
                    if session.activeRoute == nil {
                        createInitialRoute()
                    }
                }
                .onChange(of: selectedClimbType) {
                    handleClimbTypeChange()
                }
                .onChange(of: selectedGradeSystem) {
                    handleGradeSystemChange()
                }


            // Main content area - show different content based on selected tab
            switch selectedTab {
            case .routes:
                // Always show ActiveRouteCardView (auto-creates route if needed)
                ActiveRouteCardView(
                    session: session,
                    stopwatch: stopwatch,
                    workoutOrchestrator: workoutOrchestrator,
                    selectedGrade: $selectedGrade,
                    selectedGradeSystem: $selectedGradeSystem
                )

            case .progress:
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

                        // Workout summary (if active or recently completed) - only in progress tab
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

            case .menu:
                ScrollView {
                    VStack(spacing: 20) {
                        // Session controls
                        VStack(spacing: 16) {
                            Text("Session Controls")
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

                        
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private func handleClimbTypeChange() {
        print("🔄 SessionTabView - Climb type changed to \(selectedClimbType)")

        guard let activeRoute = session.activeRoute else {
            print("ℹ️ No active route to convert")
            return
        }

        // Determine the appropriate grade system for the new climb type
        let newGradeSystem = selectedClimbType == .boulder ? GradeSystem.vscale : GradeSystem.yds

        // If route has no grade, just update the climb type and grade system
        guard let currentGrade = activeRoute.grade else {
            print("📝 Route has no grade, just updating climb type and grade system")
            activeRoute.gradeSystem = newGradeSystem
            activeRoute.climbType = selectedClimbType
            do {
                try modelContext.save()
                print("💾 Updated route climb type and grade system")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
            return
        }

        print("📝 Converting grade '\(currentGrade)' from \(activeRoute.gradeSystem.description) to \(newGradeSystem.description)")

        // Try direct conversion first
        let convertedGrade = DifficultyIndex.convertGrade(
            fromGrade: currentGrade,
            fromSystem: activeRoute.gradeSystem,
            fromType: activeRoute.climbType,
            toSystem: newGradeSystem,
            toType: selectedClimbType
        )

        if let convertedGrade = convertedGrade {
            print("🔄 Successfully converted to '\(convertedGrade)'")

            // Update the existing route
            activeRoute.grade = convertedGrade
            activeRoute.gradeSystem = newGradeSystem
            activeRoute.climbType = selectedClimbType

            do {
                try modelContext.save()
                print("💾 Updated route with converted grade")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
        } else {
            print("⚠️ Direct conversion failed, trying fallback")

            // Fallback: Try to convert via normalized difficulty
            let normalized = activeRoute.gradeSystem._protocol.normalizedDifficulty(for: currentGrade)
            let fallbackGrade = newGradeSystem._protocol.grade(forNormalizedDifficulty: normalized)

            print("🔄 Fallback conversion: normalized=\(normalized) -> '\(fallbackGrade)'")

            activeRoute.grade = fallbackGrade
            activeRoute.gradeSystem = newGradeSystem
            activeRoute.climbType = selectedClimbType

            do {
                try modelContext.save()
                print("💾 Updated route with fallback conversion")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
        }
    }

    private func handleGradeSystemChange() {
        print("🔄 SessionTabView - Grade system changed to \(selectedGradeSystem)")

        guard let activeRoute = session.activeRoute else {
            print("ℹ️ No active route to convert")
            return
        }

        // If route has no grade, just update the grade system
        guard let currentGrade = activeRoute.grade else {
            print("📝 Route has no grade, just updating grade system")
            activeRoute.gradeSystem = selectedGradeSystem
            activeRoute.climbType = selectedClimbType
            do {
                try modelContext.save()
                print("💾 Updated route grade system")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
            return
        }

        print("📝 Converting grade '\(currentGrade)' from \(activeRoute.gradeSystem.description) to \(selectedGradeSystem.description)")

        // Try direct conversion first
        let convertedGrade = DifficultyIndex.convertGrade(
            fromGrade: currentGrade,
            fromSystem: activeRoute.gradeSystem,
            fromType: activeRoute.climbType,
            toSystem: selectedGradeSystem,
            toType: selectedClimbType
        )

        if let convertedGrade = convertedGrade {
            print("🔄 Successfully converted to '\(convertedGrade)'")

            // Update the existing route
            activeRoute.grade = convertedGrade
            activeRoute.gradeSystem = selectedGradeSystem
            activeRoute.climbType = selectedClimbType

            do {
                try modelContext.save()
                print("💾 Updated route with converted grade")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
        } else {
            print("⚠️ Direct conversion failed, trying fallback")

            // Fallback: Try to convert via normalized difficulty
            let normalized = activeRoute.gradeSystem._protocol.normalizedDifficulty(for: currentGrade)
            let fallbackGrade = selectedGradeSystem._protocol.grade(forNormalizedDifficulty: normalized)

            print("🔄 Fallback conversion: normalized=\(normalized) -> '\(fallbackGrade)'")

            activeRoute.grade = fallbackGrade
            activeRoute.gradeSystem = selectedGradeSystem
            activeRoute.climbType = selectedClimbType

            do {
                try modelContext.save()
                print("💾 Updated route with fallback conversion")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
        }
    }

    private func createInitialRoute() {
        // Determine the grade for the initial route
        var initialGrade: String

        // Priority 1: Use workout's selected grade if workout is active
        if workoutOrchestrator.isWorkoutActive,
           let workoutGrade = workoutOrchestrator.activeWorkout?.selectedGrade {
            initialGrade = workoutGrade
        }
        // Priority 2: Use initial selected grades from session start
        else if let selectedGrade = initialSelectedGrades?.first {
            initialGrade = selectedGrade
        }
        // Priority 3: Use sensible defaults based on grade system
        else {
            initialGrade = selectedGradeSystem._protocol.grades.first ?? "V0"
        }

        // Create the initial route
        let newRoute = Route(
            gradeSystem: selectedGradeSystem,
            grade: initialGrade,
            session: session
        )
        newRoute.status = .active
        newRoute.climbType = selectedClimbType

        modelContext.insert(newRoute)
        session.activeRoute = newRoute

        // Save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save initial route: \(error)")
        }
    }

}

#Preview {
    let session = Session.active_preview
    SessionTabView(session: session)
        .modelContainer(for: [Route.self, RouteAttempt.self, Session.self])
}
