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
    @State private var timeElapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isCountingUp = false
    @State private var restStartTime: Date?

    init(duration: TimeInterval, onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        self._timeRemaining = State(initialValue: duration)
    }

    private var progress: Double {
        if isCountingUp {
            // When overtime, keep the ring full (1.0)
            1.0
        } else {
            1.0 - (timeRemaining / duration)
        }
    }

    private var progressColor: Color {
        isCountingUp ? Color.red : Color.green
    }

    private var timeString: String {
        let totalSeconds = isCountingUp ? Int(timeElapsed) : Int(timeRemaining)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let prefix = isCountingUp ? "+" : ""
        return String(format: "%@%d:%02d", prefix, minutes, seconds)
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
                        .stroke(progressColor, lineWidth: 8)
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                        .scaleEffect(isCountingUp ? (1.0 + 0.05 * sin(Date().timeIntervalSince1970 * 6)) : 1.0)

                    // Time display
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Dismiss button
                Button(action: {
                    stopTimer()
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.7))
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
        restStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isCountingUp {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    // Switch to count-up mode when timer reaches 0
                    isCountingUp = true
                    timeElapsed = 0
                }
            } else {
                timeElapsed += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    RestTimerView(
        duration: 10, // 10 seconds for testing
        onComplete: {
            print("Rest timer completed")
        },
        onDismiss: {
            print("Rest timer dismissed")
        }
    )
}
