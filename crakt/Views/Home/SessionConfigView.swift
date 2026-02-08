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

    // Core session configuration - persisted to UserDefaults
    @AppStorage("defaultClimbType") private var storedClimbType: Int = Int(ClimbType.boulder.rawValue)
    @AppStorage("defaultGradeSystem") private var storedGradeSystem: Int = Int(GradeSystem.vscale.rawValue)
    
    @State private var selectedClimbType: ClimbType = .boulder
    @State private var selectedGradeSystem: GradeSystem = .vscale
    @State private var selectedCircuit: CustomCircuitGrade?

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
    @State private var selectedGym: Gym?
    @State private var gymGradeConfig: GymGradeConfiguration?

    // Navigation
    @State private var showSession = false
    @State private var showResumeAlert = false
    @State private var unfinishedSession: Session?
    @State private var activeSessionForView: Session?

    // Callbacks
    var onSessionComplete: ((Session) -> Void)?
    var onSessionStart: (() -> Void)?

    // MARK: - View Components

    private var locationSection: some View {
        SessionGymSelectorView(selectedGymName: $gymName)
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
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warm-up routine")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Add a guided warm-up.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isWarmupEnabled)
                    .labelsHidden()
                    .tint(.blue)
            }

            // Exercise selection - only show when warm-up is enabled
            if isWarmupEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose the moves that help you get loose.")
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
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
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.blue)
                )
        }
        .disabled(sessionType == .workout && selectedWorkout == nil)
        .padding(.horizontal, 4)
        .shadow(color: .blue.opacity(0.25), radius: 8, x: 0, y: 6)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        locationSection

                        ClimbTypeToggle(
                            selectedType: $selectedClimbType,
                            selectedGradeSystem: $selectedGradeSystem,
                            selectedCircuit: $selectedCircuit,
                            modelContext: modelContext
                        )

                        // Session Type Selection
                        VStack(spacing: 12) {
                            ForEach(SessionType.allCases, id: \.self) { type in
                                SessionTypeCard(
                                    type: type,
                                    isSelected: sessionType == type,
                                    action: { sessionType = type }
                                )
                            }
                        }

                        // Workout Selection (if workout type selected)
                        if sessionType == .workout {
                            workoutSection

                            workoutSettingsSection
                        }

                        warmupSection


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
            if let session = activeSessionForView {
                createSessionView(for: session)
            }
        }
        .alert("Resume your last session?", isPresented: $showResumeAlert, presenting: unfinishedSession) { session in
            Button("Resume") {
                // Resume existing session - sync UI state to session's stored values
                if let climbType = session.climbType {
                    selectedClimbType = climbType
                }
                if let gradeSystem = session.gradeSystem {
                    selectedGradeSystem = gradeSystem
                }
                selectedCircuit = session.customCircuit
                activeSessionForView = session
                showSession = true
            }
            Button("Finish & Start New", role: .destructive) {
                // Finish the existing session before starting a new one
                finishSession(session)
                prepareNewSession()
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
        .onChange(of: selectedClimbType) { _, newValue in
            // Persist user's climb type preference
            storedClimbType = Int(newValue.rawValue)
        }
        .onChange(of: selectedGradeSystem) { _, newValue in
            // Persist user's grade system preference
            storedGradeSystem = Int(newValue.rawValue)
        }
        .task {
            // Initialize from UserDefaults on first appear
            if let climbType = ClimbType(rawValue: Int16(storedClimbType)) {
                selectedClimbType = climbType
            }
            if let gradeSystem = GradeSystem(rawValue: Int16(storedGradeSystem)) {
                selectedGradeSystem = gradeSystem
            }
        }
    }



    private func startSession() {
        // Check for unfinished session
        if let active = findActiveSession() {
            unfinishedSession = active
            showResumeAlert = true
        } else {
            prepareNewSession()
            showSession = true
        }
    }
    
    private func prepareNewSession() {
        let session = Session()
        
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
        
        // Set session config
        session.climbType = selectedClimbType
        session.gradeSystem = selectedGradeSystem
        session.customCircuit = selectedCircuit
        if !gymName.isEmpty {
            session.gymName = gymName
        }

        // Debug logging
        print("📝 SessionConfigView - Creating NEW session with:")
        print("  - Climb Type: \(selectedClimbType)")
        print("  - Grade System: \(selectedGradeSystem)")

        // Save the new session
        modelContext.insert(session)
        do {
            try modelContext.save()
            print("💾 Session saved successfully")
        } catch {
            print("❌ Failed to save session: \(error)")
        }
        
        activeSessionForView = session
    }

    private func createSessionView(for session: Session) -> some View {
        // For resumed sessions, use the session's stored values as defaults
        let effectiveClimbType = session.climbType ?? selectedClimbType
        let effectiveGradeSystem = session.gradeSystem ?? selectedGradeSystem
        let isResumed = unfinishedSession != nil

        // Create the session view with effective values (respects resumed session config)
        return SessionView(
            session: session,
            initialWorkoutType: !isResumed ? selectedWorkout : nil,
            initialSelectedGrades: !isResumed ? (selectedWorkout == .pyramid ? [pyramidStartGrade, pyramidPeakGrade].compactMap { $0 } : [selectedGrade].compactMap { $0 }) : nil,
            defaultClimbType: effectiveClimbType,
            defaultGradeSystem: effectiveGradeSystem
        ) { completedSession in
            // Session completed - navigate to session detail view
            showSession = false
            activeSessionForView = nil
            if let completedSession = completedSession {
                onSessionComplete?(completedSession)
            }
        }
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
            return "Log attempts as you go"
        case .workout:
            return "Follow preset sets"
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
    @Binding var selectedCircuit: CustomCircuitGrade?
    var modelContext: ModelContext
    
    @Query private var circuits: [CustomCircuitGrade]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Style")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    styleSegment(for: .boulder, icon: "mountain.2.fill", label: "Boulder")
                    styleSegment(for: .toprope, icon: "figure.climbing", label: "Rope")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Grade scale")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                gradeMenu
                
                // Show circuit selector if circuit is selected
                if selectedGradeSystem == .circuit {
                    circuitSelector
                }

                Text("Match the grades used at your gym.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .onChange(of: selectedType) { _, _ in
            if !filteredGradeSystems.contains(selectedGradeSystem) {
                selectedGradeSystem = filteredGradeSystems.first ?? .vscale
            }
        }
        .onChange(of: selectedGradeSystem) { _, newValue in
            // Auto-select default circuit when circuit is selected
            if newValue == .circuit && selectedCircuit == nil {
                selectedCircuit = circuits.first(where: { $0.isDefault }) ?? circuits.first
            }
        }
        .onAppear {
            // Initialize default circuit if circuit system is selected
            if selectedGradeSystem == .circuit && selectedCircuit == nil {
                selectedCircuit = circuits.first(where: { $0.isDefault }) ?? circuits.first
            }
        }
    }
    
    @ViewBuilder
    private var circuitSelector: some View {
        if circuits.isEmpty {
            Text("No circuits configured. Create one in Settings.")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.vertical, 4)
        } else {
            Menu {
                ForEach(circuits) { circuit in
                    Button {
                        selectedCircuit = circuit
                    } label: {
                        HStack {
                            // Color preview
                            HStack(spacing: 2) {
                                ForEach(circuit.orderedMappings.prefix(5)) { mapping in
                                    Circle()
                                        .fill(mapping.swiftUIColor)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            Text(circuit.name)
                            Spacer()
                            if selectedCircuit?.id == circuit.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    // Show color preview for selected circuit
                    if let circuit = selectedCircuit {
                        HStack(spacing: 2) {
                            ForEach(circuit.orderedMappings.prefix(5)) { mapping in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(mapping.swiftUIColor)
                                    .frame(width: 16, height: 20)
                            }
                        }
                        Text(circuit.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Select Circuit")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                )
            }
        }
    }

    @ViewBuilder
    private var gradeMenu: some View {
        Menu {
            ForEach(filteredGradeSystems, id: \.self) { system in
                Button {
                    selectedGradeSystem = system
                } label: {
                    HStack {
                        Text(system.description)
                        Spacer()
                        if selectedGradeSystem == system {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedGradeSystem.description)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
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

    private func styleSegment(for type: ClimbType, icon: String, label: String) -> some View {
        let isActive: Bool
        if type == .boulder {
            isActive = selectedType == .boulder
        } else {
            isActive = selectedType.isRopes
        }
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedType = type
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.headline)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isActive ? .blue : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SessionTypeCard: View {
    let type: SessionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.blue.opacity(0.15) : Color.blue.opacity(0.08))
                            .frame(width: 44, height: 44)
                        Image(systemName: type.icon)
                            .font(.title3)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(type.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isSelected {
                        Label("Selected", systemImage: "checkmark.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
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
                                    gradeSystem: AnyGradeProtocol(GradeSystemFactory.safeProtocol(for: selectedGradeSystem)),
                                    selectedGrade: $pyramidStartGrade
                                )
                                .frame(height: 60)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Peak Grade")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ClimbingGradeSelector(
                                    gradeSystem: AnyGradeProtocol(GradeSystemFactory.safeProtocol(for: selectedGradeSystem)),
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
                            gradeSystem: AnyGradeProtocol(GradeSystemFactory.safeProtocol(for: selectedGradeSystem)),
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
