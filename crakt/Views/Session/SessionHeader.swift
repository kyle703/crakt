//
//  SessionHeader.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct SessionHeader: View {

    @Environment(\.modelContext) private var modelContext

    var session: Session
    @ObservedObject var stopwatch: Stopwatch
    var workoutOrchestrator: WorkoutOrchestrator?
    var onSessionEnd: (() -> Void)?

    @Binding var selectedClimbType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem

    @State private var isPaused = false
    @State private var showExitAlert = false
    
    private var collapsedHeaderView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stopwatch.totalTime.formatted)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(selectedClimbType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)

                        Text(selectedGradeSystem.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)

                        // Workout status chip
                        if let orchestrator = workoutOrchestrator, orchestrator.isWorkoutActive {
                            Text(orchestrator.activeWorkout?.type.shortDescription ?? "Workout")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }

                Spacer()
            }

            // Workout progress bar (shown when workout is active)
            if let orchestrator = workoutOrchestrator, orchestrator.isWorkoutActive {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)

                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (orchestrator.activeWorkout?.completionPercentage ?? 0), height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    var body: some View {
        if session.activeRoute != nil {
            // Collapsed view when there's an active route
            collapsedHeaderView
        } else {
            // Full expanded view when no active route
            VStack(spacing: 16) {
                // Main timer card
                VStack(spacing: 16) {
                    // Timer display - bold and central
                    VStack(spacing: 8) {
                        Text(stopwatch.totalTime.formatted)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(minWidth: 120, maxWidth: .infinity)

                        Text("Total Session Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }

                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4)
            }
            .padding(.horizontal, 16)
        }
    }
}
