//
//  WarmupExercise.swift
//  crakt
//
//  Created by Kyle Thompson on 1/27/25.
//

import Foundation
import SwiftData
import SwiftUI

enum ExerciseType: String, Codable, CaseIterable {
    case climbing = "Climbing"
    case yoga = "Yoga"
    case stretch = "Stretch"
    case cardio = "Cardio"
    case strength = "Strength"

    var iconName: String {
        switch self {
        case .climbing: return "figure.climbing"
        case .yoga: return "figure.mind.and.body"
        case .stretch: return "figure.flexibility"
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        }
    }

    var color: Color {
        switch self {
        case .climbing: return .blue
        case .yoga: return .purple
        case .stretch: return .green
        case .cardio: return .red
        case .strength: return .orange
        }
    }

    var sortOrder: Int {
        switch self {
        case .stretch: return 0
        case .cardio: return 1
        case .yoga: return 2
        case .strength: return 3
        case .climbing: return 4
        }
    }
}

@Model class WarmupExercise: Identifiable {
    var id: UUID
    var name: String
    var type: ExerciseType
    var duration: TimeInterval
    var exerciseDescription: String
    var instructions: String
    var isCustom: Bool = false
    var order: Int = 0

    var session: Session?

    static let allExercises: [WarmupExercise] = [
        WarmupExercise(
            name: "Shoulder Mobility",
            type: .stretch,
            duration: 120,
            exerciseDescription: "Shoulder and arm mobility",
            instructions: "Roll shoulders forward 10 times and backward 10 times. Complete 15 arm circles each direction, then 30 seconds of cross-body arm swings to finish."
        ),
        WarmupExercise(
            name: "Wrist & Finger Prep",
            type: .stretch,
            duration: 90,
            exerciseDescription: "Wrist and finger preparation",
            instructions: "Circle wrists 15 times each direction. Spread fingers wide then make a fist for 10 reps. Alternate prayer and reverse prayer stretches for 10 seconds, finishing with 10 palm presses."
        ),
        WarmupExercise(
            name: "Neck & Upper Back",
            type: .stretch,
            duration: 60,
            exerciseDescription: "Neck and upper back mobility",
            instructions: "Roll your neck in half circles 5 forward and 5 backward. Hold a shoulder blade squeeze for 5 seconds, release for 5 seconds for 10 reps. Finish with 10 thoracic twists."
        ),
        WarmupExercise(
            name: "Cardio Burst",
            type: .cardio,
            duration: 180,
            exerciseDescription: "Elevated heart rate preparation",
            instructions: "Alternate 30 seconds of marching with high knees and 30 seconds rest for three rounds. Finish with 20 slow, controlled mountain climbers."
        ),
        WarmupExercise(
            name: "Dynamic Swings",
            type: .cardio,
            duration: 120,
            exerciseDescription: "Hip and leg mobility with light cardio",
            instructions: "Face a wall for balance. Swing one leg forward/back 10 times, then side to side 10 times. Switch legs, add light arm swings, and keep the core braced."
        ),
        WarmupExercise(
            name: "Yoga Flow",
            type: .yoga,
            duration: 240,
            exerciseDescription: "Basic yoga flow for climbers",
            instructions: "Move from child's pose to downward dog for 30 seconds each, step into warrior I on both sides for 30 seconds, flow through plank to chaturanga three times, and finish with one minute of cat-cow."
        ),
        WarmupExercise(
            name: "Balance & Core",
            type: .yoga,
            duration: 120,
            exerciseDescription: "Core stability and balance",
            instructions: "Hold bird-dog for 10 seconds per side for five reps. Transition to a forearm plank: 20 seconds on, 20 seconds off, for three rounds while keeping hips level."
        ),
        WarmupExercise(
            name: "Antagonist Activation",
            type: .strength,
            duration: 150,
            exerciseDescription: "Balance climbing-specific muscles",
            instructions: "Complete three sets of eight slow push-ups. After each set do 15 banded external rotations per arm and 10 scapular push-ups with 30 seconds rest between sets."
        ),
        WarmupExercise(
            name: "Core & Hip Stability",
            type: .strength,
            duration: 120,
            exerciseDescription: "Core and hip strength for climbing",
            instructions: "Perform 10 dead bugs per side keeping the lower back planted. Follow with three sets of 10 glute bridges, holding the top for three seconds."
        ),
        WarmupExercise(
            name: "Easy Movement",
            type: .climbing,
            duration: 300,
            exerciseDescription: "Light climbing movement patterns",
            instructions: "Climb easy terrain with relaxed grip and precise feet. Downclimb each route and incorporate stemming, compression, heel hooks, and mantles."
        ),
        WarmupExercise(
            name: "Finger Prep",
            type: .climbing,
            duration: 180,
            exerciseDescription: "Finger tendon preparation",
            instructions: "Complete three rounds: 30 seconds open-hand hang on jugs, rest 20 seconds; 20 seconds half-crimp on a medium edge, rest 30 seconds. Between rounds perform 10 wrist extensions with a light band."
        ),
        WarmupExercise(
            name: "Sticky Hands & Feet",
            type: .climbing,
            duration: 240,
            exerciseDescription: "Commitment to first contact",
            instructions: "Climb easy routes without readjusting once a hand or foot touches a hold. Visualize each placement before moving. If you slip or adjust, climb down and repeat."
        ),
        WarmupExercise(
            name: "Silent Feet",
            type: .climbing,
            duration: 240,
            exerciseDescription: "Soundless foot placements",
            instructions: "Climb a circuit aiming for silent feet. Watch each placement until it is weighted. If you make noise, pause, reposition, and continue."
        ),
        WarmupExercise(
            name: "Hover Hands",
            type: .climbing,
            duration: 240,
            exerciseDescription: "Delayed commitment to holds",
            instructions: "On easy problems hover your hand a few inches above each hold for three seconds before grabbing. Use the hover to confirm grip choice while keeping hips engaged."
        ),
        WarmupExercise(
            name: "Straight Arms",
            type: .climbing,
            duration: 240,
            exerciseDescription: "Movement with relaxed arms",
            instructions: "Climb while keeping elbows straight when possible. Drive with legs and rotate hips to reach. If you bend an arm, pause, restack hips, and continue straight-armed."
        ),
        WarmupExercise(
            name: "Flag Every Move",
            type: .climbing,
            duration: 240,
            exerciseDescription: "Active flagging on each movement",
            instructions: "Climb a moderate circuit while flagging one leg on every move. Alternate inside and outside flags, pausing briefly after each to check balance."
        ),
        WarmupExercise(
            name: "High Feet",
            type: .climbing,
            duration: 240,
            exerciseDescription: "Commitment to elevated foot placements",
            instructions: "Choose footholds at or above knee height before each move. Shift hips over the high foot and trust the stand up. If it feels insecure, step down, reset, and recommit to the higher option."
        )
    ]

    static let defaultExercises: [WarmupExercise] = [
        allExercises[0],
        allExercises[3],
        allExercises[5]
    ]

    init(name: String, type: ExerciseType, duration: TimeInterval, exerciseDescription: String, instructions: String) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.duration = duration
        self.exerciseDescription = exerciseDescription
        self.instructions = instructions
    }

    init(id: UUID = UUID(), name: String, type: ExerciseType, duration: TimeInterval, exerciseDescription: String, instructions: String, isCustom: Bool = false, order: Int = 0) {
        self.id = id
        self.name = name
        self.type = type
        self.duration = duration
        self.exerciseDescription = exerciseDescription
        self.instructions = instructions
        self.isCustom = isCustom
        self.order = order
    }
}

