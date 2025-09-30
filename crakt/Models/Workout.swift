//
//  Workout.swift
//  crakt
//
//  Created by Kyle Thompson on 12/18/24.
//

import Foundation
import SwiftData

/// Represents workout intensity levels
enum WorkoutIntensity: String, Codable, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case limit = "Limit"
    case progressive = "Progressive"

    var description: String {
        switch self {
        case .easy: return "Focus on technique and efficiency"
        case .moderate: return "Build strength and technique"
        case .hard: return "Push limits with challenging problems"
        case .limit: return "Maximum effort at your current level"
        case .progressive: return "Gradually increase difficulty"
        }
    }

    var colorIntensity: Double {
        switch self {
        case .easy: return 0.3
        case .moderate: return 0.5
        case .hard: return 0.7
        case .limit: return 1.0
        case .progressive: return 0.6
        }
    }
}

/// Represents the recommended rest duration for a workout
struct RestDuration: Codable {
    /// The typical/default rest duration in seconds
    let typical: TimeInterval

    /// The minimum recommended rest duration in seconds
    let minimum: TimeInterval

    /// The maximum recommended rest duration in seconds
    let maximum: TimeInterval

    /// Whether this workout has variable rest periods
    let isVariable: Bool

    /// Human-readable description of the rest duration
    let details: String

    /// Initialize with duration values in seconds
    init(typical: TimeInterval, minimum: TimeInterval, maximum: TimeInterval, isVariable: Bool = false, details: String) {
        self.typical = typical
        self.minimum = minimum
        self.maximum = maximum
        self.isVariable = isVariable
        self.details = details
    }

    /// Initialize with duration values in minutes (converted to seconds)
    static func minutes(typical: Double, minimum: Double, maximum: Double, isVariable: Bool = false, details: String) -> RestDuration {
        return RestDuration(
            typical: typical * 60,
            minimum: minimum * 60,
            maximum: maximum * 60,
            isVariable: isVariable,
            details: details
        )
    }
}

enum WorkoutType: String, Codable, CaseIterable {
    // Bouldering Workouts
    case limitBouldering = "Limit"
    case project = "Project"
    case pyramid = "Pyramid"

    // Rope Workouts
    case redpointBurns = "Redpoint"
    case mileageSessions = "Mileage"

    // Both Disciplines
    case flashPass = "Flash-Pass"
    case intervals = "Intervals"
    case upDown = "Up-Down"

    var category: WorkoutCategory {
        switch self {
        case .limitBouldering, .project:
            return .bouldering
        case .redpointBurns, .mileageSessions:
            return .ropes
        case .pyramid, .flashPass, .intervals, .upDown:
            return .both
        }
    }

    var workoutDescription: String {
        switch self {
        case .limitBouldering:
            return "Very short, powerful problems. Stop when quality drops. 3–5 attempts × 3–5 problems with \(restDuration.details)."
        case .project:
            return "Repeated work on a single hard problem until solved. 1 problem × 20–40 min with \(restDuration.details)."
        case .redpointBurns:
            return "Repeated attempts on a hard route until send or form breaks. 3–5 burns with \(restDuration.details)."
        case .flashPass:
            return "One attempt only per route, no retries. 3–6 routes with \(restDuration.details)."
        case .mileageSessions:
            return "Accumulate volume on moderate routes for efficiency. 8–12 pitches with \(restDuration.details)."
        case .pyramid:
            return "Step up in grade each climb until near limit, then descend. 6–10 climbs with \(restDuration.details)."
        case .intervals:
            return "Complete 4 climbs back-to-back, rest, repeat. 4 climbs × 3–4 sets with \(restDuration.details)."
        case .upDown:
            return "Climb up then immediately downclimb or reclimb. 4–8 reps with \(restDuration.details)."
        }
    }

    var shortDescription: String {
        self.rawValue
    }

    var icon: String {
        switch self {
        case .limitBouldering:
            return "target"
        case .project:
            return "hammer.fill"
        case .redpointBurns:
            return "flame.fill"
        case .flashPass:
            return "bolt.fill"
        case .mileageSessions:
            return "speedometer"
        case .pyramid:
            return "triangle.fill"
        case .intervals:
            return "timer"
        case .upDown:
            return "arrow.up.arrow.down.circle.fill"
        }
    }

    var requiresGradeSelection: Bool {
        switch self {
        case .limitBouldering, .project, .pyramid, .redpointBurns, .flashPass, .mileageSessions, .intervals:
            return true
        case .upDown:
            return false
        }
    }

    var requiresProblemCount: Bool {
        switch self {
        case .mileageSessions, .intervals:
            return true
        default:
            return false
        }
    }

    var requiresDuration: Bool {
        switch self {
        case .project, .pyramid:
            return true
        default:
            return false
        }
    }

    // MARK: - Workout Properties

    /// The intensity level of this workout
    var intensity: WorkoutIntensity {
        switch self {
        case .limitBouldering:
            return .limit
        case .project:
            return .hard
        case .redpointBurns:
            return .limit
        case .flashPass:
            return .hard
        case .mileageSessions:
            return .easy
        case .pyramid:
            return .progressive
        case .intervals:
            return .hard
        case .upDown:
            return .moderate
        }
    }

    /// The recommended rest duration for this workout
    var restDuration: RestDuration {
        switch self {
        case .limitBouldering:
            return .minutes(typical: 4, minimum: 3, maximum: 5, details: "3–5 minutes between attempts")
        case .project:
            return .minutes(typical: 3.5, minimum: 2, maximum: 5, details: "2–5 minutes between burns")
        case .redpointBurns:
            return .minutes(typical: 12.5, minimum: 10, maximum: 15, details: "10–15 minutes between burns")
        case .flashPass:
            return .minutes(typical: 5, minimum: 3, maximum: 10, isVariable: true, details: "full rest as needed")
        case .mileageSessions:
            return .minutes(typical: 1, minimum: 0.5, maximum: 2, isVariable: true, details: "short minimal rest")
        case .pyramid:
            return .minutes(typical: 3, minimum: 1, maximum: 5, isVariable: true, details: "1–3 minutes (easy) or 3–5 minutes (hard)")
        case .intervals:
            return .minutes(typical: 4, minimum: 3, maximum: 5, details: "3–5 minutes between sets")
        case .upDown:
            return .minutes(typical: 2.5, minimum: 1, maximum: 4, details: "1–4 minutes between reps")
        }
    }
}

enum WorkoutCategory {
    case bouldering
    case ropes
    case both

    var displayName: String {
        switch self {
        case .bouldering: return "🧗 Bouldering Workouts"
        case .ropes: return "🧗‍♂️ Rope Workouts"
        case .both: return "🧗‍♀️ Universal Workouts"
        }
    }

    var icon: String {
        switch self {
        case .bouldering: return "figure.climbing"
        case .ropes: return "figure.climbing"
        case .both: return "figure.climbing"
        }
    }
}

enum WorkoutStatus: Int, Codable {
    case active = 0
    case paused = 1
    case completed = 2
    case cancelled = 3

    var description: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

@Model
class Workout {
    var id: UUID
    var session: Session?
    var type: WorkoutType
    var status: WorkoutStatus = WorkoutStatus.active
    var startedAt: Date
    var endedAt: Date?

    var currentSetIndex: Int = 0
    var currentRepIndex: Int = 0

    var sets: [WorkoutSet] = []

    // Selected grade for single-grade workouts
    var selectedGrade: String?

    // Pyramid specific grades
    var pyramidStartGrade: String?
    var pyramidPeakGrade: String?

    // Computed properties
    var isActive: Bool {
        status == .active
    }

    var isCompleted: Bool {
        status == .completed
    }

    var currentSet: WorkoutSet? {
        guard currentSetIndex < sets.count else { return nil }
        return sets[currentSetIndex]
    }

    var currentRep: WorkoutRep? {
        guard let currentSet = currentSet,
              currentRepIndex < currentSet.reps.count else { return nil }
        return currentSet.reps[currentRepIndex]
    }

    var completionPercentage: Double {
        guard !sets.isEmpty else { return 0.0 }

        let totalReps = sets.reduce(0) { $0 + $1.reps.count }
        let completedReps = sets.prefix(currentSetIndex).reduce(0) { $0 + $1.reps.count } + currentRepIndex

        return totalReps > 0 ? Double(completedReps) / Double(totalReps) : 0.0
    }

    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps.count }
    }

    var completedReps: Int {
        sets.prefix(currentSetIndex).reduce(0) { $0 + $1.reps.count } + currentRepIndex
    }

    public init(session: Session, type: WorkoutType, selectedGrade: String? = nil, pyramidStartGrade: String? = nil, pyramidPeakGrade: String? = nil) {
        self.id = UUID()
        self.session = session
        self.type = type
        self.selectedGrade = selectedGrade
        self.pyramidStartGrade = pyramidStartGrade
        self.pyramidPeakGrade = pyramidPeakGrade
        self.startedAt = Date()

        // Initialize sets based on workout type
        self.sets = Self.createSetsForType(type, session: session)
    }

    private static func createSetsForType(_ type: WorkoutType, session: Session) -> [WorkoutSet] {
        switch type {
        // Bouldering workouts
        case .limitBouldering:
            return [WorkoutSet(workout: nil, setNumber: 1, targetReps: 5)] // Multiple attempts per problem

        case .project:
            return [WorkoutSet(workout: nil, setNumber: 1, targetReps: 5)] // Repeated attempts on single problem

        case .pyramid:
            // Easy → Medium → Hard → Medium → Easy (5 sets)
            return [
                WorkoutSet(workout: nil, setNumber: 1, targetReps: 1), // Easy
                WorkoutSet(workout: nil, setNumber: 2, targetReps: 1), // Medium
                WorkoutSet(workout: nil, setNumber: 3, targetReps: 1), // Hard
                WorkoutSet(workout: nil, setNumber: 4, targetReps: 1), // Medium
                WorkoutSet(workout: nil, setNumber: 5, targetReps: 1)  // Easy
            ]

        case .intervals:
            // 4 climbs × 3 sets (as per workout description)
            return [
                WorkoutSet(workout: nil, setNumber: 1, targetReps: 4),
                WorkoutSet(workout: nil, setNumber: 2, targetReps: 4),
                WorkoutSet(workout: nil, setNumber: 3, targetReps: 4)
            ]

        case .upDown:
            return [WorkoutSet(workout: nil, setNumber: 1, targetReps: 8)] // 4–8 reps

        case .flashPass:
            return [WorkoutSet(workout: nil, setNumber: 1, targetReps: 6)] // 3–6 routes

        // Rope workouts
        case .redpointBurns:
            return [WorkoutSet(workout: nil, setNumber: 1, targetReps: 5)] // 3–5 burns

        case .mileageSessions:
            return [WorkoutSet(workout: nil, setNumber: 1, targetReps: 12)] // Target pitch count
        }
    }

    // MARK: - Workout Progression Methods

    func advanceToNextRep() -> Bool {
        guard let currentSet = currentSet else { return false }

        currentRepIndex += 1

        // If we've completed all reps in current set, move to next set
        if currentRepIndex >= currentSet.reps.count {
            currentSetIndex += 1
            currentRepIndex = 0

            // If we've completed all sets, mark workout as completed
            if currentSetIndex >= sets.count {
                completeWorkout()
                return false // No more reps
            }
        }

        return true // Has more reps
    }

    func completeWorkout() {
        status = .completed
        endedAt = Date()
    }

    func pauseWorkout() {
        status = .paused
    }

    func resumeWorkout() {
        status = .active
    }

    func cancelWorkout() {
        status = .cancelled
        endedAt = Date()
    }

    // MARK: - Metrics

    var metrics: WorkoutMetrics {
        WorkoutMetrics(workout: self)
    }
}

@Model
class WorkoutSet {
    var id: UUID
    var setNumber: Int
    var targetReps: Int
    var startedAt: Date?
    var completedAt: Date?

    // Codified rest duration for this set
    var restDuration: RestDuration?

    var reps: [WorkoutRep] = []

    @Relationship(inverse: \Workout.sets)
    var workout: Workout?

    var isCompleted: Bool {
        completedAt != nil
    }

    var actualReps: Int {
        reps.count
    }

    var completionRate: Double {
        guard targetReps > 0 else { return 0.0 }
        return Double(actualReps) / Double(targetReps)
    }

    public init(workout: Workout?, setNumber: Int, targetReps: Int) {
        self.id = UUID()
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.workout = workout

        // Set the rest duration from the workout type
        self.restDuration = workout?.type.restDuration
    }
}

@Model
class WorkoutRep {
    var id: UUID
    var repNumber: Int
    var startedAt: Date?
    var completedAt: Date?
    var routeAttempt: RouteAttempt?

    // Codified rest duration for this rep
    var restDuration: RestDuration?

    @Relationship(inverse: \WorkoutSet.reps)
    var workoutSet: WorkoutSet?

    var isCompleted: Bool {
        completedAt != nil && routeAttempt != nil
    }

    var duration: TimeInterval? {
        guard let startedAt = startedAt, let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }

    public init(workoutSet: WorkoutSet?, repNumber: Int) {
        self.id = UUID()
        self.repNumber = repNumber
        self.workoutSet = workoutSet

        // Set the rest duration from the workout type
        self.restDuration = workoutSet?.workout?.type.restDuration
    }

    func start() {
        startedAt = Date()
    }

    func complete(with attempt: RouteAttempt) {
        completedAt = Date()
        routeAttempt = attempt
    }
}

struct WorkoutMetrics {
    let workout: Workout

    var totalDuration: TimeInterval? {
        guard let endedAt = workout.endedAt else { return nil }
        return endedAt.timeIntervalSince(workout.startedAt)
    }

    var totalReps: Int {
        workout.totalReps
    }

    var completedReps: Int {
        workout.completedReps
    }

    var sendRate: Double {
        guard totalReps > 0 else { return 0.0 }

        let sends = workout.sets.flatMap { $0.reps }
            .compactMap { $0.routeAttempt }
            .filter { $0.status == .send || $0.status == .flash }
            .count

        return Double(sends) / Double(totalReps)
    }

    var averageRestTime: TimeInterval? {
        let completedReps = workout.sets.flatMap { $0.reps }.filter { $0.isCompleted }

        guard completedReps.count > 1 else { return nil }

        var totalRestTime: TimeInterval = 0
        var restPeriods = 0

        for i in 1..<completedReps.count {
            if let prevEnd = completedReps[i-1].completedAt,
               let currStart = completedReps[i].startedAt {
                totalRestTime += currStart.timeIntervalSince(prevEnd)
                restPeriods += 1
            }
        }

        return restPeriods > 0 ? totalRestTime / Double(restPeriods) : nil
    }

    var hardestGradeAttempted: String? {
        let attempts = workout.sets.flatMap { $0.reps }
            .compactMap { $0.routeAttempt }
            .filter { $0.route != nil }

        return attempts.max { $0.route!.gradeIndex < $1.route!.gradeIndex }?.route?.grade
    }
}
