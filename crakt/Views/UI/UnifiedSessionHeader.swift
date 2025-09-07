//
//  UnifiedSessionHeader.swift
//  crakt
//
//  Created by Kyle Thompson on 1/27/25.
//

import SwiftUI
import SwiftData

struct UnifiedSessionHeader: View {
    @Environment(\.modelContext) private var modelContext

    var session: Session
    @ObservedObject var stopwatch: Stopwatch
    var workoutOrchestrator: WorkoutOrchestrator?
    var onSessionEnd: (() -> Void)?

    @Binding var selectedClimbType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem
    @Binding var selectedTab: Tab

    enum Tab {
        case routes
        case progress
        case menu
    }

    // Route HUD state
    @State private var showAttemptHistory = false

    private var sendCount: Int {
        session.activeRoute?.attempts.filter { $0.status == .send }.count ?? 0
    }

    private var fallCount: Int {
        session.activeRoute?.attempts.filter { $0.status == .fall }.count ?? 0
    }

    private var totalAttempts: Int {
        sendCount + fallCount
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row: Grade badge + Navigation tabs
            HStack(spacing: 16) {
                // Grade badge (always show if route exists)
                if let route = session.activeRoute {
                    Text(route.gradeDescription ?? "")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(route.gradeColor)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .onTapGesture {
                            showAttemptHistory = true
                        }
                }

                Spacer()

                // Navigation tabs (always show)
                HStack(spacing: 0) {
                    TabButton(
                        icon: "figure.climbing",
                        title: "Routes",
                        isSelected: selectedTab == .routes
                    ) {
                        selectedTab = .routes
                    }

                    TabButton(
                        icon: "chart.bar.fill",
                        title: "Progress",
                        isSelected: selectedTab == .progress
                    ) {
                        selectedTab = .progress
                    }

                    TabButton(
                        icon: "line.horizontal.3",
                        title: "Menu",
                        isSelected: selectedTab == .menu
                    ) {
                        selectedTab = .menu
                    }
                }
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            // Bottom row: Session info, workout stats, and attempt counters
            HStack(spacing: 16) {
                // Left side: Session timer and workout info
                VStack(alignment: .leading, spacing: 2) {
                    Text(stopwatch.totalTime.formatted)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
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

                // Right side: Attempt counters and progress (when active route exists)
                if session.activeRoute != nil {
                    HStack(spacing: 16) {
                        // Attempt counter
                        VStack(alignment: .leading, spacing: 2) {
                            Text("A:\(totalAttempts)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            HStack(spacing: 6) {
                                if sendCount > 0 {
                                    Text("S:\(sendCount)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                if fallCount > 0 {
                                    Text("F:\(fallCount)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Progress ring (only show when there's an active workout)
                        if workoutOrchestrator?.isWorkoutActive == true {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                    .frame(width: 32, height: 32)

                                Circle()
                                    .trim(from: 0, to: workoutOrchestrator?.activeWorkout?.completionPercentage ?? 0)
                                    .stroke(Color.blue, lineWidth: 3)
                                    .frame(width: 32, height: 32)
                                    .rotationEffect(.degrees(-90))

                                if let percentage = workoutOrchestrator?.activeWorkout?.completionPercentage {
                                    Text("\(Int(percentage * 100))%")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showAttemptHistory) {
            if let route = session.activeRoute {
                AttemptHistoryView(
                    route: route,
                    onDeleteAttempt: { attempt in
                        // Handle attempt deletion
                        route.attempts.removeAll { $0.id == attempt.id }
                        workoutOrchestrator?.updateWorkoutProgress()
                    },
                    onDismiss: {
                        showAttemptHistory = false
                    }
                )
            }
        }
    }

}

#Preview {
    let tempContext = try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext
    let session = Session.active_preview
    let workoutOrchestrator = WorkoutOrchestrator(session: session, modelContext: tempContext)
    let stopwatch = Stopwatch()

    return UnifiedSessionHeader(
        session: session,
        stopwatch: stopwatch,
        workoutOrchestrator: workoutOrchestrator,
        selectedClimbType: .constant(.boulder),
        selectedGradeSystem: .constant(.vscale),
        selectedTab: .constant(.routes)
    )
    .padding(.vertical)
    .background(Color.gray.opacity(0.1))
}

private func TabButton(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .blue : .secondary)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .blue : .secondary)
        }
        .frame(width: 60, height: 50)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}
