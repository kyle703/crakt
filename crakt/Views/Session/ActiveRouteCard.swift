//
//  ActiveRouteCard.swift
//  crakt
//
//  Created by Kyle Thompson on 1/16/25.
//


import SwiftUI

struct ActiveRouteCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: Session
    @ObservedObject var stopwatch: Stopwatch

    @State private var availableStatuses: [ClimbStatus] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header with grade badge and delete button
            headerView
                .background(session.activeRoute?.gradeColor ?? .gray)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            VStack(spacing: 16) {
                // Attempt status display at the top
                attemptStatusView
                
                // Timer section
                timersView
                
                // Action buttons in 2x2 grid
                actionButtonsGrid
                
                // Wide log it button at the bottom
                logItButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .border(session.activeRoute?.gradeColor ?? .gray)
        .background(.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(session.activeRoute?.gradeColor ?? .gray, lineWidth: 4)
        )
        .padding(.horizontal, 8)
        .onAppear {
            updateAvailableStatuses()
        }
        .onChange(of: session.activeRoute?.gradeSystem) { _, _ in
            updateAvailableStatuses()
        }
        .onChange(of: session.activeRoute?.id) { _, _ in
            updateAvailableStatuses()
        }
    }

    private func updateAvailableStatuses() {
        guard let climbType = session.activeRoute?.gradeSystem.climbType else {
            availableStatuses = Array(ClimbStatus.allCases)
            return
        }
        availableStatuses = climbType == .boulder
            ? Array(ClimbStatus.fall.boulderTypes)
            : Array(ClimbStatus.allCases)
    }
    
    private var headerView: some View {
        HStack {
            // Grade badge on the left - made more prominent
            if let gradeDesc = session.activeRoute?.gradeDescription {
                Text(gradeDesc)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(16)
            }

            Spacer()

            // Delete button on the right
            Button(action: {
                session.clearRoute(context: modelContext)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var attemptStatusView: some View {
        HStack(spacing: 8) {
            ForEach(ClimbStatus.allCases, id: \.self) { status in
                if session.activeRoute?.attempts.filter({ $0.status == status }).count != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: status.iconName)
                            .font(.caption)
                            .foregroundColor(status.color)
                        Text("\(session.activeRoute?.attempts.filter { $0.status == status }.count ?? 0)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(status.color, lineWidth: 2)
                    )
                }
            }
            Spacer()
        }
    }

    private var timersView: some View {
        VStack(spacing: 6) {
            // Total time on route
            timerRow(title: "Route Time", time: stopwatch.totalTime.formatted)

            // Current rest time (time since last attempt)
            if let lastAttempt = session.activeRoute?.attempts.max(by: { $0.date < $1.date }) {
                let restTime = Date().timeIntervalSince(lastAttempt.date)
                timerRow(title: "Rest", time: restTime.formatted)
            } else {
                timerRow(title: "Rest", time: "00:00.0")
            }
        }
    }

    private func timerRow(title: String, time: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(time)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var actionButtonsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(availableStatuses, id: \.self) { status in
                ActionButton(
                    icon: status.iconName,
                    label: status.description,
                    size: 80,
                    color: status.color,
                    action: {
                        session.activeRoute?.addAttempt(status: status)
                        stopwatch.lap()
                    },
                    width: 120,
                    height: 80
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var logItButton: some View {
        Button(action: {
            session.logRoute()
            stopwatch.lap()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                Text("Log It!")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.green.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ActiveRouteCard(session: Session.active_preview, stopwatch: Stopwatch())
}
