//
//  SessionHeader.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct SessionHeader: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext

    var session: Session
    @ObservedObject var stopwatch: Stopwatch

    @Binding var selectedClimbType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem

    @State private var isPaused = false
    @State private var showExitAlert = false
    
    private var collapsedHeaderView: some View {
        HStack {
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
                }
            }

            Spacer()
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
                // Main timer and controls card
                VStack(spacing: 16) {

                    GradeSystemSelectionView(selectedClimbType: $selectedClimbType,
                                             selectedGradeSystem: $selectedGradeSystem)
                        .padding(.horizontal)
                        .padding(.bottom)



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



                    // Control buttons with consistent sizing
                    HStack(spacing: 20) {
                        Button(action: {
                            if isPaused {
                                stopwatch.start()
                            } else {
                                stopwatch.stop()
                            }
                            isPaused.toggle()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.title2)
                                Text(isPaused ? "Resume" : "Pause")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            self.showExitAlert = true
                            stopwatch.stop()
                            isPaused.toggle()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title2)
                                Text("End Session")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .alert(isPresented: $showExitAlert) {
                            Alert(
                                title: Text("End Session"),
                                message: Text("Are you sure you want to end your sesh?"),
                                primaryButton: .default(Text("Yes"), action: {
                                    session.completeSession(context: modelContext, elapsedTime: stopwatch.totalTime)
                                    self.presentationMode.wrappedValue.dismiss()
                                }),
                                secondaryButton: .cancel(Text("Just one more"), action : {
                                    stopwatch.start()
                                    isPaused.toggle()
                                })
                            )
                        }
                    }

                }
            }
            .padding(.horizontal, 16)
        }
    }
}
