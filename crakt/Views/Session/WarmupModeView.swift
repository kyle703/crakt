//
//  WarmupModeView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/27/25.
//

import SwiftUI
import SwiftData

struct WarmupModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var session: Session
    @State private var currentExerciseIndex: Int = 0
    @State private var exerciseTimer: Timer?
    @State private var timeRemaining: TimeInterval = 0
    @State private var isTimerRunning = false
    @State private var showSkipConfirmation = false
    @State private var showCompleteWarmup = false

    private var currentExercise: WarmupExercise? {
        guard currentExerciseIndex < session.warmupExercises.count else { return nil }
        return session.warmupExercises[currentExerciseIndex]
    }

    private var progress: Double {
        guard !session.warmupExercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(session.warmupExercises.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 16) {
                HStack {
                    Text("Warm-up Mode")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        showSkipConfirmation = true
                    }) {
                        Text("Skip Warm-up")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)

                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)

                Text("\(currentExerciseIndex + 1) of \(session.warmupExercises.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Exercise content
            if let exercise = currentExercise {
                ScrollView {
                    VStack(spacing: 24) {
                        // Exercise header
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: exercise.type.iconName)
                                    .font(.title2)
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Text(exercise.type.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }

                            Text(exercise.exerciseDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Timer display
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                    .frame(width: 200, height: 200)

                                Circle()
                                    .trim(from: 0, to: timeRemaining / exercise.duration)
                                    .stroke(isTimerRunning ? Color.green : Color.blue, lineWidth: 8)
                                    .frame(width: 200, height: 200)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 4) {
                                    Text(timeString(from: timeRemaining))
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)

                                    Text(isTimerRunning ? "remaining" : "duration")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Timer controls
                            HStack(spacing: 24) {
                                Button(action: {
                                    if isTimerRunning {
                                        pauseTimer()
                                    } else {
                                        startTimer()
                                    }
                                }) {
                                    Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.title)
                                        .foregroundColor(isTimerRunning ? .orange : .green)
                                }

                                Button(action: {
                                    resetTimer()
                                }) {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(exercise.instructions)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                        }

                        // Navigation buttons
                        HStack(spacing: 16) {
                            if currentExerciseIndex > 0 {
                                Button(action: {
                                    goToPreviousExercise()
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Previous")
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                            Spacer()

                            if currentExerciseIndex < session.warmupExercises.count - 1 {
                                Button(action: {
                                    completeCurrentExercise()
                                }) {
                                    HStack {
                                        Text("Next")
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                            } else {
                                Button(action: {
                                    completeWarmup()
                                }) {
                                    Text("Complete Warm-up")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 24)
                    }
                    .padding()
                }
            } else {
                // No exercises available
                VStack(spacing: 24) {
                    Text("No warm-up exercises configured")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        // Add default exercises
                        addDefaultExercises()
                    }) {
                        Text("Add Default Exercises")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .alert("Skip Warm-up?", isPresented: $showSkipConfirmation) {
            Button("Skip") {
                skipWarmup()
            }
            Button("Continue") {
                showSkipConfirmation = false
            }
        } message: {
            Text("Are you sure you want to skip the warm-up? It's recommended for injury prevention.")
        }
        .onAppear {
            setupWarmupExercises()
            if let exercise = currentExercise {
                timeRemaining = exercise.duration
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func setupWarmupExercises() {
        if !session.warmupExercises.isEmpty {
            // Sort exercises by type and then name
            session.warmupExercises.sort { lhs, rhs in
                if lhs.type == rhs.type {
                    return lhs.name < rhs.name
                }
                return lhs.type.sortOrder < rhs.type.sortOrder
            }
            return
        }

        // Fallback: Add default exercises if none exist (should be set from session config)
        let defaults = WarmupExercise.defaultExercises
        session.warmupExercises = defaults.map { exercise in
            let warmupExercise = WarmupExercise(
                name: exercise.name,
                type: exercise.type,
                duration: exercise.duration,
                exerciseDescription: exercise.exerciseDescription,
                instructions: exercise.instructions,
                isCustom: false,
                order: exercise.type.sortOrder
            )
            modelContext.insert(warmupExercise)
            return warmupExercise
        }

        // Sort by type and then name
        session.warmupExercises.sort { lhs, rhs in
            if lhs.type == rhs.type {
                return lhs.name < rhs.name
            }
            return lhs.type.sortOrder < rhs.type.sortOrder
        }
    }

    private func addDefaultExercises() {
        session.warmupExercises = WarmupExercise.defaultExercises.map { exercise in
            let warmupExercise = WarmupExercise(
                name: exercise.name,
                type: exercise.type,
                duration: exercise.duration,
                exerciseDescription: exercise.exerciseDescription,
                instructions: exercise.instructions,
                isCustom: false,
                order: exercise.order
            )
            modelContext.insert(warmupExercise)
            return warmupExercise
        }

        session.warmupExercises.sort { $0.order < $1.order }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save warmup exercises: \(error)")
        }
    }

    private func startTimer() {
        isTimerRunning = true
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Timer completed
                pauseTimer()
                // Auto-advance to next exercise or complete warmup
                if currentExerciseIndex < session.warmupExercises.count - 1 {
                    completeCurrentExercise()
                } else {
                    completeWarmup()
                }
            }
        }
    }

    private func pauseTimer() {
        isTimerRunning = false
        exerciseTimer?.invalidate()
        exerciseTimer = nil
    }

    private func resetTimer() {
        if let exercise = currentExercise {
            timeRemaining = exercise.duration
        }
        isTimerRunning = false
        exerciseTimer?.invalidate()
        exerciseTimer = nil
    }

    private func stopTimer() {
        exerciseTimer?.invalidate()
        exerciseTimer = nil
        isTimerRunning = false
    }

    private func completeCurrentExercise() {
        guard currentExerciseIndex < session.warmupExercises.count - 1 else {
            completeWarmup()
            return
        }

        currentExerciseIndex += 1
        if let exercise = currentExercise {
            timeRemaining = exercise.duration
            resetTimer()
        }
    }

    private func goToPreviousExercise() {
        guard currentExerciseIndex > 0 else { return }

        currentExerciseIndex -= 1
        if let exercise = currentExercise {
            timeRemaining = exercise.duration
            resetTimer()
        }
    }

    private func completeWarmup() {
        session.currentPhase = .main
        session.warmupCompleted = true
        session.warmupStartTime = nil

        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error)")
        }

        showCompleteWarmup = true
    }

    private func skipWarmup() {
        session.currentPhase = .main
        session.warmupCompleted = false // Mark as skipped, not completed
        session.warmupStartTime = nil

        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    WarmupModeView(session: .constant(Session.preview))
        .modelContainer(for: [Session.self, WarmupExercise.self])
}
