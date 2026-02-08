//
//  SessionTabView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/20/25.
//

import SwiftUI
import SwiftData
import UIKit

struct SessionTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var stopwatch = Stopwatch()
    @State var session: Session
    @StateObject private var workoutOrchestrator: WorkoutOrchestrator

    @State var selectedGradeSystem: GradeSystem
    @State var selectedClimbType: ClimbType
    @State var selectedGrade: String?
    @State private var selectedTab: UnifiedSessionHeader.Tab = .routes
    
    // Feedback popover state (shown at this level to overlay header)
    @State private var showFeedbackPopover = false
    @State private var feedbackPopoverRoute: Route?
    @State private var feedbackPopoverAttempt: RouteAttempt?
    
    // Route review sheet state (triggered from popover accept)
    @State private var showRouteReviewSheet = false
    @State private var reviewSheetRoute: Route?
    @State private var reviewSheetAttempt: RouteAttempt?

    private var initialWorkoutType: WorkoutType?
    private var initialSelectedGrades: [String]?
    private var defaultClimbType: ClimbType
    private var defaultGradeSystem: GradeSystem
    private var onSessionEnd: ((Session?) -> Void)?
    
    private var activeRouteCardView: some View {
        ActiveRouteCardView(
            session: session,
            stopwatch: stopwatch,
            workoutOrchestrator: workoutOrchestrator,
            selectedGrade: $selectedGrade,
            selectedGradeSystem: $selectedGradeSystem,
            onShowFeedbackPopover: { route, attempt in
                feedbackPopoverRoute = route
                feedbackPopoverAttempt = attempt
                showFeedbackPopover = true
            }
        )
    }

    init(session: Session,
         initialWorkoutType: WorkoutType? = nil,
         initialSelectedGrades: [String]? = nil,
         defaultClimbType: ClimbType = .boulder,
         defaultGradeSystem: GradeSystem = .vscale,
         onSessionEnd: ((Session?) -> Void)? = nil) {

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
            // Show warmup mode if session is in warmup phase
            if session.currentPhase == .warmup {
                WarmupModeView(session: $session)
            } else {
                // Unified Session Header - always visible during main session
                UnifiedSessionHeader(session: session,
                                    stopwatch: stopwatch,
                                    workoutOrchestrator: workoutOrchestrator,
                                    onSessionEnd: onSessionEnd,
                                    selectedClimbType: $selectedClimbType,
                                    selectedGradeSystem: $selectedGradeSystem,
                                    selectedTab: $selectedTab,
                                    showFeedbackBanner: $showFeedbackPopover,
                                    feedbackRoute: feedbackPopoverRoute,
                                    feedbackAttempt: feedbackPopoverAttempt,
                                    onFeedbackAccept: {
                                        // Show full review sheet
                                        if let route = feedbackPopoverRoute {
                                            reviewSheetRoute = route
                                            reviewSheetAttempt = feedbackPopoverAttempt
                                            showRouteReviewSheet = true
                                        }
                                        feedbackPopoverRoute = nil
                                        feedbackPopoverAttempt = nil
                                    },
                                    onFeedbackDismiss: {
                                        feedbackPopoverRoute = nil
                                        feedbackPopoverAttempt = nil
                                    })
                .onAppear {
                    // Set up background/foreground notifications for timer persistence
                    NotificationCenter.default.addObserver(
                        forName: UIApplication.willResignActiveNotification,
                        object: nil,
                        queue: .main
                    ) { [weak stopwatch] _ in
                        stopwatch?.enterBackground()
                    }

                    NotificationCenter.default.addObserver(
                        forName: UIApplication.didBecomeActiveNotification,
                        object: nil,
                        queue: .main
                    ) { [weak stopwatch] _ in
                        stopwatch?.enterForeground()
                    }

                    // Start stopwatch if not already running
                    if !stopwatch.isRunning {
                        stopwatch.start()
                    }

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

                    // Create initial route if none exists, or sync state with existing route
                    if session.activeRoute == nil {
                        createInitialRoute()
                    } else {
                        // Sync selected state with existing route's configuration
                        if let route = session.activeRoute {
                            if route.gradeSystem != selectedGradeSystem {
                                print("🔄 Syncing selectedGradeSystem to match existing route: \(route.gradeSystem)")
                                selectedGradeSystem = route.gradeSystem
                            }
                            if route.climbType != selectedClimbType {
                                print("🔄 Syncing selectedClimbType to match existing route: \(route.climbType)")
                                selectedClimbType = route.climbType
                            }
                        }
                    }
                }
                .onDisappear {
                    // Clean up notifications
                    NotificationCenter.default.removeObserver(self)
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
                activeRouteCardView

            case .progress:
                ScrollView {
                    VStack(spacing: 24) {
                        // Grade Pyramid - Sends breakdown by grade
                        GradePyramidChartView(
                            session: session,
                            currentGradeSystem: selectedGradeSystem
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4)
                        .padding(.horizontal)
                        
                        // Session Activity Chart - Shows routes and attempts over time
                        DifficultyTimelineChartView(
                            session: session,
                            currentGradeSystem: selectedGradeSystem
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4)
                        .padding(.horizontal)

                        // Session Volume Stats
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "number.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                Text("Session Volume")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }

                            HStack(spacing: 16) {
                                StatCardView(
                                    icon: "arrow.up.circle",
                                    title: "\(session.totalAttempts)",
                                    subtitle: "Total Attempts",
                                    color: .blue
                                )

                                StatCardView(
                                    icon: "checkmark.circle",
                                    title: "\(session.totalSends)",
                                    subtitle: "Sends",
                                    color: .green
                                )

                                StatCardView(
                                    icon: "percent",
                                    title: session.formattedSuccessPercentage,
                                    subtitle: "Success Rate",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Intensity Benchmarks
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                Text("Intensity Benchmarks")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }

                            HStack(spacing: 16) {
                                if let hardestGrade = session.hardestGradeSent {
                                    StatCardView(
                                        icon: "mountain.2.fill",
                                        title: hardestGrade,
                                        subtitle: "Hardest Sent",
                                        color: .red
                                    )
                                } else {
                                    StatCardView(
                                        icon: "mountain.2.fill",
                                        title: "—",
                                        subtitle: "Hardest Sent",
                                        color: .gray
                                    )
                                }

                                if let medianGrade = session.medianGradeSent {
                                    StatCardView(
                                        icon: "chart.line.uptrend.xyaxis",
                                        title: medianGrade,
                                        subtitle: "Median Grade",
                                        color: .purple
                                    )
                                } else {
                                    StatCardView(
                                        icon: "chart.line.uptrend.xyaxis",
                                        title: "—",
                                        subtitle: "Median Grade",
                                        color: .gray
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Efficiency Metrics
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "target")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                Text("Efficiency")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }

                            HStack(spacing: 16) {
                                StatCardView(
                                    icon: "repeat",
                                    title: session.formattedAttemptsPerSend,
                                    subtitle: "Attempts/Send",
                                    color: .blue
                                )

                                StatCardView(
                                    icon: "gauge.with.dots.needle.50percent",
                                    title: "2.5",
                                    subtitle: "Baseline",
                                    color: .gray
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                }

            case .menu:
                ScrollView {
                    VStack(spacing: 20) {
                        // Grade System Picker (top)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Grade System")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            SessionGradeSystemPicker(
                                selectedClimbType: $selectedClimbType,
                                selectedGradeSystem: $selectedGradeSystem
                            )
                            .padding(.horizontal)
                        }
                        
                        // Session Info Cards
                        SessionInfoCardsView(
                            session: session,
                            selectedGradeSystem: selectedGradeSystem
                        )
                        .padding(.horizontal)
                        
                        // End Session button
                        Button(action: {
                            let elapsed: TimeInterval
                            if stopwatch.isRunning {
                                stopwatch.stop()
                            }
                            elapsed = stopwatch.totalTime > 0 ? stopwatch.totalTime : Date().timeIntervalSince(session.startDate)

                            session.completeSession(context: modelContext, elapsedTime: elapsed)

                            do {
                                try modelContext.save()
                            } catch {
                                print("❌ Failed to save completed session: \(error)")
                            }

                            onSessionEnd?(session)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title2)
                                Text("End Session")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 16)
                }
            }
            }
        }
        .sheet(isPresented: $showRouteReviewSheet) {
            if let route = reviewSheetRoute {
                RouteReviewView(
                    route: route,
                    attempt: reviewSheetAttempt,
                    isAutoPresented: true,
                    onSave: { rating, wallAngles, holdTypes, movementStyles, experiences in
                        // Save difficulty rating to attempt if provided
                        if let rating = rating, let attempt = reviewSheetAttempt {
                            attempt.difficultyRating = rating
                        }
                        // Save route characteristics
                        route.wallAngles = wallAngles
                        route.holdTypes = holdTypes
                        route.movementStyles = movementStyles
                        route.experiences = experiences
                        
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save route review: \(error)")
                        }
                    }
                )
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
            let fromProtocol = GradeSystemFactory.gradeProtocol(for: activeRoute.gradeSystem, modelContext: modelContext, customCircuitId: activeRoute.customCircuitId)
            let toProtocol = GradeSystemFactory.gradeProtocol(for: newGradeSystem, modelContext: modelContext)
            let normalized = fromProtocol.normalizedDifficulty(for: currentGrade)
            let fallbackGrade = toProtocol.grade(forNormalizedDifficulty: normalized)

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
        
        // Get circuit reference for circuit grade system
        let circuitForRoute: CustomCircuitGrade? = selectedGradeSystem == .circuit 
            ? (session.customCircuit ?? GradeSystemFactory.defaultCircuit(modelContext))
            : nil

        // If route has no grade, just update the grade system
        guard let currentGrade = activeRoute.grade else {
            print("📝 Route has no grade, just updating grade system")
            activeRoute.gradeSystem = selectedGradeSystem
            activeRoute.climbType = selectedClimbType
            
            // Update circuit reference
            if let circuit = circuitForRoute {
                activeRoute.customCircuit = circuit
                activeRoute.customCircuitId = circuit.id
                // Set initial grade for circuit
                activeRoute.grade = circuit.orderedMappings.first?.id.uuidString
            } else {
                activeRoute.customCircuit = nil
                activeRoute.customCircuitId = nil
            }
            
            do {
                try modelContext.save()
                print("💾 Updated route grade system")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
            return
        }

        print("📝 Converting grade '\(currentGrade)' from \(activeRoute.gradeSystem.description) to \(selectedGradeSystem.description)")
        
        // Special handling for circuit grades
        if selectedGradeSystem == .circuit, let circuit = circuitForRoute {
            // For circuit, find the closest matching color based on difficulty
            let fromProtocol = GradeSystemFactory.gradeProtocol(for: activeRoute.gradeSystem, modelContext: modelContext, customCircuitId: activeRoute.customCircuitId)
            let normalized = fromProtocol.normalizedDifficulty(for: currentGrade)
            let circuitGrade = CircuitGrade(customCircuit: circuit)
            let circuitGradeId = circuitGrade.grade(forNormalizedDifficulty: normalized)
            
            activeRoute.grade = circuitGradeId
            activeRoute.gradeSystem = selectedGradeSystem
            activeRoute.climbType = selectedClimbType
            activeRoute.customCircuit = circuit
            activeRoute.customCircuitId = circuit.id
            
            do {
                try modelContext.save()
                print("💾 Updated route to circuit grade")
            } catch {
                print("❌ Failed to update route: \(error)")
            }
            return
        }
        
        // Clear circuit reference if not using circuit
        activeRoute.customCircuit = nil
        activeRoute.customCircuitId = nil

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
            let fromProtocol = GradeSystemFactory.gradeProtocol(for: activeRoute.gradeSystem, modelContext: modelContext, customCircuitId: activeRoute.customCircuitId)
            let toProtocol = GradeSystemFactory.gradeProtocol(for: selectedGradeSystem, modelContext: modelContext)
            let normalized = fromProtocol.normalizedDifficulty(for: currentGrade)
            let fallbackGrade = toProtocol.grade(forNormalizedDifficulty: normalized)

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
        var circuitForRoute: CustomCircuitGrade?

        // Get the session's circuit if available, or fetch default
        if selectedGradeSystem == .circuit {
            circuitForRoute = session.customCircuit ?? GradeSystemFactory.defaultCircuit(modelContext)
        }

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
            // For circuit grades, use the first mapping from the circuit
            if selectedGradeSystem == .circuit, let circuit = circuitForRoute {
                initialGrade = circuit.orderedMappings.first?.id.uuidString ?? ""
            } else {
                let gradeProtocol = GradeSystemFactory.gradeProtocol(for: selectedGradeSystem, modelContext: modelContext)
                initialGrade = gradeProtocol.grades.first ?? "V0"
            }
        }

        // Create the initial route
        let newRoute = Route(
            gradeSystem: selectedGradeSystem,
            grade: initialGrade,
            session: session
        )
        newRoute.status = .active
        newRoute.climbType = selectedClimbType
        
        // For circuit grades, set the circuit reference
        if selectedGradeSystem == .circuit, let circuit = circuitForRoute {
            newRoute.customCircuit = circuit
            newRoute.customCircuitId = circuit.id
        }

        modelContext.insert(newRoute)
        session.activeRoute = newRoute
        
        // Also update session's configuration to stay in sync
        session.gradeSystem = selectedGradeSystem
        session.climbType = selectedClimbType
        if selectedGradeSystem == .circuit {
            session.customCircuit = circuitForRoute
        }

        // Save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save initial route: \(error)")
        }
    }

}

// MARK: - Session Info Cards

struct SessionInfoCardsView: View {
    let session: Session
    let selectedGradeSystem: GradeSystem
    @Query private var circuits: [CustomCircuitGrade]
    
    var body: some View {
        VStack(spacing: 12) {
            // Gym Info Card
            InfoCard(
                icon: "building.2.fill",
                iconColor: .orange,
                title: "Gym",
                value: session.gymName ?? "Not selected",
                subtitle: nil
            )
            
            // Grade System Info Card
            InfoCard(
                icon: "number.circle.fill",
                iconColor: .blue,
                title: "Grade System",
                value: selectedGradeSystem.description,
                subtitle: gradeSystemSubtitle
            )
            
            // If using circuit, show circuit info
            if selectedGradeSystem == .circuit, let circuit = defaultCircuit {
                CircuitInfoCard(circuit: circuit)
            }
        }
    }
    
    private var defaultCircuit: CustomCircuitGrade? {
        circuits.first(where: { $0.isDefault })
    }
    
    private var gradeSystemSubtitle: String? {
        if selectedGradeSystem == .circuit, let circuit = defaultCircuit {
            return circuit.name
        }
        return nil
    }
}

struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.headline)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CircuitInfoCard: View {
    let circuit: CustomCircuitGrade
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "paintpalette.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Circuit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(circuit.name)
                        .font(.headline)
                }
                
                Spacer()
            }
            
            // Color preview with grade ranges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(circuit.orderedMappings) { mapping in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(mapping.swiftUIColor)
                                .frame(width: 40, height: 32)
                            
                            Text(mapping.gradeRangeDescription)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Session Grade System Picker

struct SessionGradeSystemPicker: View {
    @Binding var selectedClimbType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem
    
    private var isBouldering: Bool {
        selectedClimbType == .boulder
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Climb Type Toggle (top) - simplified to Boulder vs Ropes
            HStack(spacing: 8) {
                PillButton(
                    title: "Boulder",
                    isSelected: isBouldering,
                    color: .blue
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedClimbType = .boulder
                        validateGradeSystem()
                    }
                }
                
                PillButton(
                    title: "Ropes",
                    isSelected: !isBouldering,
                    color: .blue
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedClimbType = .toprope // Default to toprope for ropes
                        validateGradeSystem()
                    }
                }
            }
            
            // Grade System Pills (bottom)
            HStack(spacing: 8) {
                ForEach(validGradeSystems, id: \.self) { system in
                    PillButton(
                        title: system.description,
                        isSelected: selectedGradeSystem == system,
                        color: .orange
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedGradeSystem = system
                        }
                    }
                }
            }
        }
    }
    
    private var validGradeSystems: [GradeSystem] {
        if isBouldering {
            return [.circuit, .vscale, .font]
        } else {
            return [.yds, .french]
        }
    }
    
    private func validateGradeSystem() {
        if !validGradeSystems.contains(selectedGradeSystem) {
            selectedGradeSystem = isBouldering ? .vscale : .yds
        }
    }
}

// MARK: - Pill Button Component

struct PillButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let session = Session.active_preview
    SessionTabView(session: session)
        .modelContainer(for: [Route.self, RouteAttempt.self, Session.self, CustomCircuitGrade.self, CircuitColorMapping.self])
}
