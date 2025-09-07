//
//  RestTimerView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI

struct RestTimerView: View {
    let duration: TimeInterval
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @State private var timeRemaining: TimeInterval
    @State private var timer: Timer?
    @State private var isActive = true

    init(duration: TimeInterval, onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        self._timeRemaining = State(initialValue: duration)
    }

    private var progress: Double {
        1.0 - (timeRemaining / duration)
    }

    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Allow tapping background to dismiss
                    stopTimer()
                    onDismiss()
                }

            // Timer overlay
            VStack(spacing: 24) {
                Text("Rest Timer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Progress ring
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.green, lineWidth: 8)
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: progress)

                    // Time display
                    VStack(spacing: 8) {
                        Text(timeString)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Control buttons
                HStack(spacing: 40) {
                    Button(action: {
                        if isActive {
                            pauseTimer()
                        } else {
                            resumeTimer()
                        }
                    }) {
                        Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        stopTimer()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                timer = nil
                HapticManager.shared.playSuccess()
                onComplete()
            }
        }
    }

    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        HapticManager.shared.playAttempt()
    }

    private func resumeTimer() {
        isActive = true
        startTimer()
        HapticManager.shared.playAttempt()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
    }
}

#Preview {
    RestTimerView(
        duration: 120, // 2 minutes
        onComplete: {
            print("Rest timer completed")
        },
        onDismiss: {
            print("Rest timer dismissed")
        }
    )
}
