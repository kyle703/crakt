//
//  SessionActionBar.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI
import SwiftData

struct SessionActionBar: View {
    @Bindable var session: Session
    var actionButton: AnyView?
    var workoutOrchestrator: WorkoutOrchestrator?

    @State private var showToppedButton: Bool = false
    @State private var flashButtonDisabled: Bool = false
    @State private var showWorkoutSelector = false

    var body: some View {
        VStack(spacing: 16) {
            // Workout Progress Bar (shown when workout is active)
            if let orchestrator = workoutOrchestrator, orchestrator.isWorkoutActive {
                workoutProgressView(orchestrator: orchestrator)
            }

            HStack(spacing: 20) {

                // Fail
                ActionButton(icon: ClimbStatus.fall.iconName,
                             label: ClimbStatus.fall.description,
                             color: ClimbStatus.fall.color,
                             action: {
                    performAction(.fall)
                },
                             hapticType: .attempt)

                // Send
                ActionButton(icon: ClimbStatus.send.iconName,
                             label: ClimbStatus.send.description,
                             color: ClimbStatus.send.color,
                             action: {
                    performAction(.send)
                },
                             hapticType: .success)

                                // Topped -- only for ropes
                if showToppedButton {
                //                ActionButton(icon: ClimbStatus.topped.iconName,
                //                             label: ClimbStatus.topped.description,
                //                             color: ClimbStatus.topped.color, action: {
                //                    performAction(.highpoint)
                //                })
                }

                // Flash
                ActionButton(icon: ClimbStatus.flash.iconName,
                             label: ClimbStatus.flash.description,
                             color: ClimbStatus.flash.color,
                             action: {
                    performAction(.flash)
                },
                             disabled: flashButtonDisabled,
                             hapticType: .success)

                Divider()

                // Workout Button
                Button(action: {
                    showWorkoutSelector = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: workoutOrchestrator?.isWorkoutActive == true ? "figure.climbing" : "plus.circle")
                        Text(workoutOrchestrator?.isWorkoutActive == true ? "Workout" : "Start")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(workoutOrchestrator?.isWorkoutActive == true ? .blue : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(workoutOrchestrator?.isWorkoutActive == true ?
                                  Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                if let actionButton {
                    actionButton
                }
            }.frame(height: 50)
        }
        .sheet(isPresented: $showWorkoutSelector) {
            WorkoutSelectorView(orchestrator: workoutOrchestrator)
        }
        .onAppear {
            updateButtonStates()
        }
        .onChange(of: session.activeRoute?.gradeSystem) { _, _ in
            updateButtonStates()
        }
        .onChange(of: session.activeRoute?.attempts.count) { _, _ in
            updateButtonStates()
        }
        .onChange(of: session.activeRoute?.id) { _, _ in
            updateButtonStates()
        }
    }

    private func updateButtonStates() {
        showToppedButton = session.activeRoute?.gradeSystem.climbType != .boulder
        flashButtonDisabled = (session.activeRoute?.attempts.count ?? 0) > 0
    }
    
    private func performAction(_ action: ClimbStatus) {
        if let activeRoute = session.activeRoute {
            let attempt = RouteAttempt(status: action)
            activeRoute.attempts.append(attempt)

            // Process attempt through workout orchestrator if active
            if let orchestrator = workoutOrchestrator {
                orchestrator.processAttempt(attempt)
            }
        }
    }

    private func workoutProgressView(orchestrator: WorkoutOrchestrator) -> some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * (orchestrator.activeWorkout?.completionPercentage ?? 0), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)

            // Progress text
            HStack {
                Text(orchestrator.workoutProgressDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(orchestrator.currentRepDescription)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(8)
    }
}

