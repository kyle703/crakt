//
//  WorkoutOrchestrator.swift
//  crakt
//
//  Created by Kyle Thompson on 12/18/24.
//

import Foundation
import SwiftData
import Combine

class WorkoutOrchestrator: ObservableObject {
    @Published var activeWorkout: Workout?
    @Published var isWorkoutActive: Bool = false

    // Published computed properties for SwiftUI observation
    @Published private(set) var currentWorkoutProgress: (currentSet: Int, totalSets: Int, completedReps: Int, totalReps: Int) = (0, 0, 0, 0)

    private var session: Session
    private var modelContext: ModelContext

    // Public getter for session
    var publicSession: Session {
        session
    }

    init(session: Session, modelContext: ModelContext) {
        self.session = session
        self.modelContext = modelContext

        // Find existing active workout
        if let activeWorkout = session.workouts.first(where: { $0.isActive }) {
            self.activeWorkout = activeWorkout
            self.isWorkoutActive = true
        }
    }

    func updateModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Workout Management

    func startWorkout(type: WorkoutType, selectedGrade: String? = nil, pyramidStartGrade: String? = nil, pyramidPeakGrade: String? = nil) -> Bool {
        // End any existing active workout
        if let existingWorkout = activeWorkout {
            existingWorkout.cancelWorkout()
        }

        // Create new workout
        let workout = Workout(session: session, type: type, selectedGrade: selectedGrade, pyramidStartGrade: pyramidStartGrade, pyramidPeakGrade: pyramidPeakGrade)

        // Initialize reps for each set
        for set in workout.sets {
            for repNumber in 1...set.targetReps {
                let rep = WorkoutRep(workoutSet: set, repNumber: repNumber)
                set.reps.append(rep)
            }
        }

        // Set workout relationships
        workout.sets.forEach { $0.workout = workout }

        // Add to session and save
        session.workouts.append(workout)
        session.activeWorkout = workout

        do {
            try modelContext.save()
            activeWorkout = workout
            isWorkoutActive = true

            // Initialize workout progress for SwiftUI observation
            updateWorkoutProgress()

            return true
        } catch {
            print("Failed to start workout: \(error)")
            return false
        }
    }

    func pauseWorkout() {
        activeWorkout?.pauseWorkout()
        saveContext()
    }

    func resumeWorkout() {
        activeWorkout?.resumeWorkout()
        saveContext()
    }

    func endWorkout() {
        if let workout = activeWorkout {
            workout.completeWorkout()
            session.activeWorkout = nil
            activeWorkout = nil
            isWorkoutActive = false
            saveContext()
        }
    }

    func cancelWorkout() {
        if let workout = activeWorkout {
            workout.cancelWorkout()
            session.activeWorkout = nil
            activeWorkout = nil
            isWorkoutActive = false
            saveContext()
        }
    }

    // MARK: - Attempt Processing

    func processAttempt(_ attempt: RouteAttempt) -> WorkoutRep? {
        guard let workout = activeWorkout,
              let currentRep = workout.currentRep else {
            return nil
        }

        // Start the rep if not already started
        if currentRep.startedAt == nil {
            currentRep.start()
        }

        // Complete the rep with this attempt
        currentRep.complete(with: attempt)

        // DON'T advance to next rep here - only advance when route is logged
        // _ = workout.advanceToNextRep()

        // Update published progress for SwiftUI observation (iOS 18 compatibility)
        updateWorkoutProgress()

        // Force UI update for iOS 18 SwiftData compatibility
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }

        // If workout is completed, mark as inactive but keep reference for display
        if workout.isCompleted {
            session.activeWorkout = nil
            isWorkoutActive = false
            // Keep activeWorkout reference for progress display
        }

        saveContext()
        return currentRep
    }

    // Advance workout when a route is completed (logged)
    func advanceWorkoutOnRouteCompletion() {
        guard let workout = activeWorkout,
              let currentRep = workout.currentRep else { return }

        // Mark the current rep as completed (representing the completed route)
        if currentRep.completedAt == nil {
            // Create a dummy attempt if needed
            let dummyAttempt = RouteAttempt(status: .send)
            currentRep.complete(with: dummyAttempt)
        }

        // Advance to next rep/set
        _ = workout.advanceToNextRep()

        // Update published progress
        updateWorkoutProgress()

        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }

        // If workout is completed, mark as inactive but keep reference for display
        if workout.isCompleted {
            session.activeWorkout = nil
            isWorkoutActive = false
            // Keep activeWorkout reference for progress display
        }

        saveContext()
    }

    // MARK: - Current State

    var currentSetDescription: String {
        guard let workout = activeWorkout,
              let currentSet = workout.currentSet else {
            return "No active workout"
        }

        return "Set \(currentSet.setNumber) of \(workout.sets.count)"
    }

    var currentRepDescription: String {
        guard let workout = activeWorkout,
              let currentSet = workout.currentSet,
              let currentRep = workout.currentRep else {
            return "No active workout"
        }

        return "Rep \(currentRep.repNumber) of \(currentSet.targetReps)"
    }

    var workoutProgressDescription: String {
        guard let workout = activeWorkout else {
            return "No active workout"
        }

        let completed = workout.completedReps
        let total = workout.totalReps
        let percentage = Int(workout.completionPercentage * 100)

        return "\(completed)/\(total) reps (\(percentage)%)"
    }


    var nextActionDescription: String {
        guard let workout = activeWorkout,
              let currentRep = workout.currentRep else {
            return "Start a workout to begin"
        }

        if currentRep.isCompleted {
            return "Rep completed! Select next climb."
        } else {
            return "Complete the current climb to advance."
        }
    }

    // MARK: - Utility

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save workout context: \(error)")
        }
    }

    // Update published workout progress for SwiftUI observation
    func updateWorkoutProgress() {
        guard let workout = activeWorkout else {
            currentWorkoutProgress = (0, 0, 0, 0)
            return
        }

        // Count attempts on current active route as completed reps for current set
        let currentRouteAttempts = session.activeRoute?.attempts.count ?? 0

        currentWorkoutProgress = (
            currentSet: workout.currentSetIndex + 1,
            totalSets: workout.sets.count,
            completedReps: currentRouteAttempts,
            totalReps: workout.currentSet?.targetReps ?? 0
        )
    }

}
