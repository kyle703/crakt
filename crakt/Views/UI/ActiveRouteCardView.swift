//
//  ActiveRouteCardView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI
import SwiftData

struct ActiveRouteCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    var session: Session
    @ObservedObject var stopwatch: Stopwatch
    @ObservedObject var workoutOrchestrator: WorkoutOrchestrator

    // New parameters for grade selection
    @Binding var selectedGrade: String?
    @Binding var selectedGradeSystem: GradeSystem

    // UI State
    @State private var showAttemptHistory = false
    @State private var showRoutePicker = false
    @State private var showRestTimer = false

    // Gesture State
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragValue: DragGesture.Value?
    @State private var isDragging = false

    // Rest timer state
    @State private var restDuration: TimeInterval = 10 // 10 seconds for testing
    @State private var restStartTime: Date?
    @State private var isRestTimerActive: Bool = false

    // Animation state for attempt logging
    @State private var animateNewAttempt = false
    @State private var animateOldAttempt = false
    @State private var routeChangeTrigger: UUID = UUID() // Force view refresh on route changes

    // Difficulty rating state
    @State private var showDifficultyRating = false
    @State private var lastAttemptForRating: RouteAttempt?
    @State private var surveyRoute: Route?

    // Route style selection state
    @State private var showStylePicker = false
    @State private var pendingRouteStyles: [RouteStyle] = []



    private var cardContent: some View {
        VStack(spacing: 20) {

            // Timer section with inline controls
            if session.activeRoute != nil {
                VStack(spacing: 12) {
                    // Timer row with inline buttons (flanked left/right)
                    HStack(alignment: .center, spacing: 16) {
                        // Left: Route style indicator
                        Button(action: {
                            if let route = session.activeRoute {
                                pendingRouteStyles = route.styles
                                showStylePicker = true
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "tag")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                if let route = session.activeRoute, !route.styles.isEmpty {
                                    Text("\(route.styles.count)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }

                        Spacer(minLength: 0)

                        // Center: Main timer
                        VStack(alignment: .center, spacing: 2) {
                            // 1. TOTAL TIME ON ROUTE (from route initialization, excluding current rest periods)
                            if let startElapsed = session.activeRoute?.routeStartElapsed {
                                let currentRestDeduction = isRestTimerActive && restStartTime != nil ? Date().timeIntervalSince(restStartTime!) : 0
                                let routeTime = stopwatch.totalTime - startElapsed - currentRestDeduction
                                Text(timeString(from: max(0, routeTime))) // Ensure no negative times
                                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }

                            // 2. TIME SINCE LAST ATTEMPT (for pacing) - more subtle
                            if let lastElapsed = session.activeRoute?.lastAttemptElapsed {
                                let timeSinceLast = stopwatch.totalTime - lastElapsed
                                HStack(spacing: 4) {
                                    Text(timeString(from: max(0, timeSinceLast))) // Ensure no negative times
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.7))
                                    Text("since last")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .textCase(.uppercase)
                                }
                            }
                        }
                        .layoutPriority(1)

                        Spacer(minLength: 0)

                        // Right: Effort/feedback button
                        Button(action: {
                            if let route = session.activeRoute,
                               let attempt = route.attempts.sorted(by: { $0.date > $1.date }).first {
                                lastAttemptForRating = attempt
                                surveyRoute = route
                                showDifficultyRating = true
                            }
                        }) {
                            HStack(spacing: 0) {
                                let latestRating = session.activeRoute?.attempts.sorted(by: { $0.date > $1.date }).first?.difficultyRating
                                Image(systemName: latestRating?.iconName ?? "hand.thumbsup")
                                    .font(.system(size: 14))
                                    .foregroundColor(latestRating?.color ?? .secondary)
                                    .padding(6)
                                    .background((latestRating?.color ?? .gray).opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Rest timer is now handled by the overlay only
                }
            }

            // Route feedback tags (show under timer if route has styles, experiences, or rating)
            if let route = session.activeRoute, (!route.styles.isEmpty || !route.experiences.isEmpty || route.attempts.contains(where: { $0.difficultyRating != nil })) {
                HStack(spacing: 6) {
                    // Difficulty rating as symbol
                    if let latestRating = route.attempts.sorted(by: { $0.date > $1.date }).first?.difficultyRating {
                        Image(systemName: latestRating.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(latestRating.color)
                            .padding(6)
                            .background(latestRating.color.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Route styles
                    ForEach(route.styles, id: \.self) { style in
                        Text(style.description)
                            .font(.caption2)
                            .foregroundColor(style.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(style.color.opacity(0.1))
                            .cornerRadius(12)
                    }

                    // Climb experiences
                    ForEach(route.experiences, id: \.self) { experience in
                        Image(systemName: experience.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(experience.color)
                            .padding(6)
                            .background(experience.color.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Call to action when no attempts
            if let route = session.activeRoute, route.attempts.isEmpty {
                VStack(spacing: 8) {
                    Text("🏔️")
                        .font(.system(size: 40))
                        .foregroundColor(.primary)
                    Text("Ready to climb?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Swipe up to send, down to fall")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
            }


            // Last 3 attempts - constrained height
            if let route = session.activeRoute, !route.attempts.isEmpty {
                VStack(spacing: 4) {
                    Text("Recent Attempts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 2) {
                        let recentAttempts = route.attempts.sorted(by: { $0.date > $1.date }).prefix(3)
                        ForEach(Array(recentAttempts.enumerated()), id: \.element.id) { index, attempt in
                            VStack { // Wrapper to use routeChangeTrigger for view identity
                            HStack {
                                // Attempt status
                                Image(systemName: attempt.status.iconName)
                                    .foregroundColor(attempt.status.color)
                                    .frame(width: 20)

                                // Time (hh:mm)
                                Text(formatTime(attempt.date))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(width: 50, alignment: .leading)

                                Spacer()

                                // Relative time
                                Text(relativeTime(from: attempt.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .opacity(animateOldAttempt && index == 0 ? 0.3 : 1.0) // Fade out oldest attempt
                            .scaleEffect(animateNewAttempt && index == 0 ? 0.95 : 1.0) // Slight scale down for old attempt
                            .animation(.easeInOut(duration: 0.2), value: animateOldAttempt)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateNewAttempt)
                            }.id(routeChangeTrigger) // Force refresh when route changes
                        }
                    }
                    .frame(maxHeight: 120) // Constrain attempts list height
                }
            }

            Spacer()

            // Gesture hints
            VStack(spacing: 8) {
                Text("Swipe up to Send • Swipe down to Fall")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Long press for Rest • Double tap to repeat")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Accessibility gesture buttons
            HStack(spacing: 12) {
               
                accessibilityButton(
                    icon: "arrow.up.circle.fill",
                    title: "Send",
                    color: .green
                ) {
                    logAttempt(.send)
                }

                accessibilityButton(
                    icon: "arrow.down.circle.fill",
                    title: "Fall",
                    color: .red
                ) {
                    logAttempt(.fall)
                }
                

            
                accessibilityButton(
                    icon: "timer",
                    title: "Rest",
                    color: .orange
                ) {
                    startRestTimer()
                }

                accessibilityButton(
                    icon: "arrow.right.circle.fill",
                    title: "Next Route",
                    color: .orange
                ) {
                    resetRoute()
                }
                
            }

            
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }

    private var dragFeedbackOverlay: some View {
        ZStack {
            // Vertical gestures
            if dragOffset.height < -50 {
                Color.green.opacity(0.2)
            } else if dragOffset.height > 50 {
                Color.red.opacity(0.2)
            }

            // Horizontal gesture (reset)
            if dragOffset.width > 50 || dragOffset.width < -50 {
                Color.orange.opacity(0.2)
            }

            VStack {
                // Vertical feedback
                if dragOffset.height < -50 {
                    VStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("SEND")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                } else if dragOffset.height > 50 {
                    VStack {
                        Text("FALL")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                    }
                }

                // Horizontal feedback
                if dragOffset.width > 50 {
                    HStack {
                        Text("Next Route")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                    }
                } else if dragOffset.width < -50 {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Next Route")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .cornerRadius(16)
    }

    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            // Undo button (always visible when there's something to undo)
            Button(action: performUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(!(undoManager?.canUndo ?? false))

            Spacer()

            // Compact Grade Selector
            if let gradeSystem = session.activeRoute?.gradeSystem._protocol {
                CompactGradeSelector(
                    gradeSystem: gradeSystem,
                    selectedGrade: .init(
                        get: { session.activeRoute?.grade },
                        set: { newGrade in
                            if let newGrade = newGrade {
                                changeGrade(to: newGrade)
                            }
                        }
                    ),
                    isLocked: !(session.activeRoute?.attempts.isEmpty ?? true)
                )
            }

            Spacer()

            // Rest timer toggle
            Button(action: {
                startRestTimer()
            }) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground).opacity(0.9))
    }

    // MARK: - Gesture Handlers

    private func handleDragChanged(_ value: DragGesture.Value) {
        let verticalOffset = value.translation.height
        let horizontalOffset = value.translation.width

        // Check if it's primarily horizontal or vertical
        if abs(horizontalOffset) > abs(verticalOffset) {
            // Horizontal drag - show reset feedback
            dragOffset = CGSize(width: horizontalOffset, height: 0)
            isDragging = abs(horizontalOffset) > 30
        } else {
            // Vertical drag - show send/fall feedback
            dragOffset = CGSize(width: 0, height: verticalOffset)
            isDragging = abs(verticalOffset) > 30
        }
    }

    init(session: Session, stopwatch: Stopwatch, workoutOrchestrator: WorkoutOrchestrator) {
        self.session = session
        self.stopwatch = stopwatch
        self.workoutOrchestrator = workoutOrchestrator
        self._selectedGrade = .constant(nil)
        self._selectedGradeSystem = .constant(.vscale)

        // Timer initialization is now handled in .onAppear using stopwatch timing
    }

    init(session: Session, stopwatch: Stopwatch, workoutOrchestrator: WorkoutOrchestrator, selectedGrade: Binding<String?>, selectedGradeSystem: Binding<GradeSystem>) {
        self.session = session
        self.stopwatch = stopwatch
        self.workoutOrchestrator = workoutOrchestrator
        self._selectedGrade = selectedGrade
        self._selectedGradeSystem = selectedGradeSystem

        // Timer initialization is now handled in .onAppear using stopwatch timing
    }

    var body: some View {
        mainView
            .onAppear {
                // Initialize route timer state based on existing attempts
                initializeRouteTimer()
            }
            .onChange(of: session.activeRoute) { oldRoute, newRoute in
                // Ensure timer is initialized when route changes
                initializeRouteTimer()
            }
            
            .sheet(isPresented: $showAttemptHistory) {
                if let route = session.activeRoute {
                    AttemptHistoryView(
                        route: route,
                        onDeleteAttempt: { attempt in
                            deleteAttempt(attempt)
                        },
                        onDismiss: {
                            showAttemptHistory = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showRoutePicker) {
                RoutePickerView(
                    gradeSystem: session.activeRoute?.gradeSystem ?? .yds,
                    selectedGrade: .init(
                        get: { session.activeRoute?.grade },
                        set: { newGrade in
                            if let newGrade = newGrade {
                                changeGrade(to: newGrade)
                            }
                        }
                    )
                ) { grade in
                    showRoutePicker = false
                    // Route selected logic would go here
                } onDismiss: {
                    showRoutePicker = false
                }
            }
            .sheet(isPresented: $showStylePicker) {
                if let route = session.activeRoute {
                    StyleSelectorView(
                        selectedStyles: $pendingRouteStyles,
                        isMultiSelect: true,
                        onSelectionChanged: {
                            // Save the selected styles to the route
                            route.styles = pendingRouteStyles
                            do {
                                try modelContext.save()
                            } catch {
                                print("Failed to save route styles: \(error)")
                            }
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
    }

    private var mainView: some View {
        ZStack(alignment: .bottom) {
            // Always show the climbing interface (route will be auto-created if needed)
            VStack(spacing: 16) {
                // Main card area with gestures
                ZStack {
                    cardContent
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color(.systemBackground).opacity(0.1), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(session.activeRoute?.gradeColor ?? .gray, lineWidth: 2)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    handleDragChanged(value)
                                }
                                .onEnded { value in
                                    handleDragEnded(value)
                                }
                        )
                        .gesture(
                            LongPressGesture(minimumDuration: 0.7)
                                .onEnded { _ in
                                    handleLongPress()
                                }
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    handleDoubleTap()
                                }
                        )

                    // Visual feedback during drag
                    if isDragging {
                        dragFeedbackOverlay
                    }
                }

                // Bottom action bar
                bottomActionBar
            }
            .padding(.vertical, 16)
        }
        .overlay(
            Group {
                if showRestTimer {
                    RestTimerView(
                        duration: restDuration,
                        onComplete: {
                            showRestTimer = false
                            stopRestTimer()
                            // Handle rest completion
                            HapticManager.shared.playSuccess()
                        },
                        onDismiss: {
                            showRestTimer = false
                            stopRestTimer()
                        }
                    )
                }

                if showDifficultyRating, let attempt = lastAttemptForRating, let route = (surveyRoute ?? session.activeRoute) {
                    DifficultyRatingView(
                        route: route,
                        attempt: attempt,
                        onRatingSelected: { rating in
                            if let rating = rating {
                                attempt.difficultyRating = rating
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Failed to save difficulty rating: \(error)")
                                }
                            }
                            showDifficultyRating = false
                            lastAttemptForRating = nil
                            surveyRoute = nil
                        },
                        onDismiss: {
                            showDifficultyRating = false
                            lastAttemptForRating = nil
                            surveyRoute = nil
                        }
                    )
                }

            }
        )
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        let verticalOffset = value.translation.height
        let horizontalOffset = value.translation.width

        // Check for horizontal swipe first (reset route)
        if abs(horizontalOffset) > 150 && abs(verticalOffset) < 50 {
            // Horizontal swipe - Reset route
            resetRoute()
        } else {
            // Vertical gestures
            if verticalOffset < -100 {
                // Swipe up - Send
                logAttempt(.send)
            } else if verticalOffset > 100 {
                // Swipe down - Fall
                logAttempt(.fall)
            }
        }

        withAnimation(.spring()) {
            dragOffset = .zero
            isDragging = false
        }
    }

    private func handleLongPress() {
        startRestTimer()
        HapticManager.shared.playAttempt()
    }

    private func startRestTimer() {
        showRestTimer = true
        isRestTimerActive = true
        if restStartTime == nil {
            restStartTime = Date()
        }
    }

    private func stopRestTimer() {
        isRestTimerActive = false
        if let restStart = restStartTime, let route = session.activeRoute {
            route.totalRestTime += Date().timeIntervalSince(restStart)
            restStartTime = nil
        }
    }

    private func handleDoubleTap() {
        // Repeat last attempt
        if let route = session.activeRoute,
           let lastAttempt = route.attempts.sorted(by: { $0.date > $1.date }).first {
            logAttempt(lastAttempt.status)
        }
    }

    // MARK: - Action Handlers

    private func logAttempt(_ status: ClimbStatus) {
        guard let activeRoute = session.activeRoute else { return }

        undoManager?.registerUndo(withTarget: activeRoute, handler: { route in
            // Undo action: remove the last attempt
            if !route.attempts.isEmpty {
                route.attempts.removeLast()
                workoutOrchestrator.updateWorkoutProgress()
            }
        })

        // Start animation sequence
        withAnimation(.easeOut(duration: 0.2)) {
            animateOldAttempt = true
        }

        // Add new attempt after a brief delay for staggered effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let attempt = RouteAttempt(status: status)
            activeRoute.attempts.append(attempt)

            // Set route start time on first attempt
            if activeRoute.routeStartElapsed == nil {
                activeRoute.routeStartElapsed = stopwatch.totalTime
            }

            // Update last attempt time
            activeRoute.lastAttemptElapsed = stopwatch.totalTime

            // Update workout progress
            workoutOrchestrator.updateWorkoutProgress()

            // Update stopwatch
            stopwatch.lap()

            // Trigger new attempt animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateNewAttempt = true
            }


            // Reset animation states
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateOldAttempt = false
                animateNewAttempt = false
            }
        }

        // Play haptic feedback
        if status == .send {
            HapticManager.shared.playSuccess()
        } else {
            HapticManager.shared.playAttempt()
        }
    }

    private func changeGrade(to newGrade: String) {
        guard let route = session.activeRoute, let oldGrade = route.grade else { return }

        undoManager?.registerUndo(withTarget: route, handler: { route in
            // Undo action: revert to old grade
            route.grade = oldGrade
        })

        route.grade = newGrade

        // Reset timer for new route
        route.routeStartElapsed = stopwatch.totalTime
        route.lastAttemptElapsed = nil
        // Reset rest state
        stopRestTimer()
        route.totalRestTime = 0
        isRestTimerActive = false

        // Show experience survey for the PREVIOUS route if it had attempts
        if !route.attempts.isEmpty {
            let previousRoute = route
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                lastAttemptForRating = previousRoute.attempts.last
                surveyRoute = previousRoute
                showDifficultyRating = true
            }
        }

        HapticManager.shared.playSuccess()
    }

    private func deleteAttempt(_ attempt: RouteAttempt) {
        if let route = session.activeRoute {
            route.attempts.removeAll { $0.id == attempt.id }
            workoutOrchestrator.updateWorkoutProgress()
            HapticManager.shared.playAttempt()
        }
    }

    private func initializeRouteTimer() {
        if let route = session.activeRoute {
            if route.routeStartElapsed == nil {
                route.routeStartElapsed = stopwatch.totalTime
                print("🕐 Initialized route timer for route: \(route.grade ?? "unknown") at \(stopwatch.totalTime)")
            }
        }
    }

    private func resetRoute() {
        // Reset animation state before creating new route
        animateNewAttempt = false
        animateOldAttempt = false
        // Don't reset attemptAnimationId here - only when animating attempts

        // Capture the previous route for post-transition survey
        let previousRouteForSurvey = session.activeRoute

        // Advance workout if active, otherwise create new route with current grade
        if workoutOrchestrator.isWorkoutActive {
            // Advance to next rep in workout
            workoutOrchestrator.advanceWorkoutOnRouteCompletion()

            // Get the next grade from the workout
            let nextGrade = getNextWorkoutGrade()

            // Create new route with next grade
            createNewRoute(with: nextGrade)
        } else {
            // No active workout, create new route with current grade
            let currentGrade = session.activeRoute?.grade
            createNewRoute(with: currentGrade)
        }

        // Reset timers for new route
        if let activeRoute = session.activeRoute {
            activeRoute.routeStartElapsed = stopwatch.totalTime
            activeRoute.lastAttemptElapsed = nil
            // Reset rest state
            stopRestTimer()
            activeRoute.totalRestTime = 0
        }

        // Present experience survey for the previous route if it had attempts
        if let prev = previousRouteForSurvey, !prev.attempts.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                lastAttemptForRating = prev.attempts.last
                surveyRoute = prev
                showDifficultyRating = true
            }
        }
        HapticManager.shared.playSuccess()
    }

    private func getNextWorkoutGrade() -> String? {
        guard let workout = workoutOrchestrator.activeWorkout else { return nil }

        // For pyramid workouts, calculate grade based on current set
        if let pyramidStartGrade = workout.pyramidStartGrade,
           let pyramidPeakGrade = workout.pyramidPeakGrade {

            // Simple pyramid: set 1 (easy), set 2 (medium), set 3 (hard), set 4 (medium), set 5 (easy)
            let currentSetIndex = workout.currentSetIndex
            let totalSets = workout.sets.count

            if totalSets > 0 {
                if currentSetIndex == 0 { // First set - easy
                    return pyramidStartGrade
                } else if currentSetIndex == totalSets / 2 { // Middle set - hard
                    return pyramidPeakGrade
                } else if currentSetIndex < totalSets / 2 { // Climbing up - interpolate
                    return pyramidStartGrade // For now, use start grade
                } else { // Coming down - use start grade
                    return pyramidStartGrade
                }
            }
        }

        // For other workouts, use selected grade
        return workout.selectedGrade
    }

    private func createNewRoute(with grade: String?) {
        guard let grade = grade,
              let currentRoute = session.activeRoute else { return }

        // Create new route with specified grade
        let newRoute = Route(
            gradeSystem: currentRoute.gradeSystem,
            grade: grade,
            session: session
        )

        // Set the climb type to match the current route
        newRoute.climbType = currentRoute.climbType

        // Add to session
        session.routes.append(newRoute)

        // Reset animation state before changing route
        animateNewAttempt = false
        animateOldAttempt = false
        // Don't reset attemptAnimationId here - only when animating attempts

        // Set new active route
        session.activeRoute = newRoute

        // Initialize timers for new route
        newRoute.routeStartElapsed = stopwatch.totalTime
        newRoute.lastAttemptElapsed = nil
        // Reset rest state for new route
        stopRestTimer()
        newRoute.totalRestTime = 0

        // Do NOT auto-open style picker. Only open when user taps the tag button.

        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new route: \(error)")
        }
    }

    private func performUndo() {
        undoManager?.undo()
        workoutOrchestrator.updateWorkoutProgress()
        HapticManager.shared.playAttempt()
    }

    // MARK: - Helper Functions

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let tenths = Int((timeInterval * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func relativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return String(format: "%ds ago", Int(interval))
        } else if interval < 3600 {
            return String(format: "%dm ago", Int(interval / 60))
        } else {
            return String(format: "%dh ago", Int(interval / 3600))
        }
    }

    private func accessibilityButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(color.opacity(0.8))
            }
            .frame(width: 70, height: 70)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Tap to \(title.lowercased())")
    }
}

#Preview {
    ActiveRouteCardPreview()
}

struct ActiveRouteCardPreview: View {
    var body: some View {
        let tempContext = try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext
        let session = Session.active_preview

        // Add some sample attempts for preview
        if let route = session.activeRoute {
            let now = Date()
            route.attempts = [
                RouteAttempt(date: now.addingTimeInterval(-300), status: .fall), // 5 min ago
                RouteAttempt(date: now.addingTimeInterval(-180), status: .send), // 3 min ago
                RouteAttempt(date: now.addingTimeInterval(-60), status: .fall),  // 1 min ago
                RouteAttempt(date: now.addingTimeInterval(-30), status: .send),  // 30 sec ago
                RouteAttempt(date: now.addingTimeInterval(-10), status: .fall)   // 10 sec ago
            ]
        }

        let workoutOrchestrator = WorkoutOrchestrator(session: session, modelContext: tempContext)

        return ActiveRouteCardView(
            session: workoutOrchestrator.publicSession,
            stopwatch: Stopwatch(),
            workoutOrchestrator: workoutOrchestrator
        )
        .background(Color.gray.opacity(0.1))
    }
}
