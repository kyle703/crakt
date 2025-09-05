//
//  WorkoutSelectorView.swift
//  crakt
//
//  Created by Kyle Thompson on 12/18/24.
//

import SwiftUI

struct WorkoutSelectorView: View {
    var orchestrator: WorkoutOrchestrator?
    @Environment(\.dismiss) var dismiss

    @State private var selectedWorkoutType: WorkoutType?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let orchestrator = orchestrator, orchestrator.isWorkoutActive {
                    activeWorkoutView(orchestrator: orchestrator)
                } else {
                    workoutSelectionView
                }
            }
            .navigationTitle(orchestrator?.isWorkoutActive == true ? "Active Workout" : "Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var workoutSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Choose a workout type to structure your climbing session")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                        WorkoutTypeCard(
                            workout: workoutType,
                            isSelected: selectedWorkoutType == workoutType,
                            action: {
                                selectedWorkoutType = workoutType
                            }
                        )
                    }
                }
                .padding(.horizontal)

                if let selectedType = selectedWorkoutType {
                    Button(action: {
                        if let orchestrator = orchestrator {
                            let success = orchestrator.startWorkout(type: selectedType)
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Start \(selectedType.shortDescription)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 24)
        }
    }

    private func activeWorkoutView(orchestrator: WorkoutOrchestrator) -> some View {
        VStack(spacing: 24) {
            if let workout = orchestrator.activeWorkout {
                // Workout status card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(workout.type.shortDescription)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Text(workout.status.description)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(workout.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(workout.isActive ? .green : .gray)
                            .cornerRadius(8)
                    }

                    // Progress bar
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * workout.completionPercentage, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text(orchestrator.workoutProgressDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(orchestrator.currentRepDescription)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    Text(orchestrator.nextActionDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Control buttons
                VStack(spacing: 12) {
                    if workout.isActive {
                        Button(action: {
                            orchestrator.pauseWorkout()
                        }) {
                            HStack {
                                Image(systemName: "pause.circle.fill")
                                Text("Pause Workout")
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    } else if workout.status == .paused {
                        Button(action: {
                            orchestrator.resumeWorkout()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Resume Workout")
                            }
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    Button(action: {
                        orchestrator.endWorkout()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Workout")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button(action: {
                        orchestrator.cancelWorkout()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel Workout")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.vertical, 24)
        .padding(.horizontal)
    }
}

#Preview {
    WorkoutSelectorView()
}
