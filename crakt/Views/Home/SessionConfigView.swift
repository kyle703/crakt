//
//  SessionConfigView.swift
//  crakt
//
//  Created by Kyle Thompson on 12/18/24.
//

import SwiftUI
import SwiftData

struct ExerciseSelectionCard: View {
    let exercise: WarmupExercise
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 12) {
                // Exercise icon
                Image(systemName: exercise.type.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? exercise.type.color : .gray)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? exercise.type.color.opacity(0.15) : Color.gray.opacity(0.1))
                    )

                // Exercise details
                VStack(alignment: .leading, spacing: 2) {
                    // Exercise name
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)

                    // Duration inline
                    Text("\(Int(exercise.duration / 60))m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(exercise.type.color)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct SessionConfigView: View {
    @Environment(\.modelContext) private var modelContext

    // Core session configuration - at the top
    @State private var selectedClimbType: ClimbType = .boulder
    @State private var selectedGradeSystem: GradeSystem = .vscale

    // Session type
    @State private var sessionType: SessionType = .freeClimb

    // Workout configuration
    @State private var selectedWorkout: WorkoutType?
    @State private var selectedGrade: String?
    @State private var pyramidStartGrade: String?
    @State private var pyramidPeakGrade: String?
    @State private var problemCount: Int = 4
    @State private var sessionDuration: TimeInterval = 30 * 60 // 30 minutes

    // Warm-up configuration
    @State private var isWarmupEnabled = false
    @State private var selectedWarmupExercises: [WarmupExercise] = WarmupExercise.defaultExercises

    // Location
    @State private var gymName: String = ""

    // Navigation
    @State private var showSession = false
    @State private var showResumeAlert = false
    @State private var unfinishedSession: Session?

    // Callbacks
    var onSessionComplete: ((Session) -> Void)?
    var onSessionStart: (() -> Void)?

    // MARK: - View Components

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                TextField("Gym Name (optional)", text: $gymName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Use Current Location")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .onTapGesture {
                    // TODO: Implement location services
                }
            }
        }
    }

    private var climbingSetupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Climbing Setup")
                .font(.headline)
                .foregroundColor(.primary)

            // Climb Type Toggle
            ClimbTypeToggle(selectedType: $selectedClimbType, selectedGradeSystem: $selectedGradeSystem)
        }
    }

    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Type")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(SessionType.allCases, id: \.self) { type in
                    SessionTypeCard(
                        type: type,
                        isSelected: sessionType == type,
                        action: { sessionType = type }
                    )
                }
            }
        }
    }

    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Workout")
                .font(.headline)
                .foregroundColor(.primary)

            // Filter workouts by current climb type
            let filteredWorkouts = WorkoutType.allCases.filter { workout in
                workout.category == .both ||
                (selectedClimbType == .boulder ? workout.category == .bouldering : workout.category == .ropes)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(filteredWorkouts, id: \.self) { workout in
                    WorkoutTypeCard(
                        workout: workout,
                        isSelected: selectedWorkout == workout,
                        action: {
                            selectedWorkout = workout
                            // Scroll to workout settings after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    // proxy.scrollTo("workoutSettings", anchor: .top)
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    private var workoutSettingsSection: some View {
        Group {
            if let workout = selectedWorkout {
                VStack(alignment: .leading, spacing: 20) {
                    // Workout Header with Title and Icon
                    HStack(spacing: 12) {
                        Image(systemName: workout.icon)
                            .font(.title2)
                            .foregroundColor(.orange)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.shortDescription)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text(workout.category == .bouldering ? "Bouldering Workout" : "Rope Climbing Workout")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    WorkoutDetailsSection(
                        workout: workout,
                        selectedGrade: $selectedGrade,
                        pyramidStartGrade: $pyramidStartGrade,
                        pyramidPeakGrade: $pyramidPeakGrade,
                        selectedGradeSystem: selectedGradeSystem,
                        problemCount: $problemCount,
                        sessionDuration: $sessionDuration
                    )
                }
                .id("workoutSettings")
            }
        }
    }

    private var warmupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Warm-up")
                .font(.headline)
                .foregroundColor(.primary)

            // Warm-up toggle
            Toggle("Include warm-up routine", isOn: $isWarmupEnabled)
                .font(.subheadline)
                .foregroundColor(.primary)
                .tint(.blue)

            // Exercise selection - only show when warm-up is enabled
            if isWarmupEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select exercises to include in your warm-up routine")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Exercise selection rows
                    VStack(spacing: 8) {
                        ForEach(WarmupExercise.allExercises, id: \.id) { exercise in
                            ExerciseSelectionCard(
                                exercise: exercise,
                                isSelected: selectedWarmupExercises.contains(exercise),
                                onToggle: { isSelected in
                                    if isSelected {
                                        if !selectedWarmupExercises.contains(where: { $0.id == exercise.id }) {
                                            selectedWarmupExercises.append(exercise)
                                        }
                                    } else {
                                        selectedWarmupExercises.removeAll { $0.id == exercise.id }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var startSessionButton: some View {
        Button(action: startSession) {
            Text("Start Climbing")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(sessionType == .workout && selectedWorkout == nil)
        .padding(.horizontal, 4)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        locationSection

                        climbingSetupSection

                        sessionTypeSection

                        // Workout Selection (if workout type selected)
                        if sessionType == .workout {
                            workoutSection

                            workoutSettingsSection
                        }

                    // Warm-up Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Warm-up")
                            .font(.headline)
                            .foregroundColor(.primary)

                        // Warm-up toggle
                        Toggle("Include warm-up routine", isOn: $isWarmupEnabled)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .tint(.blue)

                        // Exercise selection - only show when warm-up is enabled
                        if isWarmupEnabled {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select exercises to include in your warm-up routine")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                // Exercise selection rows
                                VStack(spacing: 8) {
                                    ForEach(WarmupExercise.allExercises, id: \.id) { exercise in
                                        ExerciseSelectionCard(
                                            exercise: exercise,
                                            isSelected: selectedWarmupExercises.contains(exercise),
                                            onToggle: { isSelected in
                                                if isSelected {
                                                    if !selectedWarmupExercises.contains(exercise) {
                                                        selectedWarmupExercises.append(exercise)
                                                    }
                                                } else {
                                                    selectedWarmupExercises.removeAll { $0.id == exercise.id }
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4)

                        Spacer(minLength: 40)

                        // Start Session Button
                        startSessionButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Start Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: startSession) {
                    Text("Start Climbing")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .disabled(sessionType == .workout && selectedWorkout == nil)
            }
        }
        }
        .fullScreenCover(isPresented: $showSession) {
            createSessionView()
        }
        .alert("Resume your last session?", isPresented: $showResumeAlert, presenting: unfinishedSession) { session in
            Button("Resume") {
                // Resume existing session
                showSession = true
            }
            Button("Finish & Start New", role: .destructive) {
                // Finish the existing session before starting a new one
                finishSession(session)
                showSession = true
            }
            Button("Cancel", role: .cancel) {}
        } message: { session in
            Text("You have an unfinished session from \(formatDate(session.startDate)). Would you like to resume or finish it?")
        }
        .onChange(of: showSession) { oldValue, newValue in
            if newValue {
                // Session has started - reset navigation
                onSessionStart?()
            }
        }
    }



    private func startSession() {
        // Check for unfinished session
        if let active = findActiveSession() {
            unfinishedSession = active
            showResumeAlert = true
        } else {
            showSession = true
        }
    }

    private func createSessionView() -> some View {
        // Reuse unfinished session if resuming
        let session = unfinishedSession ?? Session()

        // Warm-up setup
        if isWarmupEnabled {
            let orderedExercises = selectedWarmupExercises.sorted(by: { lhs, rhs in
                if lhs.type == rhs.type {
                    return lhs.name < rhs.name
                }
                return lhs.type.sortOrder < rhs.type.sortOrder
            })

            if !orderedExercises.isEmpty {
                session.currentPhase = .warmup
                session.warmupStartTime = Date()
                session.warmupExercises = orderedExercises.map { source in
                    WarmupExercise(
                        id: source.id,
                        name: source.name,
                        type: source.type,
                        duration: source.duration,
                        exerciseDescription: source.exerciseDescription,
                        instructions: source.instructions,
                        isCustom: source.isCustom,
                        order: source.type.sortOrder
                    )
                }
            } else {
                session.currentPhase = .main
            }
        } else {
            session.currentPhase = .main
        }
        session.climbType = selectedClimbType
        session.gradeSystem = selectedGradeSystem
        if !gymName.isEmpty {
            session.gymName = gymName
        }

        // Debug logging
        print("📝 SessionConfigView - Creating session with:")
        print("  - Climb Type: \(selectedClimbType)")
        print("  - Grade System: \(selectedGradeSystem)")
        print("  - Session climbType: \(session.climbType ?? .boulder)")
        print("  - Session gradeSystem: \(session.gradeSystem ?? .vscale)")

        // Save only when creating a new session
        if unfinishedSession == nil {
            do {
                try modelContext.save()
                print("💾 Session saved successfully")
            } catch {
                print("❌ Failed to save session: \(error)")
            }
        }

        // Create the session view with defaults for nil values
        let sessionView = SessionView(
            session: session,
            initialWorkoutType: selectedWorkout,
            initialSelectedGrades: selectedWorkout == .pyramid ? [pyramidStartGrade, pyramidPeakGrade].compactMap { $0 } : [selectedGrade].compactMap { $0 },
            defaultClimbType: selectedClimbType,
            defaultGradeSystem: selectedGradeSystem
        ) { completedSession in
            // Session completed - navigate to session detail view
            showSession = false
            if let completedSession = completedSession {
                onSessionComplete?(completedSession)
            }
        }

        return sessionView
    }

    private func findActiveSession() -> Session? {
        // Workaround: SwiftData predicate macros can struggle with enum cases
        // Fetch recent sessions then filter in memory
        var descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 25
        if let results = try? modelContext.fetch(descriptor) {
            return results.first { $0.status == .active }
        }
        return nil
    }

    private func finishSession(_ session: Session) {
        let elapsed = Date().timeIntervalSince(session.startDate)
        session.completeSession(context: modelContext, elapsedTime: elapsed)
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to finish existing session: \(error)")
        }
        // Clear unfinished reference so createSessionView builds a new one
        unfinishedSession = nil
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

enum SessionType: String, CaseIterable {
    case freeClimb = "Free Climb"
    case workout = "Workout Plan"

    var description: String {
        switch self {
        case .freeClimb:
            return "Climb freely and log your routes"
        case .workout:
            return "Follow a structured workout plan"
        }
    }

    var icon: String {
        switch self {
        case .freeClimb:
            return "figure.climbing"
        case .workout:
            return "list.bullet.rectangle"
        }
    }
}

struct ClimbTypeToggle: View {
    @Binding var selectedType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem

    var body: some View {
        HStack(spacing: 12) {
            // Climb Type Selection - Custom Toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("Climb Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 50)

                    // Sliding background
                    RoundedRectangle(cornerRadius: 23)
                        .fill(.blue)
                        .frame(width: 78, height: 44)
                        .offset(x: selectedType == .boulder ? -41 : 41)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedType)

                    // Buttons
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedType = .boulder
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mountain.2.fill")
                                    .font(.title3)
                                Text("Boulder")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedType == .boulder ? .white : .secondary)
                            .frame(width: 80, height: 50)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedType = .toprope
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "figure.climbing")
                                    .font(.title3)
                                Text("Rope")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedType.isRopes ? .white : .secondary)
                            .frame(width: 80, height: 50)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 50)
            }

            // Grade System Selection (horizontal)
            VStack(alignment: .leading, spacing: 8) {
                Text("Grade System")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Grade System", selection: $selectedGradeSystem) {
                    ForEach(filteredGradeSystems, id: \.self) { system in
                        Text(system.description).tag(system)
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
                .frame(height: 50) // Match toggle height
                .onChange(of: selectedType) {
                    // Auto-adjust grade system when climb type changes
                    if !filteredGradeSystems.contains(selectedGradeSystem) {
                        selectedGradeSystem = filteredGradeSystems.first ?? .vscale
                    }
                }
            }
        }
    }

    private var filteredGradeSystems: [GradeSystem] {
        GradeSystem.allCases.filter { system in
            switch selectedType {
            case .boulder:
                return [.circuit, .vscale, .font].contains(system)
            case .toprope, .lead:
                return [.french, .yds].contains(system)
            }
        }
    }
}

struct SessionTypeCard: View {
    let type: SessionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? .blue : .blue.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(type.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.2 : 0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutTypeCard: View {
    let workout: WorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: workout.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .orange)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? .orange : .orange.opacity(0.15))
                    )

                Text(workout.shortDescription)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.orange : Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: 3, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extracted workout details section to reduce main view complexity
struct WorkoutDetailsSection: View {
    let workout: WorkoutType
    @Binding var selectedGrade: String?
    @Binding var pyramidStartGrade: String?
    @Binding var pyramidPeakGrade: String?
    let selectedGradeSystem: GradeSystem
    @Binding var problemCount: Int
    @Binding var sessionDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Workout description - moved up for better context
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(workout.workoutDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
            }

            // Visual separator
            Divider()
                .padding(.vertical, 8)

            // Grade selection for workouts that need it
            if workout.requiresGradeSelection {
                VStack(alignment: .leading, spacing: 8) {
                    if workout == .pyramid {
                        // Pyramid specific: Start grade and Peak grade
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pyramid Grades")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Starting Grade")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ClimbingGradeSelector(
                                    gradeSystem: GradeSystems.systems[selectedGradeSystem]!,
                                    selectedGrade: $pyramidStartGrade
                                )
                                .frame(height: 60)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Peak Grade")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ClimbingGradeSelector(
                                    gradeSystem: GradeSystems.systems[selectedGradeSystem]!,
                                    selectedGrade: $pyramidPeakGrade
                                )
                                .frame(height: 60)
                            }
                        }
                    } else {
                        Text("Target Grade")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ClimbingGradeSelector(
                            gradeSystem: GradeSystems.systems[selectedGradeSystem]!,
                            selectedGrade: $selectedGrade
                        )
                        .frame(height: 60)
                    }
                }
            }

            // Problem count for workouts that need it
            if workout.requiresProblemCount {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of Problems per Set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Problems", selection: $problemCount) {
                        ForEach(1...10, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            // Duration for workouts that need it
            if workout.requiresDuration {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Duration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Duration", selection: $sessionDuration) {
                        Text("30 min").tag(TimeInterval(30 * 60))
                        Text("45 min").tag(TimeInterval(45 * 60))
                        Text("60 min").tag(TimeInterval(60 * 60))
                        Text("90 min").tag(TimeInterval(90 * 60))
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}



#Preview {
    SessionConfigView()
}
